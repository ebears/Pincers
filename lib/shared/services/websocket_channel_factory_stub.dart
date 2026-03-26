import 'package:web_socket_channel/web_socket_channel.dart';

/// Web-platform stub: certificate bypass is not possible in the browser.
/// The browser controls TLS validation; [trustSelfSigned] is ignored.
Future<WebSocketChannel> createChannel(
  Uri uri,
  String token,
  bool trustSelfSigned,
) async {
  final channel = WebSocketChannel.connect(uri);
  await channel.ready;
  return channel;
}
