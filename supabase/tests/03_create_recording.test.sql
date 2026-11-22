begin;
\ir 00_fixtures.sql.inc
select * from no_plan();

select tests.act_as('00000000-0000-0000-0000-0000000000a1');

-- Validation failures (each must leave no trace).
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"consent": false}')$$,
  'P0001', 'consent_required', 'consent is required'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"cultures": []}')$$,
  'P0001', 'cultures_count_invalid', 'at least one culture is required'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || jsonb_build_object('cultures', jsonb_build_array(
      jsonb_build_object('culture_id', 1), jsonb_build_object('culture_id', 2),
      jsonb_build_object('culture_id', 3), jsonb_build_object('culture_id', 4))))$$,
  'P0001', 'cultures_count_invalid', 'at most three cultures'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || jsonb_build_object('cultures', jsonb_build_array(
      jsonb_build_object('culture_id', 1, 'other_text', 'both'))))$$,
  'P0001', 'culture_entry_invalid', 'a culture entry is either from the list or other text'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"media_upload_id": "10000000-0000-0000-0000-000000000004"}')$$,
  'P0001', 'upload_not_usable', 'unverified uploads are rejected'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"media_upload_id": "10000000-0000-0000-0000-000000000005"}')$$,
  'P0001', 'upload_not_usable', 'another user''s upload is rejected'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"media_upload_id": "10000000-0000-0000-0000-000000000002"}')$$,
  'P0001', 'upload_not_usable', 'a photo upload cannot be used as media'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"title": "  "}')$$,
  '23514', null, 'an empty title is rejected'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"kind": "song"}')$$,
  '22P02', null, 'an unknown kind is rejected'
);
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"place_id": 999}')$$,
  '23503', null, 'an unknown place is rejected'
);

-- Success.
select lives_ok(
  $$select public.create_recording(tests.valid_payload())$$,
  'a valid recording is created'
);
reset role;
select results_eq(
  $$select title, status::text, created_by, consent_by, photo_key
    from public.recordings$$,
  $$values ('Lay lay'::text, 'published'::text, '00000000-0000-0000-0000-0000000000a1'::uuid,
            '00000000-0000-0000-0000-0000000000a1'::uuid, 'photos/u1-p.jpg'::text)$$,
  'the recording stores owner, consent and photo'
);
select ok((select consent_confirmed_at is not null from public.recordings), 'consent time is recorded');
select results_eq(
  $$select position::int, culture_id, other_text from public.recording_cultures order by position$$,
  $$values (1, 1::bigint, null::text), (2, null::bigint, 'Qarapapaq'::text)$$,
  'cultures keep their order'
);
select results_eq(
  $$select revision_no, media_type::text, object_key, mime, size_bytes, duration_ms
    from public.recording_media$$,
  $$values (0, 'audio'::text, 'media/u1-a.mp3'::text, 'audio/mpeg'::text, 1000::bigint, 61000)$$,
  'the original media is stored as revision 0'
);
select is(
  (select count(*)::int from public.uploads where consumed_at is not null),
  2,
  'media and photo uploads are marked as used'
);

select tests.act_as('00000000-0000-0000-0000-0000000000a1');
select throws_ok(
  $$select public.create_recording(tests.valid_payload())$$,
  'P0001', 'upload_not_usable', 'an upload cannot be attached twice'
);

-- Disabled users cannot create recordings.
select tests.act_as('00000000-0000-0000-0000-0000000000d1');
select throws_ok(
  $$select public.create_recording(tests.valid_payload() || '{"media_upload_id": "10000000-0000-0000-0000-000000000006", "photo_upload_id": null}')$$,
  'P0001', 'not_allowed', 'disabled users cannot create recordings'
);

-- Direct inserts bypassing the RPC are not possible.
select tests.act_as('00000000-0000-0000-0000-0000000000a1');
select throws_ok(
  $$insert into public.recordings (title, kind, place_id, consent_confirmed_at, consent_by, created_by)
    values ('x', 'poem', 1, now(), auth.uid(), auth.uid())$$,
  '42501', null, 'uploaders cannot insert recordings directly'
);

select * from finish();
rollback;
