import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/pages/token_entry_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/profile/presentation/pages/onboarding_page.dart';
import '../features/profile/presentation/providers/user_profile_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final profileNotifier = ref.watch(userProfileProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final hasProfile = ref.read(userProfileProvider.notifier).hasProfile;

      if (authState.isLoading) return null;

      // No profile yet → onboarding
      if (!hasProfile && state.matchedLocation != '/setup') {
        return '/setup';
      }

      // Profile exists, not authenticated, not on /auth → /auth
      final isAuth = state.matchedLocation == '/auth';
      if (!authState.isAuthenticated && !isAuth) return '/auth';

      // Authenticated and on /auth or /setup → /
      if (authState.isAuthenticated && (isAuth || state.matchedLocation == '/setup')) {
        return '/';
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(authNotifier)..add(profileNotifier),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ChatPage()),
      GoRoute(path: '/auth', builder: (context, state) => const TokenEntryPage()),
      GoRoute(path: '/setup', builder: (context, state) => const OnboardingPage()),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(StateNotifier notifier) {
    notifier.addListener((_) => notifyListeners());
  }

  void add(StateNotifier notifier) {
    notifier.addListener((_) => notifyListeners());
  }
}
