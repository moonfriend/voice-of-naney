import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/features/lookups/domain/entities/lookup_item.dart';
import 'package:naney/features/lookups/domain/repositories/lookup_repository.dart';
import 'package:naney/features/lookups/presentation/cubit/lookups_cubit.dart';

class _MockRepo extends Mock implements LookupRepository {}

const LookupItem kurdish = LookupItem(
  id: 1,
  name: LocalizedName(en: 'Kurdish', fa: 'کرد'),
  active: true,
);
const LookupItem retired = LookupItem(
  id: 2,
  name: LocalizedName(en: 'Old', fa: 'قدیمی'),
  active: false,
);
const LookupItem azeri = LookupItem(
  id: 3,
  name: LocalizedName(en: 'Azerbaijani', fa: 'ترکی'),
  active: true,
);

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  blocTest<LookupsCubit, LookupsState>(
    'loads both lists',
    build: () {
      when(() => repo.cultures()).thenAnswer((_) async => <LookupItem>[kurdish, retired]);
      when(() => repo.languages()).thenAnswer((_) async => <LookupItem>[azeri]);
      return LookupsCubit(repo);
    },
    act: (LookupsCubit cubit) => cubit.load(),
    expect:
        () => <LookupsState>[
          const LookupsState(status: LookupsStatus.loading),
          const LookupsState(
            status: LookupsStatus.ready,
            cultures: <LookupItem>[kurdish, retired],
            languages: <LookupItem>[azeri],
          ),
        ],
  );

  test('offers only active items for new choices', () {
    const LookupsState state = LookupsState(
      status: LookupsStatus.ready,
      cultures: <LookupItem>[kurdish, retired],
    );
    expect(state.activeCultures, <LookupItem>[kurdish]);
  });

  blocTest<LookupsCubit, LookupsState>(
    'reports failures',
    build: () {
      when(() => repo.cultures()).thenThrow(const NetworkFailure());
      when(() => repo.languages()).thenAnswer((_) async => <LookupItem>[]);
      return LookupsCubit(repo);
    },
    act: (LookupsCubit cubit) => cubit.load(),
    expect:
        () => <LookupsState>[
          const LookupsState(status: LookupsStatus.loading),
          const LookupsState(status: LookupsStatus.failure),
        ],
  );
}
