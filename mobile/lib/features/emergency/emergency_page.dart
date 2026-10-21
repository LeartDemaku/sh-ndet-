import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

/// Ekrani 4 · Emergjenca.
/// "Ekran i plotë i kuq, buton telefonimi me një prekje, pa tekst të gjatë."
class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  static const _ambulance = '194';
  static const _police = '192';
  static const _fire = '193';

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    // Nëse pajisja nuk ka aftësi telefonimi (p.sh. tablet), numri mbetet i dukshëm në tekst.
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kjo pajisje nuk mund të telefonojë. Numri: $number'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: ShendetColors.emergency,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.emergency,
                color: ShendetColors.onEmergency,
                size: 56,
              ),
              const SizedBox(height: Gap.m),
              Text(
                'Telefono $_ambulance tani',
                textAlign: TextAlign.center,
                style: text.headlineMedium?.copyWith(
                  color: ShendetColors.onEmergency,
                ),
              ),
              const SizedBox(height: Gap.m),
              Text(
                'Për emergjencë mjekësore, telefono ambulancën.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: ShendetColors.onEmergency,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Telefono ambulancën $_ambulance',
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ShendetColors.onEmergency,
                    foregroundColor: ShendetColors.emergency,
                    minimumSize: const Size.fromHeight(kTouchTarget + 8),
                  ),
                  onPressed: () => _call(context, _ambulance),
                  icon: const Icon(Icons.phone),
                  label: Text('Telefono $_ambulance'),
                ),
              ),
              const SizedBox(height: Gap.s),
              Text(
                'Policia: $_police · Zjarrfikësit: $_fire',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: ShendetColors.onEmergency.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Gap.m),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ShendetColors.onEmergency,
                  minimumSize: const Size.fromHeight(kTouchTarget),
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Hyrje direkte me link: kthehu te platforma, jo në një ekran bosh.
                    context.go('/home');
                  }
                },
                child: const Text('Kthehu'),
              ),
              const SizedBox(height: Gap.s),
              Text(
                'Mos prit përgjigje nga aplikacioni.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: ShendetColors.onEmergency,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
