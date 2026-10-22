import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shendetplus/core/api/me_api.dart';
import 'package:shendetplus/core/api/providers.dart';
import 'package:shendetplus/core/theme/app_theme.dart';
import 'package:shendetplus/features/privacy/data_page.dart';

class _FakeMeApi extends MeApi {
  _FakeMeApi() : super(baseUrl: 'http://api.test', tokenProvider: () async => 't');

  final deleted = <String>[];
  bool _firstLoad = true;

  @override
  Future<Map<String, dynamic>> exportData() async {
    if (_firstLoad) {
      _firstLoad = false;
      return {
        'exported_at': '2026-10-22T10:00:00Z',
        'profile': {
          'first_name': 'Leart',
          'last_name': 'Demaku',
          'email': 'leart@example.com',
          'country': 'XK',
          'created_at': '2026-01-01T10:00:00Z',
        },
        'consents': [
          {'kind': 'history', 'granted': true},
        ],
        'medications': [],
        'conversations': [
          {
            'id': 'conv-1',
            'created_at': '2026-10-22T10:00:00Z',
            'messages': [
              {'role': 'user', 'content': 'Kam dhimbje koke'},
              {'role': 'assistant', 'content': 'Pusho dhe pi ujë.'},
            ],
          },
        ],
      };
    }
    return {
      'profile': {'first_name': 'Leart', 'last_name': 'Demaku'},
      'consents': [],
      'medications': [],
      'conversations': [],
    };
  }

  @override
  Future<void> deleteConversation(String id) async {
    deleted.add(id);
  }

  @override
  void dispose() {}
}

void main() {
  testWidgets('DataPage shfaq historikun dhe fshin një bisedë me konfirmim', (
    tester,
  ) async {
    final api = _FakeMeApi();
    addTearDown(api.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [meApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const DataPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leart Demaku'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kam dhimbje koke'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kam dhimbje koke'), findsOneWidget);
    expect(find.textContaining('2 mesazhe'), findsOneWidget);

    await tester.tap(find.byTooltip('Fshi bisedën'));
    await tester.pumpAndSettle();
    expect(find.text('Fshi bisedën?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Fshi bisedën'));
    await tester.pumpAndSettle();

    expect(api.deleted, ['conv-1']);
    expect(find.textContaining('Nuk ka biseda të ruajtura'), findsOneWidget);
  });
}
