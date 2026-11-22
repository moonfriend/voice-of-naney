import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/locale/locale_cubit.dart';
import 'core/router/app_router.dart';
import 'features/map/presentation/pages/map_route.dart';
import 'features/recordings/presentation/pages/recording_route.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppConfig config = AppConfig.fromEnvironment();
  await Supabase.initialize(
    url: config.supabaseUrl.toString(),
    publishableKey: config.supabasePublishableKey,
  );
  configureDependencies();

  runApp(
    NaneyApp(
      localeCubit: LocaleCubit(),
      router: buildAppRouter(
        homeBuilder: (_) => MapRoute(mapTilerKey: config.mapTilerKey),
        recordingBuilder:
            (_, String id) => RecordingRoute(recordingId: id, mapTilerKey: config.mapTilerKey),
      ),
    ),
  );
}
