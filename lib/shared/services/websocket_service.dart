import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'device_identity_service.dart';
import 'websocket_channel_factory.dart';

enum ConnectionStatus { disconnected, connecting, connected, reconnecting, error }

const _uuid = Uuid();

/// Parsed hello-ok payload returned after a successful connect handshake.
class HelloResult {
  final String connId;
  final Map<String, dynamic> raw;

  const HelloResult({required this.connId, required this.raw});
}

class WebSocketService {
  WebSocketChannel? _channel;

  /// Stream of gateway events (type == 'event').
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Pending request completers keyed by request id.
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _gatewayUrl;
  String? _token;
  DeviceIdentityService? _deviceIdentity;
  bool _intentionalDisconnect = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  HelloResult? _helloResult;

  void Function(ConnectionStatus)? onStatusChange;

  ConnectionStatus get status => _status;
  HelloResult? get helloResult => _helloResult;

  /// Stream of all gateway event frames (chat.event, tick, etc.).
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void _setStatus(ConnectionStatus s) {
    _status = s;
    onStatusChange?.call(s);
  }

  /// Connect to the gateway and perform the OpenClaw protocol v3 handshake.
  Future<HelloResult> connect(
    String gatewayUrl,
    String token, {
    DeviceIdentityService? deviceIdentity,
  }) async {
    _intentionalDisconnect = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _gatewayUrl = gatewayUrl;
    _token = token;
    _deviceIdentity = deviceIdentity;
    return _doConnect();
  }

