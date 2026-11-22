import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/map_bounds.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/place_area.dart';
import '../../domain/entities/recording_filter.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_data_source.dart';
import '../models/map_models.dart';

@LazySingleton(as: MapRepository)
class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(this._remote);

  final MapRemoteDataSource _remote;

  @override
  Future<List<MapPin>> pinsIn(MapBounds bounds, RecordingFilter filter) => guardRemoteCall(
    () async => (await _remote.fetchPins(bounds, filter)).map(mapPinFromJson).toList(),
  );

  @override
  Future<List<PlaceArea>> areasIn(MapBounds bounds) => guardRemoteCall(
    () async => (await _remote.fetchAreas(bounds)).map(placeAreaFromJson).toList(),
  );
}
