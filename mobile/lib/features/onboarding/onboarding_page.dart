import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_mark.dart';

/// Ekrani 1 · Mirëseardhja.
/// Qëllimi: "Vendos pritshmëri të sakta dhe merr pëlqimin."
/// Harta e navigimit: Onboarding (3 ekrane) → Regjistrim + pëlqime.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _page = PageController();
  int _index = 0;

  static final _slides = [
    (
      icon: Icons.favorite_rounded,
      title: 'Shëndeti yt,\ni qartë dhe i sigurt',
      body:
          'Pyet për simptomat, ilaçet dhe kur duhet të kërkosh ndihmë. '
          'Përgjigje të thjeshta, në shqip.',
      chips: ['Triazh i qartë', 'Ilaçet në kohë', 'Kujtesa ditore'],
      color: (ShendetPalette p) => p.primary,
    ),
    (
      icon: Icons.health_and_safety_rounded,
      title: 'Asistent AI,\njo mjek',
      body:
          'Nuk vendos diagnoza dhe nuk të përshkruan terapi. Të orienton '
          'drejt mjekut kur duhet, pa e zëvendësuar kurrë.',
      chips: ['Pa diagnoza', 'Pa receta', 'Ambulanca 194'],
      color: (ShendetPalette p) => p.urgent,
    ),
    (
      icon: Icons.lock_rounded,
      title: 'Të dhënat tuaja,\nnën kontrollin tënd',
      body:
          'Pëlqime të veçanta, enkriptim dhe kontroll i plotë. Mund t’i '
          'eksportosh ose t’i fshish kur të duash.',
      chips: ['Enkriptim', 'Pëlqim i veçantë', 'Ti vendos'],
      color: (ShendetPalette p) => p.soon,
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/register');
    }
  }

  void _back() {
    if (_index > 0) {
      _page.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, 0),
                  child: Row(
                    children: [
                      if (_index > 0)
                        IconButton(
                          onPressed: _back,
                          tooltip: 'Kthehu',
                          icon: const Icon(Icons.arrow_back_rounded),
                        )
                      else
                        const SizedBox(width: kTouchTarget),
                      const BrandMark(size: 36),
                      const SizedBox(width: Gap.s),
                      const BrandName(fontSize: 19),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Hyr'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final p = context.palette;
                      final slide = _slides[i];
                      final color = slide.color(p);
                      final text = Theme.of(context).textTheme;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.l,
                          Gap.m,
                          Gap.l,
                          Gap.m,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Illustration(icon: slide.icon, color: color),
                            const SizedBox(height: Gap.xl),
                            Text(slide.title, style: text.displaySmall),
                            const SizedBox(height: Gap.m),
                            Text(
                              slide.body,
                              style: text.bodyLarge?.copyWith(
                                color: p.muted,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: Gap.l),
                            Wrap(
                              spacing: Gap.s,
                              runSpacing: Gap.s,
                              children: [
                                for (final chip in slide.chips)
                                  _Pill(label: chip, color: color),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.l,
                    Gap.s,
                    Gap.l,
                    Gap.l,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _slides.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(
                                horizontal: Gap.xs,
                              ),
                              width: i == _index ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _index
                                    ? context.palette.primary
                                    : context.palette.line,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: Gap.m),
                      if (isLast) ...[
                        FilledButton(
                          onPressed: () => context.go('/register'),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Krijo llogari falas'),
                              SizedBox(width: Gap.s),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: Gap.s),
                        OutlinedButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Kam tashmë llogari — Hyr'),
                        ),
                      ] else
                        FilledButton(
                          onPressed: _next,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Vazhdo'),
                              SizedBox(width: Gap.s),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      const SizedBox(height: Gap.s),
                      Text(
                        'Asistent AI, jo mjek · Në rast emergjence, telefono 194',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
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

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 230,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.03)],
      ),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: color.withValues(alpha: 0.12)),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.palette.primaryLight.withValues(alpha: 0.06),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              gradient: ShendetGradients.primary,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: ShendetColors.primary.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 52),
          ),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    ),
  );
}
