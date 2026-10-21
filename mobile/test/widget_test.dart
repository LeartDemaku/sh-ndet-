// Testi i tymit: aplikacioni ngrihet dhe shfaq ekranin e mirëseardhjes.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shendetplus/core/api/providers.dart';
import 'package:shendetplus/main.dart';

import 'fakes.dart';

void main() {
  testWidgets('Aplikacioni ngrihet dhe shfaq ekranin e mirëseardhjes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(FakeSecureStore())],
        child: const ShendetApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Shëndet+'), findsWidgets);
    expect(find.text('Vazhdo'), findsOneWidget);
  });
}
