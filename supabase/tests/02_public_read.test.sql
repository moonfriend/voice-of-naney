begin;
\ir 00_fixtures.sql.inc
select * from no_plan();

-- Two recordings by uploader1; one is hidden by an admin afterwards.
select tests.act_as('00000000-0000-0000-0000-0000000000a1');
select public.create_recording(tests.valid_payload()) as published_id \gset
select public.create_recording(
  tests.valid_payload()
  || jsonb_build_object('title', 'Secret', 'media_upload_id', '10000000-0000-0000-0000-000000000003',
                        'photo_upload_id', null)
) as hidden_id \gset
reset role;
update public.recordings set status = 'hidden' where id = :'hidden_id';

-- Anonymous visitors
select tests.act_as(null);

select results_eq(
  'select title from public.recordings order by title',
  array['Lay lay'],
  'anon sees only published recordings'
);
select is((select count(*)::int from public.recording_media), 1, 'anon sees media of published recordings only');
select is((select count(*)::int from public.recording_cultures), 2, 'anon sees cultures of published recordings only');
select is((select count(*)::int from public.places), 1, 'anon can read places');
select is((select count(*)::int from public.cultures), 4, 'anon can read cultures');
select is((select count(*)::int from public.languages), 2, 'anon can read languages');
select throws_ok('select * from public.uploads', '42501', null, 'anon cannot read uploads');
select throws_ok('select * from public.profiles', '42501', null, 'anon cannot read profiles');
select throws_ok(
  $$insert into public.cultures (name_en, name_fa) values ('X', 'X')$$,
  '42501', null, 'anon cannot add cultures'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload())$$,
  '42501', null, 'anon cannot create recordings'
);

-- Map pins: one place, counting only the published recording.
select results_eq(
  $$select place_id, recording_count from public.map_pins(46.0, 37.9, 46.6, 38.3)$$,
  $$values (1::bigint, 1::bigint)$$,
  'map_pins counts published recordings in the viewport'
);
select is_empty(
  $$select * from public.map_pins(50.0, 30.0, 51.0, 31.0)$$,
  'map_pins is empty outside the viewport'
);
select results_eq(
  $$select place_id from public.map_pins(46.0, 37.9, 46.6, 38.3, p_culture_ids => array[1::bigint])$$,
  $$values (1::bigint)$$,
  'map_pins filters by culture (match)'
);
select is_empty(
  $$select * from public.map_pins(46.0, 37.9, 46.6, 38.3, p_culture_ids => array[3::bigint])$$,
  'map_pins filters by culture (no match)'
);
select is_empty(
  $$select * from public.map_pins(46.0, 37.9, 46.6, 38.3, p_kinds => array['poem'::public.recording_kind])$$,
  'map_pins filters by kind'
);
select results_eq(
  $$select place_id from public.map_pins(46.0, 37.9, 46.6, 38.3, p_tag => 'sleep')$$,
  $$values (1::bigint)$$,
  'map_pins filters by tag'
);
select isnt_empty(
  $$select * from public.place_areas(46.0, 37.9, 46.6, 38.3)$$,
  'place_areas returns outlines in the viewport'
);

-- The owner still sees their own hidden recording.
select tests.act_as('00000000-0000-0000-0000-0000000000a1');
select is((select count(*)::int from public.recordings), 2, 'the owner sees their own hidden recording');

-- Another uploader does not.
select tests.act_as('00000000-0000-0000-0000-0000000000a2');
select is((select count(*)::int from public.recordings), 1, 'other uploaders do not see hidden recordings');

select * from finish();
rollback;
