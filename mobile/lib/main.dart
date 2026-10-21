import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_session.dart';
import 'core/storage/secure_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/verify_email_page.dart';
import 'features/chat/chat_page.dart';
import 'features/emergency/emergency_page.dart';
import 'features/home/home_page.dart';
import 'features/meds/meds_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/onboarding/splash_page.dart';
import 'features/privacy/privacy_page.dart';

/// Butoni i emergjencës: i arritshëm me një prekje nga ÇDO ekran.
class EmergencyFab extends StatelessWidget {
  const EmergencyFab({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    backgroundColor: ShendetColors.emergency,
    foregroundColor: ShendetColors.onEmergency,
    elevation: 4,
    tooltip: 'Emergjencë, telefono 194',
    onPressed: () => context.push('/emergency'),
    icon: const Icon(Icons.emergency_rounded),
    label: const Text(
      '194',
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    ),
  );
}

/// Shella me shiritin e poshtëm: Ballina · Chat · Ilaçet · Profili.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  int get _index => switch (location) {
    '/chat' => 1,
    '/meds' => 2,
    '/profile' => 3,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    floatingActionButton: const EmergencyFab(),
    bottomNavigationBar: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.palette.line)),
      ),
      child: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => switch (i) {
          1 => context.go('/chat'),
          2 => context.go('/meds'),
          3 => context.go('/profile'),
          _ => context.go('/home'),
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ballina',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Ilaçet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profili',
          ),
        ],
      ),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final logged = session.isAuthenticated;
      final location = state.matchedLocation;
      final isPublic =
          location == '/' ||
          location == '/onboarding' ||
          location == '/register' ||
          location == '/login' ||
          location == '/verify-email' ||
          location == '/emergency';

      // Pa sesion, asnjë ekran i mbrojtur nuk hapet bosh.
      if (!logged && !isPublic) return '/onboarding';
      // Me sesion, ekranet e hyrjes/verifikimit nuk kanë kuptim.
      if (logged &&
          (location == '/onboarding' ||
              location == '/register' ||
              location == '/login' ||
              location == '/verify-email')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingPage()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(
        path: '/verify-email',
        builder: (c, s) {
          final q = s.uri.queryParameters;
          return VerifyEmailPage(
            email: q['email'] ?? '',
            emailSent: q['sent'] != '0',
            initialCooldown: int.tryParse(q['cooldown'] ?? '') ?? 0,
            initialTtlSeconds: int.tryParse(q['ttl'] ?? '') ?? 600,
            from: q['from'] == 'login' ? 'login' : 'register',
          );
        },
      ),
      GoRoute(path: '/emergency', builder: (c, s) => const EmergencyPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            AppShell(location: state.uri.path, child: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (c, s) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/chat', builder: (c, s) => const ChatPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/meds', builder: (c, s) => const MedsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (c, s) => const PrivacyPage()),
            ],
          ),
        ],
      ),
    ],
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SecureStore();
  String? token;
  try {
    token = await store.token();
  } catch (_) {
    token = null;
  }
  final themeMode = await loadStoredThemeMode();

  runApp(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWithValue(
          AuthSession(token != null && token.isNotEmpty),
        ),
        themeModeProvider.overrideWith(() => ThemeModeController(themeMode)),
      ],
      child: const ShendetApp(),
    ),
  );
}

class ShendetApp extends ConsumerWidget {
  const ShendetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Shëndet+',
    debugShowCheckedModeBanner: false,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    themeMode: ref.watch(themeModeProvider),
    routerConfig: ref.watch(routerProvider),
  );
}
