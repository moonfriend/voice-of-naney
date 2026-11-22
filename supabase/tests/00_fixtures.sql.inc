-- Shared fixtures, included by every test file with \ir. Runs as the postgres superuser
-- inside the test transaction, so everything is rolled back afterwards.

create extension if not exists pgtap with schema extensions;
create schema tests;
grant usage on schema tests to anon, authenticated, service_role;

insert into auth.users (id, email, aud, role)
values
  ('00000000-0000-0000-0000-0000000000a1', 'uploader1@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000a2', 'uploader2@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000ad', 'admin@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000d1', 'disabled@test.local', 'authenticated', 'authenticated');

update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-0000000000ad';
update public.profiles set disabled = true where id = '00000000-0000-0000-0000-0000000000d1';

insert into public.cultures (id, name_en, name_fa)
overriding system value
values (1, 'Azeri', 'آذری'), (2, 'Kurdish', 'کرد'), (3, 'Lur', 'لر'), (4, 'Gilaki', 'گیلک');

insert into public.languages (id, name_en, name_fa)
overriding system value
values (1, 'Azerbaijani', 'ترکی آذربایجانی'), (2, 'Kurdish', 'کردی');

-- A small square around Tabriz.
insert into public.places (id, name_en, name_fa, kind, osm_type, osm_id, area, label_point)
overriding system value
values (
  1, 'Tabriz', 'تبریز', 'city', 'relation', 123456,
  extensions.st_geogfromtext('MULTIPOLYGON(((46.2 38.0, 46.4 38.0, 46.4 38.15, 46.2 38.15, 46.2 38.0)))'),
  extensions.st_geogfromtext('POINT(46.29 38.08)')
);

-- Explicit ids above do not advance identity counters; move them past the fixture rows
-- so inserts made by the code under test do not collide (matters on a fresh database).
select setval(pg_get_serial_sequence('public.places', 'id'), (select max(id) from public.places));
select setval(pg_get_serial_sequence('public.cultures', 'id'), (select max(id) from public.cultures));
select setval(pg_get_serial_sequence('public.languages', 'id'), (select max(id) from public.languages));

insert into public.uploads (id, object_key, owner, purpose, mime, declared_size, verified_at)
values
  -- verified media + photo for uploader1
  ('10000000-0000-0000-0000-000000000001', 'media/u1-a.mp3', '00000000-0000-0000-0000-0000000000a1', 'media', 'audio/mpeg', 1000, now()),
  ('10000000-0000-0000-0000-000000000002', 'photos/u1-p.jpg', '00000000-0000-0000-0000-0000000000a1', 'photo', 'image/jpeg', 500, now()),
  ('10000000-0000-0000-0000-000000000003', 'media/u1-b.mp4', '00000000-0000-0000-0000-0000000000a1', 'media', 'video/mp4', 9000, now()),
  -- not yet verified
  ('10000000-0000-0000-0000-000000000004', 'media/u1-unverified.mp3', '00000000-0000-0000-0000-0000000000a1', 'media', 'audio/mpeg', 1000, null),
  -- belongs to uploader2
  ('10000000-0000-0000-0000-000000000005', 'media/u2-a.mp3', '00000000-0000-0000-0000-0000000000a2', 'media', 'audio/mpeg', 1000, now()),
  -- belongs to the disabled user
  ('10000000-0000-0000-0000-000000000006', 'media/d1-a.mp3', '00000000-0000-0000-0000-0000000000d1', 'media', 'audio/mpeg', 1000, now());

-- Switches the session to an authenticated user (or anon when user_id is null).
create or replace function tests.act_as(user_id uuid) returns void
language plpgsql as $$
begin
  if user_id is null then
    perform set_config('role', 'anon', true);
    perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  else
    perform set_config('role', 'authenticated', true);
    perform set_config(
      'request.jwt.claims',
      json_build_object('sub', user_id, 'role', 'authenticated')::text,
      true
    );
  end if;
end;
$$;

-- A valid create_recording payload for uploader1; tests override single fields.
create or replace function tests.valid_payload() returns jsonb
language sql as $$
  select jsonb_build_object(
    'title', 'Lay lay',
    'description', 'A lullaby my grandmother sang',
    'kind', 'lullaby',
    'tags', jsonb_build_array('sleep', 'night'),
    'performer_name', 'Naney',
    'year_recorded', 1998,
    'language_id', 1,
    'place_id', 1,
    'origin_note', 'Family moved from Urmia to Tabriz',
    'consent', true,
    'media_upload_id', '10000000-0000-0000-0000-000000000001',
    'duration_ms', 61000,
    'photo_upload_id', '10000000-0000-0000-0000-000000000002',
    'cultures', jsonb_build_array(
      jsonb_build_object('culture_id', 1),
      jsonb_build_object('other_text', 'Qarapapaq')
    )
  );
$$;

grant execute on function tests.act_as(uuid) to anon, authenticated;
grant execute on function tests.valid_payload() to anon, authenticated;
