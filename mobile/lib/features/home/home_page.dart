import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/time/kosovo_time.dart';
import '../../core/widgets/brand_mark.dart';
import '../meds/meds_providers.dart';

/// Ekrani 2 · Ballina.
/// "Pyetje e shpejtë, katër veprime kryesore dhe karta 'Sot'."
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final meds = ref.watch(medicationsProvider);

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, 120),
              children: [
                _Hero(),
                const SizedBox(height: Gap.l),
                Row(
                  children: [
                    Text('Veprimet e mia', style: text.titleLarge),
                    const Spacer(),
                    Text('Shpejt dhe thjesht', style: text.labelSmall),
                  ],
                ),
                const SizedBox(height: Gap.s),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 620;
                    return GridView.count(
                      crossAxisCount: wide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: Gap.s,
                      crossAxisSpacing: Gap.s,
                      childAspectRatio: wide ? 1.15 : 1.28,
                      children: [
                        _ActionTile(
                          icon: Icons.monitor_heart_outlined,
                          label: 'Simptomat',
                          subtitle: 'Triazh i shpejtë',
                          color: p.primary,
                          onTap: () => context.go('/chat'),
                        ),
                        _ActionTile(
                          icon: Icons.medication_outlined,
                          label: 'Ilaçet',
                          subtitle: 'Kujtesa e ditës',
                          color: p.amber,
                          onTap: () => context.go('/meds'),
                        ),
                        _ActionTile(
                          icon: Icons.event_outlined,
                          label: 'Terminet',
                          subtitle: 'Cakto dhe kujto',
                          color: p.sky,
                          onTap: () => context.go('/meds'),
                        ),
                        _ActionTile(
                          icon: Icons.description_outlined,
                          label: 'Dokumentet',
                          subtitle: 'Analiza, receta',
                          color: p.violet,
                          onTap: () => context.go('/meds'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Gap.l),
                Row(
                  children: [
                    Text('Sot', style: text.titleLarge),
                    const Spacer(),
                    Text('Kujtesa jote', style: text.labelSmall),
                  ],
                ),
                const SizedBox(height: Gap.s),
                meds.when(
                  loading: () => const _TodayLoading(),
                  error: (_, _) => _TodayError(
                    onRetry: () => ref.invalidate(medicationsProvider),
                  ),
                  data: (items) {
                    final upcoming = <({String time, String name})>[];
                    for (final m in items) {
                      for (final t
                          in ((m['times'] as List?) ?? const [])
                              .cast<String>()) {
                        upcoming.add((time: t, name: '${m['name']}'));
                      }
                    }
                    upcoming.sort((a, b) => a.time.compareTo(b.time));
                    if (upcoming.isEmpty) {
                      return _TodayEmpty(onAdd: () => context.go('/meds'));
                    }
                    return _TodayCard(
                      time: upcoming.first.time,
                      name: upcoming.first.name,
                    );
                  },
                ),
                const SizedBox(height: Gap.m),
                Container(
                  padding: const EdgeInsets.all(Gap.m),
                  decoration: BoxDecoration(
                    gradient: p.softGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.mint),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: p.mint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: p.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: Gap.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Të dhënat tuaja janë të mbrojtura',
                              style: text.labelLarge,
                            ),
                            Text(
                              'Janë të enkriptuara. Mund t’i eksportosh ose t’i fshish te Profili.',
                              style: text.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        gradient: ShendetGradients.hero,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F766E),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 38, onDark: true),
              const SizedBox(width: Gap.s),
              const BrandName(onDark: true, fontSize: 19),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Asistent AI, jo mjek',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.l),
          _Greeting(
            style: text.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Si ndihesh sot?',
            style: text.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: Gap.l),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Pyetje e shpejtë, shko te biseda',
            child: Material(
              color: p.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.go('/chat'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.m,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: p.primary),
                      const SizedBox(width: Gap.s),
                      Expanded(
                        child: Text(
                          'Pyet Shëndet+…',
                          style: text.bodyLarge?.copyWith(color: p.muted),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: ShendetGradients.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Përshëndetja e Ballinës sipas orës reale në Kosovë.
///
/// Ndjek saktësisht kufijtë 03:00, 11:00 dhe 18:00 (edhe në ditët e
/// ndryshimit të orës) dhe rifreskohet kur aplikacioni kthehet në plan të parë.
class _Greeting extends StatefulWidget {
  const _Greeting({this.style});

  final TextStyle? style;

  @override
  State<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<_Greeting> with WidgetsBindingObserver {
  late String _text;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _text = kosovoGreeting();
    _scheduleNext();
    WidgetsBinding.instance.addObserver(this);
  }

  void _scheduleNext() {
    _timer?.cancel();
    // +200 ms rezervë, që kalimi të bëhet pas kufirit, jo para tij.
    _timer = Timer(
      untilNextKosovoGreetingChange() + const Duration(milliseconds: 200),
      () {
        _refresh();
        _scheduleNext();
      },
    );
  }

  void _refresh() {
    final next = kosovoGreeting();
    if (mounted && next != _text) setState(() => _text = next);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _scheduleNext();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(_text, style: widget.style);
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$label. $subtitle',
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: context.isDark ? 0.16 : 0.11,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Text(
                  label,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: text.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatefulWidget {
  const _TodayCard({required this.time, required this.name});

  final String time;
  final String name;

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  bool _taken = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: ShendetGradients.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                Text(
                  widget.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ilaçi i radhës · sot',
                  style: text.labelSmall?.copyWith(
                    color: p.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(widget.name, style: text.titleMedium),
              ],
            ),
          ),
          const SizedBox(width: Gap.s),
          FilledButton.tonal(
            onPressed: _taken
                ? null
                : () {
                    setState(() => _taken = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('U shënua për sot.')),
                    );
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size(84, kTouchTarget),
              backgroundColor: p.mint,
              foregroundColor: p.primaryDark,
              disabledBackgroundColor: p.surfaceAlt,
              disabledForegroundColor: p.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(_taken ? 'U shënua' : 'E mora'),
          ),
        ],
      ),
    );
  }
}

class _TodayLoading extends StatelessWidget {
  const _TodayLoading();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _TodayError extends StatelessWidget {
  const _TodayError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: p.warningSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.warningBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: p.urgent),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Text(
              'Nuk u lidhëm. Provo përsëri pas pak.',
              style: text.bodyMedium,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Provo')),
        ],
      ),
    );
  }
}

class _TodayEmpty extends StatelessWidget {
  const _TodayEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.medication_outlined, color: p.primary),
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ende pa ilaçe', style: text.titleMedium),
                Text(
                  'Shto ilaçin e parë për të krijuar kujtesa.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              minimumSize: const Size(84, kTouchTarget),
              backgroundColor: p.mint,
              foregroundColor: p.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Shto'),
          ),
        ],
      ),
    );
  }
}
