import 'package:web_socket_channel/web_socket_channel.dart';

/// Native (non-web) implementation.
Future<WebSocketChannel> createChannel(Uri uri) async {
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return channel;
}
