import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:naney/core/geo/area_polygon.dart';

void main() {
  test('parses a Polygon with a hole, swapping [lng, lat] to LatLng', () {
    final List<AreaPolygon> polygons = polygonsFromGeoJson(<String, Object?>{
      'type': 'Polygon',
      'coordinates': <Object?>[
        <Object?>[
          <Object?>[46.2, 38.0],
          <Object?>[46.4, 38.0],
          <Object?>[46.4, 38.2],
          <Object?>[46.2, 38.0],
        ],
        <Object?>[
          <Object?>[46.3, 38.05],
          <Object?>[46.35, 38.05],
          <Object?>[46.3, 38.1],
          <Object?>[46.3, 38.05],
        ],
      ],
    });
    expect(polygons, hasLength(1));
    expect(polygons.first.outer.first, const LatLng(38.0, 46.2));
    expect(polygons.first.holes, hasLength(1));
  });

  test('parses a MultiPolygon with integer coordinates', () {
    final List<AreaPolygon> polygons = polygonsFromGeoJson(<String, Object?>{
      'type': 'MultiPolygon',
      'coordinates': <Object?>[
        <Object?>[
          <Object?>[
            <Object?>[1, 2],
            <Object?>[3, 2],
            <Object?>[3, 4],
            <Object?>[1, 2],
          ],
        ],
        <Object?>[
          <Object?>[
            <Object?>[5, 6],
            <Object?>[7, 6],
            <Object?>[7, 8],
            <Object?>[5, 6],
          ],
        ],
      ],
    });
    expect(polygons, hasLength(2));
    expect(polygons[1].outer.first, const LatLng(6, 5));
  });

  test('rejects other geometry types', () {
    expect(
      () => polygonsFromGeoJson(<String, Object?>{
        'type': 'Point',
        'coordinates': <Object?>[1, 2],
      }),
      throwsFormatException,
    );
  });

  test('round-trips a drawn area to a closed MultiPolygon', () {
    final Map<String, Object?> geoJson = polygonsToGeoJson(<AreaPolygon>[
      const AreaPolygon(outer: <LatLng>[LatLng(38, 46), LatLng(38, 47), LatLng(39, 47)]),
    ]);
    expect(geoJson, <String, Object?>{
      'type': 'MultiPolygon',
      'coordinates': <Object?>[
        <Object?>[
          <Object?>[
            <double>[46, 38],
            <double>[47, 38],
            <double>[47, 39],
            <double>[46, 38],
          ],
        ],
      ],
    });
    expect(polygonsFromGeoJson(geoJson).first.outer, hasLength(4));
  });
}
