/// Media is served by the Worker at `/<object_key>`; keys come from the database.
class MediaUrlBuilder {
  MediaUrlBuilder(this.apiBaseUrl);

  final Uri apiBaseUrl;

  static final RegExp _safeKey = RegExp(r'^(media|photos)/[A-Za-z0-9-]+\.[a-z0-9]{2,4}$');

  Uri urlFor(String objectKey) {
    if (!_safeKey.hasMatch(objectKey)) {
      throw ArgumentError.value(objectKey, 'objectKey', 'is not a media key');
    }
    final String basePath =
        apiBaseUrl.path.endsWith('/')
            ? apiBaseUrl.path.substring(0, apiBaseUrl.path.length - 1)
            : apiBaseUrl.path;
    return apiBaseUrl.replace(path: '$basePath/$objectKey');
  }
}
