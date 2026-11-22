import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../lookups/data/datasources/lookup_remote_data_source.dart' show JsonRow;
import '../../../map/domain/entities/recording_filter.dart';

abstract interface class RecordingRemoteDataSource {
  Future<List<JsonRow>> fetchAtPlace(int placeId, RecordingFilter filter);

  Future<JsonRow> fetchDetail(String id);

  Future<JsonRow?> fetchPlaceArea(int placeId);
}

const String detailSelect =
    'id,title,description,kind,tags,transcript,photo_key,performer_name,year_recorded,'
    'language_other,origin_note,created_at,'
    'languages(name_en,name_fa),'
    'places(id,name_en,name_fa),'
    'recording_cultures(position,other_text,cultures(name_en,name_fa)),'
    'recording_media(revision_no,media_type,object_key,mime,duration_ms,note)';

@LazySingleton(as: RecordingRemoteDataSource)
class SupabaseRecordingRemoteDataSource implements RecordingRemoteDataSource {
  SupabaseRecordingRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<JsonRow>> fetchAtPlace(int placeId, RecordingFilter filter) {
    final String cultureJoin =
        filter.cultureIds.isEmpty ? '' : ',recording_cultures!inner(culture_id)';
    PostgrestFilterBuilder<List<JsonRow>> query = _client
        .from('recordings')
        .select(
          'id,title,kind,performer_name,year_recorded,recording_media(media_type,revision_no)$cultureJoin',
        )
        .eq('place_id', placeId)
        // Owners can read their own hidden recordings; the public map never lists them.
        .eq('status', 'published');
    if (filter.cultureIds.isNotEmpty) {
      query = query.inFilter('recording_cultures.culture_id', filter.cultureIds.toList());
    }
    if (filter.languageIds.isNotEmpty) {
      query = query.inFilter('language_id', filter.languageIds.toList());
    }
    if (filter.kinds.isNotEmpty) {
      query = query.inFilter('kind', filter.kinds.map((kind) => kind.name).toList());
    }
    final String? tag = filter.normalizedTag;
    if (tag != null) {
      query = query.contains('tags', <String>[tag]);
    }
    return query.order('created_at');
  }

  @override
  Future<JsonRow> fetchDetail(String id) =>
      _client.from('recordings').select(detailSelect).eq('id', id).single();

  @override
  Future<JsonRow?> fetchPlaceArea(int placeId) async {
    final Object? geometry = await _client.rpc<Object?>(
      'place_area',
      params: <String, Object?>{'p_place_id': placeId},
    );
    return geometry as JsonRow?;
  }
}
