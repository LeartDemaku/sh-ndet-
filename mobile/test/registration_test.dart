import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shendetplus/core/api/providers.dart';
import 'package:shendetplus/main.dart';

import 'fakes.dart';

void main() {
  Future<void> openRegister(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(FakeSecureStore())],
        child: const ShendetApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazhdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazhdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Krijo llogari falas'));
    await tester.pumpAndSettle();
  }

  testWidgets('regjistrimi rendit fushat sipas kërkesës', (tester) async {
    await openRegister(tester);

    final firstName = find.byKey(const Key('register-first-name'));
    final lastName = find.byKey(const Key('register-last-name'));
    final email = find.byKey(const Key('register-email'));
    final password = find.byKey(const Key('register-password'));
    final confirm = find.byKey(const Key('register-confirm-password'));

    for (final field in [firstName, lastName, email, password, confirm]) {
      expect(field, findsOneWidget);
    }

    final positions = [
      tester.getTopLeft(firstName).dy,
      tester.getTopLeft(lastName).dy,
      tester.getTopLeft(email).dy,
      tester.getTopLeft(password).dy,
      tester.getTopLeft(confirm).dy,
    ];
    for (var i = 1; i < positions.length; i++) {
      expect(
        positions[i],
        greaterThan(positions[i - 1]),
        reason: 'Fushat duhet të jenë në rendin Emri → Mbiemri → Email → '
            'Fjalëkalimi → Konfirmimi.',
      );
    }
  });

  testWidgets('konfirmimi i fjalëkalimit kontrollon përputhjen', (tester) async {
    await openRegister(tester);

    await tester.enterText(
      find.byKey(const Key('register-first-name')),
      'Leart',
    );
    await tester.enterText(find.byKey(const Key('register-last-name')), 'Demaku');
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'leart@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'TestFjalekalim123!',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'Ndryshe12345!',
    );

    await tester.ensureVisible(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Krijo llogarinë'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Krijo llogarinë'));
    await tester.pumpAndSettle();

    expect(find.text('Fjalëkalimet nuk përputhen.'), findsOneWidget);
    expect(find.text('Krijo llogarinë tënde'), findsOneWidget);
  });
}
