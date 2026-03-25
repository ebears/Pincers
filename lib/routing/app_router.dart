import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/pages/token_entry_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;
      final isAuth = state.matchedLocation == '/auth';
      if (!authState.isAuthenticated && !isAuth) return '/auth';
      if (authState.isAuthenticated && isAuth) return '/';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authNotifier),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ChatPage()),
      GoRoute(path: '/auth', builder: (context, state) => const TokenEntryPage()),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(StateNotifier notifier) {
    notifier.addListener((_) => notifyListeners());
  }
}
