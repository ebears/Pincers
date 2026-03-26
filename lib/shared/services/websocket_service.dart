import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'websocket_channel_factory.dart';

enum ConnectionStatus { disconnected, connecting, connected, reconnecting, error }

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _gatewayUrl;
  String? _token;
  bool _trustSelfSigned = false;
  bool _intentionalDisconnect = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  void Function(ConnectionStatus)? onStatusChange;

  ConnectionStatus get status => _status;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void _setStatus(ConnectionStatus s) {
    _status = s;
    onStatusChange?.call(s);
  }

  Future<void> connect(String gatewayUrl, String token, {bool trustSelfSigned = false}) async {
    _intentionalDisconnect = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _gatewayUrl = gatewayUrl;
    _token = token;
    _trustSelfSigned = trustSelfSigned;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    _setStatus(ConnectionStatus.connecting);
    try {
      final uri = Uri.parse(_gatewayUrl!);
      _channel = await createChannel(uri, _token!, _trustSelfSigned);
      _reconnectAttempt = 0;
      _setStatus(ConnectionStatus.connected);
      _channel!.stream.listen(
        (data) {
          if (data is String) {
            final json = jsonDecode(data) as Map<String, dynamic>;
            _messageController.add(json);
          }
        },
        onError: (e) {
          _setStatus(ConnectionStatus.error);
          if (!_intentionalDisconnect) _scheduleReconnect();
        },
        onDone: () {
          if (_intentionalDisconnect) {
            _setStatus(ConnectionStatus.disconnected);
          } else {
            _scheduleReconnect();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      if (!_intentionalDisconnect) _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempt++;
    final delaySecs = min(30, pow(2, _reconnectAttempt - 1).toInt());
    _setStatus(ConnectionStatus.reconnecting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
      if (!_intentionalDisconnect) _doConnect();
    });
  }

  Future<void> send(String method, Map<String, dynamic> params, {String? id}) async {
    if (_channel == null || _status != ConnectionStatus.connected) {
      throw StateError('WebSocket not connected');
    }
    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': ?id,
    });
    _channel!.sink.add(payload);
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
  }
}
