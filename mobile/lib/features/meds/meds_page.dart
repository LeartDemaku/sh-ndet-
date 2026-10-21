import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/me_api.dart';
import '../../core/theme/app_theme.dart';
import '../chat/chat_page.dart';
import 'meds_providers.dart';

/// Ekrani 5 · Ilaçet.
/// "Lista e ditës dhe propozim nga Shëndet+ që kërkon konfirmim."
class MedsPage extends ConsumerWidget {
  const MedsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final meds = ref.watch(medicationsProvider);
    final actions = ref.watch(chatControllerProvider.select((s) => s.actions));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ilaçet e mia', style: text.titleMedium),
            Text('Kujtesa dhe plani i ditës', style: text.labelSmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Përditëso',
            onPressed: () => ref.invalidate(medicationsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(medicationsProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, 120),
              children: [
                _TodaySummary(meds: meds, onAdd: () => context.go('/chat')),
                const SizedBox(height: Gap.l),
                Row(
                  children: [
                    Text('Plani i ditës', style: text.titleLarge),
                    const Spacer(),
                    Text('Sipas orarit', style: text.labelSmall),
                  ],
                ),
                const SizedBox(height: Gap.s),
                meds.when(
                  loading: () => const _Loading(),
                  error: (e, _) => _MedError(
                    message: e is MeApiException
                        ? e.userMessage
                        : 'Nuk u ngarkuan ilaçet.',
                    onRetry: () => ref.invalidate(medicationsProvider),
                  ),
                  data: (items) => items.isEmpty
                      ? _EmptyMeds(onAdd: () => context.go('/chat'))
                      : Column(
                          children: [
                            for (final m in items)
                              for (final t
                                  in (m['times'] as List).cast<String>())
                                _MedTile(time: t, name: '${m['name']}'),
                          ],
                        ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: Gap.l),
                  Text('Në pritje të konfirmimit', style: text.titleLarge),
                  const SizedBox(height: Gap.s),
                  for (final a in actions)
                    _ProposalCard(
                      label: a.medication,
                      time: a.times.join(', '),
                      onConfirm: () => ref
                          .read(chatControllerProvider.notifier)
                          .confirmAction(a),
                      onEdit: () => ref
                          .read(chatControllerProvider.notifier)
                          .dismissAction(a.id),
                    ),
                ],
                const SizedBox(height: Gap.l),
                Container(
                  padding: const EdgeInsets.all(Gap.m),
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.mint),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: p.primary),
                      const SizedBox(width: Gap.s),
                      Expanded(
                        child: Text(
                          'Për të shtuar ose ndryshuar një kujtesë, pyet Shëndet+ në chat. '
                          'Asgjë nuk ruhet pa konfirmimin tënd.',
                          style: text.bodyMedium?.copyWith(color: p.ink),
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

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.meds, required this.onAdd});
  final AsyncValue<List<Map<String, dynamic>>> meds;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = meds.maybeWhen(
      data: (items) => items.fold<int>(
        0,
        (sum, m) => sum + ((m['times'] as List?)?.length ?? 0),
      ),
      orElse: () => 0,
    );
    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        gradient: ShendetGradients.hero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F766E),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sot',
                  style: text.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  count == 0
                      ? 'Asnjë kujtesë'
                      : count == 1
                      ? '1 kujtesë'
                      : '$count kujtesa',
                  style: text.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  count == 0
                      ? 'Shto ilaçin e parë për të filluar.'
                      : 'Kujtesat vijnë automatikisht sipas orarit.',
                  style: text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.m),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ShendetColors.primaryDark,
              minimumSize: const Size(96, kTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Shto'),
          ),
        ],
      ),
    );
  }
}

class _MedTile extends StatelessWidget {
  const _MedTile({required this.time, required this.name});
  final String time;
  final String name;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Semantics(
      container: true,
      label: '$time, $name',
      child: Container(
        margin: const EdgeInsets.only(bottom: Gap.s),
        padding: const EdgeInsets.all(Gap.m),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.medication_rounded, color: p.primary, size: 26),
            ),
            const SizedBox(width: Gap.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: p.muted),
                      const SizedBox(width: 4),
                      Text(time, style: text.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Shëno $name si të marrë',
              child: IconButton(
                onPressed: () {},
                tooltip: 'U mor',
                iconSize: 28,
                icon: const Icon(Icons.check_circle_outline_rounded),
                color: p.selfCare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.label,
    required this.time,
    required this.onConfirm,
    required this.onEdit,
  });

  final String label;
  final String time;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: Gap.s),
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROPOZIM NGA SHËNDET+',
            style: text.labelSmall?.copyWith(
              color: p.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: Gap.xs),
          Text(
            'Kujtesë ditore në orën $time për “$label”?',
            style: text.titleMedium,
          ),
          const SizedBox(height: Gap.m),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text('Konfirmo'),
                ),
              ),
              const SizedBox(width: Gap.s),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Ndrysho'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMeds extends StatelessWidget {
  const _EmptyMeds({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.medication_outlined, size: 30, color: p.primary),
          ),
          const SizedBox(height: Gap.m),
          Text(
            'Ende pa ilaçe',
            style: text.titleMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            'Shto ilaçin e parë për të krijuar kujtesa.',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gap.m),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Shto ilaç'),
          ),
        ],
      ),
    );
  }
}

class _MedError extends StatelessWidget {
  const _MedError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: p.warningSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.warningBorder),
      ),
      child: Column(
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Gap.s),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Provo')),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(Gap.l),
    child: Center(child: CircularProgressIndicator()),
  );
}
