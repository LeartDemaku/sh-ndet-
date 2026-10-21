// Teste të pëlqimeve (GDPR) dhe të navigimit bazë.
//
// Rregulli që ky test mbron: pëlqimi për të dhëna shëndetësore është I VEÇANTË
// dhe nuk kombinohet me pranimin e kushteve. Butoni "Krijo llogarinë" nuk
// aktivizohet derisa të jenë shënuar TË DYJA çelësat.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shendetplus/core/api/providers.dart';
import 'package:shendetplus/core/theme/app_theme.dart';
import 'package:shendetplus/features/auth/verify_email_page.dart';
import 'package:shendetplus/features/emergency/emergency_page.dart';
import 'package:shendetplus/main.dart';

import 'fakes.dart';

void main() {
  Future<void> shkoTeRegjistrimi(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(FakeSecureStore())],
        child: const ShendetApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Splash → Onboarding. Slajdi 1 -> 2 -> 3.
    await tester.tap(find.text('Vazhdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazhdo'));
    await tester.pumpAndSettle();

    expect(find.text('Krijo llogari falas'), findsOneWidget);
    await tester.tap(find.text('Krijo llogari falas'));
    await tester.pumpAndSettle();
  }

  testWidgets('regjistrimi kërkon TË DYJA pëlqimet veç e veç', (tester) async {
    await shkoTeRegjistrimi(tester);

    expect(find.text('Krijo llogarinë tënde'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('Pranoj kushtet e përdorimit'), findsOneWidget);
    expect(
      find.text('Pranoj përpunimin e të dhënave shëndetësore'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile).last);
    await tester.pumpAndSettle();

    final krijo = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Krijo llogarinë'),
    );
    expect(
      krijo.onPressed,
      isNull,
      reason: 'pa të dy pëlqimet, "Krijo llogarinë" duhet të jetë i fikur',
    );

    // Vetëm pëlqimi i parë (kushtet) => përsëri i fikur.
    await tester.ensureVisible(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    final endeIFikur = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Krijo llogarinë'),
    );
    expect(
      endeIFikur.onPressed,
      isNull,
      reason:
          'pëlqimi për të dhëna shëndetësore nuk mund të kombinohet me kushtet',
    );

    // Të dy pëlqimet => aktivizohet.
    await tester.ensureVisible(find.byType(CheckboxListTile).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.pumpAndSettle();
    final aktivizuar = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Krijo llogarinë'),
    );
    expect(aktivizuar.onPressed, isNotNull);
  });

  testWidgets('"Kam tashmë llogari" të çon te hyrja', (tester) async {
    await shkoTeRegjistrimi(tester);

    await tester.ensureVisible(find.text('Kam tashmë llogari'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kam tashmë llogari'));
    await tester.pumpAndSettle();

    expect(find.text('Hyr në llogarinë tënde'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Hyr'), findsOneWidget);
  });

  testWidgets('nga hyrja mund të kthehesh te regjistrimi', (tester) async {
    await shkoTeRegjistrimi(tester);
    await tester.ensureVisible(find.text('Kam tashmë llogari'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kam tashmë llogari'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Krijo llogari të re'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Krijo llogari të re'));
    await tester.pumpAndSettle();

    expect(find.text('Krijo llogarinë tënde'), findsOneWidget);
  });

  testWidgets('ekrani i emergjencës shfaq numrat zyrtarë 194, 192 dhe 193', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildLightTheme(), home: const EmergencyPage()),
    );

    expect(find.text('Telefono 194 tani'), findsOneWidget);
    expect(find.text('Telefono 194'), findsOneWidget);
    expect(find.text('Policia: 192 · Zjarrfikësit: 193'), findsOneWidget);
    expect(find.textContaining('112'), findsNothing);
    expect(find.text('Mos prit përgjigje nga aplikacioni.'), findsOneWidget);
  });

  testWidgets('verifikimi kërkon saktësisht 6 shifra', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(FakeSecureStore())],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const VerifyEmailPage(
            email: 'test@example.com',
            initialCooldown: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verifiko emailin'), findsOneWidget);
    expect(find.textContaining('test@example.com'), findsOneWidget);

    final para = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Verifiko dhe hyr'),
    );
    expect(para.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    final pjeserisht = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Verifiko dhe hyr'),
    );
    expect(pjeserisht.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    final plotesisht = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Verifiko dhe hyr'),
    );
    expect(plotesisht.onPressed, isNotNull);
  });
}
