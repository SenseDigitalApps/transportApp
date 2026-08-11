import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../components/page_components/screens_background/background_widget.dart';
import '../web_view_viewer/web_view_viewer_widget.dart';
import '/backend/api_requests/api_calls.dart';
import '/components/empty_component/empty_component_widget.dart';
import '/components/loading_card/loading_card_widget.dart';
import '/components/pop_up_filter_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'single_page_model.dart';
export 'single_page_model.dart';
import 'package:flutter/scheduler.dart';
import 'kanban/kanban_page_widget.dart';
import '/models/filter_model.dart';
import '/providers/filter_provider.dart';
import '/widgets/cached_avatar_image.dart';

class SinglePageWidget extends StatefulWidget {
  const SinglePageWidget(
      {super.key,
      required this.moduleName,
      required this.icon,
      required this.moduleType,
      required this.moduleData});

  final String? moduleName;
  final String icon;
  final String? moduleType;
  final dynamic moduleData;

  @override
  State<SinglePageWidget> createState() => _SinglePageWidgetState();
}

class _SinglePageWidgetState extends State<SinglePageWidget> {
  late SinglePageModel _model;
  late FilterProvider _filterProvider;
  List<dynamic> optionsFilter = [];
  List<Map<String, String>> objetosNuevos = [];
  List<dynamic> templates = []; // List of available templates

  final scaffoldKey = GlobalKey<ScaffoldState>();
  ApiCallResponse? moduleConfiguration;
  ApiCallResponse? currentData;
  dynamic moduleProcess;
  int? selectedIndex;
  String? selectedName;
  Map<int, bool> isLoadingMap = {};
  late int totalRegisters = 0;
  bool? isKanbanModule;
  bool showKanbanView = true;
  int _kanbanRefreshKey = 0;
  Map<int, List<dynamic>> filteredTemplatesCache = {};

  void getFilterOptions() {
    optionsFilter = getJsonField(
      (moduleConfiguration?.jsonBody ?? ''),
      r'''$.data''',
    );

    for (var config in optionsFilter) {
      String label = config['label'];
      String slug = config['slug'];
      String type = config["field_type"];

      Map<String, String> nuevoObjeto = {
        'label': label,
        'slug': slug,
        'type': type,
      };

      objetosNuevos.add(nuevoObjeto);
    }

    Map<String, String> titleObj = {
      'label': 'Titulo',
      'slug': 'title',
      'type': 'text'
    };

    Map<String, String> consecutiveObj = {
      'label': 'Consecutivo',
      'slug': 'consecutivo',
      'type': 'number'
    };

    objetosNuevos.insert(0, titleObj);
    objetosNuevos.insert(1, consecutiveObj);
  }

  void getTemplates() {
    final templatesData = widget.moduleData['document_templates'] ??
        widget.moduleData['templates'];

    if (templatesData != null &&
        templatesData is List &&
        templatesData.isNotEmpty) {
      templates = templatesData;
    }
  }

  Future<List<dynamic>> getFilteredTemplates(int recordId) async {
    if (filteredTemplatesCache.containsKey(recordId)) {
      return filteredTemplatesCache[recordId]!;
    }

    final moduleId = widget.moduleData['id'];

    final response = await GetFilteredDocumentTemplates.call(
      tenant: FFAppState().organizacion,
      token: FFAppState().token,
      moduleId: moduleId,
      recordId: recordId,
    );

    print(
        '[Templates] moduleId=$moduleId recordId=$recordId status=${response.statusCode} body=${response.jsonBody}');

    if (response.statusCode == 200) {
      final templatesList =
          GetFilteredDocumentTemplates.templates(response.jsonBody) ?? [];
      filteredTemplatesCache[recordId] = templatesList;
      return templatesList;
    }

    return [];
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SinglePageModel());
    _filterProvider = FilterProvider();
    _filterProvider.addListener(_onFiltersChanged);
    moduleProcess = widget.moduleData['process_array'];

    // Cargar templates inmediatamente desde moduleData
    getTemplates();

    if (functions.hasAnyPermissionForModule(
            FFAppState().permissions.toList(), widget.moduleName!) &&
        !functions.hasPermission(FFAppState().permissions.toList(),
            'query_-_ver', widget.moduleName!)) {
      setState(() {
        selectedIndex = 0;
        selectedName = moduleProcess[0]['name'];

        final filtros = moduleProcess[0]['filtros'];
        _filterProvider.loadProcessFilters(filtros);
        _filterProvider.resolveMeToken(FFAppState().fullName);
        _model.filters = {
          'filter_module': widget.moduleName!,
          ..._filterProvider.serialize(),
        };
      });
    }

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final cachedJson =
          FFAppState().getCachedModuleConfigJson(widget.moduleName!);
      if (cachedJson != null) {
        moduleConfiguration = ApiCallResponse(
          cachedJson,
          {},
          200,
        );
        isKanbanModule = _checkIfKanbanModule(moduleConfiguration);
        getFilterOptions();
        setState(() {});
        return;
      }

      moduleConfiguration = await GetCustomFieldsPerModuleCall.call(
        tenant: FFAppState().organizacion,
        moduleName: widget.moduleName,
        token: FFAppState().token,
      );

