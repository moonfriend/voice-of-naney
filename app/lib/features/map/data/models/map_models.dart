import 'package:latlong2/latlong.dart';

import '../../../../core/geo/area_polygon.dart';
import '../../../../core/i18n/localized_name.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/place_area.dart';

MapPin mapPinFromJson(Map<String, Object?> json) => MapPin(
  placeId: (json['place_id']! as num).toInt(),
  name: LocalizedName.fromJson(json),
  position: LatLng((json['lat']! as num).toDouble(), (json['lng']! as num).toDouble()),
  recordingCount: (json['recording_count']! as num).toInt(),
);

PlaceArea placeAreaFromJson(Map<String, Object?> json) => PlaceArea(
  placeId: (json['place_id']! as num).toInt(),
  polygons: polygonsFromGeoJson(json['geojson']! as Map<String, Object?>),
);
