import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'brand_mark.dart';

/// Korniza e përbashkët për regjistrim dhe hyrje.
///
/// Në telefon: krye me gradient + kartë e bardhë me formularin.
/// Në desktop: panel marke majtas + formular i qendërzuar djathtas.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.backTo = '/onboarding',
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String backTo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            body: Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: p.background,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(Gap.xl),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BackToStart(onDark: false, backTo: backTo),
                                const SizedBox(height: Gap.l),
                                Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall,
                                ),
                                const SizedBox(height: Gap.s),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: p.muted),
                                ),
                                const SizedBox(height: Gap.l),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 330,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: ShendetGradients.hero,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -70,
                        right: -50,
                        child: _Glow(size: 220, opacity: 0.13),
                      ),
                      Positioned(
                        bottom: -90,
                        left: -60,
                        child: _Glow(size: 200, opacity: 0.10),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.m,
                    Gap.s,
                    Gap.m,
                    Gap.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(backTo: backTo),
                      const SizedBox(height: Gap.xl),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(color: Colors.white, fontSize: 30),
                            ),
                            const SizedBox(height: Gap.s),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Gap.l),
                      Container(
                        padding: const EdgeInsets.all(Gap.l),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: p.line),
                          boxShadow: [
                            BoxShadow(
                              color: p.shadow,
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      const SizedBox(height: Gap.m),
                      Center(
                        child: Text(
                          'Asistent AI, jo mjek · Të dhënat tuaja të enkriptuara',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: p.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.backTo});
  final String backTo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Gap.s),
    child: Row(
      children: [
        IconButton(
          onPressed: () => context.go(backTo),
          tooltip: 'Kthehu',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: Gap.s),
        const BrandMark(size: 34, onDark: true),
        const SizedBox(width: Gap.s),
        const BrandName(onDark: true, fontSize: 18),
      ],
    ),
  );
}

class _BackToStart extends StatelessWidget {
  const _BackToStart({required this.onDark, required this.backTo});
  final bool onDark;
  final String backTo;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.go(backTo),
    icon: const Icon(Icons.arrow_back_rounded, size: 18),
    label: const Text('Kthehu'),
    style: TextButton.styleFrom(
      foregroundColor: onDark ? Colors.white : context.palette.muted,
      padding: EdgeInsets.zero,
      minimumSize: const Size(kTouchTarget, kTouchTarget),
      alignment: Alignment.centerLeft,
    ),
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(gradient: ShendetGradients.hero),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _Glow(size: 260, opacity: 0.12),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _Glow(size: 300, opacity: 0.10),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Gap.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      BrandMark(size: 46, onDark: true),
                      SizedBox(width: Gap.m),
                      BrandName(onDark: true, fontSize: 24),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Shëndeti yt,\ni qartë dhe i sigurt.',
                    style: text.displaySmall?.copyWith(
                      color: Colors.white,
                      height: 1.15,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: Gap.m),
                  Text(
                    'Shëndet+ të ndihmon të kuptosh simptomat, të kujtosh ilaçet '
                    'dhe të dish kur të kërkosh ndihmë.',
                    style: text.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  const _Feature(
                    icon: Icons.health_and_safety_outlined,
                    label: 'Triazh i qartë, me kufij të sigurt',
                  ),
                  const _Feature(
                    icon: Icons.medication_outlined,
                    label: 'Kujtesa për ilaçet tuaja',
                  ),
                  const _Feature(
                    icon: Icons.lock_outline_rounded,
                    label: 'Të dhënat tuaja të enkriptuara',
                  ),
                  const Spacer(),
                  Text(
                    'Asistent AI, jo mjek. Në rast emergjence, telefono 194.',
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.m),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: Gap.m),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}
