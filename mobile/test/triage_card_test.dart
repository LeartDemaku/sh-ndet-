// Teste të kartës së triazhit (Hapi 16).
//
// Rregulli i sigurisë që ky test mbron: "Vlerë e panjohur nga serveri =>
// niveli më i kujdesshëm, kurrë vetëkujdes". Nëse dikush e ndryshon logjikën
// dhe bie në "self_care" për një vlerë të panjohur, ky test dështon.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shendetplus/core/theme/app_theme.dart';
import 'package:shendetplus/features/chat/triage_card.dart';

void main() {
  group('triageFromApi', () {
    const vlerat = {
      'emergency': TriageLevel.emergency,
      'urgent_today': TriageLevel.urgent,
      'see_doctor_soon': TriageLevel.soon,
      'self_care': TriageLevel.selfCare,
    };

    vlerat.forEach((input, expected) {
      test('"$input" kthehet $expected', () {
        expect(triageFromApi(input), expected);
      });
    });

    test('vlerë e panjohur => niveli më i kujdesshëm, kurrë vetëkujdes', () {
      for (final v in ['', 'gabim', 'SELF_CARE', 'urgent', 'null']) {
        expect(
          triageFromApi(v),
          TriageLevel.urgent,
          reason: '"$v" nuk duhet të bie kurrë në vetëkujdes',
        );
      }
    });

    test(
      'rasti i rrezikshëm: vlerë e panjohur nuk kthehet kurrë self_care',
      () {
        // Këtu janë VETËM vlera që nuk janë "self_care": asnjëra nuk duhet të bjerë
        // kurrë në vetëkujdes. "self_care" i saktë testohet sipër.
        const teGjitha = [
          'emergency',
          'urgent_today',
          'see_doctor_soon',
          'diagnostikuar',
          '1',
          'true',
          'NA',
          'sick',
        ];
        for (final v in teGjitha) {
          expect(
            triageFromApi(v),
            isNot(TriageLevel.selfCare),
            reason: 'vetëkujdesi duhet të vijë VETËM nga "self_care" i saktë',
          );
        }
      },
    );
  });

  group('etiketat dhe ngjyrat', () {
    test('etiketat janë në shqip', () {
      expect(TriageLevel.emergency.label, 'Emergjencë');
      expect(TriageLevel.urgent.label, 'Urgjente sot');
      expect(TriageLevel.soon.label, 'Mjek së shpejti');
      expect(TriageLevel.selfCare.label, 'Vetëkujdes');
    });

    test('çdo nivel ka ngjyrën e vet semantike (pa varësi nga ngjyra: ikonë + tekst)', () {
      expect(TriageLevel.emergency.accent, ShendetColors.emergency);
      expect(TriageLevel.urgent.accent, ShendetColors.urgent);
      expect(TriageLevel.soon.accent, ShendetColors.soon);
      expect(TriageLevel.selfCare.accent, ShendetColors.selfCare);
    });
  });

  group('TriageCard', () {
    Future<TriageCard> pump(WidgetTester tester, TriageCard card) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(body: SingleChildScrollView(child: card)),
        ),
      );
      return card;
    }

    testWidgets('shfaq titullin, përmbledhjen dhe hapat', (tester) async {
      await pump(
        tester,
        const TriageCard(
          level: TriageLevel.soon,
          title: 'Flit me mjekun brenda 1 deri 3 ditëve',
          summary: 'Simptomat zgjasin dhe nuk po përmirësohen.',
          steps: ['Mbaj shënim kur filluan dhe sa të forta janë.'],
        ),
      );

      expect(find.text('MJEK SË SHPEJTI'), findsOneWidget);
      expect(
        find.text('Flit me mjekun brenda 1 deri 3 ditëve'),
        findsOneWidget,
      );
      expect(
        find.text('Simptomat zgjasin dhe nuk po përmirësohen.'),
        findsOneWidget,
      );
      expect(
        find.text('Mbaj shënim kur filluan dhe sa të forta janë.'),
        findsOneWidget,
      );
    });

    testWidgets('ka etiketë Semantics për lexuesin e ekranit', (tester) async {
      await pump(
        tester,
        const TriageCard(
          level: TriageLevel.emergency,
          title: 'Kërko ndihmë tani',
          summary: 'Simptomat mund të jenë urgjente.',
          steps: [],
        ),
      );

      final node = tester.getSemantics(find.byType(TriageCard));
      expect(node.label, contains('Emergjencë'));
      expect(node.label, contains('Kërko ndihmë tani'));
    });

    testWidgets('shfaq seksionin "Kur të kërkohet ndihmë më shpejt"', (
      tester,
    ) async {
      await pump(
        tester,
        const TriageCard(
          level: TriageLevel.selfCare,
          title: 'Vetëkujdes',
          summary: 'Simptoma të lehta.',
          steps: [],
          watchFor: ['Vështirësi në frymëmarrje'],
        ),
      );

      expect(
        find.text('Kur duhet të kërkosh ndihmë më shpejt'),
        findsOneWidget,
      );
      expect(find.text('Vështirësi në frymëmarrje'), findsOneWidget);
    });

    testWidgets('TriageData.fromAPI lexon strukturën e serverit', (
      tester,
    ) async {
      final data = TriageData.fromApi({
        'level': 'see_doctor_soon',
        'title': 'Flit me mjekun',
        'summary': 'Zgjidhje e pjesshme.',
        'reasons': ['arsye 1'],
        'next_steps': ['hapi 1', 'hapi 2'],
        'watch_for': ['shenjë alarmi'],
      });

      expect(data.level, TriageLevel.soon);
      expect(data.steps, hasLength(2));
      expect(data.watchFor, hasLength(1));
    });
  });
}
