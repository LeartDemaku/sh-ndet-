import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/providers.dart';
import '../../core/auth/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/emergency_action.dart';
import '../../core/widgets/theme_mode_selector.dart';

final meProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(meApiProvider);
  return api.fetchMe();
});

/// Ekrani 6 · Profili / Privatësia.
/// "Pëlqimet, eksporti dhe fshirja e të dhënave, të arritshme lehtë."
class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  bool _exporting = false;

  /// Çelësat: i pari (historiku) është ON si parazgjedhje dhe ulet kur tërhiqet.
  bool _history = true;
  bool _analytics = false;
  bool _notifications = true;

  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final me = ref.watch(meProvider);

    me.whenData((data) {
      if (_loaded) return;
      _loaded = true;
      final consents = List<Map<String, dynamic>>.from(
        data['consents'] as List,
      );
      bool grantedOf(String kind, bool fallback) {
        final row = consents.where((c) => c['kind'] == kind).toList();
        if (row.isEmpty) return fallback;
        return row.first['granted'] == true;
      }

      _history = grantedOf('history', true);
      _analytics = grantedOf('analytics', false);
      _notifications = grantedOf('notifications', true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    });

    final email = me.maybeWhen(
      data: (data) =>
          (data['profile'] as Map<String, dynamic>)['email']?.toString(),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili'),
        actions: const [EmergencyAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, 120),
        children: [
          _ProfileHeader(email: email, loading: me.isLoading),
          const SizedBox(height: Gap.l),
          _SectionCard(
            title: 'Pamja',
            icon: Icons.palette_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Zgjidh si duket Shëndet+. Zgjedhja ruhet për herën tjetër.',
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: Gap.m),
                    const ThemeModeSelector(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.m),
          _SectionCard(
            title: 'Privatësia dhe pëlqimet',
            icon: Icons.shield_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.s),
                child: Text(
                  'Ti vendos çfarë ruhet dhe për sa kohë. Ndryshimet ruhen menjëherë.',
                  style: text.bodyMedium,
                ),
              ),
              _toggle(
                title: 'Ruaj historikun e bisedave',
                value: _history,
                onChanged: (v) =>
                    _setConsent('history', v, (x) => _history = x),
              ),
              const Divider(height: 1, indent: Gap.m, endIndent: Gap.m),
              _toggle(
                title: 'Analitikë anonime (opsionale)',
                value: _analytics,
                onChanged: (v) =>
                    _setConsent('analytics', v, (x) => _analytics = x),
              ),
              const Divider(height: 1, indent: Gap.m, endIndent: Gap.m),
              _toggle(
                title: 'Njoftime për kujtesat',
                value: _notifications,
                onChanged: (v) =>
                    _setConsent('notifications', v, (x) => _notifications = x),
              ),
            ],
          ),
          const SizedBox(height: Gap.m),
          _SectionCard(
            title: 'Të dhënat e mia',
            icon: Icons.folder_outlined,
            children: [
              _tile(
                icon: Icons.download_rounded,
                title: 'Eksporto të dhënat e mia',
                subtitle: 'Merr një kopje të plotë të informacionit.',
                trailing: _exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _exporting ? null : _export,
              ),
              const Divider(height: 1, indent: Gap.m, endIndent: Gap.m),
              _tile(
                icon: Icons.delete_outline_rounded,
                title: 'Fshi llogarinë dhe të dhënat',
                subtitle: 'Fshirje e përhershme, me konfirmim.',
                danger: true,
                onTap: _confirmDelete,
              ),
            ],
          ),
          const SizedBox(height: Gap.m),
          _SectionCard(
            title: 'Sesioni',
            icon: Icons.logout_rounded,
            children: [
              _tile(
                icon: Icons.logout_rounded,
                title: 'Dil nga llogaria',
                subtitle: 'Mund të hysh përsëri në çdo moment.',
                onTap: _logout,
              ),
            ],
          ),
          const SizedBox(height: Gap.m),
          Center(
            child: Text(
              'Pëlqimet: versioni 2026-10 · Shëndet+ nuk zëvendëson mjekun.',
              textAlign: TextAlign.center,
              style: text.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setConsent(
    String kind,
    bool value,
    void Function(bool) assign,
  ) async {
    setState(() => assign(value));
    try {
      await ref.read(meApiProvider).setConsent(kind, granted: value);
      ref.invalidate(meProvider);
    } catch (_) {
      setState(() => assign(!value));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuk u ruajt ndryshimi. Provo përsëri.'),
          ),
        );
      }
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final data = await ref.read(meApiProvider).exportData();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (sheetContext, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(Gap.l),
            children: [
              Text(
                'Eksporti i të dhënave',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: Gap.s),
              Text(
                'Ky është i gjithë informacioni që kemi për ty. Mund ta ruash ose ta dërgosh diku.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: Gap.m),
              Container(
                padding: const EdgeInsets.all(Gap.m),
                decoration: BoxDecoration(
                  color: sheetContext.palette.surfaceSunken,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(data),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: sheetContext.palette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuk u përgatit eksporti. Provo përsëri pas pak.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dil nga llogaria?'),
        content: const Text(
          'Do të kthehesh te ekrani i mirëseardhjes. Të dhënat mbeten të ruajtura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anulo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Dil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref.read(secureStoreProvider).clear();
    ref.read(authSessionProvider).setAuthenticated(false);
    if (mounted) context.go('/onboarding');
  }

  /// Fshirje e konfirmuar me dy hapa (udhëzimi).
  Future<void> _confirmDelete() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fshi llogarinë?'),
        content: const Text(
          'Të dhënat tuaja personale fshihen përgjithmonë. Kjo nuk mund të zhbëhet. '
          'Konfirmo vetëm nëse je i sigurt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anulo'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ShendetColors.emergency,
              foregroundColor: ShendetColors.onEmergency,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Vazhdo'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapi i fundit'),
        content: const Text('Shtyp FSHIJ për ta konfirmuar përfundimisht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anulo'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ShendetColors.emergency,
              foregroundColor: ShendetColors.onEmergency,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('FSHIJ'),
          ),
        ],
      ),
    );
    if (second != true || !mounted) return;

    try {
      await ref.read(meApiProvider).deleteAccount();
      await ref.read(secureStoreProvider).clear();
      ref.read(authSessionProvider).setAuthenticated(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Llogaria u fshi.')));
      context.go('/onboarding');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nuk u krye fshirja. Provo përsëri.')),
        );
      }
    }
  }

  Widget _toggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Semantics(
    toggled: value,
    label: title,
    child: SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Gap.m,
        vertical: 2,
      ),
      activeThumbColor: context.palette.primary,
    ),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    String? subtitle,
    bool danger = false,
    Widget? trailing,
  }) {
    final p = context.palette;
    return Semantics(
      button: onTap != null,
      label: title,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.m,
          vertical: 4,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (danger ? p.emergency : p.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: danger ? p.emergency : p.primary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: danger ? p.emergency : p.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.email, required this.loading});
  final String? email;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        gradient: ShendetGradients.hero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F766E),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loading ? 'Po ngarkohet…' : (email ?? 'Llogaria ime'),
                  style: text.titleMedium?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Llogari e sigurt · Shëndet+',
                  style: text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, Gap.xs),
            child: Row(
              children: [
                Icon(icon, size: 20, color: p.primary),
                const SizedBox(width: Gap.s),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: Gap.xs),
        ],
      ),
    );
  }
}
