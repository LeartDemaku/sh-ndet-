import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/me_api.dart';
import '../../core/api/providers.dart';
import '../../core/auth/auth_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_mark.dart';

/// Splash: kontrollon sesionin dhe zgjedh rrjedhën.
/// Harta e navigimit (Pjesa 4): Splash → Onboarding → Regjistrim → Ballina.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final session = ref.read(authSessionProvider);
    if (!session.isAuthenticated) {
      context.go('/onboarding');
      return;
    }

    // Token ekziston: verifikohet me serverin. Nëse ka skaduar, kalohet te hyrja.
    try {
      await ref.read(meApiProvider).fetchMe();
      if (mounted) context.go('/home');
    } on MeApiException catch (e) {
      if (e.statusCode == 401) {
        await ref.read(secureStoreProvider).clear();
        session.setAuthenticated(false);
        if (mounted) context.go('/login');
      } else if (mounted) {
        context.go('/home');
      }
    } catch (_) {
      // Pa internet: vazhdohet te Ballina me gjendjen offline.
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ShendetGradients.hero),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _Glow(size: 240, opacity: 0.08),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _Glow(size: 280, opacity: 0.07),
            ),
            SafeArea(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(size: 86, onDark: true),
                      const SizedBox(height: Gap.l),
                      const BrandName(onDark: true, fontSize: 34),
                      const SizedBox(height: Gap.s),
                      Text(
                        'Shëndeti yt, i qartë dhe i sigurt',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: Gap.xl),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Text(
                'Asistent AI, jo mjek · Në rast emergjence, telefono 194',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.55)),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
