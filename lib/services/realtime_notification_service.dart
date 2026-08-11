import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../app_state.dart';
import '../backend/api_requests/api_base_url.dart';
import 'notification_channel_factory.dart';

class RealtimeNotificationEvent {
  const RealtimeNotificationEvent({
    required this.message,
    required this.route,
    required this.isChatMessage,
    this.notificationId,
    this.threadId,
    this.isRead = false,
    this.persisted = true,
    this.instanceData = const {},
  });

  final String message;
  final String route;
  final bool isChatMessage;
  final String? notificationId;
  final int? threadId;
  final bool isRead;
  final bool persisted;
  final Map<String, dynamic> instanceData;

  String get title => _safeNotificationText(
        instanceData['title'],
        isChatMessage ? 'Tu agente respondió' : 'Nueva notificación',
      );

  String get body => _safeNotificationText(instanceData['body'], message);

  factory RealtimeNotificationEvent.fromJson(Map<String, dynamic> json) {
    final rawInstance = json['instance_data'];
    final instance = rawInstance is Map
        ? rawInstance.cast<String, dynamic>()
        : <String, dynamic>{};
    final rawId = json['notification_id'];
    final rawRoute =
        (instance['route'] ?? json['link'] ?? '/notificationsScreen')
            .toString();
    final rawUri = Uri.tryParse(rawRoute);
    final threadId = int.tryParse(instance['thread_id']?.toString() ?? '');
    final isAgentEvent = const {'openclaw_message', 'openclaw_timeout'}
        .contains(instance['type']?.toString());
    final route = rawUri?.path == '/chatMode'
        ? rawRoute
        : (rawUri?.path == '/apps/agents' || isAgentEvent) && threadId != null
            ? '/chatMode?threadId=$threadId'
            : '/notificationsScreen';
    return RealtimeNotificationEvent(
      message: (json['message'] ?? '').toString(),
      route: route,
      isChatMessage: const {'openclaw_message', 'openclaw_timeout'}
          .contains(instance['type']?.toString()),
      notificationId: rawId?.toString(),
      threadId: threadId,
      isRead: json['is_read'] == true,
      persisted: json['persisted'] != false,
      instanceData: instance,
    );
  }
}

String _safeNotificationText(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty ||
      text.toLowerCase() == 'undefined' ||
      text.toLowerCase() == 'null') {
    return fallback;
  }
  return text;
}

/// Mantiene la presencia global de Query y recibe avisos en tiempo real.
class RealtimeNotificationService with WidgetsBindingObserver {
  RealtimeNotificationService._();

  static final RealtimeNotificationService instance =
      RealtimeNotificationService._();

  final _events = StreamController<RealtimeNotificationEvent>.broadcast();
  final String _sessionId = const Uuid().v4();

  Stream<RealtimeNotificationEvent> get events => _events.stream;

  bool isViewingThread(int? threadId) =>
      threadId != null && _visible && _activeThreadId == threadId;

  FFAppState? _appState;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  String _connectedToken = '';
  String _connectedTenant = '';
  int? _activeThreadId;
  bool _visible = true;
  bool _disposed = false;
  bool _connecting = false;

  String get platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unknown',
    };
  }

  void bind(FFAppState appState) {
    if (identical(_appState, appState)) return;
    _appState?.removeListener(_syncCredentials);
    _appState = appState;
    appState.addListener(_syncCredentials);
    WidgetsBinding.instance.addObserver(this);
    _syncCredentials();
  }

  void _syncCredentials() {
    final state = _appState;
    if (state == null) return;
    final token = state.token;
    final tenant = state.organizacion;
    if (token.isEmpty || tenant.isEmpty) {
      _disconnect(clearCredentials: true);
      return;
    }
    if (_channel != null &&
        token == _connectedToken &&
        tenant == _connectedTenant) {
      return;
    }
    _connect(token: token, tenant: tenant);
  }

  void _connect({required String token, required String tenant}) {
    _disconnect(clearCredentials: false);
    _connectedToken = token;
    _connectedTenant = tenant;
    if (_disposed || !_visible || _connecting) return;
    _connecting = true;

    final uri = ApiBaseUrl.buildWebSocket(
      tenant: tenant,
      path: '/ws/notifications/',
      queryParameters: {'token': token},
    );
    final channel = connectNotificationChannel(
      uri,
      origin: ApiBaseUrl.buildWebOrigin(tenant: tenant),
    );
    _channel = channel;

    channel.ready.then((_) {
      if (_channel != channel || _disposed) return;
      _connecting = false;
      _sendPresence();
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 25),
        (_) => _sendPresence(heartbeat: true),
      );
    }).catchError((Object _) {
      if (_channel == channel) _handleClosed(channel);
    });

    _subscription = channel.stream.listen(
      (raw) {
        try {
          final decoded = jsonDecode(raw.toString());
          if (decoded is! Map) return;
          final data = decoded.cast<String, dynamic>();
          if (data['type'] == 'notification') {
            _events.add(RealtimeNotificationEvent.fromJson(data));
          }
        } catch (_) {
          // Un evento invalido no debe tumbar la presencia ni el socket.
        }
      },
      onError: (_) => _handleClosed(channel),
      onDone: () => _handleClosed(channel),
      cancelOnError: true,
    );
  }

  void _sendPresence({bool heartbeat = false}) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({
      'type': heartbeat ? 'presence.heartbeat' : 'presence.update',
      'session_id': _sessionId,
      'platform': platform,
      'visible': _visible,
      'active_thread_id': _activeThreadId,
    }));
  }

  void setActiveThread(int? threadId) {
    if (_activeThreadId == threadId) return;
    _activeThreadId = threadId;
    _sendPresence();
  }

  void clearActiveThread(int? threadId) {
    if (threadId != null && _activeThreadId != threadId) return;
    setActiveThread(null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed;
    if (_visible == visible) return;
    _visible = visible;
    _sendPresence();
    if (visible && _channel == null) {
      _syncCredentials();
    }
  }

  void _handleClosed(WebSocketChannel channel) {
    if (_channel != channel) return;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _connecting = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (!_disposed && _visible && _connectedToken.isNotEmpty) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), _syncCredentials);
    }
  }

  void _disconnect({required bool clearCredentials}) {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _reconnectTimer = null;
    _heartbeatTimer = null;
    _subscription = null;
    _channel = null;
    _connecting = false;
    if (clearCredentials) {
      _connectedToken = '';
      _connectedTenant = '';
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _appState?.removeListener(_syncCredentials);
    WidgetsBinding.instance.removeObserver(this);
    _disconnect(clearCredentials: true);
    _events.close();
  }
}
