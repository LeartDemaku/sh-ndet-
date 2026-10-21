import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/me_api.dart';
import '../../core/api/providers.dart';
import '../../core/auth/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_scaffold.dart';

/// Hyrje për përdoruesit që kanë llogari.
/// Hapi 5 i udhëzimit: identiteti — regjistrim, hyrje, JWT.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _needsVerification = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
      _needsVerification = false;
    });
    try {
      final token = await ref
          .read(meApiProvider)
          .login(email: _email.text.trim(), password: _password.text);
      await ref.read(secureStoreProvider).saveToken(token);
      ref.read(authSessionProvider).setAuthenticated(true);
      if (!mounted) return;
      context.go('/home');
    } on MeApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403) {
        setState(() {
          _error = e.userMessage;
          _needsVerification = true;
        });
      } else {
        setState(
          () => _error = e.statusCode == 401
              ? 'Email ose fjalëkalim i pasaktë. Provo përsëri.'
              : e.userMessage,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Nuk u lidhëm. Provo përsëri pas pak.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AuthScaffold(
      title: 'Hyr në llogarinë tënde',
      subtitle: 'Mirë se u ktheve. Vazhdo aty ku e le.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              _FormError(message: _error!),
              const SizedBox(height: Gap.m),
            ],
            Text('Email', style: text.labelLarge),
            const SizedBox(height: Gap.s),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'emri@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@') || !v.contains('.'))
                  ? 'Email i pasaktë.'
                  : null,
            ),
            const SizedBox(height: Gap.m),
            Text('Fjalëkalimi', style: text.labelLarge),
            const SizedBox(height: Gap.s),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                hintText: 'Shkruaj fjalëkalimin',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? 'Shfaq fjalëkalimin'
                      : 'Fshih fjalëkalimin',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Shkruaj fjalëkalimin.' : null,
              onFieldSubmitted: (_) => _busy ? null : _submit(),
            ),
            const SizedBox(height: Gap.l),
            FilledButton(
              onPressed: _busy ? null : _submit,
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
                        Text('Hyr'),
                        SizedBox(width: Gap.s),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
            if (_needsVerification) ...[
              const SizedBox(height: Gap.s),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () {
                        final email = Uri.encodeComponent(_email.text.trim());
                        context.go(
                          '/verify-email?email=$email&sent=0&cooldown=0'
                          '&ttl=600&from=login',
                        );
                      },
                icon: const Icon(Icons.mark_email_unread_outlined, size: 20),
                label: const Text('Verifiko emailin ose dërgo kodin përsëri'),
              ),
            ],
            const SizedBox(height: Gap.m),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.m),
                  child: Text('ose', style: text.bodyMedium),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: Gap.m),
            OutlinedButton(
              onPressed: _busy ? null : () => context.go('/register'),
              child: const Text('Krijo llogari të re'),
            ),
            const SizedBox(height: Gap.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: context.palette.muted,
                ),
                const SizedBox(width: Gap.xs),
                Flexible(
                  child: Text(
                    'Lidhje e sigurt · Të dhënat tuaja mbeten të mbrojtura',
                    style: text.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      label: 'Gabim. $message',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Gap.m),
        decoration: BoxDecoration(
          color: p.emergencySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.emergencyBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: p.emergency, size: 20),
            const SizedBox(width: Gap.s),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: p.emergency),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
