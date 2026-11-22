import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/repositories/recording_repository.dart';
import '../cubit/recording_detail_cubit.dart';
import 'recording_page.dart';

class RecordingRoute extends StatelessWidget {
  const RecordingRoute({required this.recordingId, required this.mapTilerKey, super.key});

  final String recordingId;
  final String mapTilerKey;

  @override
  Widget build(BuildContext context) => BlocProvider<RecordingDetailCubit>(
    create: (_) => RecordingDetailCubit(getIt<RecordingRepository>())..load(recordingId),
    child: RecordingView(mapTilerKey: mapTilerKey),
  );
}
