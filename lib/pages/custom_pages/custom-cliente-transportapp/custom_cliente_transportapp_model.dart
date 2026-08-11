import '/backend/api_requests/api_calls.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'custom_cliente_transportapp_widget.dart' show CustomClienteTransportappWidget;
import 'types/solicitud_trabajo.dart';
import 'types/cliente_config.dart';
import 'package:flutter/material.dart';

class CustomClienteTransportappModel extends FlutterFlowModel<CustomClienteTransportappWidget> {
  late SideNavModel sideNavModel;

  List<SolicitudTrabajo> activeRequests = [];
  List<Map<String, dynamic>> activeRequestsJson = [];
  List<dynamic> customFields = [];
  List<dynamic> remitentes = [];
  List<dynamic> destinatarios = [];
  bool isLoading = true;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
  }

  Future<void> fetchCustomFields() async {
    final response = await GetCustomFieldsPerModuleCall.call(
      tenant: FFAppState().organizacion,
      moduleName: ClienteConfig.moduleSlug,
      token: FFAppState().token,
    );

    if (response.succeeded) {
      customFields = getJsonField(response.jsonBody, r'''$.data''', true) as List;
    }
  }

  Future<void> fetchRemitentesDestinatarios() async {
    final response = await GetDataModulesCall.call(
      tenant: FFAppState().organizacion,
      module: ClienteConfig.remitenteModuleSlug,
      token: FFAppState().token,
      page: 1,
      limit: 50,
      moduleType: 'registers',
    );

    if (response.succeeded) {
      final data = GetDataModulesCall.data(response.jsonBody) ?? [];
      remitentes = data.where((r) {
        final tipo = r['tipo']?.toString().toLowerCase() ?? '';
        return tipo.contains('remitente') || r['es_remitente'] == true;
      }).toList();
      destinatarios = data.where((r) {
        final tipo = r['tipo']?.toString().toLowerCase() ?? '';
        return tipo.contains('destinatario') || r['es_destinatario'] == true;
      }).toList();
    }
  }

  Future<void> fetchActiveRequests() async {
    final response = await GetDataModulesCall.call(
      tenant: FFAppState().organizacion,
      module: ClienteConfig.moduleSlug,
      token: FFAppState().token,
      page: 1,
      limit: 50,
      moduleType: 'registers',
    );

    if (response.succeeded) {
      final data = GetDataModulesCall.data(response.jsonBody) ?? [];
      final filteredData = data.where((json) {
        final jsonData = json['json_data'] as Map<String, dynamic>? ?? {};
        final estado = jsonData[ClienteConfig.statusFieldSlug] as String? ?? '';
        return ClienteConfig.activeStatuses.contains(estado);
      }).toList();
      activeRequestsJson = filteredData.cast<Map<String, dynamic>>();
      activeRequests = filteredData
          .map((json) => SolicitudTrabajo.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    isLoading = false;
  }

  @override
  void dispose() {
    sideNavModel.dispose();
  }
}
