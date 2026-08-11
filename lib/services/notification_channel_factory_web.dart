import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectNotificationChannel(
  Uri uri, {
  required String origin,
}) {
  return WebSocketChannel.connect(uri);
}
