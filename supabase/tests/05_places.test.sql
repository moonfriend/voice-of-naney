begin;
\ir 00_fixtures.sql.inc
select * from no_plan();

select tests.act_as('00000000-0000-0000-0000-0000000000a1');

select is(
  public.upsert_place(jsonb_build_object(
    'name_en', 'Tabriz (again)', 'kind', 'city', 'osm_type', 'relation', 'osm_id', 123456,
    'geojson', '{"type":"Polygon","coordinates":[[[46.2,38.0],[46.4,38.0],[46.4,38.15],[46.2,38.0]]]}'::jsonb
  )),
  1::bigint,
  'an OSM place that already exists is reused'
);

select public.upsert_place(jsonb_build_object(
  'name_en', 'Villages near Maragheh', 'name_fa', 'روستاهای اطراف مراغه', 'kind', 'custom',
  'geojson', '{"type":"Polygon","coordinates":[[[46.1,37.3],[46.3,37.3],[46.3,37.45],[46.1,37.45],[46.1,37.3]]]}'::jsonb
)) as custom_id \gset

reset role;
select results_eq(
  format($$select kind::text, osm_id, created_by from public.places where id = %s$$, :'custom_id'),
  $$values ('custom'::text, null::bigint, '00000000-0000-0000-0000-0000000000a1'::uuid)$$,
  'a drawn area is stored as a custom place'
);
select ok(
  (select extensions.st_covers(area, label_point) from public.places where id = :'custom_id'),
  'the label point lies inside the area'
);

select tests.act_as('00000000-0000-0000-0000-0000000000a1');
select throws_ok(
  $$select public.upsert_place(jsonb_build_object('name_en', 'Point', 'kind', 'custom',
      'geojson', '{"type":"Point","coordinates":[46.1,37.3]}'::jsonb))$$,
  'P0001', 'area_must_be_polygon', 'a point is not an area'
);
select throws_ok(
  $$select public.upsert_place(jsonb_build_object('kind', 'custom',
      'geojson', '{"type":"Polygon","coordinates":[[[46.1,37.3],[46.3,37.3],[46.3,37.45],[46.1,37.3]]]}'::jsonb))$$,
  'P0001', 'place_name_required', 'an area needs a name'
);

select tests.act_as(null);
select throws_ok(
  $$select public.upsert_place(jsonb_build_object('name_en', 'X', 'kind', 'custom',
      'geojson', '{"type":"Polygon","coordinates":[[[46.1,37.3],[46.3,37.3],[46.3,37.45],[46.1,37.3]]]}'::jsonb))$$,
  '42501', null, 'anon cannot create places'
);

select * from finish();
rollback;
