import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  ConnectionStatus get status => _status;
  Stream<Map<String, dynamic>>? get messages => _messageController?.stream;

  Future<void> connect(String gatewayUrl, String token) async {
    _status = ConnectionStatus.connecting;

    _messageController?.close();
    _messageController = StreamController<Map<String, dynamic>>.broadcast();

    try {
      final uri = Uri.parse('$gatewayUrl/rpc');
      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['Bearer $token'],
      );

      await _channel!.ready;
      _status = ConnectionStatus.connected;

      _channel!.stream.listen(
        (data) {
          if (data is String) {
            final json = jsonDecode(data) as Map<String, dynamic>;
            _messageController?.add(json);
          }
        },
        onError: (e) {
          _status = ConnectionStatus.error;
        },
        onDone: () {
          _status = ConnectionStatus.disconnected;
        },
      );
    } catch (e) {
      _status = ConnectionStatus.error;
      rethrow;
    }
  }

  Future<void> send(String method, Map<String, dynamic> params, {String? id}) async {
    if (_channel == null || _status != ConnectionStatus.connected) {
      throw StateError('WebSocket not connected');
    }
    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      // ignore: use_null_aware_elements
      if (id != null) 'id': id,
    });
    _channel!.sink.add(payload);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
  }
}
