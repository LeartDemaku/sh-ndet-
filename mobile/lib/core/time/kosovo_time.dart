/// Koha zyrtare e Kosovës (Europe/Belgrade: CET/CEST).
///
/// Përdoret për përshëndetjen e Ballinës, që të mos varet nga zona kohore
/// e pajisjes. Ndryshimi i orës është sipas rregullit të BE-së: fillon të
/// dielën e fundit të marsit dhe mbaron të dielën e fundit të tetorit,
/// gjithmonë në 01:00 UTC.
library;

/// Ofseti i Kosovës në orë për një çast UTC (+1 dimër, +2 verë).
int kosovoUtcOffsetHours(DateTime instant) {
  final utc = instant.toUtc();
  final dstStart = _lastSundayUtc(utc.year, 3).add(const Duration(hours: 1));
  final dstEnd = _lastSundayUtc(utc.year, 10).add(const Duration(hours: 1));
  final isSummer = !utc.isBefore(dstStart) && utc.isBefore(dstEnd);
  return isSummer ? 2 : 1;
}

/// Ora "murale" e Kosovës për një çast UTC (fusha .hour është ora lokale).
DateTime kosovoWallClock(DateTime instant) {
  final utc = instant.toUtc();
  return utc.add(Duration(hours: kosovoUtcOffsetHours(utc)));
}

/// Përshëndetja sipas orës aktuale në Kosovë:
/// 03:00–10:59 Mirëmëngjesi · 11:00–17:59 Mirëdita · 18:00–02:59 Mirëmbrëma.
String kosovoGreeting([DateTime? instant]) {
  final hour = kosovoWallClock(instant ?? DateTime.now()).hour;
  if (hour >= 3 && hour < 11) return 'Mirëmëngjesi';
  if (hour >= 11 && hour < 18) return 'Mirëdita';
  return 'Mirëmbrëma';
}

/// Orari i saktë (UTC) kur përshëndetja ndryshon herën tjetër.
///
/// Përdoret nga Ballina që teksti të ndryshojë pikërisht në 03:00, 11:00 ose
/// 18:00 me orën e Kosovës, pa pritur asnjë interval kontrolli.
Duration untilNextKosovoGreetingChange([DateTime? instant]) {
  final nowUtc = (instant ?? DateTime.now()).toUtc();
  final local = kosovoWallClock(nowUtc);
  DateTime? next;
  for (final hour in const [3, 11, 18]) {
    final candidate = DateTime.utc(local.year, local.month, local.day, hour);
    if (candidate.isAfter(local)) {
      next = candidate;
      break;
    }
  }
  next ??= DateTime.utc(local.year, local.month, local.day + 1, 3);
  final wait = kosovoLocalToUtc(next).difference(nowUtc);
  return wait.isNegative ? Duration.zero : wait;
}

/// Kthen orën murale të Kosovës në çastin përkatës UTC.
DateTime kosovoLocalToUtc(DateTime local) {
  final naive = DateTime.utc(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    local.second,
  );
  var utc = naive;
  // Dy përsëritje mjaftojnë edhe në ditët e ndryshimit të orës.
  for (var i = 0; i < 2; i++) {
    utc = naive.subtract(Duration(hours: kosovoUtcOffsetHours(utc)));
  }
  return utc;
}

/// E diela e fundit e muajit, në 00:00 UTC.
DateTime _lastSundayUtc(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0);
  // weekday: 1 = e hënë … 7 = e diel; nëntë % 7 = ditët që duhen zbritur.
  return DateTime.utc(year, month, lastDay.day - (lastDay.weekday % 7));
}
