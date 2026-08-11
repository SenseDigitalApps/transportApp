import 'package:flutter/material.dart';
import 'package:transport_app/flutter_flow/flutter_flow_theme.dart';
import 'package:transport_app/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/api_requests/api_base_url.dart';
import '/backend/api_requests/api_manager.dart';
import '/backend/api_requests/interceptor.dart';

/// Bottom sheet that shows records from another module
/// that reference the current record via a relational field.
///
/// Format of each option:
///   { module: "ventas", field: "ref_cliente", slugs?: ["fecha","monto"] }
class ReverseRelationalSheet extends StatefulWidget {
  const ReverseRelationalSheet({
    super.key,
    required this.options,
    required this.currentRecordId,
    this.displayFields,
    this.onCreateRecord,
  });

  final List<Map<String, dynamic>> options;
  final String currentRecordId;
  final List<String>? displayFields;
  final Future<void> Function()? onCreateRecord;

  @override
  State<ReverseRelationalSheet> createState() =>
      _ReverseRelationalSheetState();
}

class _ReverseRelationalSheetState extends State<ReverseRelationalSheet> {
  int _selectedOptionIndex = 0;
  int _currentPage = 1;
  final int _perPage = 10;
  bool _isLoading = false;
  List<dynamic> _data = [];
  int _total = 0;
  int _lastPage = 1;
  final Set<String> _deletingIds = {};

  Map<String, dynamic> get _currentOption =>
      widget.options[_selectedOptionIndex];

  List<String> get _displayFields {
    final raw = _currentOption['slugs'] ?? widget.displayFields;
    if (raw is List) {
      return raw.map((field) => field.toString()).toList();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((field) => field.trim())
          .where((field) => field.isNotEmpty)
          .toList();
    }
    return [];
  }

  bool _hasModulePermission(String action, String moduleName) {
    final normalizedModule = moduleName.trim().toLowerCase();
    if (normalizedModule.isEmpty) return false;
    final expected = 'modulo.${action.toLowerCase()}_$normalizedModule';
    return FFAppState()
        .permissions
        .any((permission) => permission.toLowerCase() == expected);
  }

  bool get _canViewSelectedModule => _hasModulePermission(
        'query_-_ver',
        _currentOption['module']?.toString() ?? '',
      );

  bool get _canEditSelectedModule => _hasModulePermission(
        'query_-_editar',
        _currentOption['module']?.toString() ?? '',
      );

  bool get _canDeleteSelectedModule => _hasModulePermission(
        'query_-_eliminar',
        _currentOption['module']?.toString() ?? '',
      );

  String _selectedModuleType() {
    final moduleName = _currentOption['module']?.toString() ?? '';
    for (final module in FFAppState().moduleList) {
      if (module is Map && module['name']?.toString().trim() == moduleName) {
        return module['type']?.toString() ?? 'registers';
      }
    }
    return 'registers';
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final moduleName = _currentOption['module']?.toString() ?? '';
      final fieldSlug = _currentOption['field']?.toString() ?? '';

      if (!_canViewSelectedModule) {
        setState(() {
          _data = [];
          _total = 0;
          _lastPage = 1;
        });
        return;
      }

      final moduleType = _selectedModuleType();

      final response = await GetDataModulesCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        module: moduleName,
        moduleType: moduleType,
        page: _currentPage,
        limit: _perPage,
        jsonKey: fieldSlug,
        jsonValue: widget.currentRecordId,
        jsonCondition: 'igual',
      );

