import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/new_recording.dart';
import '../../domain/repositories/upload_repositories.dart';

@LazySingleton(as: RecordingSubmissionRepository)
class SupabaseRecordingSubmissionRepository implements RecordingSubmissionRepository {
  SupabaseRecordingSubmissionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String> create(NewRecording recording) => guardRemoteCall(() async {
    final Object? id = await _client.rpc<Object?>(
      'create_recording',
      params: <String, Object?>{'p': recording.toJson()},
    );
    return id! as String;
  });
}
