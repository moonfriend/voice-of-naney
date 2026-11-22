import '../entities/new_recording.dart';
import '../entities/place_choice.dart';
import '../entities/upload_source.dart';

typedef ProgressCallback = void Function(int sentBytes);

abstract interface class FileUploadRepository {
  /// Uploads straight to storage and returns the verified upload id.
  Future<String> upload(UploadSource source, UploadPurpose purpose, {ProgressCallback? onProgress});
}

abstract interface class PlaceLookupRepository {
  Future<List<PlaceSearchResult>> search(String query);

  /// Null when OpenStreetMap has no area for this place (the uploader can draw one).
  Future<OsmPlaceChoice?> boundary(PlaceSearchResult result);

  /// Saves the area (reusing an existing OSM place) and returns its id.
  Future<int> save(PlaceChoice place);
}

abstract interface class RecordingSubmissionRepository {
  Future<String> create(NewRecording recording);
}
