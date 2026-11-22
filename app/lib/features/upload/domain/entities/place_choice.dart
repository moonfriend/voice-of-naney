import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/area_polygon.dart';

/// A search hit from the place search (before its boundary is fetched).
class PlaceSearchResult extends Equatable {
  const PlaceSearchResult({
    required this.name,
    required this.context,
    required this.osmType,
    required this.osmId,
    required this.kind,
    required this.position,
    required this.hasBoundary,
  });

  final String name;
  final String context;
  final String osmType;
  final int osmId;
  final String kind;
  final LatLng position;
  final bool hasBoundary;

  @override
  List<Object?> get props => <Object?>[name, context, osmType, osmId, kind, position, hasBoundary];
}

/// The origin area the uploader confirmed.
sealed class PlaceChoice extends Equatable {
  const PlaceChoice({required this.nameEn, required this.nameFa, required this.polygons});

  final String? nameEn;
  final String? nameFa;
  final List<AreaPolygon> polygons;

  String get displayName => (nameEn?.trim().isNotEmpty ?? false) ? nameEn! : (nameFa ?? '');
}

/// An OpenStreetMap boundary (city, district, village…).
class OsmPlaceChoice extends PlaceChoice {
  const OsmPlaceChoice({
    required this.osmType,
    required this.osmId,
    required this.kind,
    required super.nameEn,
    required super.nameFa,
    required super.polygons,
  });

  final String osmType;
  final int osmId;
  final String kind;

  @override
  List<Object?> get props => <Object?>[osmType, osmId, kind, nameEn, nameFa, polygons];
}

/// An area the uploader drew because OpenStreetMap had no fitting boundary.
class DrawnPlaceChoice extends PlaceChoice {
  const DrawnPlaceChoice({required super.nameEn, required super.nameFa, required super.polygons});

  @override
  List<Object?> get props => <Object?>[nameEn, nameFa, polygons];
}
