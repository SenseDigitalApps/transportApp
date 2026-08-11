import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../flutter_flow/nav/nav.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}

class PushNotificationEvent {
  const PushNotificationEvent({
    required this.title,
    required this.body,
    required this.route,
    required this.isChatMessage,
    this.notificationId,
    this.threadId,
    this.persisted = true,
  });

  final String title;
  final String body;
  final String route;
  final bool isChatMessage;
  final String? notificationId;
  final int? threadId;
  final bool persisted;

  factory PushNotificationEvent.fromMessage(RemoteMessage message) {
    final data = message.data;
    final isChatMessage = const {'openclaw_message', 'openclaw_timeout'}
        .contains(data['type']?.toString());
    return PushNotificationEvent(
      title: _safeNotificationText(
        message.notification?.title ?? data['title'],
        isChatMessage ? 'Tu agente respondió' : 'Nueva notificación',
      ),
      body: _safeNotificationText(
        message.notification?.body ?? data['body'],
        '',
      ),
      route: PushNotificationService.routeFromData(data),
      isChatMessage: isChatMessage,
      notificationId: data['notification_id']?.toString(),
      threadId: int.tryParse(data['thread_id']?.toString() ?? ''),
      persisted: data['persisted']?.toString() != 'false',
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

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  static const String fixedRoute = '/notificationsScreen';
  static const String _installationIdKey = 'query_installation_id';
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final _foregroundEvents = StreamController<PushNotificationEvent>.broadcast();

  Stream<PushNotificationEvent> get foregroundEvents =>
      _foregroundEvents.stream;

  void Function(String newToken)? onTokenChanged;
  String? _pendingRoute;
  String? _installationId;
  bool _initialized = false;

  String get platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unknown',
    };
  }

  Future<String> get installationId async {
    if (_installationId case final value?) return value;
    final preferences = await SharedPreferences.getInstance();
    var value = preferences.getString(_installationIdKey) ?? '';
    if (value.isEmpty) {
      value = const Uuid().v4();
      await preferences.setString(_installationIdKey, value);
    }
    _installationId = value;
    return value;
  }

  Future<void> initialize({
    void Function(String newToken)? onTokenChanged,
  }) async {
    this.onTokenChanged = onTokenChanged;
    if (_initialized) return;
    _initialized = true;

    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (error) {
      debugPrint(
        'No fue posible solicitar permisos FCM (${error.runtimeType}).',
      );
    }

    if (!kIsWeb) FirebaseMessaging.onBackgroundMessage(backgroundHandler);
    if (!kIsWeb) await _initLocalNotifications();
    _setUpFCMListeners();

    _firebaseMessaging.onTokenRefresh.listen((_) {
      unawaited(reportCurrentToken());
    });

    await reportCurrentToken();
    await _checkInitialMessage();
  }

  Future<String?> getCurrentToken() {
    return _firebaseMessaging.getToken();
  }

  Future<void> reportCurrentToken() async {
    try {
      final token = await getCurrentToken();
      if (token != null && token.isNotEmpty) {
        onTokenChanged?.call(token);
      }
    } catch (error) {
      debugPrint('No fue posible obtener el token FCM (${error.runtimeType}).');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      importance: Importance.max,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          _navigateOrQueue(fixedRoute);
          return;
        }
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            _navigateOrQueue(
              routeFromData(decoded.cast<String, dynamic>()),
            );
            return;
          }
        } catch (_) {}
        _navigateOrQueue(fixedRoute);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  void _setUpFCMListeners() {
    // En foreground usamos un banner dentro de Query, no una notificacion OS.
    FirebaseMessaging.onMessage.listen((message) {
      _foregroundEvents.add(PushNotificationEvent.fromMessage(message));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateOrQueue(routeFromData(message.data));
    });
  }

  Future<void> _checkInitialMessage() async {
    final message = await _firebaseMessaging.getInitialMessage();
    if (message != null) {
      _navigateOrQueue(routeFromData(message.data));
    }
  }

  static String routeFromData(Map<String, dynamic> data) {
    final route = (data['route'] ?? data['click_action'] ?? '').toString();
    final uri = Uri.tryParse(route);
    if (uri?.path == '/chatMode') return route;
    if (uri?.path == '/apps/agents') {
      final threadId =
          data['thread_id']?.toString() ?? uri?.queryParameters['threadId'];
      if (threadId != null && int.tryParse(threadId) != null) {
        return '/chatMode?threadId=$threadId';
      }
    }
    final type = data['type']?.toString();
    final threadId = data['thread_id']?.toString();
    if (const {'openclaw_message', 'openclaw_timeout'}.contains(type) &&
        threadId != null &&
        int.tryParse(threadId) != null) {
      return '/chatMode?threadId=$threadId';
    }
    return fixedRoute;
  }

  void _navigateOrQueue(String route) {
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      _pendingRoute = route;
      return;
    }
    context.go(route);
  }

  String? takePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
  }
}
