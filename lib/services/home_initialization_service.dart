import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/login_equipo/widgets/additional_info_sheet.dart';

/// Servicio de inicialización post-login para home pages.
/// Maneja verificaciones que no deben bloquear el flujo de login
/// ni el main thread durante la navegación.
class HomeInitializationService {
  static bool _hasCheckedAdditionalInfo = false;

  /// Resetea el flag para testing o logout/login
  static void reset() {
    _hasCheckedAdditionalInfo = false;
  }

  /// Verifica si el usuario tiene firma registrada.
  /// Si no, navega a la pantalla de carga de firma.
  static Future<void> checkSignature(BuildContext context) async {
    final firma = FFAppState().firma;
    if (firma == '' || firma == '/media/avatars/default.png') {
      if (context.mounted) {
        context.pushNamed('cargarFirma');
      }
    }
  }

  /// Verifica información adicional del usuario y muestra modal si hay campos incompletos.
  /// Solo se ejecuta una vez por sesión (flag estático).
  static Future<void> checkAdditionalInfo(BuildContext context) async {
    if (_hasCheckedAdditionalInfo) return;
    if (FFAppState().simpleApp == 'true') return;

    _hasCheckedAdditionalInfo = true;

    try {
      final additionalInfoResponse = await CheckAdditionalInfoUserCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      if (additionalInfoResponse.statusCode == 200) {
        final data = additionalInfoResponse.jsonBody as List<dynamic>? ?? [];
        final alerts = data
            .map((e) => AdditionalInfoAlert.fromJson(e as Map<String, dynamic>))
            .where((a) => a.completenessPercent < 1.0)
            .toList();

        if (alerts.isNotEmpty && context.mounted) {
          final selectedModule = await showModalBottomSheet<String?>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AdditionalInfoSheetWidget(alerts: alerts),
          );

          if (selectedModule != null && selectedModule.isNotEmpty && context.mounted) {
            context.pushNamed(
              'singlePage',
              queryParameters: {
                'moduleName': serializeParam(selectedModule, ParamType.String),
              }.withoutNulls,
            );
          }
        }
      }
    } catch (e) {
      print('Error checking additional info: $e');
    }
  }

  /// Ejecuta todas las verificaciones post-login de forma segura.
  /// Ideal para llamar desde addPostFrameCallback en initState de home pages.
  static Future<void> runPostLoginChecks(BuildContext context) async {
    checkSignature(context);
    await Future.delayed(const Duration(milliseconds: 300));
    await checkAdditionalInfo(context);
  }
}
