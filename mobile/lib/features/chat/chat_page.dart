import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/emergency_action.dart';
import 'chat_controller.dart';
import 'triage_card.dart';

/// Ekrani 3 · Chat.
/// "Bisedë me karta triazhi, burime dhe disclaimer të vazhdueshëm."
///
/// Gjendjet që duhen dizajnuar (udhëzimi): streaming, gabim, bllokim,
/// emergjencë, offline, kufi kërkesash (429).
final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Fokusi lëviz te përgjigja e re pas streaming-ut (lista e kontrollit).
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    ref.read(chatControllerProvider.notifier).send(text);
    _input.clear();
  }

  void _sendPrompt(String text) {
    ref.read(chatControllerProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final text = Theme.of(context).textTheme;

    // Numri i mesazheve: kur shtohet një i ri, lëviz poshtë.
    ref.listen<int>(chatControllerProvider.select((s) => s.messages.length), (
      previous,
      next,
    ) {
      if (next > (previous ?? 0)) _scrollToEnd();
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        titleSpacing: Gap.m,
        title: Row(
          children: [
            const BrandMark(size: 34),
            const SizedBox(width: Gap.s),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat', style: text.titleMedium),
                Text('Shëndet+ · Asistent AI', style: text.labelSmall),
              ],
            ),
          ],
        ),
        actions: const [EmergencyAction()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              if (state.offline) const _OfflineBanner(),
              if (state.reachedLimit) const _LimitBanner(),
              Expanded(
                child: state.messages.isEmpty
                    ? _EmptyState(onPrompt: _sendPrompt)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          Gap.m,
                          Gap.s,
                          Gap.m,
                          Gap.m,
                        ),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) =>
                            _Bubble(message: state.messages[i]),
                      ),
              ),
              if (state.errorMessage != null && state.messages.isNotEmpty)
                _ErrorBanner(
                  message: state.errorMessage!,
                  onLogin: state.unauthorized
                      ? () => context.go('/login')
                      : null,
                ),
              _Composer(
                controller: _input,
                enabled: !state.isStreaming,
                onSend: _send,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.m, Gap.xs, Gap.m, Gap.s),
                child: Text(
                  'Informacion i përgjithshëm. Nuk zëvendëson mjekun.',
                  style: text.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final isUser = message.role == 'user';

    final content = Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (message.emergency != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.s),
            child: _EmergencyCard(message: message.emergency!),
          ),
        if (message.text.isNotEmpty)
          Semantics(
            container: true,
            label: '${isUser ? 'Ti' : 'Shëndet+'}: ${message.text}',
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.m,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser ? p.primary : p.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: p.line),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: p.shadow,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                message.text,
                style: text.bodyLarge?.copyWith(
                  color: isUser ? p.onPrimary : p.ink,
                ),
              ),
            ),
          ),
        if (message.triage != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.s),
            child: TriageCard.fromData(message.triage!),
          ),
        if (message.blocked)
          Padding(
            padding: const EdgeInsets.only(top: Gap.s),
            child: const Wrap(
              spacing: Gap.s,
              runSpacing: Gap.s,
              children: [
                _Chip(label: 'Si ta mbaj të shëndetshme trupin?'),
                _Chip(label: 'Si të organizoj ilaçet?'),
              ],
            ),
          ),
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(top: Gap.s),
            child: Wrap(
              spacing: Gap.s,
              runSpacing: Gap.s,
              children: [
                if (message.sources.isNotEmpty)
                  _Chip(label: 'Burime · ${message.sources.length}'),
                const _Chip(label: 'Raporto'),
              ],
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const BrandMark(size: 30),
            const SizedBox(width: Gap.s),
          ],
          Flexible(child: content),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Emergjencë. $message',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Gap.m),
        decoration: BoxDecoration(
          color: p.emergencySurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.emergency, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency_rounded, color: p.emergency),
                const SizedBox(width: Gap.s),
                Text(
                  'EMERGJENCË',
                  style: TextStyle(
                    color: p.emergency,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.s),
            Text(message, style: text.bodyMedium?.copyWith(color: p.ink)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: ActionChip(
      onPressed: () {},
      label: Text(label),
      side: BorderSide(color: context.palette.line),
      backgroundColor: context.palette.surface,
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.m),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Gap.s, 2, 6, 2),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(24),
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
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Shkruaj një mesazh…',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Gap.s,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Gap.xs),
            Semantics(
              button: true,
              label: 'Dërgo mesazhin',
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: enabled ? ShendetGradients.primary : null,
                  color: enabled ? null : p.line,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: enabled ? onSend : null,
                  tooltip: 'Dërgo',
                  icon: const Icon(Icons.arrow_upward_rounded),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPrompt});
  final ValueChanged<String> onPrompt;

  static const _prompts = [
    'Kam dhimbje koke prej dy ditësh',
    'Si t’i marr ilaçet në kohë?',
    'Kur duhet të shkoj te mjeku?',
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: ShendetGradients.primary,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: ShendetColors.primary.withValues(alpha: 0.22),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: Gap.l),
            Text(
              'Si mund të ndihmoj sot?',
              style: text.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.s),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Trego çfarë po ndjen. Të ndihmoj ta kuptosh dhe të vendosësh hapat e radhës.\n'
                'Nuk jam mjek dhe nuk zëvendësoj mjekun.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Gap.l),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  for (final prompt in _prompts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.s),
                      child: _PromptButton(
                        label: prompt,
                        onTap: () => onPrompt(prompt),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptButton extends StatelessWidget {
  const _PromptButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.line),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: p.primary, size: 18),
              const SizedBox(width: Gap.s),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: p.ink),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: p.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onLogin});
  final String message;
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.xs),
        padding: const EdgeInsets.all(Gap.m),
        decoration: BoxDecoration(
          color: p.warningSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.warningBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: p.urgent),
            const SizedBox(width: Gap.s),
            Expanded(
              child: Semantics(
                label: 'Gabim. $message',
                excludeSemantics: true,
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            if (onLogin != null)
              TextButton(
                onPressed: onLogin,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Hyr'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LimitBanner extends StatelessWidget {
  const _LimitBanner();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: p.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Shumë kërkesa për momentin. Provo përsëri pas një minute.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.ink),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
        padding: const EdgeInsets.all(Gap.m),
        decoration: BoxDecoration(
          color: p.infoSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.infoBorder),
        ),
        child: Text(
          'Je offline. Mesazhet dërgohen më vonë. Bisedat e fundit mbeten të lexueshme.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.ink),
        ),
      ),
    );
  }
}
