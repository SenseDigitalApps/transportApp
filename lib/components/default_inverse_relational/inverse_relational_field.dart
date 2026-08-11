import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/api_requests/api_base_url.dart';
import '/backend/api_requests/api_manager.dart';
import '/backend/api_requests/interceptor.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/reverse_relational_sheet.dart';

/// Inverse relational field — fetches its own data from the API.
///
/// Config comes from the custom field definition:
///   - `inverse_relation_module`: ID of the source module
///   - `inverse_relation_field`: slug of the relational field in that module
///   - `inverse_relation_display_fields`: comma-separated slugs to display
///
/// The widget makes its own GET call to find records where
/// `json_key=<inverse_relation_field> & json_value=<currentRecordId>`.
class InverseRelationalField extends StatefulWidget {
  const InverseRelationalField({
    super.key,
    required this.campo,
    required this.generalId,
    required this.general,
  });

  /// Full field config from custom_fields_min (has inverse_relation_* keys).
  final Map<String, dynamic> campo;

  /// Current register ID.
  final dynamic generalId;

  /// Full register object (for creating related records).
  final dynamic general;

  @override
  State<InverseRelationalField> createState() => _InverseRelationalFieldState();
}

class _InverseRelationalFieldState extends State<InverseRelationalField> {
  bool _isLoading = true;
  List<dynamic> _data = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  String? _error;
  final Set<String> _deletingIds = {};

  /// Parsed from field config.
  late final String _targetModuleName;
  late final String _targetFieldSlug;
  late final List<String> _displayFields;
  late final String _fieldLabel;

  @override
  void initState() {
    super.initState();
    _targetModuleName = widget.campo['inverse_relation_module']?.toString() ?? '';
    _targetFieldSlug = widget.campo['inverse_relation_field']?.toString() ?? '';
    _fieldLabel = widget.campo['label']?.toString() ?? widget.campo['slug']?.toString() ?? '';
    _displayFields = _parseDisplayFields(widget.campo['inverse_relation_display_fields']);
    _fetchData();
  }

