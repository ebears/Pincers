import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Native (non-web) implementation. When [trustSelfSigned] is true, creates a
/// custom [HttpClient] that bypasses TLS certificate validation and connects
/// via [WebSocket.connect] directly. The URI port is normalised first to work
/// around dart:io's port-mangling bug for wss:// URIs with an implicit port.
Future<WebSocketChannel> createChannel(
  Uri uri,
  String token,
  bool trustSelfSigned,
) async {
  if (trustSelfSigned) {
    // Ensure the port is explicit so dart:io doesn't mangle it to 0.
    final effectiveUri = _withExplicitPort(uri);
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final socket = await WebSocket.connect(
      effectiveUri.toString(),
      customClient: client,
    );
    return IOWebSocketChannel(socket);
  }
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return channel;
}

Uri _withExplicitPort(Uri uri) {
  if (uri.hasPort) return uri;
  final defaultPort = switch (uri.scheme) {
    'wss' || 'https' => 443,
    'ws' || 'http' => 80,
    _ => 0,
  };
  if (defaultPort == 0) return uri;
  return uri.replace(port: defaultPort);
}
