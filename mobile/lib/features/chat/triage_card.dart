import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum TriageLevel { emergency, urgent, soon, selfCare }

/// Vlerë e panjohur nga serveri => niveli më i kujdesshëm, kurrë "vetëkujdes".
TriageLevel triageFromApi(String value) => switch (value) {
  'emergency' => TriageLevel.emergency,
  'urgent_today' => TriageLevel.urgent,
  'see_doctor_soon' => TriageLevel.soon,
  'self_care' => TriageLevel.selfCare,
  _ => TriageLevel.urgent,
};

extension TriageStyle on TriageLevel {
  Color get accent => switch (this) {
    TriageLevel.emergency => ShendetColors.emergency,
    TriageLevel.urgent => ShendetColors.urgent,
    TriageLevel.soon => ShendetColors.soon,
    TriageLevel.selfCare => ShendetColors.selfCare,
  };

  Color get tint => switch (this) {
    TriageLevel.emergency => const Color(0xFFFEE2E2),
    TriageLevel.urgent => const Color(0xFFFFEDD5),
    TriageLevel.soon => const Color(0xFFDBEAFE),
    TriageLevel.selfCare => const Color(0xFFDCFCE7),
  };

  /// Ngjyra e theksit sipas pamjes aktuale (e lexueshme edhe në dark).
  Color accentOf(ShendetPalette p) => switch (this) {
    TriageLevel.emergency => p.emergency,
    TriageLevel.urgent => p.urgent,
    TriageLevel.soon => p.soon,
    TriageLevel.selfCare => p.selfCare,
  };

  /// Sfondi i kartës sipas pamjes aktuale.
  Color tintOf(ShendetPalette p) => switch (this) {
    TriageLevel.emergency => p.emergencySurface,
    TriageLevel.urgent => p.warningSurface,
    TriageLevel.soon => p.infoSurface,
    TriageLevel.selfCare => p.successSurface,
  };

  IconData get icon => switch (this) {
    TriageLevel.emergency => Icons.emergency,
    TriageLevel.urgent => Icons.local_hospital_rounded,
    TriageLevel.soon => Icons.event_available_rounded,
    TriageLevel.selfCare => Icons.favorite_border_rounded,
  };

  String get label => switch (this) {
    TriageLevel.emergency => 'Emergjencë',
    TriageLevel.urgent => 'Urgjente sot',
    TriageLevel.soon => 'Mjek së shpejti',
    TriageLevel.selfCare => 'Vetëkujdes',
  };
}

/// Përmbledhje që vjen nga serveri. Përdoret edhe për semantikën e ekranit.
class TriageData {
  const TriageData({
    required this.level,
    required this.title,
    required this.summary,
    this.reasons = const [],
    this.steps = const [],
    this.watchFor = const [],
  });

  factory TriageData.fromApi(Map<String, dynamic> json) => TriageData(
    level: triageFromApi('${json['level']}'),
    title: '${json['title'] ?? ''}',
    summary: '${json['summary'] ?? ''}',
    reasons: List<String>.from((json['reasons'] ?? const []) as List),
    steps: List<String>.from((json['next_steps'] ?? const []) as List),
    watchFor: List<String>.from((json['watch_for'] ?? const []) as List),
  );

  final TriageLevel level;
  final String title;
  final String summary;
  final List<String> reasons;
  final List<String> steps;
  final List<String> watchFor;
}

class TriageCard extends StatelessWidget {
  const TriageCard({
    super.key,
    required this.level,
    required this.title,
    required this.summary,
    required this.steps,
    this.watchFor = const [],
    this.actions,
  });

  factory TriageCard.fromData(TriageData data, {List<Widget>? actions}) =>
      TriageCard(
        level: data.level,
        title: data.title,
        summary: data.summary,
        steps: data.steps,
        watchFor: data.watchFor,
        actions: actions,
      );

  final TriageLevel level;
  final String title;
  final String summary;
  final List<String> steps;
  final List<String> watchFor;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final accent = level.accentOf(p);
    final watchTitle = 'Kur duhet të kërkosh ndihmë më shpejt';

    return Semantics(
      container: true,
      label: '${level.label}. $title. $summary',
      child: Container(
        padding: const EdgeInsets.all(Gap.m),
        decoration: BoxDecoration(
          color: level.tintOf(p),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(level.icon, color: accent, size: 24),
                const SizedBox(width: Gap.s),
                Expanded(
                  child: Text(
                    level.label.toUpperCase(),
                    style: text.labelSmall?.copyWith(
                      color: accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.s),
            Text(title, style: text.titleMedium),
            const SizedBox(height: Gap.xs),
            Text(summary, style: text.bodyMedium),
            const SizedBox(height: Gap.m),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: accent),
                    const SizedBox(width: Gap.s),
                    Expanded(
                      child: Text(
                        step,
                        style: text.bodyMedium?.copyWith(color: p.ink),
                      ),
                    ),
                  ],
                ),
              ),
            if (watchFor.isNotEmpty) ...[
              const SizedBox(height: Gap.s),
              Text(watchTitle, style: text.labelSmall?.copyWith(color: accent)),
              const SizedBox(height: Gap.xs),
              for (final w in watchFor)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 18, color: accent),
                      const SizedBox(width: Gap.s),
                      Expanded(child: Text(w, style: text.bodyMedium)),
                    ],
                  ),
                ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: Gap.m),
              ...actions!,
            ],
          ],
        ),
      ),
    );
  }
}