  List<String> _parseDisplayFields(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  /// Resolve the module name from the module ID stored in inverse_relation_module.
  /// inverse_relation_module is a module ID (e.g. "20"), we need the name (e.g. "cotizacion").
  String get _resolvedModuleName {
    final moduleId = widget.campo['inverse_relation_module']?.toString() ?? '';
    if (moduleId.isEmpty) return '';
    for (final m in FFAppState().moduleList) {
      if (m is Map && m['id'].toString() == moduleId) {
        return m['name']?.toString() ?? '';
      }
    }
    return '';
  }

  /// Determine module type (registers vs masters) from app state.
  String get _resolvedModuleType {
    final name = _resolvedModuleName;
    for (final m in FFAppState().moduleList) {
      if (m is Map && m['name']?.toString() == name) {
        return m['type']?.toString() ?? 'registers';
      }
    }
    return 'registers';
  }

  bool _hasModulePermission(String action, String moduleName) {
    final normalizedModule = moduleName.trim().toLowerCase();
    if (normalizedModule.isEmpty) return false;
    final expected = 'modulo.${action.toLowerCase()}_$normalizedModule';
    return FFAppState()
        .permissions
        .any((permission) => permission.toLowerCase() == expected);
  }

  bool get _canCreateTargetModule =>
      _hasModulePermission('query_-_editar', _resolvedModuleName);

  bool get _allowDeleteFromConfig {
    final value = widget.campo['inverse_relation_allow_delete'] ??
        widget.campo['allow_delete'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    return {'true', '1', 'yes', 'on'}.contains(
      value?.toString().trim().toLowerCase(),
    );
  }

  bool get _canDeleteTargetModule =>
      _allowDeleteFromConfig &&
      _hasModulePermission('query_-_eliminar', _resolvedModuleName);

  Future<void> _fetchData() async {
    if (_targetModuleName.isEmpty && _resolvedModuleName.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'No module configured';
      });
      return;
    }
    if (_targetFieldSlug.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'No field configured';
      });
      return;
    }
    if (widget.generalId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No record ID';
      });
      return;
    }

    final moduleName = _resolvedModuleName;
    final moduleType = _resolvedModuleType;
    final recordId = widget.generalId.toString();
    final table = moduleType == 'registers' ? 'register' : 'master';

    try {
      // Build query params matching web pattern
      final queryParams = [
        'page=$_currentPage',
        'items_per_page=5',
        'filter_module=$moduleName',
        'json_key=$_targetFieldSlug',
        'json_condition=igual',
        'json_value=$recordId',
      ].join('&');

      final apiPath = 'v2/$table/?$queryParams';
      final apiUrl = ApiBaseUrl.forTenantCall(
        tenant: FFAppState().organizacion,
        apiPath: apiPath,
      );

      final response = await FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'inverseRelational',
          apiUrl: apiUrl,
          callType: ApiCallType.GET,
          headers: {'Authorization': 'Bearer ${FFAppState().token}'},
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        [
          ExpiredSessionInterceptor(),
        ],
      );

      if (response.succeeded && response.jsonBody != null) {
        final body = response.jsonBody;
        final List<dynamic> dataList =
            (body is Map && body['data'] is List) ? body['data'] : [];
        final pagination =
            (body is Map && body['pagination'] is Map) ? body['pagination'] : {};

        if (mounted) {
          setState(() {
            _data = dataList;
            _totalCount = pagination['total'] ?? dataList.length;
            _lastPage = pagination['last_page'] ?? 1;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _data = [];
            _totalCount = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching inverse relations: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onPageChanged(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    setState(() {
      _currentPage = page;
      _isLoading = true;
    });
    _fetchData();
  }

  Future<void> _confirmDeleteItem(Map<String, dynamic> item) async {
    if (!_canDeleteTargetModule) return;
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty || _deletingIds.contains(id)) return;

    final title = item['title']?.toString() ?? 'Sin título';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: Text(
          'Se eliminará "$title" (#$id). Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: FlutterFlowTheme.of(context).error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(id));
    try {
      final table = _resolvedModuleType == 'registers' ? 'register' : 'master';
      final apiUrl = ApiBaseUrl.forTenantCall(
        tenant: FFAppState().organizacion,
        apiPath: 'v2/$table/$id/',
      );
      final response = await FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'deleteInverseRelationalRecord',
          apiUrl: apiUrl,
          callType: ApiCallType.DELETE,
          headers: {'Authorization': 'Bearer ${FFAppState().token}'},
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        [ExpiredSessionInterceptor()],
      );
      if (!response.succeeded) {
        throw Exception('No se pudo eliminar el registro');
      }
      if (!mounted) return;
      setState(() => _deletingIds.remove(id));
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado correctamente')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $error')),
      );
    }
  }

  void _showAllRelations() {
    if (widget.generalId == null || _resolvedModuleName.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReverseRelationalSheet(
        options: [
          {
            'module': _resolvedModuleName,
            'field': _targetFieldSlug,
            'slugs': _displayFields,
          },
        ],
        currentRecordId: widget.generalId.toString(),
        displayFields: _displayFields,
        onCreateRecord:
            _canCreateTargetModule ? _createRelatedRecord : null,
      ),
    );
  }

  Map<String, dynamic>? _findModuleByName(String moduleName) {
    for (final module in FFAppState().moduleList) {
      if (module is Map && module['name']?.toString() == moduleName) {
        return Map<String, dynamic>.from(module);
      }
    }
    return null;
  }

  Map<String, dynamic>? _currentModuleInfo() {
    if (widget.general is! Map) return null;
    final rawInfo = widget.general['modulo_info'];
    if (rawInfo is Map) return Map<String, dynamic>.from(rawInfo);
    if (rawInfo is List && rawInfo.isNotEmpty && rawInfo.first is Map) {
      return Map<String, dynamic>.from(rawInfo.first);
    }
    return null;
  }

  String _currentRecordLabel() {
    if (widget.general is! Map) return widget.generalId.toString();
    final title = widget.general['title']?.toString().trim() ?? '';
    final consecutivo = widget.general['consecutivo']?.toString().trim() ?? '';
    if (consecutivo.isNotEmpty && title.isNotEmpty) {
      return '$consecutivo - $title';
    }
    return title.isNotEmpty ? title : widget.generalId.toString();
  }

  Map<String, dynamic> _inheritedFieldValues() {
    final rawConfig = widget.campo['inherited_fields']?.toString().trim() ?? '';
    if (rawConfig.isEmpty || widget.general is! Map) return {};

    final record = Map<String, dynamic>.from(widget.general);
    final jsonData = record['json_data'] is Map
        ? Map<String, dynamic>.from(record['json_data'])
        : <String, dynamic>{};
    final inherited = <String, dynamic>{};
    final groups = rawConfig.contains('|')
        ? rawConfig.split('|')
        : rawConfig.split(',');

    for (final group in groups) {
      final trimmed = group.trim();
      if (trimmed.isEmpty) continue;

      final separator = trimmed.contains(':') ? ':' : ',';
      final parts = trimmed.split(separator);
      if (parts.length < 2) continue;

      final sourceSlug = parts[0].trim();
      final targetSlug = parts[1].trim();
      if (sourceSlug.isEmpty || targetSlug.isEmpty) continue;

      final value = jsonData.containsKey(sourceSlug)
          ? jsonData[sourceSlug]
          : record[sourceSlug];
      if (value != null) inherited[targetSlug] = value;
    }
    return inherited;
  }

  Future<void> _createRelatedRecord() async {
    if (!_canCreateTargetModule) return;

    final targetModule = _findModuleByName(_resolvedModuleName);
    if (targetModule == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró el módulo "$_resolvedModuleName"'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }

    final currentModule = _currentModuleInfo() ?? {};
    final moduleId = targetModule['id'];
    final moduleType = targetModule['type']?.toString() ?? 'registers';
    final initialData = <String, dynamic>{
      ..._inheritedFieldValues(),
      _targetFieldSlug: {
        'label': _currentRecordLabel(),
        'module': currentModule['id'],
        'type': currentModule['type']?.toString() ?? 'registers',
        'value': widget.generalId,
        'module_name': currentModule['name']?.toString() ?? '',
      },
    };

    final result = await context.pushNamed(
      'newRegistersModule',
      queryParameters: {
        'moduleName': serializeParam(_resolvedModuleName, ParamType.String),
        'moduleId': serializeParam(
          moduleId is int
              ? moduleId
              : int.tryParse(moduleId?.toString() ?? ''),
          ParamType.int,
        ),
        'moduleType': serializeParam(moduleType, ParamType.String),
        'moduleData': serializeParam(targetModule, ParamType.JSON),
        'template': serializeParam(initialData, ParamType.JSON),
      }.withoutNulls,
    );

    if (result == true && mounted) {
      _currentPage = 1;
      _fetchData();
    }
  }

  String _getModuleDisplayName(String moduleName) {
    for (final m in FFAppState().moduleList) {
      if (m is Map) {
        final name = m['name']?.toString().trim() ?? '';
        if (name == moduleName) {
          final label = m['label']?.toString().trim() ?? '';
          if (label.isNotEmpty) return label;
        }
      }
    }
    return moduleName
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  Map<String, dynamic>? _findDisplayFieldConfig(
      dynamic source, String slug) {
    if (source is List) {
      for (final item in source) {
        final result = _findDisplayFieldConfig(item, slug);
        if (result != null) return result;
      }
      return null;
    }
    if (source is! Map) return null;

    if (source['slug']?.toString() == slug) {
      return Map<String, dynamic>.from(source);
    }

    const nestedKeys = [
      'fields',
      'grouped_fields',
      'ungrouped_fields',
      'custom_fields',
      'custom_fields_min',
    ];
    for (final key in nestedKeys) {
      final result = _findDisplayFieldConfig(source[key], slug);
      if (result != null) return result;
    }
    return null;
  }

  Map<String, dynamic>? _displayFieldConfig(String slug) {
    for (final module in FFAppState().moduleList) {
      if (module is Map && module['name']?.toString() == _resolvedModuleName) {
        final result = _findDisplayFieldConfig(module, slug);
        if (result != null) return result;
      }
    }
    return _findDisplayFieldConfig(
        widget.campo['inverse_relation_display_fields'], slug);
  }

  bool _isNumericField(String slug, dynamic value) {
    final fieldConfig = _displayFieldConfig(slug);
    final fieldType = (fieldConfig?['field_type'] ?? fieldConfig?['type'])
        ?.toString()
        .toLowerCase();
    return const {'number', 'calculator', 'calculator_advanced'}
            .contains(fieldType) ||
        value is num;
  }

  String _formatNumericValue(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '-';

    num? parsed = value is num ? value : num.tryParse(raw);
    if (parsed == null) {
      final normalized = raw.contains(',') && raw.contains('.')
          ? (raw.lastIndexOf(',') > raw.lastIndexOf('.')
              ? raw.replaceAll('.', '').replaceFirst(',', '.')
              : raw.replaceAll(',', ''))
          : raw.replaceFirst(',', '.');
      parsed = num.tryParse(normalized);
    }
    return parsed == null
        ? raw
        : NumberFormat.decimalPattern('es').format(parsed);
  }

  String _formatDisplayValue(dynamic value, {String? slug}) {
    if (value == null || value == '') return '-';
    if (slug != null && _isNumericField(slug, value)) {
      final numericValue = value is Map
          ? (value['value'] ?? value['label'] ?? value)
          : value;
      return _formatNumericValue(numericValue);
    }
    if (value is Map) {
      return value['label']?.toString() ??
          value['value']?.toString() ??
          '-';
    }
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').join(', ');
    }
    return value.toString();
  }

  bool _looksLikeImageValue(String value) {
    return value.startsWith('data:image/') ||
        RegExp(
          r'^(?:https?://|/|[\w.-]+/).+\.(?:png|jpe?g|gif|webp|svg)(?:\?.*)?$',
          caseSensitive: false,
        ).hasMatch(value);
  }

  String _extractFirstImageUrl(dynamic value) {
    if (value is List) {
      for (final item in value) {
        final url = _extractFirstImageUrl(item);
        if (url.isNotEmpty) return url;
      }
      return '';
    }
    if (value is Map) {
      for (final key in ['url', 'src', 'path', 'value', 'file']) {
        final url = _extractFirstImageUrl(value[key]);
        if (url.isNotEmpty) return url;
      }
      return '';
    }
    if (value is! String) return '';

    final text = value.trim();
    if (text.startsWith('{') || text.startsWith('[')) {
      try {
        final decoded = jsonDecode(text);
        final url = _extractFirstImageUrl(decoded);
        if (url.isNotEmpty) return url;
      } catch (_) {}
    }
    return _looksLikeImageValue(text) ? text : '';
  }

  bool _isImageField(String slug, dynamic value) {
    final fieldConfig = _displayFieldConfig(slug);
    final fieldType = (fieldConfig?['field_type'] ?? fieldConfig?['type'])
        ?.toString()
        .toLowerCase();
    return const {
          'image',
          'image_view',
          'image_gallery',
          'firma',
          'firmaext',
        }.contains(fieldType) ||
        _extractFirstImageUrl(value).isNotEmpty;
  }

  String _resolveImageUrl(String value) {
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:image/')) {
      return value;
    }
    return ApiBaseUrl.build(
      tenant: FFAppState().organizacion,
      path: value,
    );
  }

  Widget _buildDisplayField(
      BuildContext context, String slug, dynamic rawValue) {
    final value = _formatDisplayValue(rawValue, slug: slug);
    if (value.isEmpty || value == '-') return const SizedBox.shrink();

    final imageUrl = _isImageField(slug, rawValue)
        ? _extractFirstImageUrl(rawValue)
        : '';
    if (imageUrl.isNotEmpty) {
      return Tooltip(
        message: value,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            _resolveImageUrl(imageUrl),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image_outlined,
              size: 18,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: value,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Outfit',
                fontSize: 10,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moduleName = _resolvedModuleName;
    final moduleLabel = _getModuleDisplayName(moduleName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fieldLabel,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                      ),
                      Text(
                        'Relaciones inversas',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Outfit',
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                 ),
                if (!_isLoading &&
                    _resolvedModuleName.isNotEmpty &&
                    _canCreateTargetModule)
                  IconButton(
                    tooltip: 'Crear registro',
                    onPressed: _createRelatedRecord,
                    icon: const Icon(Icons.add, size: 20),
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                 if (!_isLoading)
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_totalCount',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ──
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Center(
                child: Text(
                  _error!,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Outfit',
                        color: FlutterFlowTheme.of(context).error,
                      ),
                ),
              ),
            )
          else if (_data.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.link_off,
                      size: 28,
                      color: FlutterFlowTheme.of(context).secondaryText.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No hay registros relacionados',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Preview items
            ..._data.take(5).map((item) => _buildItem(context, item)),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                   if (_totalCount > 5)
                     Text(
                       '... y ${_totalCount - 5} más',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).secondaryText,
                             fontSize: 11,
                           ),
                     ),
                   const Spacer(),
                   if (_totalCount > _data.length || _lastPage > 1)
                     TextButton(
                       onPressed: _showAllRelations,
                       child: const Text('Ver todos'),
                     ),
                   if (_lastPage > 1)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _currentPage > 1
                              ? () => _onPageChanged(_currentPage - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left, size: 18),
                          color: FlutterFlowTheme.of(context).primary,
                          disabledColor: Colors.grey.withValues(alpha: 0.3),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$_currentPage/$_lastPage',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: _currentPage < _lastPage
                              ? () => _onPageChanged(_currentPage + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right, size: 18),
                          color: FlutterFlowTheme.of(context).primary,
                          disabledColor: Colors.grey.withValues(alpha: 0.3),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, dynamic item) {
    if (item is! Map) return const SizedBox.shrink();

    final id = item['id'];
    final title = item['title']?.toString() ?? 'Sin título';
    final consecutivo = item['consecutivo']?.toString() ?? '';
    final moduleName = item['modulo_info']?['name']?.toString() ?? _resolvedModuleName;
    final moduleLabel = _getModuleDisplayName(moduleName);

    return InkWell(
      onTap: () {
        // Navigate to detail view of this related record
        // Find moduleData from app state
        dynamic moduleData;
        for (final m in FFAppState().moduleList) {
          if (m is Map && m['name']?.toString() == moduleName) {
            moduleData = m;
            break;
          }
        }
        if (moduleData != null) {
          context.pushNamed(
            'detailGrouped',
            queryParameters: {
              'general': serializeParam(item, ParamType.JSON),
              'moduleData': serializeParam(moduleData, ParamType.JSON),
            }.withoutNulls,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // ID badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                consecutivo.isNotEmpty ? '#$consecutivo' : '#$id',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      color: FlutterFlowTheme.of(context).primary,
                      fontSize: 11,
                    ),
              ),
            ),
            const SizedBox(width: 10),
             // Title + module
             Expanded(
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                  ),
                   Text(
                     moduleLabel,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Outfit',
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 10,
                         ),
                   ),
                   if (_displayFields.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.only(top: 4),
                       child: Wrap(
                         spacing: 4,
                         runSpacing: 4,
                         children: _displayFields.map((slug) {
                           final raw = item['json_data']?[slug] ?? item[slug];
                           return _buildDisplayField(context, slug, raw);
                         }).toList(),
                       ),
                     ),
                 ],
               ),
              ),
              const SizedBox(width: 6),
             if (_canDeleteTargetModule)
               IconButton(
                 tooltip: 'Eliminar registro',
                 onPressed: _deletingIds.contains(id.toString())
                     ? null
                     : () => _confirmDeleteItem(
                           Map<String, dynamic>.from(item),
                         ),
                 icon: _deletingIds.contains(id.toString())
                     ? const SizedBox(
                         width: 16,
                         height: 16,
                         child: CircularProgressIndicator(strokeWidth: 2),
                       )
                     : const Icon(Icons.delete_outline, size: 18),
                 color: FlutterFlowTheme.of(context).error,
               ),
             Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
