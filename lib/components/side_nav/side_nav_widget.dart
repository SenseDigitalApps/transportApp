import '../../pages/user_settings/user_settings_widget.dart';
import '../../pages/web_view_viewer/web_view_viewer_widget.dart';
import '/backend/api_requests/api_calls.dart';
import '/components/dark_light_switch_large/dark_light_switch_large_widget.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'side_nav_model.dart';
export 'side_nav_model.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/custom_functions.dart';
import '/custom_code/BiometricAuthService.dart';
import '/widgets/cached_avatar_image.dart';

class SideNavWidget extends StatefulWidget {
  const SideNavWidget({super.key});

  @override
  State<SideNavWidget> createState() => _SideNavWidgetState();
}

class _SideNavWidgetState extends State<SideNavWidget> {
  late SideNavModel _model;

  static ApiCallResponse? _cachedCategoriesResponse;
  static ApiCallResponse? _cachedModulesResponse;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiration = Duration(days: 1);

  final Map<int, bool> _expandedModulesSections = {};
  final Map<int, bool> _expandedFormatsSections = {};

  late Future<Map<String, dynamic>> _dataFuture;

  bool _isCacheValid() {
    return _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheExpiration;
  }

  Future<Map<String, dynamic>> _getCachedData() async {
    if (_isCacheValid() &&
        _cachedCategoriesResponse != null &&
        _cachedModulesResponse != null) {
      debugPrint('[SideNav] Cache hit');
      return {
        'categories': _cachedCategoriesResponse!,
        'modules': _cachedModulesResponse!,
      };
    }

    debugPrint('[SideNav] Cache miss, fetching API');
    debugPrint('[SideNav] Tenant: ${FFAppState().organizacion}');

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

    final catResp = futures[0];
    final modResp = futures[1];

    debugPrint(
        '[SideNav] Categories -> status=${catResp.statusCode} ok=${catResp.succeeded}');
    debugPrint(
        '[SideNav] Modules    -> status=${modResp.statusCode} ok=${modResp.succeeded}');

    // Solo cachear respuestas exitosas para evitar que un error
    // puntual envenene el caché y nunca se reintente.
    if (catResp.succeeded && modResp.succeeded) {
      _cachedCategoriesResponse = catResp;
      _cachedModulesResponse = modResp;
      _cacheTimestamp = DateTime.now();
      debugPrint('[SideNav] Data cached successfully');
    } else {
      debugPrint('[SideNav] API failed — NOT caching');
    }

    return {
      'categories': catResp,
      'modules': modResp,
    };
  }

  List<dynamic> _getModulesForCategory(
      List<int> relatedModuleIds, List<dynamic> allModules) {
    return allModules.where((module) {
      final moduleId = castToType<int>(getJsonField(module, r'''$.id'''));
      return moduleId != null && relatedModuleIds.contains(moduleId);
    }).toList();
  }

  bool _hasModulePermission(dynamic module) {
    final name = getJsonField(module, r'''$.name''').toString().toLowerCase();
    return functions.hasAnyPermissionForModule(
            FFAppState().permissions.toList(), name) ||
        functions.hasPermission(
            FFAppState().permissions.toList(), 'query_-_ver', name);
  }

  bool _categoryHasVisibleModules(
      dynamic categoryItem, List<dynamic> modulesSource) {
    final relatedModuleIds =
        (getJsonField(categoryItem, r'''$.related_modules''', true) as List?)
                ?.map((e) => castToType<int>(e))
                .where((e) => e != null)
                .cast<int>()
                .toList() ??
            [];

    if (relatedModuleIds.isEmpty) return false;
    final categoryModules =
        _getModulesForCategory(relatedModuleIds, modulesSource);
    return categoryModules.any(_hasModulePermission);
  }

