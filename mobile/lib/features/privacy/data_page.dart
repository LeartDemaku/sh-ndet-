import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/me_api.dart';
import '../../core/api/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/emergency_action.dart';
import '../chat/chat_controller.dart';
import '../chat/chat_page.dart';
import '../meds/meds_providers.dart';

/// Ekrani i eksportit dhe i menaxhimit të të dhënave personale.
///
/// Të gjitha të dhënat vijnë nga një kërkesë e vetme (`/v1/me/export`), që
/// historiku i bisedave, ilaçet dhe pëlqimet të shfaqen të organizuara pa
/// kërkesa shtesë. Fshirja bëhet veçmas dhe vetëm pas konfirmimit.
class DataPage extends ConsumerStatefulWidget {
  const DataPage({super.key});

  @override
  ConsumerState<DataPage> createState() => _DataPageState();
}

class _DataPageState extends ConsumerState<DataPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await ref.read(meApiProvider).exportData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } on MeApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Nuk u ngarkuan të dhënat. Provo përsëri.';
      });
    }
  }

  List<Map<String, dynamic>> get _conversations {
    final raw = _data?['conversations'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> get _medications {
    final raw = _data?['medications'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> get _profile {
    final raw = _data?['profile'];
    return raw is Map ? Map<String, dynamic>.from(raw) : const {};
  }

  String get _displayName {
    final first = '${_profile['first_name'] ?? ''}'.trim();
    final last = '${_profile['last_name'] ?? ''}'.trim();
    final value = [first, last].where((part) => part.isNotEmpty).join(' ');
    return value.isEmpty ? 'Nuk është plotësuar' : value;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _deleteConversation(Map<String, dynamic> conversation) async {
    final id = '${conversation['id'] ?? ''}';
    if (id.isEmpty || _working) return;
    final title = _conversationTitle(conversation);
    final ok = await _confirm(
      title: 'Fshi bisedën?',
      message:
          'Biseda “$title” dhe të gjitha mesazhet e saj do të fshihen përgjithmonë. '
          'Ky veprim nuk mund të zhbëhet.',
      action: 'Fshi bisedën',
    );
    if (!ok || !mounted) return;

    setState(() => _working = true);
    try {
      await ref.read(meApiProvider).deleteConversation(id);
      ref.read(chatControllerProvider.notifier).discardConversation(id);
      await _load();
      if (!mounted) return;
      _snack('Biseda u fshi.');
    } on MeApiException catch (e) {
      if (mounted) _snack(e.userMessage);
    } catch (_) {
      if (mounted) _snack('Nuk u fshi biseda. Provo përsëri.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteAllConversations() async {
    final count = _conversations.length;
    if (count == 0 || _working) return;
    final ok = await _confirm(
      title: 'Fshi të gjitha bisedat?',
      message:
          'Do të fshihen përgjithmonë $count biseda dhe të gjitha mesazhet e tyre. '
          'Ilaçet dhe pëlqimet nuk preken.',
      action: 'Fshi bisedat',
    );
    if (!ok || !mounted) return;

    setState(() => _working = true);
    try {
      await ref.read(meApiProvider).deleteAllConversations();
      ref.read(chatControllerProvider.notifier).discardAllConversations();
      await _load();
      if (!mounted) return;
      _snack('Të gjitha bisedat u fshinë.');
    } on MeApiException catch (e) {
      if (mounted) _snack(e.userMessage);
    } catch (_) {
      if (mounted) _snack('Nuk u fshinë bisedat. Provo përsëri.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteMedication(Map<String, dynamic> medication) async {
    final id = '${medication['id'] ?? ''}';
    if (id.isEmpty || _working) return;
    final name = '${medication['name'] ?? 'Ilaçi'}';
    final ok = await _confirm(
      title: 'Fshi ilaçin?',
      message:
          '“$name” dhe kujtesat e tij do të fshihen përgjithmonë. '
          'Ky veprim nuk mund të zhbëhet.',
      action: 'Fshi ilaçin',
    );
    if (!ok || !mounted) return;

    setState(() => _working = true);
    try {
      await ref.read(meApiProvider).deleteMedication(id);
      ref.invalidate(medicationsProvider);
      await _load();
      if (!mounted) return;
      _snack('Ilaçi u fshi.');
    } on MeApiException catch (e) {
      if (mounted) _snack(e.userMessage);
    } catch (_) {
      if (mounted) _snack('Nuk u fshi ilaçi. Provo përsëri.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteAllMedications() async {
    final count = _medications.length;
    if (count == 0 || _working) return;
    final ok = await _confirm(
      title: 'Fshi të gjitha ilaçet?',
      message:
          'Do të fshihen përgjithmonë $count ilaçe dhe të gjitha kujtesat e tyre. '
          'Bisedat dhe pëlqimet nuk preken.',
      action: 'Fshi ilaçet',
    );
    if (!ok || !mounted) return;

    setState(() => _working = true);
    try {
      await ref.read(meApiProvider).deleteAllMedications();
      ref.invalidate(medicationsProvider);
      await _load();
      if (!mounted) return;
      _snack('Të gjitha ilaçet u fshinë.');
    } on MeApiException catch (e) {
      if (mounted) _snack(e.userMessage);
    } catch (_) {
      if (mounted) _snack('Nuk u fshinë ilaçet. Provo përsëri.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _openConversation(Map<String, dynamic> conversation) {
    final id = '${conversation['id'] ?? ''}';
    if (id.isEmpty) return;
    final rawMessages = conversation['messages'];
    final messages = <ChatMessage>[];
    if (rawMessages is List) {
      for (final item in rawMessages) {
        if (item is! Map) continue;
        final role = '${item['role'] ?? 'assistant'}';
        final content = '${item['content'] ?? ''}';
        if (content.trim().isEmpty) continue;
        messages.add(ChatMessage(role: role, text: content));
      }
    }
    ref
        .read(chatControllerProvider.notifier)
        .openConversation(conversationId: id, messages: messages);
    context.go('/chat');
  }

  Future<void> _copyJson() async {
    final data = _data;
    if (data == null) return;
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
    );
    if (mounted) _snack('Kopja JSON u vendos në clipboard.');
  }

  void _showJson() {
    final data = _data;
    if (data == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (sheetContext, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'JSON i plotë',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Kopjo JSON',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: const JsonEncoder.withIndent('  ').convert(data),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            const SizedBox(height: Gap.s),
            Container(
              padding: const EdgeInsets.all(Gap.m),
              decoration: BoxDecoration(
                color: sheetContext.palette.surfaceSunken,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
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
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Të dhënat e mia'),
        actions: const [EmergencyAction()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.m,
                      Gap.s,
                      Gap.m,
                      120,
                    ),
                    children: [
                      Text(
                        'Kopja e plotë e të dhënave që Shëndet+ ruan për ty. '
                        'Historiku i bisedave shfaqet i organizuar; çdo bisedë '
                        'mund të hapet dhe të vazhdohet.',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: Gap.m),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyJson,
                              icon: const Icon(Icons.copy_all_rounded),
                              label: const Text('Kopjo JSON'),
                            ),
                          ),
                          const SizedBox(width: Gap.s),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showJson,
                              icon: const Icon(Icons.code_rounded),
                              label: const Text('Shiko JSON'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.l),
                      _SectionCard(
                        title: 'Profili',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _InfoRow(label: 'Emri', value: _displayName),
                          _InfoRow(
                            label: 'Shteti',
                            value: '${_profile['country'] ?? '—'}',
                          ),
                          _InfoRow(
                            label: 'Krijuar',
                            value: _date(_profile['created_at']),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.m),
                      _SectionCard(
                        title: 'Pëlqimet',
                        icon: Icons.shield_outlined,
                        children: [
                          for (final consent in _consents)
                            _InfoRow(
                              label: _consentLabel('${consent['kind'] ?? ''}'),
                              value: consent['granted'] == true
                                  ? 'Dhënë'
                                  : 'Tërhequr',
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Gap.m,
                              0,
                              Gap.m,
                              Gap.s,
                            ),
                            child: Text(
                              'Pëlqimet ndryshohen te Profili. Fshirja e tyre '
                              'nuk e fshin llogarinë.',
                              style: text.labelSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.m),
                      _medicationsSection(context),
                      const SizedBox(height: Gap.m),
                      _conversationsSection(context),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _consents {
    final raw = _data?['consents'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Widget _medicationsSection(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final meds = _medications;
    return _SectionCard(
      title: 'Ilaçet dhe kujtesat',
      icon: Icons.medication_outlined,
      children: [
        if (meds.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
            child: Text('Nuk ka ilaçe të ruajtur.', style: text.bodyMedium),
          )
        else
          for (final medication in meds)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Gap.m,
                vertical: 2,
              ),
              leading: Icon(Icons.medication_outlined, color: p.primary),
              title: Text('${medication['name'] ?? 'Ilaç'}'),
              subtitle: Text(
                _times(medication['times']),
                style: text.labelSmall,
              ),
              trailing: IconButton(
                tooltip: 'Fshi ilaçin',
                onPressed: _working
                    ? null
                    : () => _deleteMedication(medication),
                icon: Icon(Icons.delete_outline_rounded, color: p.emergency),
              ),
            ),
        if (meds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.s),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _working ? null : _deleteAllMedications,
                icon: Icon(Icons.delete_sweep_outlined, color: p.emergency),
                label: Text(
                  'Fshi të gjitha ilaçet',
                  style: TextStyle(color: p.emergency),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _conversationsSection(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final conversations = _conversations;
    return _SectionCard(
      title: 'Historiku i bisedave',
      icon: Icons.forum_outlined,
      children: [
        if (conversations.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
            child: Text(
              'Nuk ka biseda të ruajtura. Bisedat ruhen vetëm kur pëlqimi '
              'për historikun është i aktivizuar.',
              style: text.bodyMedium,
            ),
          )
        else
          for (final conversation in conversations)
            InkWell(
              onTap: _working ? null : () => _openConversation(conversation),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Gap.m,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: p.mint,
                  child: Icon(Icons.chat_bubble_outline_rounded, color: p.primary),
                ),
                title: Text(
                  _conversationTitle(conversation),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_date(conversation['created_at'])} · '
                  '${_messageCount(conversation)} mesazhe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Fshi bisedën',
                      onPressed: _working
                          ? null
                          : () => _deleteConversation(conversation),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: p.emergency,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.muted),
                  ],
                ),
              ),
            ),
        if (conversations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.s),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _working ? null : _deleteAllConversations,
                icon: Icon(Icons.delete_sweep_outlined, color: p.emergency),
                label: Text(
                  'Fshi të gjitha bisedat',
                  style: TextStyle(color: p.emergency),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _conversationTitle(Map<String, dynamic> conversation) {
    final messages = conversation['messages'];
    if (messages is List) {
      for (final item in messages) {
        if (item is Map && '${item['role']}' == 'user') {
          final content = '${item['content'] ?? ''}'.trim();
          if (content.isNotEmpty) {
            return content.length > 64
                ? '${content.substring(0, 64)}…'
                : content;
          }
        }
      }
    }
    return 'Bisedë pa titull';
  }

  int _messageCount(Map<String, dynamic> conversation) {
    final messages = conversation['messages'];
    return messages is List ? messages.length : 0;
  }

  String _times(Object? value) {
    if (value is! List || value.isEmpty) return 'Pa orar të ruajtur';
    return 'Oraret: ${value.join(' · ')}';
  }

  String _consentLabel(String kind) => switch (kind) {
    'terms' => 'Kushtet e përdorimit',
    'health_data' => 'Të dhënat shëndetësore',
    'analytics' => 'Analitikë anonime',
    'notifications' => 'Njoftime për kujtesat',
    'history' => 'Historiku i bisedave',
    _ => kind.isEmpty ? 'Pëlqim' : kind,
  };

  String _date(Object? value) {
    final raw = '${value ?? ''}';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    const months = [
      'jan',
      'shk',
      'mar',
      'pri',
      'maj',
      'qer',
      'kor',
      'gus',
      'sht',
      'tet',
      'nën',
      'dhj',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.m, 6, Gap.m, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          const SizedBox(width: Gap.m),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: p.urgent, size: 40),
            const SizedBox(height: Gap.m),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: Gap.m),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Provo')),
          ],
        ),
      ),
    );
  }
}
