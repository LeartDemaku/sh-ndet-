import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/me_api.dart';
import '../../core/api/providers.dart';
import '../../core/auth/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_scaffold.dart';

/// Hapi i dytë i regjistrimit: verifikimi i emailit me kod 6-shifror.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({
    super.key,
    required this.email,
    this.emailSent = true,
    this.initialCooldown = 0,
    this.initialTtlSeconds = 600,
    this.from = 'register',
  });

  final String email;
  final bool emailSent;
  final int initialCooldown;
  final int initialTtlSeconds;
  final String from; // register | login

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _code = TextEditingController();
  Timer? _timer;
  bool _busy = false;
  bool _resending = false;
  bool _emailSent = true;
  int _cooldown = 0;
  int _ttlSeconds = 600;
  String? _error;
  String? _info;

  String get _backTo => widget.from == 'login' ? '/login' : '/register';

  @override
  void initState() {
    super.initState();
    _emailSent = widget.emailSent;
    _ttlSeconds = widget.initialTtlSeconds;
    _beginCooldown(widget.initialCooldown);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _beginCooldown(int seconds) {
    _timer?.cancel();
    _cooldown = seconds;
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _cooldown = (_cooldown - 1).clamp(0, 3600).toInt();
      });
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Shkruaj kodin 6-shifror që more me email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final token = await ref
          .read(meApiProvider)
          .verifyEmail(email: widget.email, code: code);
      await ref.read(secureStoreProvider).saveToken(token);
      ref.read(authSessionProvider).setAuthenticated(true);
      if (!mounted) return;
      context.go('/home');
    } on MeApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Nuk u lidhëm. Provo përsëri pas pak.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      final result = await ref
          .read(meApiProvider)
          .resendVerification(email: widget.email);
      if (!mounted) return;
      setState(() {
        _emailSent = result.emailSent;
        _ttlSeconds = result.expiresIn;
        _info =
            result.message ??
            (result.emailSent
                ? 'Kodi i ri u dërgua. Kontrollo emailin.'
                : 'Kodi u krijua, por emaili nuk u dërgua. Provo përsëri.');
      });
      _beginCooldown(result.resendAfter);
    } on MeApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.userMessage);
      if (e.statusCode == 429 && _cooldown <= 0) _beginCooldown(60);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Nuk u lidhëm. Provo përsëri pas pak.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final minutes = (_ttlSeconds / 60).round().clamp(1, 60);
    final minutesText = minutes == 1 ? '1 minutë' : '$minutes minuta';

    return AuthScaffold(
      title: 'Verifiko emailin',
      subtitle: widget.email.isEmpty
          ? 'Shkruaj kodin 6-shifror që more me email.'
          : 'Dërguam një kod 6-shifror në ${widget.email}.',
      backTo: _backTo,
      child: widget.email.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Notice(
                  icon: Icons.error_outline_rounded,
                  message: 'Mungon emaili. Kthehu dhe plotëso regjistrimin.',
                  color: p.emergency,
                  background: p.emergencySurface,
                ),
                const SizedBox(height: Gap.m),
                OutlinedButton(
                  onPressed: () => context.go(_backTo),
                  child: const Text('Kthehu te regjistrimi'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_emailSent) ...[
                  _Notice(
                    icon: Icons.mark_email_unread_outlined,
                    message:
                        'Emaili nuk u dërgua automatikisht. '
                        'Kontrollo lidhjen dhe shtyp “Dërgo kodin përsëri”.',
                    color: p.urgent,
                    background: p.warningSurface,
                  ),
                  const SizedBox(height: Gap.m),
                ],
                if (_error != null) ...[
                  _Notice(
                    icon: Icons.error_outline_rounded,
                    message: _error!,
                    color: p.emergency,
                    background: p.emergencySurface,
                  ),
                  const SizedBox(height: Gap.m),
                ],
                if (_info != null) ...[
                  _Notice(
                    icon: Icons.mark_email_read_outlined,
                    message: _info!,
                    color: p.selfCare,
                    background: p.successSurface,
                  ),
                  const SizedBox(height: Gap.m),
                ],
                Text('Kodi 6-shifror', style: text.labelLarge),
                const SizedBox(height: Gap.s),
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: TextStyle(
                    fontSize: 28,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    prefixIcon: Icon(Icons.password_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (!_busy && _code.text.trim().length == 6) _verify();
                  },
                ),
                const SizedBox(height: Gap.s),
                Text(
                  'Kodi vlen $minutesText. Nëse nuk e shikon në Inbox, '
                  'kontrollo edhe dosjen Spam.',
                  style: text.labelSmall,
                ),
                const SizedBox(height: Gap.l),
                FilledButton(
                  onPressed: (_busy || _code.text.trim().length != 6)
                      ? null
                      : _verify,
                  child: _busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Verifiko dhe hyr'),
                            SizedBox(width: Gap.s),
                            Icon(Icons.verified_rounded, size: 20),
                          ],
                        ),
                ),
                const SizedBox(height: Gap.m),
                OutlinedButton.icon(
                  onPressed: (_resending || _cooldown > 0) ? null : _resend,
                  icon: _resending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    _cooldown > 0
                        ? 'Dërgo përsëri (${_cooldown}s)'
                        : 'Dërgo kodin përsëri',
                  ),
                ),
                const SizedBox(height: Gap.s),
                TextButton(
                  onPressed: _busy ? null : () => context.go(_backTo),
                  child: const Text('Ndrysho emailin'),
                ),
                const SizedBox(height: Gap.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 15, color: p.muted),
                    const SizedBox(width: Gap.xs),
                    Flexible(
                      child: Text(
                        'Kodi ruhet vetëm si hash dhe skadon automatikisht.',
                        style: text.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    label: message,
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.all(Gap.m),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    ),
  );
}
