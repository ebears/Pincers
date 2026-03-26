import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../shared/services/websocket_channel_factory.dart';

const _tokenKey = 'gateway_token';
const _urlKey = 'gateway_url';
const _trustKey = 'trust_self_signed';

enum AuthFailureReason { timeout, networkError, authRejected, sslError, generic }

class AuthException implements Exception {
  final AuthFailureReason reason;

  /// Raw exception text from the underlying error, shown alongside the
  /// friendly message so users can diagnose unexpected failures.
  final String? detail;

  const AuthException(this.reason, {this.detail});

  @override
  String toString() => 'AuthException($reason${detail != null ? ': $detail' : ''})';
}

class AuthState {
  final String? token;
  final String? gatewayUrl;
  final bool isLoading;
  final bool trustSelfSigned;

  const AuthState({
    this.token,
    this.gatewayUrl,
    this.isLoading = false,
    this.trustSelfSigned = false,
  });

  bool get isAuthenticated => token != null && gatewayUrl != null;

  AuthState copyWith({
    String? token,
    String? gatewayUrl,
    bool? isLoading,
    bool? trustSelfSigned,
  }) {
    return AuthState(
      token: token ?? this.token,
      gatewayUrl: gatewayUrl ?? this.gatewayUrl,
      isLoading: isLoading ?? this.isLoading,
      trustSelfSigned: trustSelfSigned ?? this.trustSelfSigned,
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
    final trust = await _storage.read(key: _trustKey);
    state = AuthState(
      token: token,
      gatewayUrl: url,
      trustSelfSigned: trust == 'true',
      isLoading: false,
    );
  }

  /// Validates credentials against the gateway then saves them.
  /// Always runs a real connection probe; [trustSelfSigned] controls whether
  /// TLS certificate errors are bypassed during that probe.
  Future<void> validateAndSaveCredentials(
    String gatewayUrl,
    String token, {
    bool trustSelfSigned = false,
  }) async {
    await _validateConnection(gatewayUrl, token, trustSelfSigned);
    await saveCredentials(gatewayUrl, token, trustSelfSigned: trustSelfSigned);
  }

  Future<void> _validateConnection(
    String gatewayUrl,
    String token,
    bool trustSelfSigned,
  ) async {
    final uri = Uri.parse(gatewayUrl);
    try {
      final channel = await createChannel(uri, token, trustSelfSigned)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw const AuthException(AuthFailureReason.timeout),
      );
      channel.sink.close();
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(AuthFailureReason.timeout);
    } catch (e) {
      final raw = e.toString();
      final msg = raw.toLowerCase();
      if (msg.contains('401') ||
          msg.contains('403') ||
          msg.contains('unauthorized') ||
          msg.contains('forbidden')) {
        throw AuthException(AuthFailureReason.authRejected, detail: raw);
      }
      if (msg.contains('handshake') ||
          msg.contains('certificate') ||
          msg.contains('tls') ||
          msg.contains('ssl') ||
          msg.contains('verify') ||
          msg.contains('-2146') || // Windows SChannel cert error codes
          msg.contains('sec_e')) {
        throw AuthException(AuthFailureReason.sslError, detail: raw);
      }
      if (msg.contains('failed host lookup') ||
          msg.contains('no address associated') ||
          msg.contains('connection refused') ||
          msg.contains('network is unreachable')) {
        throw AuthException(AuthFailureReason.networkError, detail: raw);
      }
      throw AuthException(AuthFailureReason.generic, detail: raw);
    }
  }

  Future<void> saveCredentials(
    String gatewayUrl,
    String token, {
    bool trustSelfSigned = false,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _urlKey, value: gatewayUrl);
    await _storage.write(key: _trustKey, value: trustSelfSigned.toString());
    state = AuthState(
      token: token,
      gatewayUrl: gatewayUrl,
      trustSelfSigned: trustSelfSigned,
    );
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _urlKey);
    await _storage.delete(key: _trustKey);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
