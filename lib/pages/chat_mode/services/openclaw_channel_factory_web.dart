import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectOpenClawChannel(
  Uri uri, {
  required String origin,
}) {
  // El navegador asigna Origin y no permite sobrescribirlo desde JavaScript.
  return WebSocketChannel.connect(uri);
}
