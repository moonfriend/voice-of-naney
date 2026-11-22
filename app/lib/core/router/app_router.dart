import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';

/// Route paths are part of the public contract: recordings are shared as `/r/<id>`.
abstract final class AppRoutes {
  static const String home = '/';
  static const String recording = '/r/:id';

  static String recordingPath(String id) => '/r/$id';
}

typedef RecordingPageBuilder = Widget Function(BuildContext context, String recordingId);

GoRouter buildAppRouter({
  required WidgetBuilder homeBuilder,
  RecordingPageBuilder? recordingBuilder,
  List<RouteBase> extraRoutes = const <RouteBase>[],
  GoRouterRedirect? redirect,
  Listenable? refreshListenable,
  List<Widget> Function(BuildContext context)? shellActions,
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: redirect,
    refreshListenable: refreshListenable,
    routes: <RouteBase>[
      ShellRoute(
        builder:
            (BuildContext context, GoRouterState state, Widget child) =>
                AppShell(actions: shellActions?.call(context) ?? const <Widget>[], child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            builder: (BuildContext context, GoRouterState state) => homeBuilder(context),
          ),
          if (recordingBuilder != null)
            GoRoute(
              path: AppRoutes.recording,
              builder:
                  (BuildContext context, GoRouterState state) =>
                      recordingBuilder(context, state.pathParameters['id'] ?? ''),
            ),
          ...extraRoutes,
        ],
      ),
    ],
  );
}
