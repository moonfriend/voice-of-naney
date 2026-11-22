import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/domain/media_type.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/features/recordings/domain/entities/recording_detail.dart';
import 'package:naney/features/recordings/presentation/cubit/recording_detail_cubit.dart';
import 'package:naney/features/recordings/presentation/pages/recording_page.dart';

import '../../../helpers/pump_localized.dart';

class _MockCubit extends MockCubit<RecordingDetailState> implements RecordingDetailCubit {}

final RecordingDetail detail = RecordingDetail(
  id: '11111111-1111-4111-8111-111111111111',
  title: 'Lay lay',
  kind: RecordingKind.lullaby,
  place: const RecordingPlace(id: 1, name: LocalizedName(en: 'Tabriz', fa: 'تبریز')),
  cultures: const <CultureEntry>[
    CultureEntry(name: LocalizedName(en: 'Azeri', fa: 'آذری')),
    CultureEntry(otherText: 'Qarapapaq'),
  ],
  revisions: <MediaRevision>[
    MediaRevision(
      revisionNo: 0,
      mediaType: MediaType.audio,
      url: Uri.parse('https://x/media/a.mp3'),
      mime: 'audio/mpeg',
    ),
    MediaRevision(
      revisionNo: 1,
      mediaType: MediaType.audio,
      url: Uri.parse('https://x/media/b.mp3'),
      mime: 'audio/mpeg',
      note: 'noise removed',
    ),
  ],
  createdAt: DateTime.utc(2026, 11, 22),
  performerName: 'Naney',
  yearRecorded: 1998,
  originNote: 'Family moved from Urmia',
  tags: const <String>['sleep'],
  transcript: 'Lay lay, my little one',
);

Widget fakePlayer(BuildContext context, MediaRevision revision) =>
    Text('player:${revision.url.path}', key: const Key('player'));

void main() {
  late _MockCubit cubit;
  setUp(() => cubit = _MockCubit());

  Future<void> pump(
    WidgetTester tester,
    RecordingDetailState state, {
    Locale locale = const Locale('en'),
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpLocalized(
      tester,
      BlocProvider<RecordingDetailCubit>.value(
        value: cubit,
        child: const RecordingView(mapTilerKey: '', playerBuilder: fakePlayer),
      ),
      locale: locale,
    );
  }

  testWidgets('shows the recording and plays the selected revision', (WidgetTester tester) async {
    await pump(tester, RecordingDetailLoaded(detail: detail, selectedRevisionNo: 1));

    expect(find.text('Lay lay'), findsOneWidget);
    expect(find.text('Lullaby'), findsOneWidget);
    expect(find.text('Performed by Naney'), findsOneWidget);
    expect(find.text('Recorded in 1998'), findsOneWidget);
    expect(find.text('Tabriz'), findsOneWidget);
    expect(find.text('Azeri, Qarapapaq'), findsOneWidget);
    expect(find.text('Family moved from Urmia'), findsOneWidget);
    expect(find.text('#sleep'), findsOneWidget);
    expect(find.text('player:/media/b.mp3'), findsOneWidget);
    expect(find.text('noise removed'), findsOneWidget);
  });

  testWidgets('offers the original when there are revisions', (WidgetTester tester) async {
    await pump(tester, RecordingDetailLoaded(detail: detail, selectedRevisionNo: 1));
    await tester.tap(
      find.descendant(of: find.byType(DropdownMenu<int>), matching: find.byType(TextField)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Original').last);
    await tester.pumpAndSettle();
    verify(() => cubit.selectRevision(0)).called(1);
  });

  testWidgets('hides the version picker for a single file', (WidgetTester tester) async {
    final RecordingDetail single = RecordingDetail(
      id: detail.id,
      title: detail.title,
      kind: detail.kind,
      place: detail.place,
      cultures: detail.cultures,
      revisions: <MediaRevision>[detail.revisions.first],
      createdAt: detail.createdAt,
    );
    await pump(tester, RecordingDetailLoaded(detail: single, selectedRevisionNo: 0));
    expect(find.byType(DropdownMenu<int>), findsNothing);
    expect(find.text('player:/media/a.mp3'), findsOneWidget);
  });

  testWidgets('explains when a recording is missing or hidden', (WidgetTester tester) async {
    await pump(tester, const RecordingDetailNotFound());
    expect(find.text('This recording does not exist or is no longer public.'), findsOneWidget);
    expect(find.text('Back to the map'), findsOneWidget);
  });

  testWidgets('explains load failures', (WidgetTester tester) async {
    await pump(tester, const RecordingDetailFailed(NetworkFailure()));
    expect(find.text('Could not load this recording.'), findsOneWidget);
  });

  testWidgets('renders right-to-left with Persian names in Persian', (WidgetTester tester) async {
    await pump(
      tester,
      RecordingDetailLoaded(detail: detail, selectedRevisionNo: 1),
      locale: const Locale('fa'),
    );
    expect(find.text('تبریز'), findsOneWidget);
    expect(find.text('آذری، Qarapapaq'), findsOneWidget);
    expect(find.text('لالایی'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('تبریز'))), TextDirection.rtl);
  });
}
