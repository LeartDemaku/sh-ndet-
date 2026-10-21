import 'package:flutter_test/flutter_test.dart';
import 'package:shendetplus/core/time/kosovo_time.dart';

void main() {
  group('Përshëndetja sipas orës së Kosovës', () {
    test('verë (CEST, +2): kufijtë 03:00, 11:00, 18:00', () {
      // 20 tetor 2026 — ora verore është ende në fuqi.
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 20, 0, 59)),
        'Mirëmbrëma', // 02:59
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 20, 1, 0)),
        'Mirëmëngjesi', // 03:00
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 20, 8, 59)),
        'Mirëmëngjesi', // 10:59
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 20, 9, 0)),
        'Mirëdita', // 11:00
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 20, 15, 59)),
        'Mirëdita', // 17:59
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 20, 16, 0)),
        'Mirëmbrëma', // 18:00
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 20, 22, 30)),
        'Mirëmbrëma', // 00:30 e ditës tjetër
      );
    });

    test('dimër (CET, +1): kufijtë 03:00, 11:00, 18:00', () {
      expect(
        kosovoGreeting(DateTime.utc(2026, 12, 15, 1, 59)),
        'Mirëmbrëma', // 02:59
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 12, 15, 2, 0)),
        'Mirëmëngjesi', // 03:00
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 12, 15, 9, 59)),
        'Mirëmëngjesi', // 10:59
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 12, 15, 10, 0)),
        'Mirëdita', // 11:00
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 12, 15, 16, 59)),
        'Mirëdita', // 17:59
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 12, 15, 17, 0)),
        'Mirëmbrëma', // 18:00
      );
    });

    test('ndryshimi i orës: e diela e fundit e marsit dhe e tetorit', () {
      // Kalimi në orë verore: 29 mars 2026, 01:00 UTC (02:00 → 03:00).
      expect(kosovoUtcOffsetHours(DateTime.utc(2026, 3, 29, 0, 59)), 1);
      expect(kosovoUtcOffsetHours(DateTime.utc(2026, 3, 29, 1, 0)), 2);
      expect(
        kosovoGreeting(DateTime.utc(2026, 3, 29, 0, 59)),
        'Mirëmbrëma', // 01:59
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 3, 29, 1, 0)),
        'Mirëmëngjesi', // 03:00
      );

      // Kthimi në orë dimërore: 25 tetor 2026, 01:00 UTC (03:00 → 02:00).
      expect(kosovoUtcOffsetHours(DateTime.utc(2026, 10, 25, 0, 59)), 2);
      expect(kosovoUtcOffsetHours(DateTime.utc(2026, 10, 25, 1, 0)), 1);
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 25, 0, 59)),
        'Mirëmbrëma', // 02:59
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 25, 1, 0)),
        'Mirëmbrëma', // 02:00 — ende natë
      );
      expect(
        kosovoGreeting(DateTime.utc(2026, 10, 25, 2, 0)),
        'Mirëmëngjesi', // 03:00
      );
    });

    test('ora murale e Kosovës përputhet me ofsetin', () {
      final summer = kosovoWallClock(DateTime.utc(2026, 7, 15, 12, 0));
      expect(summer.hour, 14);
      final winter = kosovoWallClock(DateTime.utc(2026, 1, 15, 12, 0));
      expect(winter.hour, 13);
    });

    test('pranon edhe kohë jo-UTC dhe e kthen saktë', () {
      final instant = DateTime.utc(2026, 10, 20, 9, 0); // 11:00 në Kosovë
      expect(kosovoGreeting(instant.toLocal()), 'Mirëdita');
    });

    test('kohëzgjatja deri në ndryshimin e radhës', () {
      // 12:16 në Kosovë → 18:00 (16:00 UTC).
      expect(
        untilNextKosovoGreetingChange(DateTime.utc(2026, 10, 20, 10, 16)),
        const Duration(hours: 5, minutes: 44),
      );
      // 17:59:30 → 18:00.
      expect(
        untilNextKosovoGreetingChange(DateTime.utc(2026, 10, 20, 15, 59, 30)),
        const Duration(seconds: 30),
      );
      // 18:00 → 03:00 të ditës tjetër.
      expect(
        untilNextKosovoGreetingChange(DateTime.utc(2026, 10, 20, 16)),
        const Duration(hours: 9),
      );
      // 02:59 → 03:00.
      expect(
        untilNextKosovoGreetingChange(DateTime.utc(2026, 10, 20, 0, 59)),
        const Duration(minutes: 1),
      );
      // 03:00 → 11:00.
      expect(
        untilNextKosovoGreetingChange(DateTime.utc(2026, 10, 20, 1)),
        const Duration(hours: 8),
      );
    });

    test('kohëzgjatja është e saktë në ditët e ndryshimit të orës', () {
      // 29 mars: 01:00 lokale → 03:00 lokale është vetëm 1 orë më vonë.
      expect(
        untilNextKosovoGreetingChange(DateTime.utc(2026, 3, 29, 0)),
        const Duration(hours: 1),
      );
      // 25 tetor: 02:00 lokale (CEST) → 03:00 lokale (CET) është 2 orë më vonë.
      expect(
        untilNextKosovoGreetingChange(DateTime.utc(2026, 10, 25, 0)),
        const Duration(hours: 2),
      );
    });

    test('konvertimi i orës murale në UTC', () {
      expect(
        kosovoLocalToUtc(DateTime.utc(2026, 10, 20, 18)),
        DateTime.utc(2026, 10, 20, 16),
      );
      expect(
        kosovoLocalToUtc(DateTime.utc(2026, 12, 15, 18)),
        DateTime.utc(2026, 12, 15, 17),
      );
      expect(
        kosovoLocalToUtc(DateTime.utc(2026, 3, 29, 3)),
        DateTime.utc(2026, 3, 29, 1),
      );
      expect(
        kosovoLocalToUtc(DateTime.utc(2026, 10, 25, 3)),
        DateTime.utc(2026, 10, 25, 2),
      );
    });
  });
}
