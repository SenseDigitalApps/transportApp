import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:transport_app/app_state.dart';
import 'package:transport_app/backend/api_requests/api_base_url.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_models.dart';
import 'openclaw_channel_factory.dart';

enum OpenClawConnectionState { disconnected, connecting, connected }

/// Evento del protocolo Query <-> agente externo.
class OpenClawEvent {
  final String type;
  final String role;
  final String content;
  final Map<String, dynamic> data;
  final String clientMsgId;
  final String eventId;

  const OpenClawEvent({
    required this.type,
    this.role = 'assistant',
    this.content = '',
    this.data = const {},
    this.clientMsgId = '',
    this.eventId = '',
  });

  factory OpenClawEvent.fromJson(Map<String, dynamic> json) => OpenClawEvent(
        type: (json['type'] ?? 'message').toString(),
        role: (json['role'] ?? 'assistant').toString(),
        content: normalizeChatText(json['content']),
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        clientMsgId: (json['client_msg_id'] ?? '').toString(),
        eventId: (json['event_id'] ?? '').toString(),
      );
}

/// WebSocket autenticado con reconexión automática.
class OpenClawSocket {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int? _threadId;

  /// Ultima presencia anunciada por el servidor para el canal abierto.
  ///
  /// `session.status` solo se emite al aceptar la conexion y cuando el agente
  /// entra o se cae. Quien vuelva a pedir el hilo que ya esta abierto no
  /// provoca conexion nueva y por tanto no recibe anuncio: sin este recuerdo,
  /// reiniciar el indicador lo dejaba en «verificando» para siempre.
  OpenClawEvent? _lastPresence;
  bool _disposed = false;
  bool _intentionalDisconnect = false;
  bool _isRetrying = false;
  int _reconnectAttempt = 0;
  OpenClawConnectionState _state = OpenClawConnectionState.disconnected;

  final _eventController = StreamController<OpenClawEvent>.broadcast();
  final _stateController =
      StreamController<OpenClawConnectionState>.broadcast();

  Stream<OpenClawEvent> get events => _eventController.stream;
  Stream<OpenClawConnectionState> get states => _stateController.stream;
  OpenClawConnectionState get state => _state;
  bool get isConnected => _state == OpenClawConnectionState.connected;

  /// Hay canal vivo (abierto o abriendose) para ese hilo.
  bool isLiveFor(int threadId) =>
      _threadId == threadId && _state != OpenClawConnectionState.disconnected;

  static Uri _wsUri(int threadId) {
    return ApiBaseUrl.buildWebSocket(
      tenant: FFAppState().organizacion,
      path: '/ws/openclaw/$threadId/',
      queryParameters: {'token': FFAppState().token},
    );
  }

  void connect(int threadId) {
    if (_threadId == threadId &&
        _state != OpenClawConnectionState.disconnected) {
      // El canal se reaprovecha, pero quien lo pide espera saber como esta el
      // agente. Como no habra anuncio nuevo, se repite el ultimo conocido.
      final presence = _lastPresence;
      if (presence != null && !_disposed) _eventController.add(presence);
      return;
    }
    disconnect();
    _threadId = threadId;
    _intentionalDisconnect = false;
    _isRetrying = false;
    _open();
  }

  void _open() {
    final threadId = _threadId;
    if (_disposed || _intentionalDisconnect || threadId == null) return;
    if (!_isRetrying) {
      _setState(OpenClawConnectionState.connecting);
    }
    final tenant = FFAppState().organizacion;
    final channel = connectOpenClawChannel(
      _wsUri(threadId),
      origin: ApiBaseUrl.buildWebOrigin(tenant: tenant),
    );
    _channel = channel;

    channel.ready.then((_) {
      if (_channel == channel && !_intentionalDisconnect) {
        _isRetrying = false;
        _reconnectAttempt = 0;
        _setState(OpenClawConnectionState.connected);
      }
    }).catchError((Object error) {
      if (_channel == channel) {
        _emitError('No fue posible conectar con el agente.');
        _handleClosed(channel);
      }
    });

    _subscription = channel.stream.listen(
      (raw) {
        try {
          final decoded = jsonDecode(raw.toString());
          if (decoded is Map) {
            final event = OpenClawEvent.fromJson(decoded.cast<String, dynamic>());
            if (event.type == 'session.status') _lastPresence = event;
            _eventController.add(event);
          }
        } catch (_) {
          _emitError('El agente envió una respuesta que no se pudo leer.');
        }
      },
      onError: (_) => _handleClosed(channel),
      onDone: () => _handleClosed(channel),
      cancelOnError: true,
    );
  }

  void _handleClosed(WebSocketChannel channel) {
    if (_channel != channel) return;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    // Con el canal caido la presencia deja de estar respaldada: el agente pudo
    // irse mientras no habia nadie escuchando. La proxima conexion la anuncia.
    _lastPresence = null;
    _isRetrying = true;
    _setState(OpenClawConnectionState.disconnected);
    if (!_intentionalDisconnect && !_disposed && _threadId != null) {
      _reconnectTimer?.cancel();
      _reconnectAttempt++;
      final exponentialSeconds = min(30, 1 << min(_reconnectAttempt, 5));
      final jitter = Random().nextInt(750);
      _reconnectTimer = Timer(
        Duration(seconds: exponentialSeconds, milliseconds: jitter),
        _open,
      );
    }
  }

  bool sendMessage(
    String content, {
    required String clientMsgId,
    List<ChatAttachment> attachments = const [],
  }) {
    final channel = _channel;
    if (channel == null || !isConnected) return false;
    channel.sink.add(jsonEncode({
      'type': 'message',
      'role': 'user',
      'content': content,
      'client_msg_id': clientMsgId,
      'data': {
        'attachments': attachments.map((item) => item.toJson()).toList(),
      },
    }));
    return true;
  }

  void _emitError(String message) {
    if (_disposed) return;
    _eventController.add(OpenClawEvent(
      type: 'error',
      role: 'system',
      content: message,
      data: const {'code': 'connection_error', 'recoverable': true},
    ));
  }

  void _setState(OpenClawConnectionState value) {
    if (_state == value) return;
    _state = value;
    if (!_disposed) _stateController.add(value);
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _lastPresence = null;
    _threadId = null;
    _isRetrying = false;
    _setState(OpenClawConnectionState.disconnected);
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
