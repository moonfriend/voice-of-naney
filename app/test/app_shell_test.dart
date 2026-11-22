import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naney/app.dart';
import 'package:naney/core/locale/locale_cubit.dart';
import 'package:naney/core/router/app_router.dart';

void main() {
  Widget buildApp(LocaleCubit localeCubit) => NaneyApp(
    localeCubit: localeCubit,
    router: buildAppRouter(homeBuilder: (_) => const Text('home')),
  );

  testWidgets('renders the English title left-to-right', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp(LocaleCubit()));
    await tester.pumpAndSettle();

    expect(find.text('Voice of Naney'), findsOneWidget);
    final TextDirection direction = Directionality.of(tester.element(find.text('home')));
    expect(direction, TextDirection.ltr);
  });

  testWidgets('switching to Persian renders right-to-left', (WidgetTester tester) async {
    final LocaleCubit localeCubit = LocaleCubit();
    await tester.pumpWidget(buildApp(localeCubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فارسی').last);
    await tester.pumpAndSettle();

    expect(find.text('صدای ننه'), findsOneWidget);
    final TextDirection direction = Directionality.of(tester.element(find.text('home')));
    expect(direction, TextDirection.rtl);
    await localeCubit.close();
  });
}
