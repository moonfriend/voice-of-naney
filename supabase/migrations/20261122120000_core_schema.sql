-- Voice of Naney — core schema.
-- Security model:
--   * anon: reads published recordings and the lookup tables, nothing else.
--   * authenticated uploaders: create recordings only through create_recording(),
--     edit metadata of their own recordings, never moderation fields or media rows.
--   * admin tooling and the Worker use the secret key (service_role, bypasses RLS).

create extension if not exists postgis with schema extensions;

-- ---------------------------------------------------------------- types
create type public.user_role as enum ('admin', 'uploader');
create type public.recording_kind as enum ('lullaby', 'poem', 'wisdom', 'murmur', 'other');
create type public.recording_status as enum ('published', 'hidden');
create type public.media_type as enum ('audio', 'video');
create type public.upload_purpose as enum ('media', 'photo');
create type public.place_kind as enum ('country', 'province', 'city', 'district', 'village', 'custom');

-- ---------------------------------------------------------------- profiles
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.user_role not null default 'uploader',
  display_name text check (char_length(display_name) <= 100),
  disabled boolean not null default false,
  created_at timestamptz not null default now()
);

-- Sign-ups are disabled, so every auth user is someone an admin invited.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.is_active_uploader() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and not disabled
  );
$$;

-- ---------------------------------------------------------------- lookup lists
create table public.cultures (
  id bigint generated always as identity primary key,
  name_en text not null check (char_length(btrim(name_en)) between 1 and 100),
  name_fa text not null check (char_length(btrim(name_fa)) between 1 and 100),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index cultures_name_en_key on public.cultures (lower(name_en));

create table public.languages (
  id bigint generated always as identity primary key,
  name_en text not null check (char_length(btrim(name_en)) between 1 and 100),
  name_fa text not null check (char_length(btrim(name_fa)) between 1 and 100),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index languages_name_en_key on public.languages (lower(name_en));

-- ---------------------------------------------------------------- places (origin areas)
create table public.places (
  id bigint generated always as identity primary key,
  name_en text check (char_length(name_en) <= 200),
  name_fa text check (char_length(name_fa) <= 200),
  kind public.place_kind not null,
  osm_type text check (osm_type in ('node', 'way', 'relation')),
  osm_id bigint,
  area extensions.geography(MultiPolygon, 4326) not null,
  label_point extensions.geography(Point, 4326) not null,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  constraint places_name_present check (coalesce(btrim(name_en), '') <> '' or coalesce(btrim(name_fa), '') <> ''),
  constraint places_osm_ref_complete check ((osm_type is null) = (osm_id is null)),
  constraint places_osm_ref_unique unique (osm_type, osm_id)
);
create index places_label_point_idx on public.places using gist (label_point);
create index places_area_idx on public.places using gist (area);

-- ---------------------------------------------------------------- uploads (written by the Worker)
create table public.uploads (
  id uuid primary key default gen_random_uuid(),
  object_key text not null unique,
  owner uuid not null references auth.users (id) on delete cascade,
  purpose public.upload_purpose not null,
  mime text not null,
  declared_size bigint not null check (declared_size > 0),
  multipart_upload_id text,
  created_at timestamptz not null default now(),
  verified_at timestamptz,
  consumed_at timestamptz
);
create index uploads_owner_created_idx on public.uploads (owner, created_at desc);

-- ---------------------------------------------------------------- recordings
create table public.recordings (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 1 and 200),
  description text check (char_length(description) <= 5000),
  kind public.recording_kind not null,
  tags text[] not null default '{}' check (cardinality(tags) <= 20),
  transcript text check (char_length(transcript) <= 20000),
  photo_key text,
  performer_name text check (char_length(performer_name) <= 200),
  year_recorded integer check (year_recorded between 1800 and 2100),
  language_id bigint references public.languages (id),
  language_other text check (char_length(language_other) <= 100),
  place_id bigint not null references public.places (id),
  origin_note text check (char_length(origin_note) <= 2000),
  consent_confirmed_at timestamptz not null,
  consent_by uuid not null references auth.users (id),
  status public.recording_status not null default 'published',
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint recordings_single_language check (language_id is null or language_other is null)
);
create index recordings_place_idx on public.recordings (place_id) where status = 'published';
create index recordings_tags_idx on public.recordings using gin (tags);

create function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger recordings_touch_updated_at
  before update on public.recordings
  for each row execute function public.touch_updated_at();

-- 1–3 cultures per recording: either a curated culture or free text.
create table public.recording_cultures (
  recording_id uuid not null references public.recordings (id) on delete cascade,
  position smallint not null check (position between 1 and 3),
  culture_id bigint references public.cultures (id),
  other_text text check (char_length(btrim(other_text)) between 1 and 200),
  primary key (recording_id, position),
  constraint recording_cultures_one_source check ((culture_id is null) <> (other_text is null))
);
create index recording_cultures_culture_idx on public.recording_cultures (culture_id);

-- Media revisions: revision 0 is the uploader's original and never changes.
create table public.recording_media (
  id uuid primary key default gen_random_uuid(),
  recording_id uuid not null references public.recordings (id) on delete restrict,
  revision_no integer not null check (revision_no >= 0),
  media_type public.media_type not null,
  object_key text not null unique,
  mime text not null,
  size_bytes bigint not null check (size_bytes > 0),
  duration_ms integer check (duration_ms >= 0),
  note text check (char_length(note) <= 1000),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (recording_id, revision_no)
);

create function public.protect_recording_media() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' then
    raise exception using message = 'media_rows_are_immutable', errcode = 'P0001';
  end if;
  if old.revision_no = 0 then
    raise exception using message = 'original_media_cannot_be_deleted', errcode = 'P0001';
  end if;
  return old;
end;
$$;

create trigger recording_media_protect
  before update or delete on public.recording_media
  for each row execute function public.protect_recording_media();

-- ---------------------------------------------------------------- row-level security
alter table public.profiles enable row level security;
alter table public.cultures enable row level security;
alter table public.languages enable row level security;
alter table public.places enable row level security;
alter table public.uploads enable row level security;
alter table public.recordings enable row level security;
alter table public.recording_cultures enable row level security;
alter table public.recording_media enable row level security;

-- Start from zero privileges for API roles and grant only what is needed.
revoke all on all tables in schema public from anon, authenticated;
revoke all on all functions in schema public from anon, authenticated, public;
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on functions from anon, authenticated, public;

grant select on public.cultures, public.languages, public.places,
  public.recordings, public.recording_cultures, public.recording_media
  to anon, authenticated;
grant select on public.profiles to authenticated;
grant update (title, description, kind, tags, transcript, performer_name, year_recorded,
  language_id, language_other, origin_note)
  on public.recordings to authenticated;

create policy "lookup lists are public" on public.cultures for select using (true);
create policy "lookup lists are public" on public.languages for select using (true);
create policy "places are public" on public.places for select using (true);

create policy "users read their own profile" on public.profiles
  for select to authenticated using (id = (select auth.uid()));

create policy "published recordings are public; owners see their own" on public.recordings
  for select using (status = 'published' or created_by = (select auth.uid()));

create policy "owners edit their own recordings" on public.recordings
  for update to authenticated
  using (created_by = (select auth.uid()) and (select public.is_active_uploader()))
  with check (created_by = (select auth.uid()));

create policy "children follow recording visibility" on public.recording_cultures
  for select using (exists (select 1 from public.recordings r where r.id = recording_id));

create policy "children follow recording visibility" on public.recording_media
  for select using (exists (select 1 from public.recordings r where r.id = recording_id));

-- ---------------------------------------------------------------- RPC: places
create function public.upsert_place(p jsonb) returns bigint
language plpgsql security definer set search_path = '' as $$
declare
  v_id bigint;
  v_geom extensions.geometry;
  v_name_en text := nullif(btrim(p ->> 'name_en'), '');
  v_name_fa text := nullif(btrim(p ->> 'name_fa'), '');
begin
  if not public.is_active_uploader() then
    raise exception using message = 'not_allowed', errcode = 'P0001';
  end if;

  if p ? 'osm_id' and p ->> 'osm_id' is not null then
    select id into v_id from public.places
    where osm_type = p ->> 'osm_type' and osm_id = (p ->> 'osm_id')::bigint;
    if v_id is not null then
      return v_id;
    end if;
  end if;

  if v_name_en is null and v_name_fa is null then
    raise exception using message = 'place_name_required', errcode = 'P0001';
  end if;

  v_geom := extensions.st_setsrid(extensions.st_geomfromgeojson((p -> 'geojson')::text), 4326);
  if extensions.geometrytype(v_geom) not in ('POLYGON', 'MULTIPOLYGON') then
    raise exception using message = 'area_must_be_polygon', errcode = 'P0001';
  end if;
  -- Keep stored outlines light: ~50 m tolerance is plenty for a village/region shape.
  v_geom := extensions.st_multi(
    extensions.st_makevalid(extensions.st_simplifypreservetopology(v_geom, 0.0005))
  );
  v_geom := extensions.st_multi(extensions.st_collectionextract(v_geom, 3));
  if extensions.st_isempty(v_geom) then
    raise exception using message = 'area_must_be_polygon', errcode = 'P0001';
  end if;

  insert into public.places (name_en, name_fa, kind, osm_type, osm_id, area, label_point, created_by)
  values (
    v_name_en, v_name_fa, (p ->> 'kind')::public.place_kind,
    p ->> 'osm_type', (p ->> 'osm_id')::bigint,
    v_geom::extensions.geography,
    extensions.st_pointonsurface(v_geom)::extensions.geography,
    (select auth.uid())
  )
  returning id into v_id;
  return v_id;
end;
$$;

-- ---------------------------------------------------------------- RPC: create a recording
create function public.claim_upload(p_upload_id uuid, p_purpose public.upload_purpose)
returns public.uploads
language plpgsql security definer set search_path = '' as $$
declare
  v_upload public.uploads;
begin
  update public.uploads
  set consumed_at = now()
  where id = p_upload_id
    and owner = (select auth.uid())
    and purpose = p_purpose
    and verified_at is not null
    and consumed_at is null
  returning * into v_upload;
  if v_upload.id is null then
    raise exception using message = 'upload_not_usable', errcode = 'P0001';
  end if;
  return v_upload;
end;
$$;

create function public.create_recording(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := (select auth.uid());
  v_recording_id uuid;
  v_media public.uploads;
  v_photo public.uploads;
  v_cultures jsonb := coalesce(p -> 'cultures', '[]'::jsonb);
  v_entry jsonb;
  v_position smallint := 0;
begin
  if v_user is null or not public.is_active_uploader() then
    raise exception using message = 'not_allowed', errcode = 'P0001';
  end if;
  if coalesce((p ->> 'consent')::boolean, false) is not true then
    raise exception using message = 'consent_required', errcode = 'P0001';
  end if;
  if jsonb_typeof(v_cultures) <> 'array' or jsonb_array_length(v_cultures) not between 1 and 3 then
    raise exception using message = 'cultures_count_invalid', errcode = 'P0001';
  end if;

  v_media := public.claim_upload((p ->> 'media_upload_id')::uuid, 'media');
  if p ->> 'photo_upload_id' is not null then
    v_photo := public.claim_upload((p ->> 'photo_upload_id')::uuid, 'photo');
  end if;

  insert into public.recordings (
    title, description, kind, tags, transcript, photo_key, performer_name, year_recorded,
    language_id, language_other, place_id, origin_note,
    consent_confirmed_at, consent_by, created_by
  )
  values (
    btrim(p ->> 'title'),
    nullif(btrim(p ->> 'description'), ''),
    (p ->> 'kind')::public.recording_kind,
    coalesce(array(select btrim(t) from jsonb_array_elements_text(p -> 'tags') as t where btrim(t) <> ''), '{}'),
    nullif(btrim(p ->> 'transcript'), ''),
    v_photo.object_key,
    nullif(btrim(p ->> 'performer_name'), ''),
    (p ->> 'year_recorded')::integer,
    (p ->> 'language_id')::bigint,
    nullif(btrim(p ->> 'language_other'), ''),
    (p ->> 'place_id')::bigint,
    nullif(btrim(p ->> 'origin_note'), ''),
    now(), v_user, v_user
  )
  returning id into v_recording_id;

  for v_entry in select value from jsonb_array_elements(v_cultures) loop
    v_position := v_position + 1;
    if (v_entry ? 'culture_id' and v_entry ->> 'culture_id' is not null)
       = (v_entry ? 'other_text' and nullif(btrim(v_entry ->> 'other_text'), '') is not null) then
      raise exception using message = 'culture_entry_invalid', errcode = 'P0001';
    end if;
    insert into public.recording_cultures (recording_id, position, culture_id, other_text)
    values (
      v_recording_id, v_position,
      (v_entry ->> 'culture_id')::bigint,
      nullif(btrim(v_entry ->> 'other_text'), '')
    );
  end loop;

  insert into public.recording_media (
    recording_id, revision_no, media_type, object_key, mime, size_bytes, duration_ms, created_by
  )
  values (
    v_recording_id, 0,
    case when v_media.mime like 'video/%' then 'video' else 'audio' end::public.media_type,
    v_media.object_key, v_media.mime, v_media.declared_size,
    (p ->> 'duration_ms')::integer, v_user
  );

  return v_recording_id;
end;
$$;

-- ---------------------------------------------------------------- RPC: map reads
-- security invoker: RLS decides what each caller may count.
create function public.map_pins(
  p_min_lng double precision,
  p_min_lat double precision,
  p_max_lng double precision,
  p_max_lat double precision,
  p_culture_ids bigint[] default null,
  p_language_ids bigint[] default null,
  p_kinds public.recording_kind[] default null,
  p_tag text default null
)
returns table (
  place_id bigint,
  name_en text,
  name_fa text,
  lng double precision,
  lat double precision,
  recording_count bigint
)
language sql stable security invoker set search_path = '' as $$
  select
    pl.id, pl.name_en, pl.name_fa,
    extensions.st_x(pl.label_point::extensions.geometry),
    extensions.st_y(pl.label_point::extensions.geometry),
    count(distinct r.id)
  from public.places pl
  join public.recordings r on r.place_id = pl.id and r.status = 'published'
  where pl.label_point operator(extensions.&&)
        extensions.st_makeenvelope(p_min_lng, p_min_lat, p_max_lng, p_max_lat, 4326)::extensions.geography
    and (p_language_ids is null or r.language_id = any (p_language_ids))
    and (p_kinds is null or r.kind = any (p_kinds))
    and (p_tag is null or p_tag = any (r.tags))
    and (p_culture_ids is null or exists (
      select 1 from public.recording_cultures rc
      where rc.recording_id = r.id and rc.culture_id = any (p_culture_ids)
    ))
  group by pl.id;
$$;

create function public.place_areas(
  p_min_lng double precision,
  p_min_lat double precision,
  p_max_lng double precision,
  p_max_lat double precision
)
returns table (place_id bigint, geojson jsonb)
language sql stable security invoker set search_path = '' as $$
  select pl.id, extensions.st_asgeojson(pl.area, 5)::jsonb
  from public.places pl
  where pl.area operator(extensions.&&)
        extensions.st_makeenvelope(p_min_lng, p_min_lat, p_max_lng, p_max_lat, 4326)::extensions.geography
    and exists (select 1 from public.recordings r where r.place_id = pl.id and r.status = 'published');
$$;

-- Outline of one place (for the recording page mini-map); only places with a visible recording.
create function public.place_area(p_place_id bigint) returns jsonb
language sql stable security invoker set search_path = '' as $$
  select extensions.st_asgeojson(pl.area, 5)::jsonb
  from public.places pl
  where pl.id = p_place_id
    and exists (select 1 from public.recordings r where r.place_id = pl.id);
$$;

grant execute on function public.place_area(bigint) to anon, authenticated;
grant execute on function public.map_pins(double precision, double precision, double precision,
  double precision, bigint[], bigint[], public.recording_kind[], text) to anon, authenticated;
grant execute on function public.place_areas(double precision, double precision, double precision,
  double precision) to anon, authenticated;
grant execute on function public.create_recording(jsonb) to authenticated;
grant execute on function public.upsert_place(jsonb) to authenticated;
grant execute on function public.is_active_uploader() to authenticated;
