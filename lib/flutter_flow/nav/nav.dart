import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transport_app/pages/detail_simple_app/detail_simple_app_widget.dart';
import 'package:transport_app/pages/mercadopago/payment_result_screen.dart';

import 'package:transport_app/pages/chat_mode/chat_mode_widget.dart';
import 'package:transport_app/pages/notifications/notifications.dart';
import 'package:transport_app/pages/tasks/tasks.dart';
import 'package:transport_app/pages/upload_sign/upload_sign_widget.dart';
import 'package:transport_app/pages/user_settings/user_settings_widget.dart';

import '../../pages/user_register/register_user_widget.dart';
import '../../pages/detail_grouped/detail_grouped_widget.dart';
import '../../pages/home_simple_app/home_simple_app_widget.dart';
import '../../pages/pdf_viewer/pdf_viewer.dart';
import '../../pages/web_view_viewer/web_view_viewer_widget.dart';
import '../../pages/custom_pages/custom-map-transportapp/custom_map_transportapp_widget.dart';
import '../../widgets/home_wrapper.dart';
import '/index.dart';
import '/flutter_flow/flutter_flow_util.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: () {
        // Si el usuario ya inicio sesion y activo el modo chat, la app abre
        // directamente en el chat (se preserva entre cierres via SharedPreferences).
        if (FFAppState().role != '' && FFAppState().isChatModeActive) {
          return '/chatMode';
        }
        final loc = (FFAppState().role != '')
            ? (FFAppState().simpleApp == 'true' &&
                    FFAppState().simpleAppRole.isNotEmpty &&
                    FFAppState().role == FFAppState().simpleAppRole)
                ? '/homeSimpleApp'
                : '/home'
            : '/';
        return loc;
      }(),
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => const SplashScreenWidget(),
      redirect: (context, state) {
        // Interceptar deep links queryapp:// antes de que GoRouter los procese
        final uri = state.uri;
        if (uri.scheme == 'queryapp') {
          // Guardar URI completa antes de que GoRouter la strippee
          FFAppState().mpDeepLinkUri = uri;
          final host = uri.host;
          if (host == 'pago-exitoso') return '/payment-result/success';
          if (host == 'pago-fallido') return '/payment-result/failure';
          if (host == 'pago-pendiente') return '/payment-result/pending';
          return '/home';
        }
        return null;
      },
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => const SplashScreenWidget(),
        ),
        FFRoute(
          name: 'SplashScreen',
          path: '/splashScreen',
          builder: (context, params) => const SplashScreenWidget(),
        ),
        FFRoute(
          name: 'singlePage',
          path: '/singlePage',
          builder: (context, params) => SinglePageWidget(
            moduleName: params.getParam(
              'moduleName',
              ParamType.String,
            ),
            icon: params.getParam(
              'icon',
              ParamType.String,
            ),
            moduleType: params.getParam(
              'moduleType',
              ParamType.String,
            ),
            moduleData: params.getParam(
              'moduleData',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: 'newRegistersModule',
          path: '/newRegistersModule',
          builder: (context, params) => DetailGroupedWidget(
            mode: FormMode.create,
            moduleName: params.getParam(
              'moduleName',
              ParamType.String,
            ),
            moduleId: params.getParam('moduleId', ParamType.int),
            moduleType: params.getParam(
              'moduleType',
              ParamType.String,
            ),
            moduleData: params.getParam(
              'moduleData',
              ParamType.JSON,
            ),
            moduleConfigData: params.getParam(
              'moduleConfigData',
              ParamType.JSON,
            ),
            template: params.getParam(
              'template',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: 'home',
          path: '/home',
          builder: (context, params) {
            // print('DEBUG nav.dart /home: simpleApp=${FFAppState().simpleApp}, simpleAppRole=${FFAppState().simpleAppRole}, role=${FFAppState().role}');
            // print('DEBUG nav.dart /home: conditionResult=${FFAppState().simpleApp == 'true' && FFAppState().simpleAppRole.isNotEmpty && FFAppState().simpleAppRole.split(',')[0].trim() == FFAppState().role}');
            return (FFAppState().simpleApp == 'true' &&
                    FFAppState().simpleAppRole.isNotEmpty &&
                    FFAppState().simpleAppRole.split(',')[0].trim() ==
                        FFAppState().role)
                ? const HomeSimpleAppWidget()
                : const HomeWrapper();
          },
        ),
        FFRoute(
          name: 'pdfviewer',
          path: '/pdfviewer',
          builder: (context, params) => PdfViewWidget(
            pdfUrl: params.getParam(
              'pdfUrl',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: 'detail',
          path: '/detail',
          builder: (context, params) => DetailWidget(
            title: params.getParam(
              'title',
              ParamType.String,
            ),
            body: params.getParam(
              'body',
              ParamType.String,
            ),
            general: params.getParam(
              'general',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: 'detailGrouped',
          path: '/detailGrouped',
          builder: (context, params) => DetailGroupedWidget(
            title: params.getParam(
              'title',
              ParamType.String,
            ),
            body: params.getParam(
              'body',
              ParamType.String,
            ),
            general: params.getParam(
              'general',
              ParamType.JSON,
            ),
            moduleData: params.getParam(
              'moduleData',
              ParamType.JSON,
            ),
            moduleConfigData: params.getParam(
              'moduleConfigData',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: 'LoginClientes',
          path: '/loginClientes',
          builder: (context, params) => const LoginClientesWidget(),
        ),
        FFRoute(
          name: 'LoginEquipo',
          path: '/loginEquipo',
          builder: (context, params) => const LoginEquipoWidget(),
        ),
        FFRoute(
          name: 'homeClient',
          path: '/homeClient',
          builder: (context, params) => HomeClientWidget(
            userId: params.getParam(
              'userId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: 'detailSense',
          path: '/detailSense',
          builder: (context, params) => DetailSenseWidget(
            title: params.getParam(
              'title',
              ParamType.String,
            ),
            body: params.getParam(
              'body',
              ParamType.String,
            ),
            general: params.getParam(
              'general',
              ParamType.JSON,
            ),
            precio: params.getParam(
              'precio',
              ParamType.int,
            ),
            anticipo: params.getParam(
              'anticipo',
              ParamType.int,
            ),
            saldo: params.getParam(
              'saldo',
              ParamType.int,
            ),
            avance: params.getParam(
              'avance',
              ParamType.double,
            ),
            estadoProductoEnCartera: params.getParam(
              'estadoProductoEnCartera',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: 'webViewSupport',
          path: '/webViewSupport',
          builder: (context, params) => WebViewSupportWidget(
            title: params.getParam(
              'title',
              ParamType.String,
            ),
            body: params.getParam(
              'body',
              ParamType.String,
            ),
            general: params.getParam(
              'general',
              ParamType.JSON,
            ),
          ),
        ),
        FFRoute(
          name: 'homeSimpleApp',
          path: '/homeSimpleApp',
          builder: (context, params) => const HomeSimpleAppWidget(),
        ),
        FFRoute(
          name: 'detailSimpleApp',
          path: '/detailSimpleApp',
          builder: (context, params) => DetailSimpleAppWidget(
            detail: params.getParam('detail', ParamType.JSON),
          ),
        ),
        FFRoute(
          name: 'cargarFirma',
          path: '/cargarFirma',
          builder: (context, params) => const UploadSignWidget(),
        ),
        FFRoute(
          name: 'notificationsScreen',
          path: '/notificationsScreen',
          builder: (context, params) => const NotificationsScreen(),
        ),
        FFRoute(
          name: 'taskScreen',
          path: '/taskScreen',
          builder: (context, params) => const TaskScreen(),
        ),
        FFRoute(
          name: 'chatMode',
          path: '/chatMode',
          builder: (context, params) => ChatModeWidget(
            initialThreadId: params.getParam('threadId', ParamType.int),
          ),
        ),
        FFRoute(
          name: WebViewViewerWidget.routeName,
          path: WebViewViewerWidget.routePath,
          builder: (context, params) => WebViewViewerWidget(
            url: params.getParam(
              'url',
              ParamType.String,
            ),
            title: params.getParam(
              'title',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: UserSettingsWidget.routeName,
          path: UserSettingsWidget.routePath,
          builder: (context, params) => const UserSettingsWidget(),
        ),
        FFRoute(
          name: RegistrationUserScreen.routeName,
          path: RegistrationUserScreen.routePath,
          builder: (context, params) => RegistrationUserScreen(
            publicRoles: params.getParam(
                  'publicRoles',
                  ParamType.JSON,
                ) ??
                [],
          ),
        ),
        FFRoute(
          name: 'customMapTransportapp',
          path: '/custom-map-transportapp',
          builder: (context, params) => const CustomMapTransportappWidget(),
        ),
        // Deep links para resultados de pago Mercado Pago
        FFRoute(
          name: 'pagoExitoso',
          path: '/pago-exitoso',
          builder: (context, params) =>
              const _PaymentResultRedirect(type: 'success'),
        ),
        FFRoute(
          name: 'pagoFallido',
          path: '/pago-fallido',
          builder: (context, params) =>
              const _PaymentResultRedirect(type: 'failure'),
        ),
        FFRoute(
          name: 'pagoPendiente',
          path: '/pago-pendiente',
          builder: (context, params) =>
              const _PaymentResultRedirect(type: 'pending'),
        ),
        // PaymentResult screen (equivalente a PaymentResult.tsx del web)
        FFRoute(
          name: 'paymentResult',
          path: '/payment-result/:type',
          builder: (context, params) => PaymentResultScreen(
            type: params.getParam('type', ParamType.String),
          ),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => const TransitionInfo(
        hasTransition: true,
        transitionType: PageTransitionType.fade,
        duration: Duration(milliseconds: 300),
      );
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

/// Widget simple que redirige a home tras mostrar un snackbar
/// con el resultado del pago. Usado por deep links de Mercado Pago.
class _PaymentResultRedirect extends StatelessWidget {
  final String type;

  const _PaymentResultRedirect({required this.type});

  String get _message {
    switch (type) {
      case 'success':
        return 'Pago completado. Sincronizando estado...';
      case 'failure':
        return 'El pago no se completó.';
      case 'pending':
        return 'Pago pendiente de confirmación.';
      default:
        return 'Procesando resultado del pago...';
    }
  }

  IconData get _icon {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'failure':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(_message)),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.go('/home');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
