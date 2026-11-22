import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../lookups/data/datasources/lookup_remote_data_source.dart' show JsonRow;
import '../../domain/entities/map_bounds.dart';
import '../../domain/entities/recording_filter.dart';

abstract interface class MapRemoteDataSource {
  Future<List<JsonRow>> fetchPins(MapBounds bounds, RecordingFilter filter);

  Future<List<JsonRow>> fetchAreas(MapBounds bounds);
}

@LazySingleton(as: MapRemoteDataSource)
class SupabaseMapRemoteDataSource implements MapRemoteDataSource {
  SupabaseMapRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<JsonRow>> fetchPins(MapBounds bounds, RecordingFilter filter) async {
    final Object? rows = await _client.rpc<Object?>(
      'map_pins',
      params: mapPinsParams(bounds, filter),
    );
    return _asRows(rows);
  }

  @override
  Future<List<JsonRow>> fetchAreas(MapBounds bounds) async {
    final Object? rows = await _client.rpc<Object?>('place_areas', params: boundsParams(bounds));
    return _asRows(rows);
  }

  static List<JsonRow> _asRows(Object? rows) =>
      (rows as List<Object?>? ?? const <Object?>[]).cast<JsonRow>();
}

Map<String, Object?> boundsParams(MapBounds bounds) => <String, Object?>{
  'p_min_lng': bounds.west,
  'p_min_lat': bounds.south,
  'p_max_lng': bounds.east,
  'p_max_lat': bounds.north,
};

/// Unset filters are sent as null so the SQL function ignores them.
Map<String, Object?> mapPinsParams(MapBounds bounds, RecordingFilter filter) => <String, Object?>{
  ...boundsParams(bounds),
  'p_culture_ids': filter.cultureIds.isEmpty ? null : (filter.cultureIds.toList()..sort()),
  'p_language_ids': filter.languageIds.isEmpty ? null : (filter.languageIds.toList()..sort()),
  'p_kinds': filter.kinds.isEmpty ? null : filter.kinds.map((kind) => kind.name).toList(),
  'p_tag': filter.normalizedTag,
};
