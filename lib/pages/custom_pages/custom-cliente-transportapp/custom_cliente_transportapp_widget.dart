import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/backend/api_requests/api_calls.dart';
import '/services/home_initialization_service.dart';
import 'custom_cliente_transportapp_model.dart';
import 'widgets/client_map_view.dart';
import 'widgets/cliente_app_bar.dart';
import 'widgets/active_requests_section.dart';

class CustomClienteTransportappWidget extends StatefulWidget {
  const CustomClienteTransportappWidget({Key? key}) : super(key: key);

  @override
  State<CustomClienteTransportappWidget> createState() => _CustomClienteTransportappWidgetState();
}

class _CustomClienteTransportappWidgetState extends State<CustomClienteTransportappWidget> {
  late CustomClienteTransportappModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomClienteTransportappModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HomeInitializationService.runPostLoginChecks(context);
      await Future.wait([
        _model.fetchCustomFields(),
        _model.fetchRemitentesDestinatarios(),
        _model.fetchActiveRequests(),
      ]);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      drawer: Drawer(
        child: WebViewAware(
          child: wrapWithModel(
            model: _model.sideNavModel,
            updateCallback: () => setState(() {}),
            child: const SideNavWidget(),
          ),
        ),
      ),
      body: Stack(
        children: [
          const ClientMapView(),
          Positioned.fill(
            child: ActiveRequestsSection(
              requests: _model.activeRequests,
              requestsJson: _model.activeRequestsJson,
              isLoading: _model.isLoading,
              onRequestTap: (index) => _openRequestDetail(index),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: ClienteAppBar(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewRequestForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Solicitud'),
        backgroundColor: theme.primary,
      ),
    );
  }

  Future<void> _openNewRequestForm() async {
    final moduleConfigResponse = await GetCustomFieldsPerModuleCall.call(
      tenant: FFAppState().organizacion,
      moduleName: 'solicitud_de_trabajo',
      token: FFAppState().token,
    );

    if (!mounted) return;

    final result = await context.pushNamed(
      'newRegistersModule',
      queryParameters: {
        'moduleConfigData': serializeParam(
          getJsonField(moduleConfigResponse.jsonBody, r'''$.data'''),
          ParamType.JSON,
        ),
        'moduleName': serializeParam('solicitud_de_trabajo', ParamType.String),
        'moduleId': serializeParam(46, ParamType.int),
        'moduleType': serializeParam('registers', ParamType.String),
      }.withoutNulls,
    );

    if (result == true && mounted) {
      await _model.fetchActiveRequests();
      setState(() {});
    }
  }

  Future<void> _openRequestDetail(int index) async {
    if (index >= _model.activeRequestsJson.length) return;

    final general = _model.activeRequestsJson[index];

    if (!mounted) return;

    final result = await context.pushNamed(
      'detailGrouped',
      queryParameters: {
        'general': serializeParam(general, ParamType.JSON),
      }.withoutNulls,
    );

    if (result == true && mounted) {
      await _model.fetchActiveRequests();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }
}
