import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/features/lookups/data/datasources/lookup_remote_data_source.dart';
import 'package:naney/features/lookups/data/repositories/lookup_repository_impl.dart';
import 'package:naney/features/lookups/domain/entities/lookup_item.dart';

class _MockRemote extends Mock implements LookupRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late LookupRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = LookupRepositoryImpl(remote);
  });

  test('maps culture rows', () async {
    when(() => remote.fetchTable('cultures')).thenAnswer(
      (_) async => <JsonRow>[
        <String, Object?>{'id': 1, 'name_en': 'Kurdish', 'name_fa': 'کرد', 'active': true},
        <String, Object?>{'id': 2, 'name_en': 'Lur', 'name_fa': 'لر', 'active': false},
      ],
    );
    expect(await repository.cultures(), const <LookupItem>[
      LookupItem(id: 1, name: LocalizedName(en: 'Kurdish', fa: 'کرد'), active: true),
      LookupItem(id: 2, name: LocalizedName(en: 'Lur', fa: 'لر'), active: false),
    ]);
  });

  test('reads languages from their own table', () async {
    when(() => remote.fetchTable('languages')).thenAnswer((_) async => <JsonRow>[]);
    expect(await repository.languages(), isEmpty);
    verify(() => remote.fetchTable('languages')).called(1);
  });

  test('turns connectivity errors into NetworkFailure', () async {
    when(() => remote.fetchTable(any())).thenThrow(http.ClientException('offline'));
    await expectLater(repository.cultures(), throwsA(isA<NetworkFailure>()));
  });
}
