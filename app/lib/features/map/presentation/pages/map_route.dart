import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../lookups/domain/repositories/lookup_repository.dart';
import '../../../lookups/presentation/cubit/lookups_cubit.dart';
import '../../../recordings/domain/repositories/recording_repository.dart';
import '../../../recordings/presentation/cubit/place_recordings_cubit.dart';
import '../../domain/repositories/map_repository.dart';
import '../cubit/map_cubit.dart';
import 'map_page.dart';

/// Route entry: creates the cubits the map needs from the DI container.
class MapRoute extends StatelessWidget {
  const MapRoute({required this.mapTilerKey, super.key});

  final String mapTilerKey;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<MapCubit>(create: (_) => MapCubit(getIt<MapRepository>())),
      BlocProvider<LookupsCubit>(create: (_) => LookupsCubit(getIt<LookupRepository>())..load()),
      BlocProvider<PlaceRecordingsCubit>(
        create: (_) => PlaceRecordingsCubit(getIt<RecordingRepository>()),
      ),
    ],
    child: MapView(mapTilerKey: mapTilerKey),
  );
}
