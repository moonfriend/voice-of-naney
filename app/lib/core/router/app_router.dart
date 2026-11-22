import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';

/// Route paths are part of the public contract: recordings are shared as `/r/<id>`.
abstract final class AppRoutes {
  static const String home = '/';
}

GoRouter buildAppRouter({required WidgetBuilder homeBuilder}) {
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
        ],
      ),
    ],
  );
}
