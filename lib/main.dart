import 'dart:async';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:app_links/app_links.dart';
import 'package:transport_app/config/home_widget_registry.dart';
import 'package:transport_app/pages/custom_pages/custom-dashboard/custom_dashboard_widget.dart';
import 'package:transport_app/pages/custom_pages/custom-map-transportapp/custom_map_transportapp_widget.dart';
import 'package:transport_app/pages/custom_pages/custom-cliente-transportapp/custom_cliente_transportapp_widget.dart';
import 'package:transport_app/pages/custom_pages/cohet-custom-home/cohet_custom_home_widget.dart';
import 'custom_code/PushNotificationService.dart';
import 'flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'firebase_options.dart';
import 'backend/api_requests/api_calls.dart';
import 'services/realtime_notification_service.dart';
import 'widgets/chat_message_notification_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  final pushService = PushNotificationService();
  await pushService.initialize(
    onTokenChanged: (newToken) async {
      if (FFAppState().token.isNotEmpty) {
        await PatchUser.call(
          tenant: FFAppState().organizacion,
          token: FFAppState().token,
          pushToken: newToken,
          deviceId: await pushService.installationId,
          platform: pushService.platform,
        );
      }
    },
  );

  // Register custom home pages
  HomeWidgetRegistry.register(
      'custom-dashboard', (context) => const CustomDashboardWidget());
  HomeWidgetRegistry.register('custom-map-transportapp',
      (context) => const CustomMapTransportappWidget());
  HomeWidgetRegistry.register('custom-cliente-transportapp',
      (context) => const CustomClienteTransportappWidget());
  HomeWidgetRegistry.register(
      'cohet-custom-home', (context) => const CohetCustomHomeWidget());

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  StreamSubscription<RealtimeNotificationEvent>? _realtimeSubscription;
  StreamSubscription<PushNotificationEvent>? _pushSubscription;
  final Set<String> _seenNotificationIds = {};
  OverlayEntry? _chatNotificationEntry;
  int _bannerGeneration = 0;
  String _lastPushRegistrationKey = '';
  String _lastAuthToken = '';
  String _lastAuthTenant = '';

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    RealtimeNotificationService.instance.bind(FFAppState());
    FFAppState().addListener(_handleAuthStateChanged);
    _handleAuthStateChanged();
    _realtimeSubscription =
        RealtimeNotificationService.instance.events.listen((event) {
      if (event.isChatMessage &&
          RealtimeNotificationService.instance
              .isViewingThread(event.threadId)) {
        return;
      }
      _showInAppNotification(
        title: event.title,
        body: event.body,
        route: event.route,
        isChatMessage: event.isChatMessage,
        notificationId: event.notificationId,
        incrementUnread: event.persisted && !event.isRead,
      );
    });
    _pushSubscription =
        PushNotificationService().foregroundEvents.listen((event) {
      if (event.isChatMessage &&
          RealtimeNotificationService.instance
              .isViewingThread(event.threadId)) {
        return;
      }
      _showInAppNotification(
        title: event.title,
        body: event.body,
        route: event.route,
        isChatMessage: event.isChatMessage,
        notificationId: event.notificationId,
        incrementUnread: event.persisted,
      );
    });

    // Deep links (queryapp://pago-exitoso, etc.)
    // Esperar a que el router esté listo antes de procesar deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
      final pendingRoute = PushNotificationService().takePendingRoute();
      if (pendingRoute != null) _router.go(pendingRoute);
    });
  }

  @override
  void dispose() {
    FFAppState().removeListener(_handleAuthStateChanged);
    _realtimeSubscription?.cancel();
    _pushSubscription?.cancel();
    _chatNotificationEntry?.remove();
    _chatNotificationEntry = null;
    RealtimeNotificationService.instance.dispose();
    super.dispose();
  }

  void _handleAuthStateChanged() {
    final state = FFAppState();
    final key = '${state.organizacion}:${state.token}';
    if (state.token.isEmpty || state.organizacion.isEmpty) {
      if (_lastAuthToken.isNotEmpty && _lastAuthTenant.isNotEmpty) {
        unawaited(_unregisterPushDevice(
          tenant: _lastAuthTenant,
          token: _lastAuthToken,
        ));
      }
      _lastPushRegistrationKey = '';
      _lastAuthToken = '';
      _lastAuthTenant = '';
      return;
    }
    _lastAuthToken = state.token;
    _lastAuthTenant = state.organizacion;
    if (_lastPushRegistrationKey == key) return;
    _lastPushRegistrationKey = key;
    unawaited(PushNotificationService().reportCurrentToken());
  }

  Future<void> _unregisterPushDevice({
    required String tenant,
    required String token,
  }) async {
    final pushService = PushNotificationService();
    await PatchUser.call(
      tenant: tenant,
      token: token,
      pushToken: '',
      deviceId: await pushService.installationId,
      platform: pushService.platform,
      active: false,
    );
  }

  void _showInAppNotification({
    required String title,
    required String body,
    required String route,
    bool isChatMessage = false,
    String? notificationId,
    bool incrementUnread = true,
  }) {
    if (notificationId != null && notificationId.isNotEmpty) {
      if (!_seenNotificationIds.add(notificationId)) return;
      if (_seenNotificationIds.length > 100) {
        _seenNotificationIds.remove(_seenNotificationIds.first);
      }
    }
    if (incrementUnread) {
      FFAppState().update(() {
        FFAppState().unreadNotifications++;
      });
    }

    if (isChatMessage) {
      _showChatMessageNotification(title: title, body: body, route: route);
      return;
    }

    final generation = ++_bannerGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = appNavigatorKey.currentContext;
      if (context == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentMaterialBanner();
      messenger.showMaterialBanner(
        MaterialBanner(
          leading: const Icon(Icons.notifications_active_outlined),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (body.isNotEmpty) Text(body, maxLines: 2),
            ],
          ),
          actions: [
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                _router.go(route.startsWith('/')
                    ? route
                    : PushNotificationService.fixedRoute);
              },
              child: const Text('Abrir'),
            ),
          ],
        ),
      );
      Timer(const Duration(seconds: 6), () {
        if (mounted && generation == _bannerGeneration) {
          messenger.hideCurrentMaterialBanner();
        }
      });
    });
  }

  void _showChatMessageNotification({
    required String title,
    required String body,
    required String route,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlay = appNavigatorKey.currentState?.overlay;
      if (overlay == null) return;

      _chatNotificationEntry?.remove();
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => ChatMessageNotificationOverlay(
          title: title,
          body: body,
          onClose: () => _removeChatMessageNotification(entry),
          onOpen: () {
            _removeChatMessageNotification(entry);
            _router.go(route.startsWith('/')
                ? route
                : PushNotificationService.fixedRoute);
          },
        ),
      );
      _chatNotificationEntry = entry;
      overlay.insert(entry);
    });
  }

  void _removeChatMessageNotification(OverlayEntry entry) {
    if (entry.mounted) entry.remove();
    if (identical(_chatNotificationEntry, entry)) {
      _chatNotificationEntry = null;
    }
  }

  void setThemeMode(ThemeMode mode) => setState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  void _initDeepLinks() {
    final appLinks = AppLinks();

    // Deep link cuando app ya está abierta
    appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link stream error: $err');
    });

    // Deep link cuando app se abre desde cerrada
    appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }).catchError((err) {
      debugPrint('Deep link initial error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    // queryapp://pago-exitoso?collection_id=...&status=approved
    final host = uri.host;
    debugPrint('MercadoPago DeepLink _handleDeepLink: uri=$uri, host=$host');

    if (host == 'pago-exitoso' ||
        host == 'pago-fallido' ||
        host == 'pago-pendiente') {
      // Navegar a PaymentResult screen (como web PaymentResult.tsx)
      String type = 'pending';
      if (host == 'pago-exitoso') {
        type = 'success';
      } else if (host == 'pago-fallido') {
        type = 'failure';
      }

      _router.go('/payment-result/$type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TransportApp',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
        focusColor: FlutterFlowTheme.of(context).primary,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: FlutterFlowTheme.of(context).primary,
          selectionColor: FlutterFlowTheme.of(context).primary,
          selectionHandleColor: FlutterFlowTheme.of(context).primary,
        ),
      ),
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        focusColor: FlutterFlowTheme.of(context).primary,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: FlutterFlowTheme.of(context).primary,
          selectionColor: FlutterFlowTheme.of(context).primary,
          selectionHandleColor: FlutterFlowTheme.of(context).primary,
        ),
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
