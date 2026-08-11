import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectOpenClawChannel(
  Uri uri, {
  required String origin,
}) {
  return WebSocketChannel.connect(uri);
}
