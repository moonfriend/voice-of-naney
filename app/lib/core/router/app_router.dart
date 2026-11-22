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
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      ShellRoute(
        builder:
            (BuildContext context, GoRouterState state, Widget child) => AppShell(child: child),
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
        ],
      ),
    ],
  );
}
