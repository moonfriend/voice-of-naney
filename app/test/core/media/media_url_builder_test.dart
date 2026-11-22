import 'package:flutter_test/flutter_test.dart';
import 'package:naney/core/media/media_url_builder.dart';

void main() {
  test('builds media URLs on the API origin', () {
    final MediaUrlBuilder builder = MediaUrlBuilder(Uri.parse('https://naney.example.dev/'));
    expect(
      builder.urlFor('media/3f0e7f0e-1b7e-4c47-9a9e-0b5d1c2a6f11.mp3'),
      Uri.parse('https://naney.example.dev/media/3f0e7f0e-1b7e-4c47-9a9e-0b5d1c2a6f11.mp3'),
    );
  });

  test('keeps a path prefix on the base URL', () {
    final MediaUrlBuilder builder = MediaUrlBuilder(Uri.parse('http://127.0.0.1:8787/base'));
    expect(builder.urlFor('photos/a.jpg'), Uri.parse('http://127.0.0.1:8787/base/photos/a.jpg'));
  });

  test('rejects keys that could escape the media folders', () {
    final MediaUrlBuilder builder = MediaUrlBuilder(Uri.parse('https://naney.example.dev'));
    expect(() => builder.urlFor('../secret'), throwsArgumentError);
    expect(() => builder.urlFor('https://evil.example/x.mp3'), throwsArgumentError);
  });
}
