import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  static const _storage = FlutterSecureStorage();

  Future<void> _loadCredentials() async {
    final token = await _storage.read(key: _tokenKey);
    final url = await _storage.read(key: _urlKey);
    state = AuthState(token: token, gatewayUrl: url, isLoading: false);
  }

  Future<void> saveCredentials(String gatewayUrl, String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _urlKey, value: gatewayUrl);
    state = AuthState(token: token, gatewayUrl: gatewayUrl);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _urlKey);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
