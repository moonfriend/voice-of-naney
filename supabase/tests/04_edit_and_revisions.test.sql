begin;
\ir 00_fixtures.sql.inc
select * from no_plan();

select tests.act_as('00000000-0000-0000-0000-0000000000a1');
select public.create_recording(tests.valid_payload()) as rec_id \gset

-- Owner may edit metadata but not moderation status.
select lives_ok(
  format($$update public.recordings set title = 'Lay lay (edited)' where id = %L$$, :'rec_id'),
  'the owner can edit the title'
);
select is((select title from public.recordings where id = :'rec_id'), 'Lay lay (edited)', 'title was updated');
select throws_ok(
  format($$update public.recordings set status = 'hidden' where id = %L$$, :'rec_id'),
  '42501', null, 'the owner cannot change status'
);
select throws_ok(
  format($$update public.recordings set created_by = '00000000-0000-0000-0000-0000000000a2' where id = %L$$, :'rec_id'),
  '42501', null, 'the owner cannot change ownership'
);

-- Another uploader cannot edit it (row is filtered out, nothing changes).
select tests.act_as('00000000-0000-0000-0000-0000000000a2');
update public.recordings set title = 'Hijacked' where id = :'rec_id';
reset role;
select is((select title from public.recordings where id = :'rec_id'), 'Lay lay (edited)', 'others cannot edit');

-- Uploaders cannot add revisions or touch media rows.
select tests.act_as('00000000-0000-0000-0000-0000000000a1');
select throws_ok(
  format($$insert into public.recording_media (recording_id, revision_no, media_type, object_key, mime, size_bytes)
           values (%L, 1, 'audio', 'media/x.mp3', 'audio/mpeg', 1)$$, :'rec_id'),
  '42501', null, 'uploaders cannot add revisions'
);
select throws_ok(
  format($$delete from public.recordings where id = %L$$, :'rec_id'),
  '42501', null, 'uploaders cannot delete recordings'
);

-- Admin tooling (service role) adds a revision next to the original.
reset role;
set local role service_role;
select lives_ok(
  format($$insert into public.recording_media (recording_id, revision_no, media_type, object_key, mime, size_bytes, note)
           values (%L, 1, 'audio', 'media/rev1.mp3', 'audio/mpeg', 2000, 'noise removed')$$, :'rec_id'),
  'service role can add revision 1'
);
select throws_ok(
  format($$update public.recording_media set object_key = 'media/other.mp3' where recording_id = %L and revision_no = 0$$, :'rec_id'),
  'P0001', 'media_rows_are_immutable', 'the original cannot be modified'
);
select throws_ok(
  format($$delete from public.recording_media where recording_id = %L and revision_no = 0$$, :'rec_id'),
  'P0001', 'original_media_cannot_be_deleted', 'the original cannot be deleted'
);
select lives_ok(
  format($$delete from public.recording_media where recording_id = %L and revision_no = 1$$, :'rec_id'),
  'a later revision can be removed'
);
reset role;

-- Direct inserts beyond three cultures are refused by the database itself.
insert into public.recording_cultures (recording_id, position, culture_id) values (:'rec_id', 3, 3);
select throws_ok(
  format($$insert into public.recording_cultures (recording_id, position, culture_id) values (%L, 4, 4)$$, :'rec_id'),
  '23514', null, 'position must be between 1 and 3'
);

select * from finish();
rollback;
