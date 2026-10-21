// Regresion: "Kthehu" duhet të kthejë te platforma, jo të mbetet te emergjenca.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:shendetplus/core/theme/app_theme.dart';
import 'package:shendetplus/features/emergency/emergency_page.dart';
import 'package:shendetplus/main.dart';

GoRouter _router({String initialLocation = '/home'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => Scaffold(
        body: const Center(child: Text('Ballina test')),
        floatingActionButton: const EmergencyFab(),
      ),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyPage(),
    ),
  ],
);

void main() {
  testWidgets('Kthehu nga emergjenca kthehet te ekrani i platformës', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(theme: buildLightTheme(), routerConfig: _router()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('194'));
    await tester.pumpAndSettle();
    expect(find.text('Telefono 194 tani'), findsOneWidget);

    await tester.tap(find.text('Kthehu'));
    await tester.pumpAndSettle();

    expect(find.text('Ballina test'), findsOneWidget);
    expect(find.text('Telefono 194 tani'), findsNothing);
  });

  testWidgets('Kthehu funksionon edhe kur emergjenca hapet me link direkt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildLightTheme(),
        routerConfig: _router(initialLocation: '/emergency'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kthehu'));
    await tester.pumpAndSettle();

    expect(find.text('Ballina test'), findsOneWidget);
    expect(find.text('Telefono 194 tani'), findsNothing);
  });
}
