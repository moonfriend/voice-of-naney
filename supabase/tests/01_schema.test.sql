begin;
\ir 00_fixtures.sql.inc
select * from no_plan();

select has_table('public', t, 'table ' || t || ' exists')
from unnest(array['profiles','cultures','languages','places','recordings',
                  'recording_cultures','recording_media','uploads']) as t;

select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  0,
  'every public table has row-level security enabled'
);

select is(
  (select role::text from public.profiles where id = '00000000-0000-0000-0000-0000000000a1'),
  'uploader',
  'a new auth user automatically gets an uploader profile'
);

select * from finish();
rollback;
