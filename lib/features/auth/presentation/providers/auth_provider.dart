import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _tokenKey = 'gateway_token';
const _urlKey = 'gateway_url';

class AuthState {
  final String? token;
  final String? gatewayUrl;
  final bool isLoading;

  const AuthState({
    this.token,
    this.gatewayUrl,
    this.isLoading = false,
  });

  bool get isAuthenticated => token != null && gatewayUrl != null;

  AuthState copyWith({String? token, String? gatewayUrl, bool? isLoading}) {
    return AuthState(
      token: token ?? this.token,
      gatewayUrl: gatewayUrl ?? this.gatewayUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _loadCredentials();
  }

  Box get _box => Hive.box('settings');

  Future<void> _loadCredentials() async {
    final token = _box.get(_tokenKey) as String?;
    final url = _box.get(_urlKey) as String?;
    state = AuthState(token: token, gatewayUrl: url, isLoading: false);
  }

  Future<void> saveCredentials(String gatewayUrl, String token) async {
    await _box.put(_tokenKey, token);
    await _box.put(_urlKey, gatewayUrl);
    state = AuthState(token: token, gatewayUrl: gatewayUrl);
  }

  Future<void> clearCredentials() async {
    await _box.delete(_tokenKey);
    await _box.delete(_urlKey);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