  Future<HelloResult> _doConnect() async {
    _setStatus(ConnectionStatus.connecting);
    _cancelAllPending('Connection reset');
    try {
      final uri = Uri.parse(_gatewayUrl!);
      _channel = await createChannel(uri);
      _reconnectAttempt = 0;

      // Set up stream listener before handshake so we receive the challenge.
      final helloCompleter = Completer<HelloResult>();
      bool handshakeDone = false;

      _channel!.stream.listen(
        (data) {
          if (data is! String) return;
          final msg = jsonDecode(data) as Map<String, dynamic>;
          final type = msg['type'] as String?;

          if (!handshakeDone) {
            _handleHandshakeMessage(msg, helloCompleter);
            if (helloCompleter.isCompleted) handshakeDone = true;
            return;
          }

          // Post-handshake: route by frame type.
          switch (type) {
            case 'res':
              _handleResponse(msg);
            case 'event':
              _handleEvent(msg);
          }
        },
        onError: (e) {
          _cancelAllPending('WebSocket error: $e');
          _setStatus(ConnectionStatus.error);
          if (!handshakeDone && !helloCompleter.isCompleted) {
            helloCompleter.completeError(e);
          }
          if (!_intentionalDisconnect) _scheduleReconnect();
        },
        onDone: () {
          _cancelAllPending('WebSocket closed');
          if (!handshakeDone && !helloCompleter.isCompleted) {
            helloCompleter.completeError(
                StateError('Connection closed before handshake completed'));
          }
          if (_intentionalDisconnect) {
            _setStatus(ConnectionStatus.disconnected);
          } else {
            _scheduleReconnect();
          }
        },
        cancelOnError: true,
      );

      final result = await helloCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Handshake timed out'),
      );
      _helloResult = result;
      _setStatus(ConnectionStatus.connected);
      return result;
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      if (!_intentionalDisconnect) _scheduleReconnect();
      rethrow;
    }
  }

  // ── Handshake ──────────────────────────────────────────────────────────────

  bool _challengeReceived = false;

  void _handleHandshakeMessage(
      Map<String, dynamic> msg, Completer<HelloResult> completer) {
    if (completer.isCompleted) return;

    final type = msg['type'] as String?;

    if (!_challengeReceived && type == 'event' && msg['event'] == 'connect.challenge') {
      _challengeReceived = true;

      // Extract nonce from challenge payload.
      final payload = (msg['payload'] as Map<String, dynamic>?) ?? {};
      final nonce = (payload['nonce'] as String?) ?? '';

      // Build connect params with optional device identity.
      _buildConnectParams(nonce).then((params) {
        final reqId = _uuid.v4();
        _sendRaw({
          'type': 'req',
          'id': reqId,
          'method': 'connect',
          'params': params,
        });
      }).catchError((e) {
        completer.completeError(StateError('Failed to build connect params: $e'));
      });
      return;
    }

    if (_challengeReceived && type == 'res') {
      if (msg['ok'] == true) {
        final payload = (msg['payload'] as Map<String, dynamic>?) ?? {};
        final server = (payload['server'] as Map<String, dynamic>?) ?? {};
        final connId = server['connId'] as String? ?? '';
        completer.complete(HelloResult(connId: connId, raw: payload));
      } else {
        final error = msg['error'];
        final errorMsg = error is Map
            ? (error['message'] ?? '$error')
            : 'Handshake rejected';
        completer.completeError(StateError('$errorMsg'));
      }
      return;
    }
  }

  static const _clientId = 'cli';
  static const _clientMode = 'backend';
  static const _role = 'operator';
  static const _scopes = ['operator.read', 'operator.write'];

  Future<Map<String, dynamic>> _buildConnectParams(String nonce) async {
    final params = <String, dynamic>{
      'minProtocol': 3,
      'maxProtocol': 3,
      'client': {
        'id': _clientId,
        'displayName': 'Pincers',
        'version': '1.0.0',
        'platform': 'flutter',
        'mode': _clientMode,
      },
      'role': _role,
      'scopes': _scopes,
      'caps': <String>[],
      'commands': <String>[],
      'permissions': <String, dynamic>{},
      'auth': {'token': _token},
      'locale': 'en-US',
      'userAgent': 'pincers/1.0.0',
    };

    if (_deviceIdentity != null) {
      params['device'] = await _deviceIdentity!.buildDeviceAuth(
        clientId: _clientId,
        clientMode: _clientMode,
        role: _role,
        scopes: List<String>.from(_scopes),
        token: _token ?? '',
        nonce: nonce,
      );
    }

    return params;
  }

  // ── Post-handshake message routing ─────────────────────────────────────────

  void _handleResponse(Map<String, dynamic> msg) {
    final id = msg['id'] as String?;
    if (id == null) return;
    final completer = _pending.remove(id);
    if (completer == null) return;

    if (msg['ok'] == true) {
      completer.complete(
          (msg['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{});
    } else {
      final error = msg['error'];
      final errorMsg =
          error is Map ? (error['message'] ?? '$error') : 'Request failed';
      completer.completeError(StateError('$errorMsg'));
    }
  }

  void _handleEvent(Map<String, dynamic> msg) {
    _eventController.add(msg);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Send a request and await the response payload.
  Future<Map<String, dynamic>> sendRequest(
      String method, Map<String, dynamic> params) {
    if (_channel == null || _status != ConnectionStatus.connected) {
      return Future.error(StateError('WebSocket not connected'));
    }
    final id = _uuid.v4();
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _sendRaw({
      'type': 'req',
      'id': id,
      'method': method,
      'params': params,
    });
    return completer.future;
  }

  void _sendRaw(Map<String, dynamic> frame) {
    _channel?.sink.add(jsonEncode(frame));
  }

  void _cancelAllPending(String reason) {
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError(reason));
    }
    _pending.clear();
  }

  void _scheduleReconnect() {
    _reconnectAttempt++;
    final delaySecs = min(30, pow(2, _reconnectAttempt - 1).toInt());
    _setStatus(ConnectionStatus.reconnecting);
    _reconnectTimer?.cancel();
    _challengeReceived = false;
    _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
      if (!_intentionalDisconnect) _doConnect();
    });
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancelAllPending('Disconnected');
    _challengeReceived = false;
    _helloResult = null;
    _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
  }
}
