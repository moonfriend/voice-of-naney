import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../lookups/domain/repositories/lookup_repository.dart';
import '../../../lookups/presentation/cubit/lookups_cubit.dart';
import '../../data/datasources/audio_recorder_service.dart';
import '../../data/datasources/file_picker_service.dart';
import '../../domain/repositories/upload_repositories.dart';
import '../../domain/usecases/submit_recording.dart';
import '../cubit/area_draw_cubit.dart';
import '../cubit/area_mode_cubit.dart';
import '../cubit/place_search_cubit.dart';
import '../cubit/recorder_cubit.dart';
import '../cubit/upload_form_cubit.dart';
import 'upload_page.dart';

class UploadRoute extends StatelessWidget {
  const UploadRoute({required this.mapTilerKey, super.key});

  final String mapTilerKey;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<UploadFormCubit>(create: (_) => UploadFormCubit(getIt<SubmitRecording>())),
      BlocProvider<LookupsCubit>(create: (_) => LookupsCubit(getIt<LookupRepository>())..load()),
      BlocProvider<RecorderCubit>(create: (_) => RecorderCubit(getIt<AudioRecorderService>())),
      BlocProvider<PlaceSearchCubit>(
        create: (_) => PlaceSearchCubit(getIt<PlaceLookupRepository>()),
      ),
      BlocProvider<AreaDrawCubit>(create: (_) => AreaDrawCubit()),
      BlocProvider<AreaModeCubit>(create: (_) => AreaModeCubit()),
    ],
    child: UploadView(picker: getIt<FilePickerService>(), mapTilerKey: mapTilerKey),
  );
}
