import 'package:flutter_test/flutter_test.dart';
import 'package:naney/features/upload/data/datasources/file_picker_service.dart';
import 'package:naney/features/upload/domain/entities/upload_source.dart';

Stream<List<int>> once(List<List<int>> chunks) => Stream<List<int>>.fromIterable(chunks);

void main() {
  test('maps file extensions to accepted types', () {
    expect(mimeFor('Lay Lay.MP3', UploadRules.mediaMimeByExtension), 'audio/mpeg');
    expect(mimeFor('clip.mp4', UploadRules.mediaMimeByExtension), 'video/mp4');
    expect(mimeFor('IMG_0042.MOV', UploadRules.mediaMimeByExtension), 'video/quicktime');
    expect(mimeFor('export.m4v', UploadRules.mediaMimeByExtension), 'video/x-m4v');
    expect(mimeFor('notes.pdf', UploadRules.mediaMimeByExtension), isNull);
    expect(mimeFor('noextension', UploadRules.mediaMimeByExtension), isNull);
  });

  test('small files can be read again after the first upload attempt', () async {
    final Stream<List<int>> Function() read = replayableReader(
      once(<List<int>>[
        <int>[1, 2],
        <int>[3],
      ]),
      3,
    );
    expect(await read().expand((List<int> c) => c).toList(), <int>[1, 2, 3]);
    expect(await read().expand((List<int> c) => c).toList(), <int>[1, 2, 3]);
  });

  test('large files can be streamed only once', () async {
    final Stream<List<int>> Function() read = replayableReader(
      once(<List<int>>[
        <int>[1, 2, 3],
      ]),
      3,
      bufferLimit: 2,
    );
    expect(await read().expand((List<int> c) => c).toList(), <int>[1, 2, 3]);
    await expectLater(read().toList(), throwsStateError);
  });
}
