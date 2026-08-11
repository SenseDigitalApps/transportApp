import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/components/page_components/screens_background/background_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/home_initialization_service.dart';

import 'cohet_custom_home_model.dart';
import 'types/cohet_module.dart';
import 'widgets/cohet_app_bar.dart';
import 'widgets/cohet_drawer.dart';
import 'widgets/modules_section.dart';
import 'widgets/solicitudes_status_section.dart';
import 'widgets/welcome_card.dart';

class CohetCustomHomeWidget extends StatefulWidget {
  const CohetCustomHomeWidget({super.key});

  @override
  State<CohetCustomHomeWidget> createState() => _CohetCustomHomeWidgetState();
}

class _CohetCustomHomeWidgetState extends State<CohetCustomHomeWidget> {
  late CohetCustomHomeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CohetCustomHomeModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HomeInitializationService.runPostLoginChecks(context);
      await Future.wait([
        _model.fetchAndResolveModules(),
        _model.fetchSolicitudesCounts(),
      ]);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await HomeInitializationService.runPostLoginChecks(context);
    await Future.wait([
      _model.fetchAndResolveModules(),
      _model.fetchSolicitudesCounts(),
    ]);
    if (mounted) setState(() {});
  }

  void _openModule(CohetModule module) {
    // El API devuelve el slug técnico en rawData['name']; se usa para
    // navegación, con fallback al nombre legible de configuración.
    final moduleName = module.rawData['name']?.toString() ?? module.name;

    context.pushNamed(
      'singlePage',
      queryParameters: {
        'moduleName': serializeParam(moduleName, ParamType.String),
        'icon': serializeParam(module.iconKey, ParamType.String),
        'moduleType': serializeParam(module.type, ParamType.String),
        'moduleData': serializeParam(module.rawData, ParamType.JSON),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.secondaryBackground,
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: CohetAppBar(),
        ),
        drawer: CohetDrawer(
          model: _model,
          updateCallback: () => safeSetState(() {}),
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              DynamicBackground(
                bottomLeftColor: theme.accent3,
                topRightColor: theme.primary,
              ),
              RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  primary: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const WelcomeCard(),
                      const SizedBox(height: 20),
                      ModulesSection(
                        resolvedModules: _model.resolvedModules,
                        isLoading: _model.modulesLoading,
                        onModuleTap: _openModule,
                      ),
                      const SizedBox(height: 20),
                      SolicitudesStatusSection(
                        counts: _model.solicitudesCounts,
                        isLoading: _model.solicitudesLoading,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
