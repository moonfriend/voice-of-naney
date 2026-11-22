import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/locale/locale_cubit.dart';
import 'core/router/app_router.dart';
import 'core/router/auth_redirect.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/set_password_page.dart';
import 'features/auth/presentation/widgets/account_actions.dart';
import 'features/map/presentation/pages/map_route.dart';
import 'features/recordings/presentation/pages/recording_route.dart';
import 'features/upload/presentation/pages/upload_route.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URLs (not #/...) so shared links look clean and invite tokens in the
  // URL fragment are not confused with routes.
  usePathUrlStrategy();
  final AppConfig config = AppConfig.fromEnvironment();
  await Supabase.initialize(
    url: config.supabaseUrl.toString(),
    publishableKey: config.supabasePublishableKey,
  );
  configureDependencies();

  final AuthCubit authCubit = AuthCubit(getIt<AuthRepository>());
  await authCubit.start();

  final GoRouter router = buildAppRouter(
    homeBuilder: (_) => MapRoute(mapTilerKey: config.mapTilerKey),
    recordingBuilder:
        (_, String id) => RecordingRoute(recordingId: id, mapTilerKey: config.mapTilerKey),
    extraRoutes: <RouteBase>[
      GoRoute(path: AuthRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: AuthRoutes.setPassword, builder: (_, __) => const SetPasswordPage()),
      GoRoute(
        path: AuthRoutes.upload,
        builder: (_, __) => UploadRoute(mapTilerKey: config.mapTilerKey),
      ),
    ],
    redirect: (_, GoRouterState state) => authRedirect(location: state.uri, auth: authCubit.state),
    refreshListenable: StreamRefreshListenable(authCubit.stream),
    shellActions: (_) => const <Widget>[AccountActions()],
  );

  runApp(
    BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: NaneyApp(localeCubit: LocaleCubit(), router: router),
    ),
  );
}
