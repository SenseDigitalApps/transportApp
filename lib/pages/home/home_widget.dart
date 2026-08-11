import 'dart:async';

import 'package:transport_app/components/page_components/loader_image/loader_image.dart';
import 'package:transport_app/pages/chat_mode/widgets/chat_mode_toggle_button.dart';
import '../../components/page_components/screens_background/background_widget.dart';
import '../../flutter_flow/flutter_flow_expanded_image_view.dart';
import '/backend/api_requests/api_calls.dart';
import '/components/empty_component/empty_component_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/services/home_initialization_service.dart';
import '/widgets/cached_avatar_image.dart';
import 'home_model.dart';
export 'home_model.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  late HomeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _model = createModel(context, () => HomeModel());

    _groupedModulesFuture = _getModulesAndCategories(); // carga inicial

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HomeInitializationService.runPostLoginChecks(context);
      await fetchUnreadNotifications();
    });

    Timer.periodic(const Duration(seconds: 240), (timer) {
      fetchUnreadNotifications();
    });

    fetchRoleGroups();
    // _getModules(); // opcional si ya cargas modulos en _getModulesAndCategories
  }

  Future<Map<String, dynamic>>? _groupedModulesFuture;
  int? _expandedActiveCategoryId; // carrusel "Modulos activos"
  int? _expandedMastersCategoryId; // carrusel "Formatos"

  Future<Map<String, dynamic>> _getModulesAndCategories() async {
    final futures = await Future.wait([
      CategorizedModulesCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      ),
      ModulosCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      ),
    ]);

    final categoriesResponse = futures[0];
    final modulesResponse = futures[1];

    final categories =
        CategorizedModulesCall.data(categoriesResponse.jsonBody) ?? [];
    final allModules = ModulosCall.data(modulesResponse.jsonBody) ?? [];

    // Guarda modulos en AppState (por si otras pantallas lo usan)
    FFAppState().update(() {
      FFAppState().moduleList = allModules;
    });

    return {
      'categories': categories,
      'modules': allModules,
    };
  }

  bool _hasModulePermission(dynamic module) {
    final moduleName =
        getJsonField(module, r'''$.name''').toString().toLowerCase();
    return functions.hasAnyPermissionForModule(
            FFAppState().permissions.toList(), moduleName) ||
        functions.hasPermission(
            FFAppState().permissions.toList(), 'query_-_ver', moduleName);
  }

  List<dynamic> _modulesForCategory(
      List<int> relatedModuleIds, List<dynamic> allModules) {
    return allModules.where((m) {
      final id = castToType<int>(getJsonField(m, r'''$.id'''));
      return id != null && relatedModuleIds.contains(id);
    }).toList();
  }

  List<dynamic> _filterCategoriesWithVisibleModules(
    List<dynamic> categories,
    List<dynamic> modulesSource,
  ) {
    return categories.where((c) {
      final relatedModuleIds =
          (getJsonField(c, r'''$.related_modules''', true) as List?)
                  ?.map((e) => castToType<int>(e))
                  .where((e) => e != null)
                  .cast<int>()
                  .toList() ??
              [];

      if (relatedModuleIds.isEmpty) return false;

      final categoryModules =
          _modulesForCategory(relatedModuleIds, modulesSource);
      final visible = categoryModules.where(_hasModulePermission).toList();

      return visible.isNotEmpty;
    }).toList();
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    String? countLabel,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  FlutterFlowTheme.of(context).primary.withOpacity(0.20),
                  FlutterFlowTheme.of(context).secondary.withOpacity(0.24),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.18),
              ),
            ),
            child: Icon(
              icon,
              color: FlutterFlowTheme.of(context).primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                        fontFamily: 'Outfit',
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Outfit',
                        letterSpacing: 0.0,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
          if (countLabel != null && countLabel.isNotEmpty)
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.18),
                ),
              ),
              child: Text(
                countLabel,
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      fontFamily: 'Outfit',
                      color: FlutterFlowTheme.of(context).primary,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openRecentRegister(dynamic recientesItem) async {
    context.pushNamed(
      'detailGrouped',
      queryParameters: {
        'title': serializeParam(
          getJsonField(recientesItem, r'''$.title''').toString(),
          ParamType.String,
        ),
        'body': serializeParam(
          getJsonField(recientesItem, r'''$.body''').toString(),
          ParamType.String,
        ),
        'general': serializeParam(
          recientesItem,
          ParamType.JSON,
        ),
      }.withoutNulls,
    );

    final newItemId = getJsonField(recientesItem, r'''$.id''').toString();
    int existingIndex = -1;
    for (int i = 0; i < FFAppState().recientes.length; i++) {
      final currentItemId =
          getJsonField(FFAppState().recientes[i], r'''$.id''').toString();
      if (currentItemId == newItemId) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      FFAppState().removeAtIndexFromRecientes(existingIndex);
    }
    FFAppState().insertAtIndexInRecientes(0, recientesItem);
    setState(() {});
  }

  Widget _buildRecentInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: FlutterFlowTheme.of(context).secondaryText,
        ),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: FlutterFlowTheme.of(context).labelMedium.override(
                fontFamily: 'Outfit',
                letterSpacing: 0.0,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Outfit',
                  letterSpacing: 0.0,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRegisterCard(dynamic recientesItem) {
    final title = getJsonField(recientesItem, r'''$.title''').toString();
    final moduleIcon =
        getJsonField(recientesItem, r'''$.modulo_info.icon''').toString();
    final consecutivo =
        getJsonField(recientesItem, r'''$.consecutivo''').toString();
    final publishedDate =
        getJsonField(recientesItem, r'''$.published_date''').toString();
    final lastUpdated =
        getJsonField(recientesItem, r'''$.last_updated''').toString();
    final authorName =
        getJsonField(recientesItem, r'''$.profile_info.full_name''').toString();
    final avatarUrl =
        'https://${FFAppState().organizacion}.itsquery.com${getJsonField(recientesItem, r'''$.profile_info.avatar''').toString()}';

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => _openRecentRegister(recientesItem),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.86,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.18),
                          FlutterFlowTheme.of(context)
                              .secondary
                              .withOpacity(0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      functions.getIconData(moduleIcon),
                      color: FlutterFlowTheme.of(context).primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentInfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Consecutivo',
                value: consecutivo,
              ),
              const SizedBox(height: 6),
              _buildRecentInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Publicacion',
                value: publishedDate,
              ),
              const SizedBox(height: 6),
              _buildRecentInfoRow(
                icon: Icons.update_outlined,
                label: 'Ultima actualizacion',
                value: lastUpdated,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.network(
                      avatarUrl,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/app_launcher_icon.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Outfit',
                            letterSpacing: 0.0,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeModuleCard(dynamic moduleItem) {
    final icon = getJsonField(moduleItem, r'''$.icon''').toString();
    final title = getJsonField(moduleItem, r'''$.label''').toString();
    final description =
        getJsonField(moduleItem, r'''$.description''').toString();

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        context.pushNamed(
          'singlePage',
          queryParameters: {
            'moduleName': serializeParam(
                getJsonField(moduleItem, r'''$.name''').toString(),
                ParamType.String),
            'icon': serializeParam(
                getJsonField(moduleItem, r'''$.icon''').toString(),
                ParamType.String),
            'moduleType': serializeParam(
                getJsonField(moduleItem, r'''$.type''').toString(),
                ParamType.String),
            'moduleData': serializeParam(moduleItem, ParamType.JSON),
            'moduleId': serializeParam(
                getJsonField(moduleItem, r'''$.id''').toString(),
                ParamType.String),
          }.withoutNulls,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 18.0,
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0.0, 8.0),
                spreadRadius: 0.0,
              )
            ],
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(14.0, 12.0, 12.0, 12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      FlutterFlowTheme.of(context).primary.withOpacity(0.18),
                      FlutterFlowTheme.of(context).secondary.withOpacity(0.22),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  functions.getIconData(icon),
                  color: FlutterFlowTheme.of(context).primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Outfit',
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: FlutterFlowTheme.of(context).primaryText),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Outfit',
                            letterSpacing: 0.0,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeSingleModuleParent(dynamic moduleItem) {
    final title = getJsonField(moduleItem, r'''$.label''').toString();
    final desc = getJsonField(moduleItem, r'''$.description''').toString();
    final icon = getJsonField(moduleItem, r'''$.icon''').toString();

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          context.pushNamed(
            'singlePage',
            queryParameters: {
              'moduleName': serializeParam(
                  getJsonField(moduleItem, r'''$.name''').toString(),
                  ParamType.String),
              'icon': serializeParam(icon, ParamType.String),
              'moduleType': serializeParam(
                  getJsonField(moduleItem, r'''$.type''').toString(),
                  ParamType.String),
              'moduleData': serializeParam(moduleItem, ParamType.JSON),
              'moduleId': serializeParam(
                  getJsonField(moduleItem, r'''$.id''').toString(),
                  ParamType.String),
            }.withoutNulls,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FlutterFlowTheme.of(context).primary.withOpacity(0.18),
                      FlutterFlowTheme.of(context).secondary.withOpacity(0.24),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  functions.getIconData(icon),
                  color: FlutterFlowTheme.of(context).primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            fontFamily: 'Outfit',
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Outfit',
                              letterSpacing: 0.0,
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeCategorySection(
    dynamic categoryItem,
    List<dynamic> modulesSource, {
    required int? expandedId,
    required ValueChanged<int?> onToggle,
  }) {
    final categoryId =
        castToType<int>(getJsonField(categoryItem, r'''$.id''')) ?? -9999;
    final title = getJsonField(categoryItem, r'''$.title''').toString();
    final desc = getJsonField(categoryItem, r'''$.description''').toString();
    final icon = getJsonField(categoryItem, r'''$.icon''').toString();

    final relatedModuleIds =
        (getJsonField(categoryItem, r'''$.related_modules''', true) as List?)
                ?.map((e) => castToType<int>(e))
                .where((e) => e != null)
                .cast<int>()
                .toList() ??
            [];

    final isExpanded = expandedId == categoryId;
    final categoryModules =
        _modulesForCategory(relatedModuleIds, modulesSource);
    final visibleModules = categoryModules.where(_hasModulePermission).toList();
    if (visibleModules.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => setState(() {
              onToggle(isExpanded ? null : categoryId);
            }),
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 12, 14),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      )
                    : BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.18),
                          FlutterFlowTheme.of(context)
                              .secondary
                              .withOpacity(0.24),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      functions.getIconData(icon),
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText),
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Outfit',
                                      letterSpacing: 0.0,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 8, 5),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      visibleModules.length.toString(),
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).primary,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      FlutterFlowTheme.of(context).secondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < visibleModules.length; i++) ...[
                        if (i > 0) const SizedBox(height: 5),
                        _buildHomeModuleCard(visibleModules[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> fetchRoleGroups() async {
    try {
      final response = await GetRoleGroups.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );
      if (response.succeeded) {
        final data = response.jsonBody;
        setState(() {
          FFAppState().roleGroups = data['data'];
        });
      }
    } catch (e) {
      print('Error al obtener grupos de roles');
    }
  }

  Future<void> fetchUnreadNotifications() async {
    try {
      final response = await GetNotificationsCount.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      if (response.succeeded) {
        final data = response.jsonBody;
        setState(() {
          FFAppState().unreadNotifications = data['count'] ?? "0";
        });
      }
    } catch (e) {}
  }

  Future<void> _getModules() async {
    try {
      final response = await ModulosCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      final data = response.jsonBody['data'];
      if (data is List) {
        FFAppState().update(() {
          FFAppState().moduleList = data;
        });
      }
    } catch (e) {
      print('Error al cargar los modulos: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si realmente quieres refrescar:
    // _groupedModulesFuture = _getModulesAndCategories();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bottomLeftColor = FlutterFlowTheme.of(context).accent3.withOpacity(1);
    Color topRightColor = FlutterFlowTheme.of(context).primary.withOpacity(0.7);
    context.watch<FFAppState>();
    final loaderBackground = FFAppState().fondoLink.isEmpty
        ? 'https://us.itsquery.com/mediafiles/auth/bg9-dark.jpg'
        : FFAppState().fondoLink;
    return WillPopScope(
        onWillPop: () async => false,
        child: Stack(
          children: [
            Scaffold(
              key: scaffoldKey,
              // backgroundColor: const Color(0xFFE5E8EB),
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
                iconTheme:
                    IconThemeData(color: FlutterFlowTheme.of(context).primary),
                automaticallyImplyLeading: false,
                leadingWidth: 96.0,
                leading: ChatModeLeading(scaffoldKey: scaffoldKey),
                toolbarHeight: 74.0,
                title: Align(
                  alignment: const AlignmentDirectional(0.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Pantalla',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Outfit',
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                      Text(
                        'Home',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FlutterFlowTheme.of(context)
                            .titleMedium
                            .override(
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
                      GestureDetector(
                        onTap: () {
                          context.pushNamed('notificationsScreen');
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              5.0, 5.0, 10.0, 5.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 38.0,
                                height: 38.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.16),
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 20.0,
                                ),
                              ),
                              if (FFAppState().unreadNotifications > 0)
                                Positioned(
                                  right: -4.0,
                                  top: -2.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.red, // Color del contador
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18.0,
                                      minHeight: 18.0,
                                    ),
                                    child: Text(
                                      FFAppState()
                                          .unreadNotifications
                                          .toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.pushNamed('taskScreen'); // <-- tu ruta
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              5.0, 5.0, 10.0, 5.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 38.0,
                                height: 38.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.16),
                                  ),
                                ),
                                child: Icon(
                                  Icons.task_alt, // o Icons.assignment_outlined
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 20.0,
                                ),
                              ),
                              if (FFAppState().pendingTasks >
                                  0) // <-- tu contador
                                Positioned(
                                  right: -4.0,
                                  top: -2.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18.0,
                                      minHeight: 18.0,
                                    ),
                                    child: Text(
                                      FFAppState().pendingTasks.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                centerTitle: true,
                elevation: 0,
              ),
              body: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                      // color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                  child: Stack(
                    children: [
                      DynamicBackground(
                        bottomLeftColor: bottomLeftColor,
                        topRightColor: topRightColor,
                      ),
                      SingleChildScrollView(
                        primary: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  20, 0, 20, 0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    14, 14, 14, 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: LinearGradient(
                                    colors: [
                                      FlutterFlowTheme.of(context)
                                          .primary
                                          .withOpacity(0.36),
                                      FlutterFlowTheme.of(context)
                                          .secondary
                                          .withOpacity(0.40),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 78,
                                      height: 78,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .primary
                                              .withOpacity(0.28),
                                          width: 1.4,
                                        ),
                                      ),
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            PageTransition(
                                              type: PageTransitionType.fade,
                                              child:
                                                  FlutterFlowExpandedImageView(
                                                image: CachedAvatarImage(
                                                  imageUrl:
                                                      'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}',
                                                  width: 300.0,
                                                  height: 200.0,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Image.asset(
                                                      'assets/images/app_launcher_icon.png',
                                                      width: 300.0,
                                                      height: 200.0,
                                                      fit: BoxFit.contain,
                                                    );
                                                  },
                                                ),
                                                allowRotation: false,
                                                tag:
                                                    'https://${valueOrDefault<String>(
                                                  FFAppState().organizacion,
                                                  'api',
                                                )}.itsquery.com${FFAppState().avatar}home1',
                                                useHeroAnimation: true,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Hero(
                                          tag:
                                              'https://${valueOrDefault<String>(
                                            FFAppState().organizacion,
                                            'api',
                                          )}.itsquery.com${FFAppState().avatar}home2',
                                          transitionOnUserGestures: true,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: CachedAvatarImage(
                                              imageUrl:
                                                  'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/images/app_launcher_icon.png',
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'BIENVENIDOS',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: FlutterFlowTheme.of(context)
                                                .labelLarge
                                                .override(
                                                  fontFamily: 'Outfit',
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.8,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            FFAppState().fullName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.0,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(10, 5, 10, 5),
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground
                                                      .withOpacity(0.72),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              FFAppState().role,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily: 'Outfit',
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryText,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.0,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            FutureBuilder<Map<String, dynamic>>(
                              future: _groupedModulesFuture ??=
                                  _getModulesAndCategories(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 20, 0, 20),
                                    child: Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final categories = (snapshot.data!['categories']
                                        as List<dynamic>?) ??
                                    [];
                                final allModules = (snapshot.data!['modules']
                                        as List<dynamic>?) ??
                                    [];

                                if (categories.isEmpty && allModules.isEmpty) {
                                  return const Center(
                                      child: EmptyComponentWidget());
                                }

                                // Ordenar categorias por priority (igual que sidenav)
                                categories.sort((a, b) {
                                  final pa =
                                      getJsonField(a, r'''$.priority''') ?? 999;
                                  final pb =
                                      getJsonField(b, r'''$.priority''') ?? 999;
                                  return pa.compareTo(pb);
                                });

                                // 1) Ordenar categorias
                                // Ordenar categorias por priority (una sola vez)
                                categories.sort((a, b) {
                                  final pa =
                                      getJsonField(a, r'''$.priority''') ?? 999;
                                  final pb =
                                      getJsonField(b, r'''$.priority''') ?? 999;
                                  return pa.compareTo(pb);
                                });

                                // 2) Separar modulos
                                final activeModules = allModules.where((m) {
                                  final type = getJsonField(m, r'''$.type''')
                                      .toString()
                                      .toLowerCase();
                                  final replaceHome =
                                      getJsonField(m, r'''$.replace_home''');
                                  return type != 'masters' &&
                                      replaceHome != true;
                                }).toList();

                                final mastersModules = allModules.where((m) {
                                  final type = getJsonField(m, r'''$.type''')
                                      .toString()
                                      .toLowerCase();
                                  final replaceHome =
                                      getJsonField(m, r'''$.replace_home''');
                                  return type == 'masters' &&
                                      replaceHome != true;
                                }).toList();

                                // ids que estan en alguna categoria
                                final Set<int> relatedIdsAll = {};
                                for (final c in categories) {
                                  final rel = (getJsonField(
                                              c,
                                              r'''$.related_modules''',
                                              true) as List?)
                                          ?.map((e) => castToType<int>(e))
                                          .where((e) => e != null)
                                          .cast<int>()
                                          .toList() ??
                                      [];
                                  relatedIdsAll.addAll(rel);
                                }

// categorias visibles (reales)
                                final activeCategoriesVisible =
                                    _filterCategoriesWithVisibleModules(
                                        categories, activeModules);

                                final mastersCategoriesVisible =
                                    _filterCategoriesWithVisibleModules(
                                        categories, mastersModules);

// modulos sueltos (sin grupo) + permisos
                                final ungroupedActiveVisible =
                                    activeModules.where((m) {
                                  final id = castToType<int>(
                                      getJsonField(m, r'''$.id'''));
                                  return id != null &&
                                      !relatedIdsAll.contains(id) &&
                                      _hasModulePermission(m);
                                }).toList();

                                final ungroupedMastersVisible =
                                    mastersModules.where((m) {
                                  final id = castToType<int>(
                                      getJsonField(m, r'''$.id'''));
                                  return id != null &&
                                      !relatedIdsAll.contains(id) &&
                                      _hasModulePermission(m);
                                }).toList();

                                final activeCarouselItems = [
                                  ...ungroupedActiveVisible.map(
                                      (m) => {'kind': 'module', 'data': m}),
                                  ...activeCategoriesVisible.map(
                                      (c) => {'kind': 'category', 'data': c}),
                                ];

                                final mastersCarouselItems = [
                                  ...ungroupedMastersVisible.map(
                                      (m) => {'kind': 'module', 'data': m}),
                                  ...mastersCategoriesVisible.map(
                                      (c) => {'kind': 'category', 'data': c}),
                                ];

                                // Si quedo expandida una categoria que ya no existe (por permisos), resetea
                                if (_expandedActiveCategoryId != null &&
                                    !activeCategoriesVisible.any((c) =>
                                        castToType<int>(
                                            getJsonField(c, r'''$.id''')) ==
                                        _expandedActiveCategoryId)) {
                                  _expandedActiveCategoryId = null;
                                }

                                if (_expandedMastersCategoryId != null &&
                                    !mastersCategoriesVisible.any((c) =>
                                        castToType<int>(
                                            getJsonField(c, r'''$.id''')) ==
                                        _expandedMastersCategoryId)) {
                                  _expandedMastersCategoryId = null;
                                }

                                // Compute carousel heights dynamically so all modules in the
                                // expanded category are visible without nested scroll conflicts.
                                double _carouselHeight(
                                    int? expandedId,
                                    List<dynamic> visibleCats,
                                    List<dynamic> modulesSource) {
                                  if (expandedId == null) return 110;
                                  for (final c in visibleCats) {
                                    if (castToType<int>(
                                            getJsonField(c, r'''$.id''')) !=
                                        expandedId) continue;
                                    final relIds = (getJsonField(
                                                c,
                                                r'''$.related_modules''',
                                                true) as List?)
                                            ?.map((e) => castToType<int>(e))
                                            .where((e) => e != null)
                                            .cast<int>()
                                            .toList() ??
                                        [];
                                    final n = _modulesForCategory(
                                            relIds, modulesSource)
                                        .where(_hasModulePermission)
                                        .length;
                                    // header(74) + bottom_pad(12) + inner_pad(20) + items + separators
                                    return (74 +
                                            12 +
                                            20 +
                                            n * 85 +
                                            (n > 1 ? (n - 1) * 5 : 0) +
                                            12)
                                        .toDouble();
                                  }
                                  return 110;
                                }

                                final double activeCarouselHeight =
                                    _carouselHeight(_expandedActiveCategoryId,
                                        activeCategoriesVisible, activeModules);
                                final double mastersCarouselHeight =
                                    _carouselHeight(
                                        _expandedMastersCategoryId,
                                        mastersCategoriesVisible,
                                        mastersModules);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    _buildSectionHeader(
                                      title: 'Modulos',
                                      subtitle:
                                          'Accesos disponibles para este usuario',
                                      icon: Icons.dashboard_customize_outlined,
                                      countLabel:
                                          activeCarouselItems.length.toString(),
                                    ),
                                    const SizedBox(height: 12),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeInOut,
                                      height: activeCarouselHeight,
                                      child: ListView.separated(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(20, 0, 20, 0),
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: activeCarouselItems.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 5),
                                        itemBuilder: (context, index) {
                                          final item =
                                              activeCarouselItems[index];
                                          final kind = item['kind'] as String;

                                          return Align(
                                            alignment: Alignment.topCenter,
                                            child: SizedBox(
                                              width: MediaQuery.sizeOf(context)
                                                      .width *
                                                  (kind == 'category'
                                                      ? 0.82
                                                      : 0.74),
                                              child: kind == 'category'
                                                  ? _buildHomeCategorySection(
                                                      item['data'],
                                                      activeModules,
                                                      expandedId:
                                                          _expandedActiveCategoryId,
                                                      onToggle: (v) =>
                                                          _expandedActiveCategoryId =
                                                              v,
                                                    )
                                                  : _buildHomeSingleModuleParent(
                                                      item['data']),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    if (mastersCarouselItems.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        title: 'Formatos',
                                        subtitle:
                                            'Catalogo de formatos maestros',
                                        icon: Icons.library_books_outlined,
                                        countLabel: mastersCarouselItems.length
                                            .toString(),
                                      ),
                                      const SizedBox(height: 12),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        curve: Curves.easeInOut,
                                        height: mastersCarouselHeight,
                                        child: ListView.separated(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(20, 0, 20, 0),
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount:
                                              mastersCarouselItems.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 5),
                                          itemBuilder: (context, index) {
                                            final item =
                                                mastersCarouselItems[index];
                                            final kind = item['kind'] as String;

                                            return Align(
                                              alignment: Alignment.topCenter,
                                              child: SizedBox(
                                                width:
                                                    MediaQuery.sizeOf(context)
                                                            .width *
                                                        (kind == 'category'
                                                            ? 0.82
                                                            : 0.74),
                                                child: kind == 'category'
                                                    ? _buildHomeCategorySection(
                                                        item['data'],
                                                        mastersModules,
                                                        expandedId:
                                                            _expandedMastersCategoryId,
                                                        onToggle: (v) =>
                                                            _expandedMastersCategoryId =
                                                                v,
                                                      )
                                                    : _buildHomeSingleModuleParent(
                                                        item['data']),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            _buildSectionHeader(
                              title: 'Recientes',
                              subtitle: 'Ultimos registros visitados',
                              icon: Icons.history_toggle_off_rounded,
                              countLabel: FFAppState()
                                  .recientes
                                  .take(10)
                                  .length
                                  .toString(),
                            ),
                            // Generated code for this ListView Widget...
                            Builder(
                              builder: (context) {
                                final recientes = FFAppState()
                                    .recientes
                                    .toList()
                                    .take(10)
                                    .toList();
                                if (recientes.isEmpty) {
                                  return const EmptyComponentWidget(
                                    title: 'Aún no hay recientes',
                                    message:
                                        'Los registros que visites aparecerán aquí para encontrarlos rápidamente.',
                                    hint: 'Explora un módulo para comenzar',
                                    icon: Icons.history_rounded,
                                  );
                                }
                                return ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    0,
                                    10,
                                    0,
                                    100,
                                  ),
                                  primary: false,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  scrollDirection: Axis.vertical,
                                  itemCount: recientes.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: 5),
                                  itemBuilder: (context, recientesIndex) {
                                    final recientesItem =
                                        recientes[recientesIndex];
                                    return Padding(
                                      padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              20, 0, 20, 0),
                                      child: _buildRecentRegisterCard(
                                          recientesItem),
                                    );
                                  },
                                );
                              },
                            ),
                          ]
                              .divide(const SizedBox(height: 0.0))
                              .addToStart(const SizedBox(height: 30.0)),
                        ),
                      ),
                    ],
                  )),
            ),
            if (_isLoading)
              LoaderImage(
                backgroundUrl: loaderBackground,
                loadingText: 'Cargando...',
              )
          ],
        ));
  }
}
