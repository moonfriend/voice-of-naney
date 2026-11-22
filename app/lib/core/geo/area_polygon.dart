import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// One polygon of an origin area: an outer ring plus optional holes.
class AreaPolygon extends Equatable {
  const AreaPolygon({required this.outer, this.holes = const <List<LatLng>>[]});

  final List<LatLng> outer;
  final List<List<LatLng>> holes;

  @override
  List<Object?> get props => <Object?>[outer, holes];
}

/// Parses GeoJSON Polygon / MultiPolygon geometry (coordinates are `[lng, lat]`).
List<AreaPolygon> polygonsFromGeoJson(Map<String, Object?> geometry) {
  final Object? type = geometry['type'];
  final Object? coordinates = geometry['coordinates'];
  if (coordinates is! List<Object?>) {
    throw const FormatException('GeoJSON geometry without coordinates');
  }
  return switch (type) {
    'Polygon' => <AreaPolygon>[_polygon(coordinates)],
    'MultiPolygon' =>
      coordinates.map((Object? polygon) => _polygon(polygon! as List<Object?>)).toList(),
    _ => throw FormatException('Unsupported GeoJSON geometry: $type'),
  };
}

/// Inverse of [polygonsFromGeoJson]; used when an uploader draws an area.
Map<String, Object?> polygonsToGeoJson(List<AreaPolygon> polygons) => <String, Object?>{
  'type': 'MultiPolygon',
  'coordinates':
      polygons
          .map(
            (AreaPolygon polygon) => <List<List<double>>>[
              _closedRing(polygon.outer),
              ...polygon.holes.map(_closedRing),
            ],
          )
          .toList(),
};

AreaPolygon _polygon(List<Object?> rings) {
  final List<List<LatLng>> parsed =
      rings.map((Object? ring) => _ring(ring! as List<Object?>)).toList();
  if (parsed.isEmpty) {
    throw const FormatException('Polygon without rings');
  }
  return AreaPolygon(outer: parsed.first, holes: parsed.skip(1).toList());
}

List<LatLng> _ring(List<Object?> positions) =>
    positions.map((Object? position) {
      final List<Object?> pair = position! as List<Object?>;
      return LatLng((pair[1]! as num).toDouble(), (pair[0]! as num).toDouble());
    }).toList();

List<List<double>> _closedRing(List<LatLng> ring) {
  final List<List<double>> coordinates =
      ring.map((LatLng point) => <double>[point.longitude, point.latitude]).toList();
  if (coordinates.isNotEmpty &&
      (coordinates.first[0] != coordinates.last[0] ||
          coordinates.first[1] != coordinates.last[1])) {
    coordinates.add(coordinates.first);
  }
  return coordinates;
}