      if (moduleConfiguration?.succeeded == true) {
        final moduleId = getJsonField(
                moduleConfiguration?.jsonBody ?? '', r'''$.data[0].module''')
            .toString();
        FFAppState().setCachedModuleConfig(
            widget.moduleName!, moduleId, moduleConfiguration?.jsonBody);
      }

      isKanbanModule = _checkIfKanbanModule(moduleConfiguration);
      getFilterOptions();
      setState(() {});
    });

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      setState(() => _model.listViewPagingController?.refresh());
      await _model.waitForOnePageForListView();

      _getTotalRegisters(null);
    });
  }

  @override
  void dispose() {
    _filterProvider.removeListener(_onFiltersChanged);
    _filterProvider.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    _model.filters =
        _filterProvider.hasFilters ? _filterProvider.serialize() : null;
    setState(() {});
    setState(() => _model.listViewPagingController?.refresh());
    _getTotalRegisters(_model.filters);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _getTotalRegisters(null);
    });
  }

  void _getTotalRegisters(dynamic filters) async {
    currentData = await GetDataModulesCall.call(
      tenant: FFAppState().organizacion,
      module: widget.moduleName,
      token: FFAppState().token,
      moduleType: widget.moduleType,
      page: 1,
      limit: 10,
      jsonKey: filters != null
          ? getJsonField(filters, r'''$.json_key''').toString()
          : '',
      jsonValue: filters != null
          ? getJsonField(filters, r'''$.json_value''').toString()
          : '',
      jsonCondition: filters != null
          ? getJsonField(filters, r'''$.json_condition''').toString()
          : '',
    );

    setState(() {
      totalRegisters =
          currentData?.jsonBody['payload']['pagination']['total'] ?? 0;
    });
  }

  bool _checkIfKanbanModule(ApiCallResponse? config) {
    if (widget.moduleData is Map) {
      final md = widget.moduleData as Map;
      final kanbanModuleFromData = md['kanban_module'];
      if (kanbanModuleFromData == true ||
          kanbanModuleFromData.toString() == 'true') {
        return true;
      }
      final kanbanStatusFromData = md['kanban_status']?.toString() ?? '';
      if (kanbanStatusFromData.isNotEmpty) {
        return true;
      }
    }

    if (config?.jsonBody == null) {
      return false;
    }

    final jsonBody = config!.jsonBody;
    if (jsonBody is Map) {
      final kanbanModuleTop = jsonBody['kanban_module'];
      if (kanbanModuleTop == true || kanbanModuleTop.toString() == 'true') {
        return true;
      }
      final kanbanStatusTop = jsonBody['kanban_status']?.toString() ?? '';
      if (kanbanStatusTop.isNotEmpty) {
        return true;
      }
    }

    final data =
        getJsonField(config.jsonBody, r'''$.data''', true) as List? ?? [];

    dynamic statusField;
    for (final field in data) {
      final kanbanModule = getJsonField(field, r'''$.kanban_module''');
      final kanbanStatus =
          getJsonField(field, r'''$.kanban_status''')?.toString() ?? '';
      if (kanbanModule == true || kanbanModule.toString() == 'true') {
        return true;
      }
      if (kanbanStatus.isNotEmpty) {
        return true;
      }

      final fieldType =
          getJsonField(field, r'''$.field_type''')?.toString().toLowerCase() ??
              '';
      if (fieldType == 'status') {
        statusField = field;
      }
    }

    if (statusField != null) {
      final options =
          getJsonField(statusField, r'''$.options''')?.toString() ?? '';
      if (options.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  bool _canShowFilter() {
    return functions.hasPermission(
      FFAppState().permissions.toList(),
      'query_-_ver',
      widget.moduleName!,
    );
  }

  bool _canShowCreate() {
    return functions.hasPermission(
      FFAppState().permissions.toList(),
      'query_-_crear',
      widget.moduleName!.toLowerCase(),
    );
  }

  Future<void> _openFilterDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          alignment: const AlignmentDirectional(0.0, 1.0)
              .resolve(Directionality.of(context)),
          child: WebViewAware(
            child: PopUpFilterWidget(
              filterProvider: _filterProvider,
              optionsFilter: objetosNuevos,
              onApply: () {
                _onFiltersChanged();
              },
            ),
          ),
        );
      },
    ).then((value) => setState(() {}));
  }

  Map<String, dynamic>? _resolveCreateTemplate() {
    final creationTemplates = widget.moduleData['templates'];
    if (FFAppState().organizacion == 'apicadi' &&
        creationTemplates is List &&
        creationTemplates.isNotEmpty) {
      final firstTemplate = creationTemplates.first;
      final templateData =
          (firstTemplate['json_data'] as Map<String, dynamic>?) ?? {};
      templateData['title'] = firstTemplate['title'] ?? '';
      return templateData;
    }
    return null;
  }

  Future<void> _navigateToCreate(Map<String, dynamic>? template) async {
    final moduleId = getJsonField(
        moduleConfiguration?.jsonBody ?? '', r'''$.data[0].module''');
    final moduleType = widget.moduleType?.isNotEmpty == true
        ? widget.moduleType
        : widget.moduleData is Map
            ? widget.moduleData['type']?.toString()
            : null;

    final result = await context.pushNamed(
      'newRegistersModule',
      queryParameters: {
        'moduleConfigData': serializeParam(
          getJsonField((moduleConfiguration?.jsonBody ?? ''), r'''$.data'''),
          ParamType.JSON,
        ),
        'moduleName': serializeParam(widget.moduleName, ParamType.String),
        'moduleId': serializeParam(moduleId, ParamType.int),
        'moduleType': serializeParam(moduleType, ParamType.String),
        'moduleData': serializeParam(widget.moduleData, ParamType.JSON),
        'template': serializeParam(template, ParamType.JSON),
      }.withoutNulls,
    );

    if (result == true) {
      setState(() {
        _model.listViewPagingController?.refresh();
        _kanbanRefreshKey++;
      });
      _getTotalRegisters(null);
    }
  }

  Widget _buildBottomStickyBar(BuildContext context) {
    final showFilter = _canShowFilter();
    final showCreate = _canShowCreate();

    // Si no hay ninguno, no mostramos barra
    if (!showFilter && !showCreate) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color:
            FlutterFlowTheme.of(context).primaryBackground, // blanco del theme
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x22000000),
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
          child: Row(
            children: [
              if (showFilter)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openFilterDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FlutterFlowTheme.of(context).primary,
                      side: BorderSide(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Filtrar',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              if (showFilter && showCreate) const SizedBox(width: 12),
              if (showCreate) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _navigateToCreate(_resolveCreateTemplate()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: FlutterFlowTheme.of(context).white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Crear',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                          color:
                              FlutterFlowTheme.of(context).primaryBackground),
                    ),
                  ),
                ),
                // Botón dropdown para plantillas (solo si hay templates)
                if (templates.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
                    child: PopupMenuButton<Map<String, dynamic>>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          size: 24,
                        ),
                      ),
                      itemBuilder: (context) {
                        return templates.map((template) {
                          return PopupMenuItem<Map<String, dynamic>>(
                            value: template,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        template['title'] ??
                                            template['name'] ??
                                            'Plantilla',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium,
                                      ),
                                      if (template['description'] != null)
                                        Text(
                                          template['description'],
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      onSelected: (template) {
                        // Extraer json_data y agregar title
                        final templateData =
                            template['json_data'] as Map<String, dynamic>? ??
                                {};
                        templateData['title'] = template['title'] ?? '';
                        _navigateToCreate(templateData);
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bottomLeftColor = const Color(0xFFD7D7D7).withOpacity(0.98);
    Color topRightColor = FlutterFlowTheme.of(context).primary;
    context.watch<FFAppState>();
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        drawer: Drawer(
          elevation: 16.0,
          child: WebViewAware(
            child: wrapWithModel(
              model: _model.sideNavModel,
              updateCallback: () => setState(() {}),
              child: const SideNavWidget(),
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          iconTheme: IconThemeData(color: FlutterFlowTheme.of(context).primary),
          automaticallyImplyLeading: true,
          toolbarHeight: 74.0,
          title: Align(
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Registros de',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  widget.moduleData['label']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        color: FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (isKanbanModule == true)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        0.0, 5.0, 8.0, 5.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        setState(() {
                          showKanbanView = !showKanbanView;
                        });
                      },
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          showKanbanView
                              ? Icons.view_list_rounded
                              : Icons.view_kanban_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        5.0, 5.0, 5.0, 5.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.pushNamed('UserSettings');
                      },
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: FFAppState().avatar.isNotEmpty
                              ? CachedAvatarImage(
                                  imageUrl: functions
                                      .buildMediaUrl(FFAppState().avatar),
                                  width: 40.0,
                                  height: 40.0,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildInitialsAvatar(context),
                                )
                              : _buildInitialsAvatar(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          centerTitle: false,
          elevation: 1.0,
        ),
        bottomNavigationBar: _buildBottomStickyBar(context),
        body: Align(
          alignment: const AlignmentDirectional(1.0, 0.9),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                DynamicBackground(
                  bottomLeftColor: bottomLeftColor,
                  topRightColor: topRightColor,
                ),
                Stack(
                  children: [
                    if (functions.hasAnyPermissionForModule(
                        FFAppState().permissions.toList(), widget.moduleName!))
                      Container(
                          width: MediaQuery.sizeOf(context).width * 1.0,
                          height: 60.0,
                          decoration: const BoxDecoration(),
                          child: ListView.separated(
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 1),
                              primary: false,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: moduleProcess.length,
                              itemBuilder: (context, index) {
                                final processItem = moduleProcess[index];
                                final processName = processItem['name'];
                                final isSelected = index == selectedIndex;

                                return Visibility(
                                  visible: functions.hasPermissionProcess(
                                      FFAppState().permissions.toList(),
                                      widget.moduleName!,
                                      processName),
                                  child: Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 10.0, 0.0, 10.0),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        if (selectedIndex != index) {
                                          setState(() {
                                            selectedIndex = index;
                                            selectedName = processItem['name'];
                                            final filtros =
                                                processItem['filtros'];

                                            _filterProvider
                                                .loadProcessFilters(filtros);
                                            _filterProvider.resolveMeToken(
                                                FFAppState().fullName);
                                            _model.filters = {
                                              'filter_module':
                                                  widget.moduleName!,
                                              ..._filterProvider.serialize(),
                                            };
                                          });

                                          _getTotalRegisters(_model.filters);
                                          setState(() {});
                                          setState(() => _model
                                              .listViewPagingController
                                              ?.refresh());
                                          await _model
                                              .waitForOnePageForListView();
                                        } else if (selectedIndex == index &&
                                            functions.hasPermission(
                                                FFAppState()
                                                    .permissions
                                                    .toList(),
                                                'query_-_ver',
                                                widget.moduleName!)) {
                                          setState(() {
                                            selectedIndex = null;
                                            _filterProvider.clearAll();
                                            _model.filters = {
                                              'json_key': '',
                                              'json_value': '',
                                              'json_condition': '',
                                            };
                                          });

                                          _getTotalRegisters(null);
                                          setState(() {});
                                          setState(() => _model
                                              .listViewPagingController
                                              ?.refresh());
                                          await _model
                                              .waitForOnePageForListView();
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            left: 8, right: 8),
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.3,
                                        height: 60.0,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? FlutterFlowTheme.of(context)
                                                  .primary
                                              : FlutterFlowTheme.of(context)
                                                  .primaryBackground,
                                          boxShadow: const [
                                            BoxShadow(
                                              blurRadius: 6.0,
                                              color: Color(0x33000000),
                                              offset: Offset(0.0, 2.0),
                                              spreadRadius: 2.0,
                                            ),
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Center(
                                          child: Text(
                                            valueOrDefault<String>(
                                              processName,
                                              'No data',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: FlutterFlowTheme.of(context)
                                                .headlineSmall
                                                .override(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.0,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              })),

                    if (selectedIndex != null &&
                        functions.hasAnyPermissionForModule(
                            FFAppState().permissions.toList(),
                            widget.moduleName!) &&
                        functions.hasPermission(
                            FFAppState().permissions.toList(),
                            'query_-_ver',
                            widget.moduleName!))
                      Positioned(
                        top: 13,
                        right: 10,
                        child: InkWell(
                          onTap: () async {
                            setState(() {
                              selectedIndex = null;
                              _filterProvider.clearAll();
                              _model.filters = {
                                'json_key': '',
                                'json_value': '',
                                'json_condition': '',
                              };
                            });

                            setState(() {});
                            setState(() =>
                                _model.listViewPagingController?.refresh());
                            await _model.waitForOnePageForListView();
                            _getTotalRegisters(null);
                          },
                          child: Container(
                            width: MediaQuery.sizeOf(context).width * 0.08,
                            height: 35.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(
                                  12), // Esquina redondeada
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.2), // Sombra negra tenue
                                  blurRadius: 4, // Difuminado
                                  offset: Offset(
                                      2, 2), // Desplazamiento de la sombra
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.clear,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    // ── Active filters display ──────────────
                    if (_filterProvider.hasFilters)
                      _buildActiveFiltersChips(context),
                    Container(
                      margin: (functions.hasAnyPermissionForModule(
                              FFAppState().permissions.toList(),
                              widget.moduleName!)
                          ? EdgeInsets.fromLTRB(
                              30, _filterProvider.hasFilters ? 5 : 75, 0, 5)
                          : const EdgeInsets.fromLTRB(30, 10, 0, 5)),
                      child: Text(
                        '$totalRegisters Resultados',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 1.0,
                      margin: (functions.hasAnyPermissionForModule(
                              FFAppState().permissions.toList(),
                              widget.moduleName!)
                          ? const EdgeInsets.only(top: 65)
                          : const EdgeInsets.only(top: 0)),
                      child: Builder(
                        builder: (context) {
                          if (isKanbanModule == true && showKanbanView) {
                            return KanbanPageWidget(
                              key: ValueKey<int>(_kanbanRefreshKey),
                              moduleName: widget.moduleName,
                              moduleConfig: moduleConfiguration?.jsonBody,
                              moduleData: widget.moduleData,
                              moduleType: widget.moduleType,
                              filters: _model.filters,
                            );
                          }
                          return RefreshIndicator(
                            color: FlutterFlowTheme.of(context).companyColor,
                            onRefresh: () async {
                              setState(() =>
                                  _model.listViewPagingController?.refresh());
                              await _model.waitForOnePageForListView();
                              _getTotalRegisters(null);
                            },
                            child: PagedListView<ApiPagingParams,
                                dynamic>.separated(
                              pagingController: _model.setListViewController(
                                (nextPageMarker) {
                                  final filters = _model.filters;
                                  return GetDataModulesCall.call(
                                    tenant: FFAppState().organizacion,
                                    module: widget.moduleName,
                                    token: FFAppState().token,
                                    page: nextPageMarker.nextPageNumber + 1,
                                    limit: 10,
                                    moduleType: widget.moduleType,
                                    jsonKey: filters != null
                                        ? getJsonField(
                                                filters, r'''$.json_key''')
                                            .toString()
                                        : '',
                                    jsonValue: filters != null
                                        ? getJsonField(
                                                filters, r'''$.json_value''')
                                            .toString()
                                        : '',
                                    jsonCondition: filters != null
                                        ? getJsonField(filters,
                                                r'''$.json_condition''')
                                            .toString()
                                        : '',
                                  );
                                },
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                0,
                                30.0,
                                0,
                                100.0,
                              ),
                              primary: false,
                              reverse: false,
                              scrollDirection: Axis.vertical,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 15.0),
                              builderDelegate:
                                  PagedChildBuilderDelegate<dynamic>(
                                // Customize what your widget looks like when it's loading the first page.
                                firstPageProgressIndicatorBuilder: (_) =>
                                    Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(30, 0, 30, 450),
                                  width: MediaQuery.sizeOf(context).width * 0.9,
                                  height: 250,
                                  child: const LoadingCardWidget(),
                                ),
                                // Customize what your widget looks like when it's loading another page.
                                newPageProgressIndicatorBuilder: (_) =>
                                    Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(30, 0, 30, 450),
                                  width: MediaQuery.sizeOf(context).width * 0.9,
                                  height: 250,
                                  child: const LoadingCardWidget(),
                                ),
                                noItemsFoundIndicatorBuilder: (_) => Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(30, 0, 30, 450),
                                  child: const EmptyComponentWidget(),
                                ),

                                itemBuilder: (context, _, modulesIndex) {
                                  final modulesItem = _model
                                      .listViewPagingController!
                                      .itemList![modulesIndex];
                                  final docLink = getJsonField(
                                    modulesItem,
                                    r'''$.docLink''',
                                  ).toString();
                                  final docLinkPDF = getJsonField(
                                    modulesItem,
                                    r'''$.docLinkPdf''',
                                  ).toString();
                                  final documentModule = getJsonField(
                                    modulesItem,
                                    r'''$.modulo_info.documentModule''',
                                  );
                                  final module = getJsonField(
                                    modulesItem,
                                    r'''$.modulo_info.name''',
                                  );
                                  final hasAdminPermission = FFAppState()
                                      .permissions
                                      .contains(
                                          'modulo.query_-_editar_$module');
                                  final isLoading =
                                      isLoadingMap[modulesIndex] ?? false;

                                  return Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            16.0, 0.0, 16.0, 0.0),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        onTap: () async {
                                          final result =
                                              await context.pushNamed(
                                            'detailGrouped',
                                            queryParameters: {
                                              'title': serializeParam(
                                                  'a', ParamType.String),
                                              'body': serializeParam(
                                                  'aa', ParamType.String),
                                              'general': serializeParam(
                                                getJsonField(
                                                    modulesItem, r'''$'''),
                                                ParamType.JSON,
                                              ),
                                              'moduleData': serializeParam(
                                                widget.moduleData,
                                                ParamType.JSON,
                                              ),
                                              'moduleConfigData':
                                                  serializeParam(
                                                getJsonField(
                                                    (moduleConfiguration
                                                            ?.jsonBody ??
                                                        ''),
                                                    r'''$.data'''),
                                                ParamType.JSON,
                                              ),
                                            }.withoutNulls,
                                          );

                                          if (result == true) {
                                            setState(() => _model
                                                .listViewPagingController
                                                ?.refresh());
                                            _getTotalRegisters(null);
                                          }

                                          String newItemId = getJsonField(
                                                  modulesItem, r'''$.id''')
                                              .toString();
                                          int existingIndex = -1;

                                          for (int i = 0;
                                              i < FFAppState().recientes.length;
                                              i++) {
                                            String currentItemId = getJsonField(
                                                    FFAppState().recientes[i],
                                                    r'''$.id''')
                                                .toString();
                                            if (currentItemId == newItemId) {
                                              existingIndex = i;
                                              break;
                                            }
                                          }

                                          if (existingIndex != -1) {
                                            FFAppState()
                                                .removeAtIndexFromRecientes(
                                                    existingIndex);
                                          }

                                          if (FFAppState().recientes.length >=
                                              11) {
                                            FFAppState()
                                                .removeAtIndexFromRecientes(11);
                                            setState(() {});
                                          }
                                          FFAppState().insertAtIndexInRecientes(
                                              0,
                                              getJsonField(
                                                  modulesItem, r'''$'''));
                                          setState(() {});
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primaryBackground,
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            boxShadow: [
                                              BoxShadow(
                                                blurRadius: 12.0,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary
                                                        .withValues(
                                                            alpha: 0.08),
                                                offset: const Offset(0.0, 4.0),
                                                spreadRadius: 0.0,
                                              ),
                                              const BoxShadow(
                                                blurRadius: 4.0,
                                                color: Color(0x0D000000),
                                                offset: Offset(0.0, 1.0),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              // Accent bar izquierdo
                                              Positioned(
                                                left: 0,
                                                top: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 4.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(16.0),
                                                      bottomLeft:
                                                          Radius.circular(16.0),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Contenido principal
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        20.0, 16.0, 16.0, 16.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Columna de contenido
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // Fila superior: badge ID + fecha
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10.0,
                                                                    vertical:
                                                                        4.0),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary
                                                                      .withValues(
                                                                          alpha:
                                                                              0.12),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20.0),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Text(
                                                                      '#',
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .override(
                                                                            fontFamily:
                                                                                'Outfit',
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            fontSize:
                                                                                12.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                          ),
                                                                    ),
                                                                    Text(
                                                                      getJsonField(
                                                                              modulesItem,
                                                                              r'''$.consecutivo''')
                                                                          .toString(),
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .override(
                                                                            fontFamily:
                                                                                'Outfit',
                                                                            color:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            fontSize:
                                                                                12.0,
                                                                            letterSpacing:
                                                                                0.0,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .schedule_rounded,
                                                                    size: 13.0,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText
                                                                        .withValues(
                                                                            alpha:
                                                                                0.7),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          4.0),
                                                                  Text(
                                                                    getJsonField(
                                                                            modulesItem,
                                                                            r'''$.last_updated''')
                                                                        .toString(),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .override(
                                                                          fontFamily:
                                                                              'Outfit',
                                                                          color: FlutterFlowTheme.of(context)
                                                                              .secondaryText
                                                                              .withValues(alpha: 0.7),
                                                                          fontSize:
                                                                              11.5,
                                                                          letterSpacing:
                                                                              0.0,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),

                                                          const SizedBox(
                                                              height: 10.0),

                                                          // Título
                                                          Text(
                                                            getJsonField(
                                                                    modulesItem,
                                                                    r'''$.title''')
                                                                .toString(),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .titleMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      15.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                          ),

                                                          const SizedBox(
                                                              height: 12.0),

                                                          // Divider
                                                          Divider(
                                                            height: 1,
                                                            thickness: 1,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryText
                                                                .withValues(
                                                                    alpha: 0.1),
                                                          ),

                                                          const SizedBox(
                                                              height: 10.0),

                                                          // Fila inferior: avatar + nombre
                                                          Row(
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            18.0),
                                                                child: Image
                                                                    .network(
                                                                  functions.buildMediaUrl(getJsonField(
                                                                          modulesItem,
                                                                          r'''$.profile_info.avatar''')
                                                                      .toString()),
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    return Container(
                                                                      width:
                                                                          28.0,
                                                                      height:
                                                                          28.0,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary
                                                                            .withValues(alpha: 0.15),
                                                                        shape: BoxShape
                                                                            .circle,
                                                                      ),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .person_rounded,
                                                                        size:
                                                                            16.0,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primary,
                                                                      ),
                                                                    );
                                                                  },
                                                                  width: 28.0,
                                                                  height: 28.0,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8.0),
                                                              Expanded(
                                                                child: Text(
                                                                  getJsonField(
                                                                          modulesItem,
                                                                          r'''$.profile_info.full_name''')
                                                                      .toString(),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .override(
                                                                        fontFamily:
                                                                            'Outfit',
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryText,
                                                                        fontSize:
                                                                            12.5,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Chevron de navegación
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0,
                                                              top: 4.0),
                                                      child: Icon(
                                                        Icons
                                                            .chevron_right_rounded,
                                                        size: 20.0,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText
                                                                .withValues(
                                                                    alpha: 0.4),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Menú de acciones (documentModule)
                                              if (documentModule &&
                                                  hasAdminPermission)
                                                Positioned(
                                                  top: 10.0,
                                                  right: 8.0,
                                                  child: FutureBuilder<
                                                      List<dynamic>>(
                                                    future:
                                                        getFilteredTemplates(
                                                            getJsonField(
                                                                    modulesItem,
                                                                    r'''$.id''')
                                                                as int),
                                                    builder:
                                                        (context, snapshot) {
                                                      final filteredTemplates =
                                                          snapshot.data ?? [];
                                                      final hasConditionalTemplates =
                                                          templates.isNotEmpty;
                                                      final showDocumentOptions =
                                                          filteredTemplates
                                                                  .isNotEmpty ||
                                                              !hasConditionalTemplates;

                                                      return PopupMenuButton<
                                                          String>(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        elevation: 8.0,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                        ),
                                                        onSelected:
                                                            (value) async {
                                                          if (isLoading) return;

                                                          if (value != null &&
                                                              value.startsWith(
                                                                  'generate_')) {
                                                            final templateIdx =
                                                                int.tryParse(value
                                                                        .replaceFirst(
                                                                            'generate_',
                                                                            '')) ??
                                                                    0;
                                                            final selectedTemplate =
                                                                filteredTemplates
                                                                        .isNotEmpty
                                                                    ? filteredTemplates[
                                                                        templateIdx]
                                                                    : null;

                                                            int? resolvedIndex;
                                                            if (selectedTemplate !=
                                                                    null &&
                                                                templates
                                                                    .isNotEmpty) {
                                                              final byRef =
                                                                  templates.indexOf(
                                                                      selectedTemplate);
                                                              if (byRef >= 0) {
                                                                resolvedIndex =
                                                                    byRef;
                                                              } else {
                                                                final byMatch = templates.indexWhere((t) =>
                                                                    t?['name'] ==
                                                                        selectedTemplate[
                                                                            'name'] &&
                                                                    (t?['template_file'] ??
                                                                            '') ==
                                                                        (selectedTemplate['template_file'] ??
                                                                            '') &&
                                                                    (t?['template_mode'] ??
                                                                            'file') ==
                                                                        (selectedTemplate['template_mode'] ??
                                                                            'file'));
                                                                resolvedIndex =
                                                                    byMatch >= 0
                                                                        ? byMatch
                                                                        : templateIdx;
                                                              }
                                                            } else {
                                                              resolvedIndex =
                                                                  templateIdx;
                                                            }

                                                            print(
                                                                '[GenerateDoc] templateIdx=$templateIdx, resolvedIndex=$resolvedIndex, filteredTemplates.length=${filteredTemplates.length}');

                                                            setState(() =>
                                                                isLoadingMap[
                                                                        modulesIndex] =
                                                                    true);

                                                            final bodyMap = Map<
                                                                    String,
                                                                    dynamic>.from(
                                                                modulesItem);
                                                            bodyMap['template_index'] =
                                                                resolvedIndex;

                                                            print(
                                                                '[GenerateDoc] body keys: ${bodyMap.keys.toList()}');
                                                            print(
                                                                '[GenerateDoc] body: ${jsonEncode(bodyMap)}');

                                                            ApiCallResponse?
                                                                responseDoc =
                                                                await GenerateDocument
                                                                    .call(
                                                              tenant: FFAppState()
                                                                  .organizacion,
                                                              token:
                                                                  FFAppState()
                                                                      .token,
                                                              body: jsonEncode(
                                                                  bodyMap),
                                                            );

                                                            print(
                                                                '[GenerateDoc] statusCode: ${responseDoc.statusCode}');
                                                            print(
                                                                '[GenerateDoc] jsonBody: ${responseDoc.jsonBody}');
                                                            print(
                                                                '[GenerateDoc] bodyText: ${responseDoc.bodyText}');
                                                            print(
                                                                '[GenerateDoc] exception: ${responseDoc.exception}');

                                                            if (responseDoc
                                                                    .statusCode ==
                                                                200) {
                                                              final url = getJsonField(
                                                                      responseDoc
                                                                          .jsonBody,
                                                                      r'''$.file_url''')
                                                                  .toString();
                                                              print(
                                                                  '[GenerateDoc] url extracted: $url');
                                                              if (url.isNotEmpty &&
                                                                  url !=
                                                                      'null') {
                                                                setState(() => _model
                                                                    .listViewPagingController
                                                                    ?.refresh());
                                                                await launchURL(
                                                                    url);
                                                                setState(() =>
                                                                    isLoadingMap[
                                                                            modulesIndex] =
                                                                        false);
                                                              } else {
                                                                print(
                                                                    '[GenerateDoc] url is null or empty, not launching');
                                                                setState(() =>
                                                                    isLoadingMap[
                                                                            modulesIndex] =
                                                                        false);
                                                              }
                                                            }

                                                            if (responseDoc
                                                                    .statusCode ==
                                                                504) {
                                                              ScaffoldMessenger.of(
                                                                  appNavigatorKey
                                                                      .currentContext!)
                                                                ..hideCurrentSnackBar()
                                                                ..showSnackBar(
                                                                    SnackBar(
                                                                  content: Text(
                                                                    'Espera 2 minutos y revisa el contrato disponible en acciones > Descargar documento. La solicitud está tardando un poco',
                                                                    style: TextStyle(
                                                                        color: FlutterFlowTheme.of(appNavigatorKey.currentContext!)
                                                                            .white),
                                                                  ),
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          4000),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              appNavigatorKey.currentContext!)
                                                                          .primary,
                                                                ));
                                                              setState(() =>
                                                                  isLoadingMap[
                                                                          modulesIndex] =
                                                                      false);
                                                            }

                                                            if (responseDoc
                                                                        .statusCode !=
                                                                    200 &&
                                                                responseDoc
                                                                        .statusCode !=
                                                                    504) {
                                                              print(
                                                                  '[GenerateDoc] ERROR status: ${responseDoc.statusCode}');
                                                              ScaffoldMessenger.of(
                                                                  appNavigatorKey
                                                                      .currentContext!)
                                                                ..hideCurrentSnackBar()
                                                                ..showSnackBar(
                                                                    SnackBar(
                                                                  content: Text(
                                                                    'Ocurrió un error inesperado. Por favor, intenta de nuevo más tarde.',
                                                                    style: TextStyle(
                                                                        color: FlutterFlowTheme.of(appNavigatorKey.currentContext!)
                                                                            .white),
                                                                  ),
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          4000),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              appNavigatorKey.currentContext!)
                                                                          .error,
                                                                ));
                                                              setState(() =>
                                                                  isLoadingMap[
                                                                          modulesIndex] =
                                                                      false);
                                                            }
                                                            setState(() =>
                                                                isLoadingMap[
                                                                        modulesIndex] =
                                                                    false);
                                                          }

                                                          if (value ==
                                                              'opcion_dos') {
                                                            final docLink =
                                                                getJsonField(
                                                                        modulesItem,
                                                                        r'''$.docLink''')
                                                                    .toString();
                                                            await launchURL(
                                                                'https://${FFAppState().organizacion}.itsquery.com/media/$docLink');
                                                          }

                                                          if (value ==
                                                              'opcion_tres') {
                                                            final linkPdf =
                                                                'https://${FFAppState().organizacion}.itsquery.com/media/${getJsonField(modulesItem, r'''$.docLinkPdf''').toString()}';
                                                            await launchURL(
                                                                linkPdf);
                                                          }
                                                        },
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context) =>
                                                                <PopupMenuEntry<
                                                                    String>>[
                                                          if (showDocumentOptions &&
                                                              filteredTemplates
                                                                  .isEmpty)
                                                            PopupMenuItem<
                                                                String>(
                                                              value:
                                                                  'generate_0',
                                                              child: Text(
                                                                'Generar documento',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontSize:
                                                                          15.5,
                                                                    ),
                                                              ),
                                                            ),
                                                          if (showDocumentOptions &&
                                                              filteredTemplates
                                                                  .isNotEmpty)
                                                            ...filteredTemplates
                                                                .asMap()
                                                                .entries
                                                                .map((entry) {
                                                              final idx =
                                                                  entry.key;
                                                              final tpl =
                                                                  entry.value;
                                                              final tplName =
                                                                  getJsonField(
                                                                          tpl,
                                                                          r'''$.name''')
                                                                      ?.toString();
                                                              final label = (tplName !=
                                                                          null &&
                                                                      tplName
                                                                          .isNotEmpty &&
                                                                      tplName !=
                                                                          'null')
                                                                  ? tplName
                                                                  : 'Generar documento ${idx + 1}';
                                                              return PopupMenuItem<
                                                                  String>(
                                                                value:
                                                                    'generate_$idx',
                                                                child: Text(
                                                                  label,
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .headlineSmall
                                                                      .override(
                                                                        fontFamily:
                                                                            'Outfit',
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .primaryText,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontSize:
                                                                            15.5,
                                                                      ),
                                                                ),
                                                              );
                                                            }),
                                                          if (docLink
                                                                  .isNotEmpty &&
                                                              docLink != 'null')
                                                            PopupMenuItem<
                                                                String>(
                                                              value:
                                                                  'opcion_dos',
                                                              child: Text(
                                                                'Ver documento',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontSize:
                                                                          15.5,
                                                                    ),
                                                              ),
                                                            ),
                                                          if (docLinkPDF
                                                                  .isNotEmpty &&
                                                              docLinkPDF !=
                                                                  'null' &&
                                                              showDocumentOptions)
                                                            PopupMenuItem<
                                                                String>(
                                                              value:
                                                                  'opcion_tres',
                                                              child: Text(
                                                                'Ver documento PDF',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .headlineSmall
                                                                    .override(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontSize:
                                                                          15.5,
                                                                    ),
                                                              ),
                                                            ),
                                                        ],
                                                        enabled: !isLoading,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryBackground,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: isLoading
                                                              ? SizedBox(
                                                                  width: 16.0,
                                                                  height: 16.0,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2.0,
                                                                    valueColor:
                                                                        AlwaysStoppedAnimation<
                                                                            Color>(
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Icon(
                                                                  Icons
                                                                      .more_vert,
                                                                  size: 18.0,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips(BuildContext context) {
    final filters = _filterProvider.filters;
    final dateRange = _filterProvider.dateRange;
    final hasFilters = filters.isNotEmpty;
    final hasDateRange = dateRange?.isNotEmpty ?? false;
    if (!hasFilters && !hasDateRange) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Manual filter chips
            for (int i = 0; i < filters.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: filters[i - 1].relation == 'OR'
                        ? FlutterFlowTheme.of(context)
                            .tertiary
                            .withValues(alpha: 0.12)
                        : FlutterFlowTheme.of(context)
                            .primary
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    filters[i - 1].relation == 'OR' ? 'O' : 'Y',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: filters[i - 1].relation == 'OR'
                          ? FlutterFlowTheme.of(context).tertiary
                          : FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              _buildFilterChip(context, filters[i], i),
            ],

            // Date range chip
            if (hasDateRange) ...[
              if (hasFilters) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context)
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Y',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              _buildDateRangeChip(context, dateRange!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, FilterModel filter, int index) {
    final fieldLabel = objetosNuevos
            .where((o) => o['slug'] == filter.key)
            .map((o) => o['label'])
            .firstOrNull ??
        filter.key;
    final conditionLabel =
        FilterConditions.labels[filter.condition] ?? filter.condition;
    final displayValue = filter.value == FilterTokens.empty
        ? '(vacío)'
        : filter.value == FilterTokens.notEmpty
            ? '(no vacío)'
            : filter.value;

    return GestureDetector(
      onTap: () => _openFilterDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$fieldLabel $conditionLabel "$displayValue"',
              style: TextStyle(
                fontSize: 11,
                color: FlutterFlowTheme.of(context).primaryText,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                _filterProvider.removeFilter(index);
              },
              child: Icon(
                Icons.close,
                size: 14,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeChip(BuildContext context, DateRangeFilter range) {
    const builtinLabels = {
      'published_date': 'Fecha de Publicación',
      'last_updated': 'Última Actualización',
    };
    final fieldLabel = objetosNuevos
            .where((o) => o['slug'] == range.fieldKey)
            .map((o) => o['label'])
            .firstOrNull ??
        builtinLabels[range.fieldKey] ??
        range.fieldKey;
    final dateFormat = DateFormat('dd/MM');
    final startStr = range.start != null ? dateFormat.format(range.start!) : '';
    final endStr = range.end != null ? dateFormat.format(range.end!) : '';
    final label = startStr.isNotEmpty && endStr.isNotEmpty
        ? '$startStr - $endStr'
        : startStr.isNotEmpty
            ? 'Desde $startStr'
            : 'Hasta $endStr';

    return GestureDetector(
      onTap: () => _openFilterDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 13,
              color: FlutterFlowTheme.of(context).primary,
            ),
            const SizedBox(width: 4),
            Text(
              '$fieldLabel $label',
              style: TextStyle(
                fontSize: 11,
                color: FlutterFlowTheme.of(context).primaryText,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                _filterProvider.clearDateRange();
              },
              child: Icon(
                Icons.close,
                size: 14,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary,
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: const AlignmentDirectional(0.0, 0.0),
        child: Text(
          functions.getShortName(FFAppState().fullName),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Outfit',
                color: FlutterFlowTheme.of(context).white,
                letterSpacing: 0.0,
              ),
        ),
      ),
    );
  }
}
