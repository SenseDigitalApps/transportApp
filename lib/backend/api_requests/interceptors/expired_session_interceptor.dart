
import 'package:flutter/material.dart';

import '../../../app_state.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/nav/nav.dart';
import '../api_calls.dart';
import '/backend/api_requests/api_interceptor.dart';

class ExpiredSessionInterceptor extends FFApiInterceptor {
  // Flag para evitar bucles infinitos de reintento
  static bool _isRefreshingToken = false;

  // Almacenar las opciones de la petición original para reintento
  static ApiCallOptions? _lastRequestOptions;

  @override
  Future<ApiCallOptions> onRequest({
    required ApiCallOptions options,
  }) async {
    // Guardar las opciones para un posible reintento
    _lastRequestOptions = options;
    return options;
  }

  @override
  Future<ApiCallResponse> onResponse({
    required ApiCallResponse response,
    required Future<ApiCallResponse> Function() retryFn,
  }) async {
    print('[ExpiredSessionInterceptor] onResponse: statusCode=${response.statusCode}, _isRefreshingToken=$_isRefreshingToken');
    if (response.statusCode == 401 && !_isRefreshingToken) {
      final responseData = response.jsonBody;
      print('[ExpiredSessionInterceptor] 401 response data: $responseData');
      if (responseData is Map<String, dynamic> &&
          responseData['code'] == 'token_not_valid') {

        // Intentar refresh token
        print('[ExpiredSessionInterceptor] token not valid, attempting refresh...');
        return await _handleTokenExpired(retryFn);
      }
    }
    return response;
  }

  Future<ApiCallResponse> _handleTokenExpired(Future<ApiCallResponse> Function() retryFn) async {
    try {
      _isRefreshingToken = true;
      print('[ExpiredSessionInterceptor] _handleTokenExpired: starting token refresh');

      // 1. Intenta usar el refresh token primero
      if (FFAppState().refreshToken.isNotEmpty) {
        print('[ExpiredSessionInterceptor] using refreshToken');
        FFAppState().token = FFAppState().refreshToken;
        FFAppState().refreshToken = '';

        return await retryFn();
      }

      // 2. Si el refresh token falló o no existe, intenta con login completo
      if (FFAppState().loginUser.isNotEmpty && FFAppState().loginPassword.isNotEmpty) {
        print('[ExpiredSessionInterceptor] attempting full login...');
        final loginResponse = await LoginTenantCall.call(
          tenant: FFAppState().organizacion,
          username: FFAppState().loginUser,
          password: FFAppState().loginPassword,
        );

        print('[ExpiredSessionInterceptor] login response: ${loginResponse.statusCode}');
        if (loginResponse.statusCode == 200) {
          // Extraer y actualizar tokens
          final accessToken = LoginTenantCall.token(loginResponse.jsonBody);
          final refreshToken = LoginTenantCall.refresh(loginResponse.jsonBody);

          if (accessToken != null && accessToken.isNotEmpty) {
            FFAppState().token = accessToken;

            if (refreshToken != null && refreshToken.isNotEmpty) {
              FFAppState().refreshToken = refreshToken;
            }

            // Reintenta la petición original
            print('[ExpiredSessionInterceptor] login successful, retrying original request...');
            return await retryFn();
          }
        }
      }

      // 3. Si todo falló, mostrar mensaje y redirigir al login
      print('[ExpiredSessionInterceptor] all refresh attempts failed, redirecting to login');
      _redirectToLogin('Tu sesión ha expirado. Redirigiendo al inicio de sesión.');

      return const ApiCallResponse(
        '{"error": "Sesión expirada"}',
        {},
        401,
      );
    } catch (e) {
      print('[ExpiredSessionInterceptor] error in _handleTokenExpired: $e');
      _redirectToLogin('Error de sesión. Redirigiendo al inicio de sesión.');

      return const ApiCallResponse(
        '{"error": "Error en renovación de sesión"}',
        {},
        500,
      );
    } finally {
      _isRefreshingToken = false;
      print('[ExpiredSessionInterceptor] _handleTokenExpired: _isRefreshingToken set to false');
    }
  }

  void _redirectToLogin(String message) {
    if (appNavigatorKey.currentContext != null) {
      // Mostrar un Snackbar
      ScaffoldMessenger.of(appNavigatorKey.currentContext!)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(
                color: FlutterFlowTheme.of(appNavigatorKey.currentContext!).white,
              ),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(appNavigatorKey.currentContext!).error,
          ),
        );

      // Redirigir a la página de login
      appNavigatorKey.currentContext!.goNamed('LoginEquipo');
    }
  }
}