  // ───────────────────────────── UI Helpers ──────────────────────────────

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 4),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Datos del usuario ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Row(
                children: [
                  // Avatar con hero animation
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          child: FlutterFlowExpandedImageView(
                            image: CachedAvatarImage(
                              imageUrl: buildMediaUrl(FFAppState().avatar),
                              width: 300.0,
                              height: 200.0,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/app_launcher_icon.png',
                                width: 300.0,
                                height: 200.0,
                                fit: BoxFit.contain,
                              ),
                            ),
                            allowRotation: false,
                            tag: buildMediaUrl(FFAppState().avatar),
                            useHeroAnimation: true,
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: buildMediaUrl(FFAppState().avatar),
                      transitionOnUserGestures: true,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: CachedAvatarImage(
                            imageUrl: buildMediaUrl(FFAppState().avatar),
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/app_launcher_icon.png',
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nombre y correo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FFAppState().fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FFAppState().email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                fontFamily: 'Outfit',
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                fontSize: 11.5,
                                letterSpacing: 0,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── CTA ver perfil ─────────────────────────────────────
            InkWell(
              onTap: () => context.pushNamed(UserSettingsWidget.routeName),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .primary
                      .withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: FlutterFlowTheme.of(context)
                          .alternate
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.manage_accounts_outlined,
                      size: 16,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ver y editar perfil',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            letterSpacing: 0,
                          ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 10, 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: FlutterFlowTheme.of(context).secondaryText,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            fontFamily: 'Outfit',
          ),
        ),
      );

  Widget _groupCard({required List<_GroupTileData> tiles}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final i = entry.key;
          final tile = entry.value;
          final isFirst = i == 0;
          final isLast = i == tiles.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: tile.onTap,
                borderRadius: BorderRadius.vertical(
                  top: isFirst ? const Radius.circular(14) : Radius.zero,
                  bottom: isLast ? const Radius.circular(14) : Radius.zero,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (tile.iconColor ??
                                  FlutterFlowTheme.of(context).primary)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          tile.icon,
                          color: tile.iconColor ??
                              FlutterFlowTheme.of(context).primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tile.title,
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                      tile.trailing ??
                          Icon(
                            Icons.chevron_right_rounded,
                            color: FlutterFlowTheme.of(context)
                                .secondaryText
                                .withValues(alpha: 0.35),
                            size: 18,
                          ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 14,
                  color: FlutterFlowTheme.of(context)
                      .alternate
                      .withValues(alpha: 0.6),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModuleItem(dynamic moduleItem, dynamic originalModuleData) {
    final hasPermission = _hasModulePermission(moduleItem);
    if (!hasPermission) return const SizedBox.shrink();

    final label = valueOrDefault<String>(
      getJsonField(moduleItem, r'''$.label''').toString(),
      'No data',
    );

    return InkWell(
      onTap: () async {
        final allModules =
            ModulosCall.data(_cachedModulesResponse!.jsonBody) ?? [];
        final moduleIndex = allModules.indexWhere((m) =>
            getJsonField(m, r'''$.id''') ==
            getJsonField(moduleItem, r'''$.id'''));

        if (moduleIndex != -1) {
          context.pushNamed(
            'singlePage',
            queryParameters: {
              'moduleName': serializeParam(
                valueOrDefault<String>(
                  getJsonField(moduleItem, r'''$.name''').toString(),
                  'No data',
                ),
                ParamType.String,
              ),
              'icon': serializeParam(
                  getJsonField(moduleItem, r'''$.icon''').toString(),
                  ParamType.String),
              'moduleType': serializeParam(
                valueOrDefault<String>(
                  getJsonField(moduleItem, r'''$.type''').toString(),
                  'No data',
                ),
                ParamType.String,
              ),
              'moduleData': serializeParam(moduleItem, ParamType.JSON),
              'moduleId': serializeParam(
                  getJsonField(moduleItem, r'''$.id''').toString(),
                  ParamType.String),
            }.withoutNulls,
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Outfit',
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontSize: 13.5,
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: FlutterFlowTheme.of(context)
                  .secondaryText
                  .withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleModuleParent(dynamic moduleItem) {
    final title = getJsonField(moduleItem, r'''$.label''').toString();
    final desc = getJsonField(moduleItem, r'''$.description''').toString();
    final icon = getJsonField(moduleItem, r'''$.icon''').toString();

    if (!_hasModulePermission(moduleItem)) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).titleSmall.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (desc.isNotEmpty && desc != 'null') ...[
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Outfit',
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: FlutterFlowTheme.of(context)
                    .secondaryText
                    .withValues(alpha: 0.35),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    dynamic categoryItem,
    List<dynamic> modulesSource, {
    required Map<int, bool> expandedMap,
  }) {
    final categoryId =
        castToType<int>(getJsonField(categoryItem, r'''$.id''')) ?? -9999;
    final categoryTitle = getJsonField(categoryItem, r'''$.title''').toString();
    final categoryDescription =
        getJsonField(categoryItem, r'''$.description''').toString();
    final categoryIcon = getJsonField(categoryItem, r'''$.icon''').toString();
    final relatedModuleIds =
        (getJsonField(categoryItem, r'''$.related_modules''', true) as List?)
                ?.map((e) => castToType<int>(e))
                .where((e) => e != null)
                .cast<int>()
                .toList() ??
            [];
    final categoryModules =
        _getModulesForCategory(relatedModuleIds, modulesSource);
    final isExpanded = expandedMap[categoryId] ?? false;
    final visibleModules = categoryModules.where(_hasModulePermission).toList();

    if (visibleModules.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expandedMap[categoryId] = !isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: isExpanded ? Radius.zero : const Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      functions.getIconData(categoryIcon),
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
                          categoryTitle,
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (categoryDescription.isNotEmpty &&
                            categoryDescription != 'null') ...[
                          const SizedBox(height: 3),
                          Text(
                            categoryDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Outfit',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontSize: 12,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: FlutterFlowTheme.of(context)
                      .alternate
                      .withValues(alpha: 0.6),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 10),
                  child: Column(
                    children: visibleModules
                        .map((m) => _buildModuleItem(m, m))
                        .toList(),
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── Lifecycle ───────────────────────────────

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SideNavModel());
    _dataFuture = _getCachedData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onDependenciesChanged();
  }

  bool _didRunOnce = false;

  void _onDependenciesChanged() {
    // Skip the very first call (right after initState) to avoid
    // duplicating the initial load started in initState.
    if (!_didRunOnce) {
      _didRunOnce = true;
      return;
    }

    final cacheValid = _isCacheValid() &&
        _cachedCategoriesResponse != null &&
        _cachedModulesResponse != null;

    if (!cacheValid) {
      debugPrint('[SideNav] didChangeDependencies: cache invalid, reloading');
      setState(() {
        _dataFuture = _getCachedData();
      });
    }
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  static void clearCache() {
    _cachedCategoriesResponse = null;
    _cachedModulesResponse = null;
    _cacheTimestamp = null;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 32,
              color: FlutterFlowTheme.of(context)
                  .secondaryText
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay módulos disponibles',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  clearCache();
                  _expandedModulesSections.clear();
                  _expandedFormatsSections.clear();
                  _dataFuture = _getCachedData();
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context)
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recargar',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).primary,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Visibility(
      visible: responsiveVisibility(context: context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 50, 0, 0),
        width: MediaQuery.sizeOf(context).width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Perfil ──────────────────────────────────────────────
              _buildProfileHeader(),

              // ── Navegación principal ────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Navegación'),
                  _groupCard(
                      tiles: [
                    _GroupTileData(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      onTap: () async {
                        if (FFAppState().clientId == '') {
                          context.pushNamed('home');
                        } else {
                          context.pushNamed(
                            'homeClient',
                            queryParameters: {
                              'userId': serializeParam(
                                  FFAppState().clientId, ParamType.String),
                            }.withoutNulls,
                          );
                        }
                      },
                    ),
                    if (FFAppState().lookerStudio.isNotEmpty &&
                        functions.hasPermissionDashboard(
                            FFAppState().permissions.toList(), ''))
                      _GroupTileData(
                        icon: Icons.dashboard_rounded,
                        title: 'Dashboard',
                        onTap: () async {
                          context.pushNamed(
                            WebViewViewerWidget.routeName,
                            queryParameters: {
                              'url': serializeParam(
                                  FFAppState().lookerStudio, ParamType.String),
                              'title':
                                  serializeParam('Dashboard', ParamType.String),
                            }.withoutNulls,
                          );
                        },
                      ),
                  ].whereType<_GroupTileData>().toList()),
                ],
              ),

              // ── Módulos y Formatos ──────────────────────────────────
              FutureBuilder<Map<String, dynamic>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary,
                          ),
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint('[SideNav] Future error: ${snapshot.error}');
                    return _buildEmptyState();
                  }

                  final categoriesResponse =
                      snapshot.data!['categories'] as ApiCallResponse;
                  final modulesResponse =
                      snapshot.data!['modules'] as ApiCallResponse;

                  if (!categoriesResponse.succeeded ||
                      !modulesResponse.succeeded) {
                    debugPrint(
                        '[SideNav] API call not succeeded — showing empty state');
                    return _buildEmptyState();
                  }

                  final categories = CategorizedModulesCall.data(
                          categoriesResponse.jsonBody) ??
                      [];
                  final allModules =
                      ModulosCall.data(modulesResponse.jsonBody) ?? [];

                  if (categories.isEmpty && allModules.isEmpty) {
                    return _buildEmptyState();
                  }

                  categories.sort((a, b) {
                    final priorityA = getJsonField(a, r'''$.priority''') ?? 999;
                    final priorityB = getJsonField(b, r'''$.priority''') ?? 999;
                    return priorityA.compareTo(priorityB);
                  });

                  Set<int> relatedModuleIds = {};
                  for (var category in categories) {
                    final ids =
                        (getJsonField(category, r'''$.related_modules''', true)
                                    as List?)
                                ?.map((e) => castToType<int>(e))
                                .where((e) => e != null)
                                .cast<int>()
                                .toList() ??
                            [];
                    relatedModuleIds.addAll(ids);
                  }

                  final activeModules = allModules.where((m) {
                    final t = getJsonField(m, r'''$.type''')
                        ?.toString()
                        .toLowerCase();
                    final replaceHome = getJsonField(m, r'''$.replace_home''');
                    return t != 'masters' && replaceHome != true;
                  }).toList();

                  final mastersModules = allModules.where((m) {
                    final t = getJsonField(m, r'''$.type''')
                        ?.toString()
                        .toLowerCase();
                    final replaceHome = getJsonField(m, r'''$.replace_home''');
                    return t == 'masters' && replaceHome != true;
                  }).toList();

                  final ungroupedActiveVisible = activeModules.where((m) {
                    final id = castToType<int>(getJsonField(m, r'''$.id'''));
                    return id != null &&
                        !relatedModuleIds.contains(id) &&
                        _hasModulePermission(m);
                  }).toList();

                  final ungroupedMastersVisible = mastersModules.where((m) {
                    final id = castToType<int>(getJsonField(m, r'''$.id'''));
                    return id != null &&
                        !relatedModuleIds.contains(id) &&
                        _hasModulePermission(m);
                  }).toList();

                  final visibleActiveCategories = categories
                      .where(
                          (c) => _categoryHasVisibleModules(c, activeModules))
                      .toList();

                  final visibleFormatCategories = categories
                      .where(
                          (c) => _categoryHasVisibleModules(c, mastersModules))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ungroupedActiveVisible.isNotEmpty ||
                          visibleActiveCategories.isNotEmpty) ...[
                        _sectionLabel('Módulos'),
                        ...ungroupedActiveVisible.map((m) => Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: _buildSingleModuleParent(m),
                            )),
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleActiveCategories.length,
                          itemBuilder: (context, index) {
                            return _buildCategorySection(
                              visibleActiveCategories[index],
                              activeModules,
                              expandedMap: _expandedModulesSections,
                            );
                          },
                        ),
                      ],
                      if (ungroupedMastersVisible.isNotEmpty ||
                          visibleFormatCategories.isNotEmpty) ...[
                        _sectionLabel('Formatos'),
                        ...ungroupedMastersVisible
                            .map((m) => _buildSingleModuleParent(m)),
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleFormatCategories.length,
                          itemBuilder: (context, index) {
                            return _buildCategorySection(
                              visibleFormatCategories[index],
                              mastersModules,
                              expandedMap: _expandedFormatsSections,
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),

              // ── Ajustes ─────────────────────────────────────────────
              _sectionLabel('Ajustes'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const DarkLightSwitchLargeWidget(),
                ),
              ),
              const SizedBox(height: 8),
              _groupCard(tiles: [
                _GroupTileData(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Chat de soporte',
                  onTap: () async {
                    await launchURL(
                        'https://api.whatsapp.com/send/?phone=573143575870&text=Hola%21+te+contacto+desde+mi+app+de+query+para+la+siguiente+duda&type=phone_number&app_absent=0');
                  },
                ),
                _GroupTileData(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar sesión',
                  iconColor: const Color(0xFFE53935),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFFE53935).withValues(alpha: 0.4),
                    size: 18,
                  ),
                  onTap: () {
                    clearCache();
                    FFAppState().clienteEquipo = '';
                    FFAppState().token = '';
                    FFAppState().refreshToken = '';
                    FFAppState().loginUser = '';
                    FFAppState().loginPassword = '';
                    FFAppState().id = '';
                    FFAppState().clientId = '';
                    FFAppState().permissions.clear();
                    FFAppState().modulesPermissions.clear();
                    FFAppState().recientes.clear();
                    FFAppState().role = '';
                    FFAppState().textoControlador.clear();
                    FFAppState().fullName = '';
                    FFAppState().username = '';
                    FFAppState().email = '';
                    FFAppState().avatar = '';
                    FFAppState().shortname = '';
                    context.pushReplacementNamed('LoginEquipo');
                  },
                ),
              ]),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Modelo de datos para los tiles agrupados
class _GroupTileData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  const _GroupTileData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });
}
