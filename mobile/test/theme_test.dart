// Testet e pamjes (light/dark): paleta, kontrasti dhe zgjedhësi i ruajtur.
//
// Rregullat që mbrojnë këto teste:
// 1) Çdo tekst kryesor ka kontrast ≥ 4.5:1 në TË DYJA pamjet.
// 2) Parazgjedhja është GJITHMONË e ndritshme (edhe kur sistemi është i errët);
//    zgjedhja E ndritshme/E errët ruhet për rihapjen tjetër.
// 3) ShendetApp zbaton pamjen e zgjedhur përmes MaterialApp.themeMode.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shendetplus/core/api/providers.dart';
import 'package:shendetplus/core/theme/app_theme.dart';
import 'package:shendetplus/core/theme/theme_mode.dart';
import 'package:shendetplus/core/widgets/theme_mode_selector.dart';
import 'package:shendetplus/main.dart';

import 'fakes.dart';

/// Raporti i kontrastit sipas WCAG (4.5:1 për tekst normal).
double _kontrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Paleta semantike', () {
    test('light dhe dark ndryshojnë në sfond e sipërfaqe', () {
      expect(
        ShendetPalette.light.background,
        isNot(ShendetPalette.dark.background),
      );
      expect(ShendetPalette.light.surface, isNot(ShendetPalette.dark.surface));
      expect(ShendetPalette.light.ink, isNot(ShendetPalette.dark.ink));
    });

    test('teksti kryesor ka kontrast ≥ 4.5:1 në të dyja pamjet', () {
      for (final p in [ShendetPalette.light, ShendetPalette.dark]) {
        expect(_kontrast(p.ink, p.background), greaterThanOrEqualTo(4.5));
        expect(_kontrast(p.ink, p.surface), greaterThanOrEqualTo(4.5));
        expect(_kontrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
        expect(_kontrast(p.muted, p.surface), greaterThanOrEqualTo(3.0));
        expect(_kontrast(p.muted, p.background), greaterThanOrEqualTo(3.0));
      }
    });

    test('temat regjistrojnë paletën e duhur', () {
      final light = buildLightTheme();
      final dark = buildDarkTheme();
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<ShendetPalette>(), same(ShendetPalette.light));
      expect(dark.extension<ShendetPalette>(), same(ShendetPalette.dark));
    });
  });

  group('Zgjedhja e pamjes', () {
    test('loadStoredThemeMode: e ndritshme si parazgjedhje', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await loadStoredThemeMode(), ThemeMode.light);

      SharedPreferences.setMockInitialValues({kThemeModeKey: 'dark'});
      expect(await loadStoredThemeMode(), ThemeMode.dark);

      // Vlera e vjetër "system" nuk duhet ta kthejë app-in në të errët.
      SharedPreferences.setMockInitialValues({kThemeModeKey: 'system'});
      expect(await loadStoredThemeMode(), ThemeMode.light);
      expect(
        (await SharedPreferences.getInstance()).getString(kThemeModeKey),
        'light',
      );

      SharedPreferences.setMockInitialValues({kThemeModeKey: 'e paditur'});
      expect(await loadStoredThemeMode(), ThemeMode.light);
    });

    testWidgets('zgjedhësi ndryshon pamjen dhe e ruan zgjedhjen', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: container.read(themeModeProvider),
            home: const Scaffold(body: Center(child: ThemeModeSelector())),
          ),
        ),
      );

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(find.text('Sistemi'), findsNothing);
      expect(find.text('E ndritshme'), findsOneWidget);
      expect(find.text('E errët'), findsOneWidget);

      await tester.tap(find.text('E errët'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(
        (await SharedPreferences.getInstance()).getString(kThemeModeKey),
        'dark',
      );

      await tester.tap(find.text('E ndritshme'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(
        (await SharedPreferences.getInstance()).getString(kThemeModeKey),
        'light',
      );
    });

    testWidgets('ShendetApp zbaton pamjen e errët të zgjedhur', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStoreProvider.overrideWithValue(FakeSecureStore()),
            themeModeProvider.overrideWith(
              () => ThemeModeController(ThemeMode.dark),
            ),
          ],
          child: const ShendetApp(),
        ),
      );
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(app.darkTheme, isNotNull);
      expect(app.theme, isNotNull);
    });

    testWidgets('ShendetApp hapet i ndritshëm si parazgjedhje', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [secureStoreProvider.overrideWithValue(FakeSecureStore())],
          child: const ShendetApp(),
        ),
      );
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
    });
  });
}
