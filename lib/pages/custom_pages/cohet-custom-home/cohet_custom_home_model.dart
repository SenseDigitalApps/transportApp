import 'dart:async';

import '/backend/api_requests/api_calls.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

import 'cohet_custom_home_widget.dart' show CohetCustomHomeWidget;
import 'types/cohet_home_config.dart';
import 'types/cohet_module.dart';
import 'types/solicitud_status.dart';
import 'utils/module_resolver.dart';

class CohetCustomHomeModel extends FlutterFlowModel<CohetCustomHomeWidget> {
  late SideNavModel sideNavModel;

  Map<String, CohetModule> resolvedModules = {};
  bool modulesLoading = true;

  /// Conteo de solicitudes por estado (apiValue → count).
  Map<String, int> solicitudesCounts = {};
  bool solicitudesLoading = true;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
  }

  /// Fetches the full module list and resolves the configured Cohet modules.
  /// Updates [FFAppState().moduleList] so the side nav has the latest data.
  Future<void> fetchAndResolveModules() async {
    modulesLoading = true;

    try {
      final response = await ModulosCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      if (!response.succeeded) {
        modulesLoading = false;
        return;
      }

      final allModules = ModulosCall.data(response.jsonBody) ?? [];

      FFAppState().update(() {
        FFAppState().moduleList = allModules;
      });

      resolvedModules = resolveModules(allModules, CohetHomeConfig.modules);
    } catch (e) {
      // Preserve previous behavior: stop loading on error.
    } finally {
      modulesLoading = false;
    }
  }

  /// Consulta el conteo de solicitudes para cada estado definido en
  /// [SolicitudStatus.values]. Ejecuta las llamadas en paralelo.
  Future<void> fetchSolicitudesCounts() async {
    solicitudesLoading = true;

    try {
      final tenant = FFAppState().organizacion;
      final token = FFAppState().token;

      // Lanzar todas las queries en paralelo.
      final futures = SolicitudStatus.values.map((status) {
        return GetDataModulesCall.call(
          tenant: tenant,
          token: token,
          module: 'solicitudes',
          moduleType: 'registers',
          jsonKey: 'estado_de_la_solicitud',
          jsonValue: status.apiValue,
          jsonCondition: 'exacto',
          page: 1,
          limit: 1, // Solo necesitamos el total, no los registros.
        );
      }).toList();

      final responses = await Future.wait(futures);

      final Map<String, int> result = {};
      for (var i = 0; i < SolicitudStatus.values.length; i++) {
        final status = SolicitudStatus.values[i];
        final response = responses[i];
        if (response.succeeded) {
          result[status.apiValue] =
              GetDataModulesCall.total(response.jsonBody) ?? 0;
        } else {
          result[status.apiValue] = 0;
        }
      }

      solicitudesCounts = result;
    } catch (e) {
      // En error, dejar counts vacíos (se muestra 0 para cada estado).
    } finally {
      solicitudesLoading = false;
    }
  }

  @override
  void dispose() {
    sideNavModel.dispose();
  }
}
