import 'dart:async';

import '/backend/api_requests/api_calls.dart';
import '/components/app_notification_bell/app_notification_bell_widget.dart';
import '/components/page_components/screens_background/background_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/web_view_viewer/web_view_viewer_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/services/home_initialization_service.dart';

import 'custom_dashboard_model.dart';
export 'custom_dashboard_model.dart';

class CustomDashboardWidget extends StatefulWidget {
  const CustomDashboardWidget({super.key});

  @override
  State<CustomDashboardWidget> createState() => _CustomDashboardWidgetState();
}

class _CustomDashboardWidgetState extends State<CustomDashboardWidget> {
  late CustomDashboardModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Kanban state
  List<Map<String, dynamic>> _kanbanColumns = [];
  String _kanbanKeyUsed = '';
  Map<String, Color> _kanbanColumnColors = {}; // status_label -> Color
  bool _kanbanLoading = true;
  String? _kanbanError;

  // Recent projects state
  List<dynamic> _recentProjects = [];
  bool _recentProjectsLoading = true;

  // Dashboard URL
  String? _dashboardUrl;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomDashboardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HomeInitializationService.runPostLoginChecks(context);
      await _loadDashboardUrl();
      await _loadKanban();
      await _loadRecentProjects();
    });
  }

  Future<void> _loadDashboardUrl() async {
    setState(() {
      _dashboardUrl = FFAppState().lookerStudio.isNotEmpty
          ? FFAppState().lookerStudio
          : null;
    });
  }

  Future<void> _loadKanban() async {
    final ctx = context;
    setState(() {
      _kanbanLoading = true;
      _kanbanError = null;
    });

    try {
      // Step 1: Get custom fields for 'proyectos' module
      final fieldsResponse = await GetCustomFieldsPerModuleCall.call(
        tenant: FFAppState().organizacion,
        moduleName: 'proyectos',
        token: FFAppState().token,
      );

      String kanbanKey = 'estado_general'; // default fallback

      if (fieldsResponse.succeeded) {
        final fieldsData = getJsonField(fieldsResponse.jsonBody, r'''$.data''', true) as List? ?? [];

        // Look for a field with field_type 'status' or slug containing 'estado'
        for (final field in fieldsData) {
          final fieldType = getJsonField(field, r'''$.field_type''')?.toString().toLowerCase() ?? '';
          final slug = getJsonField(field, r'''$.slug''')?.toString().toLowerCase() ?? '';
          if (fieldType == 'status' || slug.contains('estado')) {
            kanbanKey = getJsonField(field, r'''$.slug''')?.toString() ?? kanbanKey;
            // Parse options/choices to get color config
            final options = getJsonField(field, r'''$.options''', true) ?? getJsonField(field, r'''$.choices''', true);
            if (options != null) {
              final Map<String, Color> colorMap = {};
              if (options is List) {
                for (final opt in options) {
                  if (opt is Map) {
                    final label = (opt['label'] ?? opt['value'] ?? opt['name'] ?? '').toString().trim();
                    final colorRaw = (opt['color'] ?? opt['bg_color'] ?? opt['background_color'] ?? '').toString().trim().toLowerCase();
                    if (label.isNotEmpty) {
                      colorMap[label] = _parseColor(colorRaw, ctx);
                    }
                  } else {
                    final optStr = opt.toString();
                    final entries = optStr.split(',');
                    for (final entry in entries) {
                      final parts = entry.split('|');
                      if (parts.length >= 2) {
                        final label = parts[0].trim();
                        final colorName = parts[1].trim().toLowerCase();
                        colorMap[label] = _parseColor(colorName, ctx);
                      } else if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
                        final label = parts[0].trim();
                        colorMap[label] = FlutterFlowTheme.of(ctx).secondary;
                      }
                    }
                  }
                }
              } else if (options is Map) {
                options.forEach((key, value) {
                  String colorName = '';
                  if (value is Map) {
                    colorName = (value['color'] ?? value['bg_color'] ?? '').toString().toLowerCase();
                  } else if (value is String) {
                    final parts = value.split('|');
                    colorName = parts.length > 1 ? parts[1].trim().toLowerCase() : parts[0].trim().toLowerCase();
                  }
                  colorMap[key.toString()] = _parseColor(colorName, ctx);
                });
              }
              _kanbanColumnColors = colorMap;
            }
            break;
          }
        }
      }

      _kanbanKeyUsed = kanbanKey;

      if (kanbanKey.isEmpty) {
        kanbanKey = 'estado_general';
        _kanbanKeyUsed = kanbanKey;
      }

      // Step 2: Get registers from 'proyectos' module
      final registersResponse = await GetDataModulesCall.call(
        tenant: FFAppState().organizacion,
        module: 'proyectos',
        moduleType: 'registers',
        limit: 50,
        page: 1,
        token: FFAppState().token,
      );

      if (registersResponse.succeeded) {
        final registers = getJsonField(registersResponse.jsonBody, r'''$.data''', true) as List? ?? [];

        // Step 3: Group by kanbanKey
        final Map<String, List<dynamic>> groupedData = {};
        for (final register in registers) {
          final jsonData = getJsonField(register, r'''$.json_data''') ?? {};

          String statusValue = 'sin estado';
          if (jsonData is Map && jsonData.containsKey(kanbanKey)) {
            statusValue = jsonData[kanbanKey]?.toString().toLowerCase() ?? 'sin estado';
          } else if (jsonData is Map) {
            final matchingKey = jsonData.keys.cast<String?>().firstWhere(
              (k) => k?.toLowerCase() == kanbanKey.toLowerCase(),
              orElse: () => null,
            );
            if (matchingKey != null) {
              statusValue = jsonData[matchingKey]?.toString().toLowerCase() ?? 'sin estado';
            }
          }

          if (!groupedData.containsKey(statusValue)) {
            groupedData[statusValue] = [];
          }
          groupedData[statusValue]!.add(register);
        }

        // Step 4: Build columns
        final List<Map<String, dynamic>> columns = [];

        // Use color map keys for column order, otherwise use found keys
        final List<String> columnOrder = _kanbanColumnColors.isNotEmpty
            ? _kanbanColumnColors.keys.toList()
            : groupedData.keys.toList();

        for (final columnName in columnOrder) {
          final items = groupedData[columnName] ?? [];
          columns.add({
            'name': columnName,
            'items': items,
          });
        }

        // Add any columns not in options
        for (final key in groupedData.keys) {
          if (!columnOrder.contains(key)) {
            columns.add({
              'name': key,
              'items': groupedData[key]!,
            });
          }
        }

        setState(() {
          _kanbanColumns = columns;
          _kanbanLoading = false;
        });
      } else {
        _kanbanError = 'Error al cargar registros de proyectos';
        setState(() {
          _kanbanLoading = false;
        });
      }
    } catch (e) {
      _kanbanError = 'Error: $e';
      setState(() {
        _kanbanLoading = false;
      });
    }
  }

  Future<void> _loadRecentProjects() async {
    setState(() {
      _recentProjectsLoading = true;
    });

    try {
      final response = await GetDataModulesCall.call(
        tenant: FFAppState().organizacion,
        module: 'proyectos_2',
        moduleType: 'registers',
        limit: 20,
        page: 1,
        token: FFAppState().token,
      );

      if (response.succeeded) {
        final data = getJsonField(response.jsonBody, r'''$.data''', true) as List? ?? [];
        setState(() {
          _recentProjects = data;
          _recentProjectsLoading = false;
        });
      } else {
        setState(() {
          _recentProjectsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _recentProjectsLoading = false;
      });
    }
  }

  Color _parseColor(String colorText, [BuildContext? ctx]) {
    final theme = ctx != null ? FlutterFlowTheme.of(ctx) : null;
    switch (colorText) {
      case 'warning':
        return Colors.orangeAccent;
      case 'info':
        return Colors.deepPurpleAccent;
      case 'primary':
        return Colors.blueAccent;
      case 'success':
        return Colors.green;
      case 'danger':
        return Colors.red;
      case 'dark':
        return Colors.black54;
      default:
        return theme?.secondary ?? Colors.grey;
    }
  }

  String _formatLastUpdated(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Ahora';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
      return DateFormat('dd/MM/yy').format(dt);
    } catch (e) {
      // Try to return a shortened version of the raw timestamp
      if (timestamp.length > 10) return timestamp.substring(0, 10);
      return timestamp;
    }
  }

  Color _getKanbanColumnColor(String status) {
    // Try exact match first
    if (_kanbanColumnColors.containsKey(status)) {
      return _kanbanColumnColors[status]!;
    }
    // Try case-insensitive match
    final lowerStatus = status.toLowerCase();
    for (final entry in _kanbanColumnColors.entries) {
      if (entry.key.toLowerCase() == lowerStatus) {
        return entry.value;
      }
    }
    // Fallback to default badge color logic
    return _getBadgeColor(status);
  }

  Color _getBadgeColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('planeaci') || statusLower.contains('planeacion')) {
      return FlutterFlowTheme.of(context).primary;
    } else if (statusLower.contains('activo')) {
      return FlutterFlowTheme.of(context).success;
    } else if (statusLower.contains('sustent') || statusLower.contains('suspend')) {
      return FlutterFlowTheme.of(context).warning;
    } else if (statusLower.contains('finalizado') || statusLower.contains('completado')) {
      return FlutterFlowTheme.of(context).info;
    }
    return FlutterFlowTheme.of(context).secondary;
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final clientName = FFAppState().fullName;
    final clientLogoUrl = FFAppState().logoLink;

    Color bottomLeftColor = FlutterFlowTheme.of(context).accent3.withOpacity(1);
    Color topRightColor = FlutterFlowTheme.of(context).primary.withOpacity(0.7);

    return WillPopScope(
      onWillPop: () async => false,
      child: Stack(
        children: [
          Scaffold(
            key: scaffoldKey,
            backgroundColor: Colors.transparent,
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
              title: Align(
                alignment: const AlignmentDirectional(0.0, 0.0),
                child: Text(
                  'Panel Dashboard',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        color: FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.0,
                      ),
                ),
              ),
              actions: const [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                  child: AppNotificationBell(),
                ),
              ],
              centerTitle: true,
              elevation: 0,
            ),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  DynamicBackground(
                    bottomLeftColor: bottomLeftColor,
                    topRightColor: topRightColor,
                  ),
                  RefreshIndicator(
                    onRefresh: () async {
                      await _loadKanban();
                      await _loadRecentProjects();
                    },
                    child: SingleChildScrollView(
                      primary: true,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Section 1: Header with client info
                        _buildClientHeader(clientName, clientLogoUrl),

                        // Section 2: Embedded dashboard (reduced height: 300px)
                        if (_dashboardUrl != null)
                          _buildEmbeddedDashboard(_dashboardUrl!),

                        // Section 3: Kanban board
                        _buildKanbanSection(),

                        // Section 4: Recent projects cards
                        _buildRecentProjectsSection(),
                      ],
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientHeader(String clientName, String? clientLogoUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (clientLogoUrl != null && clientLogoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 16, 0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                ),
                child: ClipOval(
                  child: Image.network(
                    clientLogoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.business,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientName,
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Panel Dashboard',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Outfit',
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedDashboard(String url) {
    return Container(
      width: double.infinity,
      height: 300, // Reduced from 600 to 300 (half)
      margin: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewViewerWidget(
          url: url,
          title: 'Dashboard',
        ),
      ),
    );
  }

  Widget _buildKanbanSection() {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
            child: Row(
              children: [
                Text(
                  'Proyectos - Kanban',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
                // Debug info badge
                if (_kanbanKeyUsed.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'key: $_kanbanKeyUsed | ${_kanbanColumns.length} cols | ${_kanbanColumns.fold<int>(0, (sum, c) => sum + (c['items'] as List).length)} items',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _kanbanLoading
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                )
              : _kanbanError != null
                  ? Container(
                      height: 100,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Kanban error',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _kanbanError!,
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Outfit',
                                  color: Colors.red,
                                ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _loadKanban,
                            child: Text(
                              'Tap to retry',
                              style: TextStyle(
                                color: FlutterFlowTheme.of(context).primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _kanbanColumns.isEmpty
                      ? Container(
                          height: 100,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'No hay proyectos en el kanban (key: $_kanbanKeyUsed)',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Outfit',
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(
                          height: 380, // Increased from 300 for larger cards
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _kanbanColumns.length,
                            itemBuilder: (context, columnIndex) {
                              final column = _kanbanColumns[columnIndex];
                              final columnName = column['name'] as String;
                              final items = column['items'] as List<dynamic>;
                              // Use color from custom field config with case-insensitive matching
                              final badgeColor = _getKanbanColumnColor(columnName);

                              return Container(
                                width: 340, // Increased from 280 for bigger cards
                                margin: EdgeInsets.only(
                                  right: columnIndex < _kanbanColumns.length - 1 ? 12 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: badgeColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Column header
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.15),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              columnName.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                    fontFamily: 'Outfit',
                                                    fontWeight: FontWeight.w700,
                                                    color: FlutterFlowTheme.of(context).primaryText,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              items.length.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Cards list
                                    Expanded(
                                      child: items.isEmpty
                                          ? const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text(
                                                  'Sin registros',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              padding: const EdgeInsets.all(8),
                                              itemCount: items.length,
                                              itemBuilder: (context, itemIndex) {
                                                final item = items[itemIndex];
                                                final title = getJsonField(item, r'''$.title''')?.toString() ?? 'Sin título';
                                                final descripcion = getJsonField(item, r'''$.json_data.descripcion''')?.toString() ?? '';
                                                
                                                // Assigned user info
                                                final assignedUser = getJsonField(item, r'''$.json_data.ref_usuario_asignado_a_proyecto''') ?? {};
                                                final assignedUserLabel = getJsonField(assignedUser, r'''$.label''')?.toString() ?? '';
                                                final assignedUserAvatar = getJsonField(assignedUser, r'''$.avatar''')?.toString() ?? '';
                                                
                                                // Last updated
                                                final lastUpdated = getJsonField(item, r'''$.last_updated''')?.toString() ?? '';

                                                return InkWell(
                                                  onTap: () async {
                                                    context.pushNamed(
                                                      'detailGrouped',
                                                      queryParameters: {
                                                        'title': serializeParam(title, ParamType.String),
                                                        'body': serializeParam(descripcion, ParamType.String),
                                                        'general': serializeParam(item, ParamType.JSON),
                                                      }.withoutNulls,
                                                    );
                                                  },
                                                  child: Container(
                                                    margin: const EdgeInsets.only(bottom: 10),
                                                    decoration: BoxDecoration(
                                                      color: FlutterFlowTheme.of(context).primaryBackground,
                                                      borderRadius: BorderRadius.circular(10),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.06),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    padding: const EdgeInsets.all(12),
                                                    child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Title
                                                      Text(
                                                        title,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: FlutterFlowTheme.of(context).titleMedium.override(
                                                              fontFamily: 'Outfit',
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 14,
                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                            ),
                                                      ),
                                                      if (descripcion.isNotEmpty) ...[
                                                        const SizedBox(height: 5),
                                                        Text(
                                                          descripcion,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                fontFamily: 'Outfit',
                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                              ),
                                                        ),
                                                      ],
                                                      const SizedBox(height: 8),
                                                      // Divider
                                                      Divider(
                                                        height: 1,
                                                        color: FlutterFlowTheme.of(context).secondaryText.withOpacity(0.15),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Assigned user row
                                                      if (assignedUserLabel.isNotEmpty)
                                                        Padding(
                                                          padding: const EdgeInsets.only(bottom: 6),
                                                          child: Row(
                                                            children: [
                                                              // Avatar
                                                              if (assignedUserAvatar.isNotEmpty)
                                                                Container(
                                                                  width: 24,
                                                                  height: 24,
                                                                  decoration: BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                  ),
                                                                  child: ClipOval(
                                                                    child: Image.network(
                                                                      'https://${FFAppState().organizacion}.itsquery.com$assignedUserAvatar',
                                                                      fit: BoxFit.cover,
                                                                      errorBuilder: (_, __, ___) => Icon(
                                                                        Icons.person,
                                                                        size: 14,
                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              else
                                                                Container(
                                                                  width: 24,
                                                                  height: 24,
                                                                  decoration: BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    color: badgeColor.withOpacity(0.2),
                                                                  ),
                                                                  child: Icon(
                                                                    Icons.person,
                                                                    size: 14,
                                                                    color: badgeColor,
                                                                  ),
                                                                ),
                                                              const SizedBox(width: 6),
                                                              Expanded(
                                                                child: Text(
                                                                  assignedUserLabel,
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                        fontFamily: 'Outfit',
                                                                        fontWeight: FontWeight.w500,
                                                                        color: FlutterFlowTheme.of(context).primaryText,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      // Last updated row
                                                      if (lastUpdated.isNotEmpty)
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              _formatLastUpdated(lastUpdated),
                                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                    fontFamily: 'Outfit',
                                                                    color: FlutterFlowTheme.of(context).secondaryText,
                                                                    fontSize: 11,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
        ],
      ),
    );
  }

  Widget _buildRecentProjectsSection() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - 60 - 16) / 2; // 2 columns with gap

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
            child: Text(
              'Proyectos Recientes',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
          ),
          _recentProjectsLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                )
              : _recentProjects.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No hay proyectos recientes',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _recentProjects.map((registro) {
                        final title = getJsonField(registro, r'''$.title''')?.toString() ?? 'Sin título';
                        final descripcion = getJsonField(registro, r'''$.json_data.descripcion''')?.toString() ?? '';
                        final estado = getJsonField(registro, r'''$.json_data.estado_general''')?.toString() ?? 'Sin estado';
                        final badgeColor = _getBadgeColor(estado);

                        return SizedBox(
                          width: cardWidth,
                          child: InkWell(
                            onTap: () async {
                              context.pushNamed(
                                'detailGrouped',
                                queryParameters: {
                                  'title': serializeParam(title, ParamType.String),
                                  'body': serializeParam(descripcion, ParamType.String),
                                  'general': serializeParam(registro, ParamType.JSON),
                                }.withoutNulls,
                              );
                            },
                            child: Hero(
                              tag: title.hashCode,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border(
                                    top: BorderSide(
                                      color: badgeColor,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: FlutterFlowTheme.of(context).titleMedium.override(
                                              fontFamily: 'Outfit',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: FlutterFlowTheme.of(context).primaryText,
                                            ),
                                      ),
                                      if (descripcion.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          descripcion,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                                fontFamily: 'Outfit',
                                                color: FlutterFlowTheme.of(context).secondaryText,
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              estado,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                    fontFamily: 'Outfit',
                                                    fontWeight: FontWeight.w600,
                                                    color: badgeColor,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }
}
