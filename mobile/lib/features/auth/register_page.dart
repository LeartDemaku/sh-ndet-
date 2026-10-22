import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/me_api.dart';
import '../../core/api/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_scaffold.dart';

/// Regjistrimi me pëlqime TË VEÇANTA për kushtet dhe për të dhënat shëndetësore.
/// (Udhëzimi: pëlqimi për të dhëna shëndetësore nuk kombinohet me pranimin e kushteve.)
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _terms = false;
  bool _health = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateFirstName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Shkruaj emrin.';
    if (name.length > 80) return 'Emri është shumë i gjatë.';
    return null;
  }

  String? _validateLastName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Shkruaj mbiemrin.';
    if (name.length > 80) return 'Mbiemri është shumë i gjatë.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Shkruaj emailin.';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Email i pasaktë.';
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Shkruaj fjalëkalimin.';
    if (password.length < 10) {
      return 'Fjalëkalimi duhet të ketë të paktën 10 shenja.';
    }
    if (password.length > 128) return 'Fjalëkalimi është shumë i gjatë.';
    return null;
  }

  String? _validateConfirmation(String? value) {
    final confirmation = value ?? '';
    if (confirmation.isEmpty) return 'Konfirmo fjalëkalimin.';
    if (confirmation != _password.text) return 'Fjalëkalimet nuk përputhen.';
    return null;
  }

  int get _strength {
    final v = _password.text;
    var score = 0;
    if (v.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'\d').hasMatch(v)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) score++;
    return score;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_terms || !_health) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(meApiProvider)
          .register(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            acceptTerms: _terms,
            acceptHealthData: _health,
          );
      if (!mounted) return;
      // Regjistrimi vazhdon me verifikimin e emailit (faktor i dytë).
      final email = Uri.encodeComponent(result.email);
      context.go(
        '/verify-email?email=$email'
        '&sent=${result.emailSent ? 1 : 0}'
        '&cooldown=${result.resendAfter}'
        '&ttl=${result.expiresIn}',
      );
    } on MeApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.userMessage);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Nuk u realizua regjistrimi. Provo përsëri pas pak.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AuthScaffold(
      title: 'Krijo llogarinë tënde',
      subtitle: 'Në 30 sekonda. Falas. Ti vendos për të dhënat tuaja.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              _FormError(message: _error!),
              const SizedBox(height: Gap.m),
            ],
            Text('Emri', style: text.labelLarge),
            const SizedBox(height: Gap.s),
            TextFormField(
              key: const Key('register-first-name'),
              controller: _firstName,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              decoration: const InputDecoration(
                hintText: 'Emri yt',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _validateFirstName,
            ),
            const SizedBox(height: Gap.m),
            Text('Mbiemri', style: text.labelLarge),
            const SizedBox(height: Gap.s),
            TextFormField(
              key: const Key('register-last-name'),
              controller: _lastName,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              decoration: const InputDecoration(
                hintText: 'Mbiemri yt',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: _validateLastName,
            ),
            const SizedBox(height: Gap.m),
            Text('Email', style: text.labelLarge),
            const SizedBox(height: Gap.s),
            TextFormField(
              key: const Key('register-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'emri@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: Gap.m),
            Text('Fjalëkalimi', style: text.labelLarge),
            const SizedBox(height: Gap.s),
            TextFormField(
              key: const Key('register-password'),
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Të paktën 10 shenja',
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
              validator: _validatePassword,
            ),
            const SizedBox(height: Gap.s),
            _PasswordStrength(
              score: _strength,
              hasValue: _password.text.isNotEmpty,
            ),
            const SizedBox(height: Gap.m),
            Text('Konfirmimi i fjalëkalimit', style: text.labelLarge),
            const SizedBox(height: Gap.s),
            TextFormField(
              key: const Key('register-confirm-password'),
              controller: _confirm,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                hintText: 'Përsërit fjalëkalimin',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
              validator: _validateConfirmation,
            ),
            const SizedBox(height: Gap.l),
            Text('Pëlqimet', style: text.labelLarge),
            const SizedBox(height: Gap.s),
            _ConsentCard(
              value: _terms,
              title: 'Pranoj kushtet e përdorimit',
              subtitle: 'Kushtet për përdorimin e Shëndet+.',
              icon: Icons.article_outlined,
              onChanged: (v) => setState(() => _terms = v),
            ),
            const SizedBox(height: Gap.s),
            _ConsentCard(
              value: _health,
              title: 'Pranoj përpunimin e të dhënave shëndetësore',
              subtitle: 'Pëlqim i veçantë. Mund ta tërheqësh kur të duash te Profili.',
              icon: Icons.health_and_safety_outlined,
              highlight: true,
              onChanged: (v) => setState(() => _health = v),
            ),
            const SizedBox(height: Gap.l),
            FilledButton(
              onPressed: (!_terms || !_health || _busy) ? null : _submit,
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
                        Text('Krijo llogarinë'),
                        SizedBox(width: Gap.s),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
            if (!_terms || !_health) ...[
              const SizedBox(height: Gap.s),
              Text(
                'Për të vazhduar, prano të dyja pëlqimet veç e veç.',
                style: text.labelSmall,
                textAlign: TextAlign.center,
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
              onPressed: _busy ? null : () => context.go('/login'),
              child: const Text('Kam tashmë llogari'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.score, required this.hasValue});

  final int score;
  final bool hasValue;

  @override
  Widget build(BuildContext context) {
    if (!hasValue) {
      return Text(
        'Përdor të paktën 10 shenja, me shkronja dhe numra.',
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
    final p = context.palette;
    final (label, color) = switch (score) {
      >= 4 => ('Fjalëkalim i fortë', p.selfCare),
      >= 3 => ('Fjalëkalim i mirë', p.amber),
      >= 2 => ('Fjalëkalim i dobët', p.urgent),
      _ => ('Fjalëkalim shumë i dobët', p.emergency),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < score ? color : p.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: Gap.xs),
            ],
          ],
        ),
        const SizedBox(height: Gap.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
    this.highlight = false,
  });

  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool> onChanged;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: value && highlight ? p.surfaceAlt : p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? p.primary : p.line,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: CheckboxListTile(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: p.primary,
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          secondary: Icon(icon, color: p.primary),
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
