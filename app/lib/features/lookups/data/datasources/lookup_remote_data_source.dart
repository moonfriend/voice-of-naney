import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonRow = Map<String, Object?>;

abstract interface class LookupRemoteDataSource {
  Future<List<JsonRow>> fetchTable(String table);
}

@LazySingleton(as: LookupRemoteDataSource)
class SupabaseLookupRemoteDataSource implements LookupRemoteDataSource {
  SupabaseLookupRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<JsonRow>> fetchTable(String table) =>
      _client.from(table).select('id,name_en,name_fa,active').order('name_en');
}
