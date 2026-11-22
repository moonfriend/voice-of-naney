import 'package:equatable/equatable.dart';

import '../../../../core/geo/area_polygon.dart';

class PlaceArea extends Equatable {
  const PlaceArea({required this.placeId, required this.polygons});

  final int placeId;
  final List<AreaPolygon> polygons;

  @override
  List<Object?> get props => <Object?>[placeId, polygons];
}
