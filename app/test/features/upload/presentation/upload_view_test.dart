import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/geo/area_polygon.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/features/lookups/domain/entities/lookup_item.dart';
import 'package:naney/features/lookups/domain/repositories/lookup_repository.dart';
import 'package:naney/features/lookups/presentation/cubit/lookups_cubit.dart';
import 'package:naney/features/upload/data/datasources/audio_recorder_service.dart';
import 'package:naney/features/upload/data/datasources/file_picker_service.dart';
import 'package:naney/features/upload/domain/entities/culture_choice.dart';
import 'package:naney/features/upload/domain/entities/place_choice.dart';
import 'package:naney/features/upload/domain/entities/upload_draft.dart';
import 'package:naney/features/upload/domain/entities/upload_source.dart';
import 'package:naney/features/upload/domain/repositories/upload_repositories.dart';
import 'package:naney/features/upload/domain/usecases/submit_recording.dart';
import 'package:naney/features/upload/presentation/cubit/area_draw_cubit.dart';
import 'package:naney/features/upload/presentation/cubit/area_mode_cubit.dart';
import 'package:naney/features/upload/presentation/cubit/place_search_cubit.dart';
import 'package:naney/features/upload/presentation/cubit/recorder_cubit.dart';
import 'package:naney/features/upload/presentation/cubit/upload_form_cubit.dart';
import 'package:naney/features/upload/presentation/pages/upload_page.dart';

import '../../../helpers/pump_localized.dart';

class _Picker extends Mock implements FilePickerService {}

class _Submit extends Mock implements SubmitRecording {}

class _Lookups extends Mock implements LookupRepository {}

class _Places extends Mock implements PlaceLookupRepository {}

class _Recorder extends Mock implements AudioRecorderService {}

final UploadSource mp3 = UploadSource.bytes(
  name: 'lay-lay.mp3',
  mime: 'audio/mpeg',
  bytes: Uint8List(2048),
);

const DrawnPlaceChoice place = DrawnPlaceChoice(
  nameEn: 'Villages near Maragheh',
  nameFa: null,
  polygons: <AreaPolygon>[
    AreaPolygon(outer: <LatLng>[LatLng(37, 46), LatLng(37, 47), LatLng(38, 47)]),
  ],
);

void main() {
  late _Picker picker;
  late _Submit submit;
  late UploadFormCubit form;
  late LookupsCubit lookups;

  setUpAll(() {
    registerFallbackValue(const UploadDraft());
    registerFallbackValue(const SubmissionCheckpoint());
  });

  setUp(() {
    picker = _Picker();
    submit = _Submit();
    form = UploadFormCubit(submit);
    final _Lookups lookupRepo = _Lookups();
    when(() => lookupRepo.cultures()).thenAnswer(
      (_) async => const <LookupItem>[
        LookupItem(id: 1, name: LocalizedName(en: 'Kurdish', fa: 'کرد'), active: true),
        LookupItem(id: 2, name: LocalizedName(en: 'Lur', fa: 'لر'), active: true),
      ],
    );
    when(() => lookupRepo.languages()).thenAnswer((_) async => const <LookupItem>[]);
    lookups = LookupsCubit(lookupRepo);
  });

  Future<void> pump(WidgetTester tester) async {
    await lookups.load();
    final _Recorder recorder = _Recorder();
    when(() => recorder.dispose()).thenAnswer((_) async {});
    await pumpLocalized(
      tester,
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<UploadFormCubit>.value(value: form),
          BlocProvider<LookupsCubit>.value(value: lookups),
          BlocProvider<RecorderCubit>(create: (_) => RecorderCubit(recorder)),
          BlocProvider<PlaceSearchCubit>(create: (_) => PlaceSearchCubit(_Places())),
          BlocProvider<AreaDrawCubit>(create: (_) => AreaDrawCubit()),
          BlocProvider<AreaModeCubit>(create: (_) => AreaModeCubit()),
        ],
        child: UploadView(picker: picker, mapTilerKey: ''),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cannot continue without a file, and says why', (WidgetTester tester) async {
    await pump(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a file or record your voice.'), findsOneWidget);
    expect(form.state.step, UploadStep.media);
  });

  testWidgets('a chosen file is shown and lets the uploader continue', (WidgetTester tester) async {
    when(() => picker.pickMedia()).thenAnswer((_) async => mp3);
    await pump(tester);

    await tester.tap(find.text('Choose audio or video file'));
    await tester.pumpAndSettle();
    expect(find.text('lay-lay.mp3 · 2 KB'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(form.state.step, UploadStep.details);
    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets('offers at most three cultures', (WidgetTester tester) async {
    form
      ..edit(
        (UploadDraft d) => d.copyWith(media: () => mp3, title: 'x', kind: () => RecordingKind.poem),
      )
      ..next()
      ..next();
    await pump(tester);
    expect(form.state.step, UploadStep.cultures);

    for (int i = 0; i < 3; i += 1) {
      await tester.tap(find.text('Add another culture'));
      await tester.pumpAndSettle();
    }
    expect(form.state.draft.cultures, hasLength(3));
    expect(find.text('Add another culture'), findsNothing);
    expect(find.text('Culture 3'), findsOneWidget);
  });

  testWidgets('"Other" lets the uploader type a culture name', (WidgetTester tester) async {
    form
      ..edit(
        (UploadDraft d) => d.copyWith(media: () => mp3, title: 'x', kind: () => RecordingKind.poem),
      )
      ..next()
      ..next()
      ..addCulture(const CultureChoice.other(''));
    await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name of the culture or group'),
      'Qashqai',
    );
    await tester.pump();
    expect(form.state.draft.cultures.single, const CultureChoice.other('Qashqai'));
  });

  testWidgets('sharing is disabled until consent is given', (WidgetTester tester) async {
    when(
      () => submit(
        any(),
        checkpoint: any(named: 'checkpoint'),
        onCheckpoint: any(named: 'onCheckpoint'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => '11111111-1111-4111-8111-111111111111');
    form.edit(
      (UploadDraft d) => d.copyWith(
        media: () => mp3,
        title: 'Lay lay',
        kind: () => RecordingKind.lullaby,
        cultures: const <CultureChoice>[CultureChoice.listed(1)],
        place: () => place,
      ),
    );
    for (int i = 0; i < 4; i += 1) {
      form.next();
    }
    await pump(tester);
    expect(form.state.step, UploadStep.consent);

    // FilledButton.icon builds a private subclass, so match by `is` rather than exact type.
    final Finder share = find.ancestor(
      of: find.text('Share recording'),
      matching: find.byWidgetPredicate((Widget widget) => widget is FilledButton),
    );
    expect(tester.widget<FilledButton>(share).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(share).onPressed, isNotNull);
  });
}
