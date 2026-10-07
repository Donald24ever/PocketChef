import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_extensions.dart';

import '../features/auth/welcome_screen.dart';
import '../features/cooking/cooking_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/legal/credits_screen.dart';
import '../features/nigerian/nigerian_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/privacy_screen.dart';
import '../features/recipes/recipe_detail_screen.dart';
import '../features/recipes/recipes_screen.dart';
import '../features/recipes/search_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/scan/ingredients_review_screen.dart';
import '../features/scan/scanner_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import '../state/app_state_provider.dart';

CustomTransitionPage<void> _slideUp(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _slideIn(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _zoomIn(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    fullscreenDialog: false,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _subscription = _ref.listen(sessionProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription<SessionState> _subscription;

  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    if (location == '/splash') return null;

    final session = _ref.read(sessionProvider);
    if (!session.ready) return '/splash';

    if (!session.onboarded) {
      return location == '/onboarding' ? null : '/onboarding';
    }
    if (!session.authed) {
      return location == '/welcome' ? null : '/welcome';
    }
    if (location == '/onboarding' || location == '/welcome') {
      return '/home';
    }
    return null;
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recipes',
                builder: (context, state) => RecipesScreen(
                  source: state.uri.queryParameters['source'] ?? '',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (context, state) => const PlanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/scan',
        pageBuilder: (context, state) => _slideUp(
          context,
          state,
          ScannerScreen(keepPrevious: state.extra == 'keep'),
        ),
      ),
      GoRoute(
        path: '/scan/review',
        pageBuilder: (context, state) =>
            _slideUp(context, state, const IngredientsReviewScreen()),
      ),
      GoRoute(
        path: '/recipe/:id',
        pageBuilder: (context, state) => _slideIn(
          context,
          state,
          RecipeDetailScreen(recipeId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/cook/:id',
        pageBuilder: (context, state) => _zoomIn(
          context,
          state,
          CookingScreen(recipeId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/saved',
        pageBuilder: (context, state) =>
            _slideIn(context, state, const SavedScreen()),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) =>
            _slideUp(context, state, const SearchScreen()),
      ),
      GoRoute(
        path: '/nigerian',
        pageBuilder: (context, state) => _slideIn(
          context,
          state,
          NigerianScreen(
            initialRegion: state.uri.queryParameters['region'],
          ),
        ),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) =>
            _slideIn(context, state, const PrivacyScreen()),
      ),
      GoRoute(
        path: '/legal/privacy',
        pageBuilder: (context, state) =>
            _slideIn(context, state, const LegalScreen(doc: LegalDoc.privacy)),
      ),
      GoRoute(
        path: '/legal/terms',
        pageBuilder: (context, state) =>
            _slideIn(context, state, const LegalScreen(doc: LegalDoc.terms)),
      ),
      GoRoute(
        path: '/legal/credits',
        pageBuilder: (context, state) =>
            _slideIn(context, state, const CreditsScreen()),
      ),
    ],
    errorBuilder: (context, state) => _NotFoundScreen(
      location: state.uri.toString(),
    ),
  );
});

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_off_outlined, size: 44, color: c.inkTertiary),
                const SizedBox(height: 16),
                Text('Page not found', style: context.serif(24)),
                const SizedBox(height: 8),
                Text(
                  'We could not find $location.',
                  textAlign: TextAlign.center,
                  style: context.ui(14.5, color: c.inkSecondary),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
