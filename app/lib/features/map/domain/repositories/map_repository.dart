import '../entities/map_bounds.dart';
import '../entities/map_pin.dart';
import '../entities/place_area.dart';
import '../entities/recording_filter.dart';

abstract interface class MapRepository {
  Future<List<MapPin>> pinsIn(MapBounds bounds, RecordingFilter filter);

  Future<List<PlaceArea>> areasIn(MapBounds bounds);
}
