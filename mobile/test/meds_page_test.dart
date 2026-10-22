import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shendetplus/core/api/me_api.dart';
import 'package:shendetplus/core/api/providers.dart';
import 'package:shendetplus/core/theme/app_theme.dart';
import 'package:shendetplus/features/meds/meds_page.dart';

class _FakeMeApi extends MeApi {
  _FakeMeApi()
    : super(baseUrl: 'http://api.test', tokenProvider: () async => null);

  int deleteCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchMedications() async {
    if (deleteCalls > 0) return [];
    return [
      {
        'id': 'med-1',
        'name': 'Metformin',
        'times': ['08:00', '20:00'],
      },
    ];
  }

  @override
  Future<void> deleteMedication(String id) async {
    deleteCalls++;
  }
}

void main() {
  testWidgets('fshirja e ilaçit kërkon konfirmim dhe e heq nga paneli', (
    tester,
  ) async {
    final api = _FakeMeApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [meApiProvider.overrideWithValue(api)],
        child: MaterialApp(theme: buildLightTheme(), home: const MedsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Metformin'), findsWidgets);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Fshij ilaçin?'), findsOneWidget);

    await tester.tap(find.text('Fshij'));
    await tester.pumpAndSettle();

    expect(api.deleteCalls, 1);
    expect(find.text('Ende pa ilaçe'), findsOneWidget);
    expect(find.text('Ilaçi u fshi.'), findsOneWidget);
    api.dispose();
  });
}
