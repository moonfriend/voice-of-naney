import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/i18n/localized_name.dart';

/// One origin area on the map, drawn at its label point with a recording count.
class MapPin extends Equatable {
  const MapPin({
    required this.placeId,
    required this.name,
    required this.position,
    required this.recordingCount,
  });

  final int placeId;
  final LocalizedName name;
  final LatLng position;
  final int recordingCount;

  @override
  List<Object?> get props => <Object?>[placeId, name, position, recordingCount];
}
