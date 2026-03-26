import 'package:web_socket_channel/web_socket_channel.dart';

/// Web-platform implementation.
Future<WebSocketChannel> createChannel(Uri uri) async {
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return channel;
}