      if (response.succeeded && response.jsonBody != null) {
        final body = response.jsonBody;
        final List<dynamic> dataList =
            (body is Map && body['data'] is List) ? body['data'] : [];
        final pagination =
            (body is Map && body['pagination'] is Map) ? body['pagination'] : {};

        setState(() {
          _data = dataList;
          _total = pagination['total'] ?? dataList.length;
          _lastPage = pagination['last_page'] ?? 1;
        });
      } else {
        setState(() {
          _data = [];
          _total = 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reverse relations: $e');
      setState(() {
        _data = [];
        _total = 0;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOptionChanged(int index) {
    if (index == _selectedOptionIndex) return;
    setState(() {
      _selectedOptionIndex = index;
      _currentPage = 1;
      _data = [];
      _total = 0;
    });
    _fetchData();
  }

  void _onPageChanged(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    setState(() => _currentPage = page);
    _fetchData();
  }

  Future<void> _confirmDelete(Map<String, dynamic> record) async {
    if (!_canDeleteSelectedModule) return;
    final id = record['id']?.toString() ?? '';
    if (id.isEmpty || _deletingIds.contains(id)) return;

    final title = record['title']?.toString() ?? 'Sin título';
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
      final table = _selectedModuleType() == 'registers'
          ? 'register'
          : 'master';
      final apiUrl = ApiBaseUrl.forTenantCall(
        tenant: FFAppState().organizacion,
        apiPath: 'v2/$table/$id/',
      );
      final response = await FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'deleteReverseRelationalRecord',
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

  String _getModuleDisplayName(String moduleName) {
    // Look up label from app state
    for (final m in FFAppState().moduleList) {
      if (m is Map) {
        final name = m['name']?.toString().trim() ?? '';
        if (name == moduleName) {
          final label = m['label']?.toString().trim() ?? '';
          if (label.isNotEmpty) return label;
        }
      }
    }
    // Fallback: capitalize
    return moduleName
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : w)
        .join(' ');
  }

  dynamic _recordValue(Map record, String slug) {
    final jsonData = record['json_data'];
    if (jsonData is Map && jsonData.containsKey(slug)) {
      return jsonData[slug];
    }
    return record[slug];
  }

  String _formatDisplayValue(dynamic value) {
    if (value == null || value == '') return '-';
    if (value is Map) {
      return value['label']?.toString() ??
          value['value']?.toString() ??
          value['url']?.toString() ??
          '-';
    }
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').join(', ');
    }
    return value.toString();
  }

  num? _parseNumericValue(dynamic value) {
    if (value is Map) {
      value = value['value'] ?? value['label'];
    }
    if (value is num) return value;
    if (value is! String) return null;

    final raw = value.trim();
    if (raw.isEmpty) return null;
    final direct = num.tryParse(raw);
    if (direct != null) return direct;

    final normalized = raw.contains(',') && raw.contains('.')
        ? (raw.lastIndexOf(',') > raw.lastIndexOf('.')
            ? raw.replaceAll('.', '').replaceFirst(',', '.')
            : raw.replaceAll(',', ''))
        : raw.replaceFirst(',', '.');
    return num.tryParse(normalized);
  }

  String _formatNumericValue(num value) {
    return NumberFormat.decimalPattern('es').format(value);
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
    if (text.startsWith('data:image/')) return text;
    return RegExp(
      r'^(?:https?://|/|[\w.-]+/).+\.(?:png|jpe?g|gif|webp|svg)(?:\?.*)?$',
      caseSensitive: false,
    ).hasMatch(text)
        ? text
        : '';
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

  Widget _buildDisplayField(BuildContext context, String slug, dynamic value) {
    final imageUrl = _extractFirstImageUrl(value);
    if (imageUrl.isNotEmpty) {
      return Tooltip(
        message: _formatDisplayValue(value),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            _resolveImageUrl(imageUrl),
            width: 40,
            height: 40,
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

    final numericValue = _parseNumericValue(value);
    final displayValue = numericValue == null
        ? _formatDisplayValue(value)
        : _formatNumericValue(numericValue);
    if (displayValue.isEmpty || displayValue == '-') {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: displayValue,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          displayValue,
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

  Map<String, num> _numericTotals() {
    final totals = <String, num>{};
    for (final slug in _displayFields) {
      num total = 0;
      var hasValue = false;
      for (final record in _data) {
        if (record is! Map) continue;
        final value = _parseNumericValue(_recordValue(record, slug));
        if (value == null) continue;
        total += value;
        hasValue = true;
      }
      if (hasValue) totals[slug] = total;
    }
    return totals;
  }

  Widget _buildTotalsFooter() {
    final totals = _numericTotals();
    if (totals.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: totals.entries
            .map(
              (entry) => Text(
                '${entry.key}: ${_formatNumericValue(entry.value)}',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 11,
                    ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relaciones',
                        style: FlutterFlowTheme.of(context)
                            .titleMedium
                            .override(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                      ),
                      if (_total > 0)
                        Text(
                          '$_total registro${_total != 1 ? 's' : ''} encontrado${_total != 1 ? 's' : ''}',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText,
                                fontSize: 12,
                              ),
                        ),
                    ],
                  ),
                 ),
                if (widget.onCreateRecord != null && _canEditSelectedModule)
                  IconButton(
                    tooltip: 'Crear registro',
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.onCreateRecord!.call();
                    },
                    icon: const Icon(Icons.add, size: 22),
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                 IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 22),
                ),
              ],
            ),
          ),
          // Option chips
          if (widget.options.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final opt = widget.options[i];
                    final isSelected = i == _selectedOptionIndex;
                    final moduleLabel =
                        _getModuleDisplayName(opt['module']?.toString() ?? '');
                    return ChoiceChip(
                      label: Text(moduleLabel),
                      selected: isSelected,
                      onSelected: (_) => _onOptionChanged(i),
                      selectedColor:
                          FlutterFlowTheme.of(context).primary.withValues(alpha: 0.15),
                      labelStyle: FlutterFlowTheme.of(context)
                          .bodySmall
                          .override(
                            fontFamily: 'Outfit',
                            color: isSelected
                                ? FlutterFlowTheme.of(context).primary
                                : FlutterFlowTheme.of(context).secondaryText,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          // Content
          Expanded(
            child: _isLoading && _data.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  )
                : _data.isEmpty || !_canViewSelectedModule
                    ? _buildEmptyState()
                    : _buildRecordsList(),
          ),
           // Pagination
          if (!_isLoading && _data.isNotEmpty) _buildTotalsFooter(),
           if (_lastPage > 1)
             _buildPagination(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final moduleLabel = _getModuleDisplayName(
        _currentOption['module']?.toString() ?? '');
    if (!_canViewSelectedModule) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No tienes permiso para ver registros en $moduleLabel.',
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off,
              size: 48,
              color: FlutterFlowTheme.of(context).secondaryText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin relaciones',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'No se encontraron registros en $moduleLabel que referencien este registro.',
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Outfit',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, index) {
        final record = _data[index];
        final id = record['id'];
        final title = record['title']?.toString() ?? 'Sin título';
        final consecutivo = record['consecutivo']?.toString() ?? '';
        final moduleName =
            record['modulo_info']?['name']?.toString() ?? '';
        final moduleLabel = _getModuleDisplayName(moduleName);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openRecordDetail(record),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: FlutterFlowTheme.of(context)
                      .primary
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  // ID badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      consecutivo.isNotEmpty ? '#$consecutivo' : '#$id',
                      style: FlutterFlowTheme.of(context)
                          .bodySmall
                          .override(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: FlutterFlowTheme.of(context).primary,
                            fontSize: 12,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + module
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 2),
                         Text(
                           moduleLabel,
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText,
                                 fontSize: 11,
                               ),
                         ),
                   if (_displayFields.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: _displayFields.map((slug) {
                                return _buildDisplayField(
                                  context,
                                  slug,
                                  _recordValue(record, slug),
                                );
                              }).toList(),
                           ),
                          ),
                    ],
                      ),
                   ),
                  if (_canDeleteSelectedModule)
                    IconButton(
                      tooltip: 'Eliminar registro',
                      onPressed: _deletingIds.contains(id.toString())
                          ? null
                          : () => _confirmDelete(
                                Map<String, dynamic>.from(record),
                              ),
                      icon: _deletingIds.contains(id.toString())
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline, size: 20),
                      color: FlutterFlowTheme.of(context).error,
                    ),
                   Icon(
                    Icons.arrow_forward_ios,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página $_currentPage de $_lastPage',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 12,
                ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () => _onPageChanged(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                color: FlutterFlowTheme.of(context).primary,
                disabledColor: Colors.grey.withValues(alpha: 0.3),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_currentPage',
                  style: FlutterFlowTheme.of(context)
                      .bodySmall
                      .override(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                ),
              ),
              IconButton(
                onPressed: _currentPage < _lastPage
                    ? () => _onPageChanged(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 20),
                color: FlutterFlowTheme.of(context).primary,
                disabledColor: Colors.grey.withValues(alpha: 0.3),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRecordDetail(Map<String, dynamic> record) {
    Navigator.pop(context); // Close the sheet first

    final moduleName = record['modulo_info']?['name']?.toString() ?? '';

    // Find moduleData from app state
    dynamic moduleData;
    for (final m in FFAppState().moduleList) {
      if (m is Map) {
        final name = m['name']?.toString().trim() ?? '';
        if (name == moduleName) {
          moduleData = m;
          break;
        }
      }
    }

    if (moduleData == null) return;

    // Navigate to grouped detail view
    context.pushNamed(
      'detailGrouped',
      queryParameters: {
        'general': serializeParam(record, ParamType.JSON),
        'moduleData': serializeParam(moduleData, ParamType.JSON),
      }.withoutNulls,
    );
  }
}
