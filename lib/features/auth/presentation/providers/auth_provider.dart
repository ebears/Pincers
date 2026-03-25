import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static bool get _useSecureStorage => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static const _storage = FlutterSecureStorage();

  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    String? token;
    String? url;
    if (_useSecureStorage) {
      token = await _storage.read(key: _tokenKey);
      url = await _storage.read(key: _urlKey);
    } else {
      final box = Hive.box('settings');
      token = box.get(_tokenKey) as String?;
      url = box.get(_urlKey) as String?;
    }
    state = AuthState(token: token, gatewayUrl: url, isLoading: false);
  }

  Future<void> saveCredentials(String gatewayUrl, String token) async {
    if (_useSecureStorage) {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _urlKey, value: gatewayUrl);
    } else {
      final box = Hive.box('settings');
      await box.put(_tokenKey, token);
      await box.put(_urlKey, gatewayUrl);
    }
    state = AuthState(token: token, gatewayUrl: gatewayUrl);
  }

  Future<void> clearCredentials() async {
    if (_useSecureStorage) {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _urlKey);
    } else {
      final box = Hive.box('settings');
      await box.delete(_tokenKey);
      await box.delete(_urlKey);
    }
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
