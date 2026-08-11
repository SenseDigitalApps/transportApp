import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectNotificationChannel(
  Uri uri, {
  required String origin,
}) {
  return IOWebSocketChannel.connect(
    uri,
    headers: {'Origin': origin},
    pingInterval: const Duration(seconds: 25),
    connectTimeout: const Duration(seconds: 15),
  );
}
