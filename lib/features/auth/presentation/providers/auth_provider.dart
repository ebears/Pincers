import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/services/websocket_channel_factory.dart';

const _tokenKey = 'gateway_token';
const _urlKey = 'gateway_url';

enum AuthFailureReason { timeout, networkError, authRejected, generic }

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

  const AuthState({
    this.token,
    this.gatewayUrl,
    this.isLoading = false,
  });

  bool get isAuthenticated => token != null && gatewayUrl != null;

  AuthState copyWith({
    String? token,
    String? gatewayUrl,
    bool? isLoading,
  }) {
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
    state = AuthState(
      token: token,
      gatewayUrl: url,
      isLoading: false,
    );
  }

  /// Validates credentials against the gateway then saves them.
  Future<void> validateAndSaveCredentials(
    String gatewayUrl,
    String token,
  ) async {
    await _validateConnection(gatewayUrl, token);
    await saveCredentials(gatewayUrl, token);
  }

  /// Opens a WebSocket, performs the OpenClaw connect handshake, and checks
  /// that the gateway accepts the token before saving credentials.
  Future<void> _validateConnection(
    String gatewayUrl,
    String token,
  ) async {
    final uri = Uri.parse(gatewayUrl);
    try {
      final channel = await createChannel(uri)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw const AuthException(AuthFailureReason.timeout),
      );

      try {
        await _performConnectHandshake(channel, token);
      } finally {
        channel.sink.close();
      }
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
        throw AuthException(AuthFailureReason.networkError, detail: raw);
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

  static const _uuid = Uuid();

  /// Waits for the connect.challenge event, sends a connect request with the
  /// token, and verifies the gateway responds with hello-ok.
  Future<void> _performConnectHandshake(dynamic channel, String token) async {
    final messages = <Map<String, dynamic>>[];
    final completer = Completer<void>();

    final sub = channel.stream.listen(
      (data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        messages.add(msg);

        if (messages.length == 1) {
          // First message: expect connect.challenge, then send connect request.
          if (msg['type'] != 'event' || msg['event'] != 'connect.challenge') {
            completer.completeError(const AuthException(
              AuthFailureReason.generic,
              detail: 'Expected connect.challenge from gateway',
            ));
            return;
          }

          final reqId = _uuid.v4();
          channel.sink.add(jsonEncode({
            'type': 'req',
            'id': reqId,
            'method': 'connect',
            'params': {
              'minProtocol': 3,
              'maxProtocol': 3,
              'client': {
                'id': 'gateway-client',
                'version': '1.0.0',
                'platform': 'flutter',
                'mode': 'ui',
              },
              'role': 'operator',
              'scopes': ['operator.read', 'operator.write'],
              'caps': [],
              'commands': [],
              'permissions': {},
              'auth': {'token': token},
              'locale': 'en-US',
              'userAgent': 'pincers/1.0.0',
            },
          }));
        } else if (messages.length == 2) {
          // Second message: expect hello-ok response.
          if (msg['type'] == 'res' && msg['ok'] == true) {
            completer.complete();
          } else {
            final error = msg['error'];
            final errorMsg =
                error is Map ? (error['message'] ?? '$error') : '$msg';
            completer.completeError(
              AuthException(AuthFailureReason.authRejected, detail: '$errorMsg'),
            );
          }
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(
            AuthException(AuthFailureReason.generic, detail: '$e'),
          );
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(const AuthException(
            AuthFailureReason.generic,
            detail: 'Connection closed before handshake completed',
          ));
        }
      },
    );

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw const AuthException(AuthFailureReason.timeout),
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<void> saveCredentials(
    String gatewayUrl,
    String token,
  ) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _urlKey, value: gatewayUrl);
    state = AuthState(
      token: token,
      gatewayUrl: gatewayUrl,
    );
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
