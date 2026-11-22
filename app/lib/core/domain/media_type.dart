enum MediaType {
  audio,
  video;

  static MediaType fromDb(String value) => switch (value) {
    'audio' => MediaType.audio,
    'video' => MediaType.video,
    _ => throw FormatException('Unknown media type: $value'),
  };
}
