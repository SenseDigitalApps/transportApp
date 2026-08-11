import 'dart:async';
import 'package:flutter/material.dart';
import '../../backend/api_requests/api_calls.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../flutter_flow/custom_functions.dart';
import 'relational_field_config.dart';
import 'relational_formula_parser.dart';
import 'services/relational_search_service.dart';

/// Widget relacional avanzado que replica el comportamiento web en mobile.
/// Soporta: single relational, multiple_relational_select, formulas,
/// herencia de campos, valor por defecto, y bottom sheet para búsqueda.
class RelationalField extends StatefulWidget {
  final Map<String, dynamic> field;
  final Map<String, dynamic> jsonData;
  final bool isEdit;
  final bool isUpdate;
  final bool onlyView;
  final int? index;
  final String? mainSlug;
  final void Function(String slug, dynamic value, int? index, String? mainSlug)
      onChanged;
  final void Function(Map<String, dynamic> updates, {int? index, String? mainSlug})?
      onBatchUpdate;

  const RelationalField({
    super.key,
    required this.field,
    required this.jsonData,
    required this.onChanged,
    this.isEdit = true,
    this.isUpdate = false,
    this.onlyView = false,
    this.index,
    this.mainSlug,
    this.onBatchUpdate,
  });

  @override
  State<RelationalField> createState() => _RelationalFieldState();
}

class _RelationalFieldState extends State<RelationalField> {
  List<RelationalValue> _selectedValues = [];
  bool _isLoading = false;
  List<RelationalSearchResult> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  void Function(VoidCallback)? _sheetSetState;
  String? _nameModule;
  int _relatedModuleId = 0;
  String _typeRelation = 'module';
  RelationalFieldConfig? _config;

  bool get _isMultiple =>
      (widget.field['field_type']?.toString() ?? '') == 'multiple_relational_select';

  String get _slug => widget.field['slug']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _initConfig();
    _syncFromJsonData();
    _maybeLoadDefaultValue();
  }

  @override
  void didUpdateWidget(covariant RelationalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonData != widget.jsonData ||
        oldWidget.field != widget.field) {
      _syncFromJsonData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Configuración
  // ─────────────────────────────────────────────────────────────

  void _initConfig() {
    _config = widget.field['relationalConfig'] as RelationalFieldConfig?;
    if (_config == null) {
      _config = RelationalFieldConfig.fromRawConfig(
          Map<String, dynamic>.from(widget.field));
    }

    _typeRelation = _config!.relationType;
    _relatedModuleId = _config!.relatedModuleId;
    _nameModule = _config!.relatedModuleName;

    if ((_nameModule == null || _nameModule!.isEmpty) && _relatedModuleId > 0) {
      _nameModule = _resolveModuleNameFromList(_relatedModuleId);
    }
  }

  String? _resolveModuleNameFromList(int moduleId) {
    for (final m in FFAppState().moduleList) {
      if (m is Map) {
        final id = m['id'];
        if (id?.toString() == moduleId.toString()) {
          return m['name']?.toString();
        }
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Sincronización con jsonData
  // ─────────────────────────────────────────────────────────────

  dynamic get _rawValue {
    if (widget.mainSlug != null && widget.index != null) {
      final mainData = widget.jsonData[widget.mainSlug!];
      if (mainData is List && widget.index! < mainData.length) {
        return mainData[widget.index!][_slug];
      }
    }
    return widget.jsonData[_slug];
  }

  void _syncFromJsonData() {
    final raw = _rawValue;
    if (_isMultiple) {
      if (raw is List) {
        _selectedValues = raw
            .map((r) => RelationalValue.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        _selectedValues = [];
      }
    } else {
      if (raw is Map) {
        _selectedValues = [RelationalValue.fromJson(raw as Map<String, dynamic>)];
      } else {
        _selectedValues = [];
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Valor por defecto (solo en creación)
  // ─────────────────────────────────────────────────────────────

  Future<void> _maybeLoadDefaultValue() async {
    if (widget.isUpdate) return;
    final defaultVal = widget.field['default_value']?.toString() ?? '';
    if (defaultVal.isEmpty) return;

    final defaultId = num.tryParse(defaultVal);
    if (defaultId == null) return;

    if (_selectedValues.isNotEmpty) return;

    await _ensureModuleNameResolved();
    if (!mounted) return;

    try {
      final response = await RelationalSearchService.fetchDetail(
        type: _config!.storageType,
        id: defaultId.toString(),
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      if (!mounted || response.statusCode != 200) return;
      final data = response.jsonBody;
      if (data == null) return;

      final item = _buildSearchResult(data, fromSingle: true);
      if (item != null) {
        _selectValue(_resultToValue(item));
      }
    } catch (e) {
      debugPrint('Default value load error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Búsqueda
  // ─────────────────────────────────────────────────────────────

  Future<void> _ensureModuleNameResolved() async {
    if (_typeRelation == 'user' ||
        (_nameModule != null && _nameModule!.isNotEmpty) ||
        _relatedModuleId <= 0) {
      return;
    }

    _nameModule = _resolveModuleNameFromList(_relatedModuleId);
    if (_nameModule != null && _nameModule!.isNotEmpty) return;

    final modulesResponse = await ModulosCall.call(
      tenant: FFAppState().organizacion,
      token: FFAppState().token,
    );
    if (!modulesResponse.succeeded) return;
    final data = modulesResponse.jsonBody['data'];
    if (data is! List) return;

    FFAppState().update(() {
      FFAppState().moduleList = data;
    });
    _nameModule = _resolveModuleNameFromList(_relatedModuleId);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String term) async {
    if (term.trim().isEmpty) {
      _sheetSetState?.call(() => _searchResults = []);
      return;
    }
    _sheetSetState?.call(() => _isLoading = true);

    try {
      await _ensureModuleNameResolved();
      if (!mounted) return;

      final relationsFormula = widget.field['relations_formula']?.toString();

      final response = await RelationalSearchService.search(
        query: term,
        typeRelation: _typeRelation,
        nameModule: _nameModule,
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        relationsFormula: relationsFormula,
        jsonData: widget.jsonData,
        mainSlug: widget.mainSlug,
        index: widget.index,
      );

      if (!mounted) return;

      final data = GetInfoModuleForRelationalCall.data(response);
      if (data is List) {
        _searchResults = data
            .map((item) => _buildSearchResult(item))
            .where((r) => r != null)
            .cast<RelationalSearchResult>()
            .toList();
      } else {
        _searchResults = [];
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) {
        _sheetSetState?.call(() => _isLoading = false);
      }
    }
  }

  RelationalSearchResult? _buildSearchResult(dynamic item, {bool fromSingle = false}) {
    if (item == null) return null;
    final map = item is Map<String, dynamic> ? item : <String, dynamic>{};

    if (_typeRelation == 'user') {
      final id = map['id'];
      final fullName = map['full_name']?.toString() ?? '';
      final avatar = map['avatar']?.toString() ?? '';
      return RelationalSearchResult(
        id: id,
        label: fullName.isNotEmpty ? fullName : map['username']?.toString() ?? '',
        subtitle: map['username']?.toString(),
        avatar: avatar,
        type: 'user',
        rawData: map,
      );
    } else {
      final id = map['id'];
      final consecutivo = map['consecutivo']?.toString() ?? '';
      final title = map['title']?.toString() ?? '';
      final moduleInfo = map['modulo_info'] is Map ? map['modulo_info'] as Map : null;
      final moduleId = moduleInfo?['id'] ?? _relatedModuleId;
      final moduleName = moduleInfo?['name']?.toString() ?? _nameModule ?? '';

      final showConsecutive = widget.field['show_consecutive'] != false;
      final label = (showConsecutive && consecutivo.isNotEmpty)
          ? '$consecutivo - $title'
          : title;

      return RelationalSearchResult(
        id: id,
        label: label,
        subtitle: moduleName.isNotEmpty ? moduleName : null,
        type: _config!.storageType,
        moduleId: moduleId,
        moduleName: moduleName,
        rawData: map,
      );
    }
  }

  RelationalValue _resultToValue(RelationalSearchResult result) {
    return RelationalValue(
      value: result.id,
      label: result.label,
      type: result.type ?? _config!.storageType,
      module: result.moduleId ?? _relatedModuleId,
      moduleName: result.moduleName ?? _nameModule,
      avatar: result.avatar,
      fullName: result.avatar != null ? result.label : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Selección / Clear
  // ─────────────────────────────────────────────────────────────

  void _selectValue(RelationalValue value) {
    if (_isMultiple) {
      // Evitar duplicados
      if (_selectedValues.any((v) => v.value.toString() == value.value.toString())) {
        return;
      }
      final newList = [..._selectedValues, value];
      _selectedValues = newList;
      _updateValue(newList.map((v) => v.toJson()).toList());
    } else {
      _selectedValues = [value];
      _updateValue(value.toJson());
      Navigator.pop(context);

      // Procesar campos heredados
      final inherited = widget.field['inherited_fields']?.toString();
      if (inherited != null && inherited.isNotEmpty && widget.onBatchUpdate != null) {
        _processInheritance(value, inherited);
      }
    }
  }

  void _removeValue(RelationalValue value) {
    if (_isMultiple) {
      final newList = _selectedValues
          .where((v) => v.value.toString() != value.value.toString())
          .toList();
      _selectedValues = newList;
      _updateValue(newList.map((v) => v.toJson()).toList());
    } else {
      _selectedValues = [];
      _updateValue(null);
    }
  }

  void _clearAll() {
    _selectedValues = [];
    _updateValue(_isMultiple ? [] : null);
  }

  void _updateValue(dynamic value) {
    widget.onChanged(_slug, value, widget.index, widget.mainSlug);
  }

  // ─────────────────────────────────────────────────────────────
  // Herencia de campos (inherited_fields)
  // ─────────────────────────────────────────────────────────────

  Future<void> _processInheritance(RelationalValue selected, String inheritedFieldsStr) async {
    try {
      // Obtener registro completo
      final response = await RelationalSearchService.fetchDetail(
        type: selected.type,
        id: selected.value.toString(),
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );
      if (response.statusCode != 200) {
        debugPrint('[INHERITANCE] [REPEATER] ERROR: fetchDetail devolvió ${response.statusCode}');
        return;
      }
      final record = response.jsonBody;
      if (record == null) {
        debugPrint('[INHERITANCE] [REPEATER] ERROR: record es null');
        return;
      }
      // Log del json_data completo para debug de repeaters
      if (record['json_data'] != null) {
        final jsonData = record['json_data'] as Map<String, dynamic>;
        final repeaterKeys = jsonData.keys.where((k) => k.startsWith('rep_')).toList();
        if (repeaterKeys.isNotEmpty) {
          debugPrint('[INHERITANCE] [REPEATER] json_data contiene repeaters: $repeaterKeys');
          for (final repKey in repeaterKeys) {
            final repValue = jsonData[repKey];
            debugPrint('[INHERITANCE] [REPEATER] $repKey = ${repValue.runtimeType}: ${repValue.toString().substring(0, repValue.toString().length > 300 ? 300 : repValue.toString().length)}...');
          }
        }
        final jsonString = jsonEncode(jsonData);
        debugPrint('[INHERITANCE] [REPEATER] json_data completo (truncado): ${jsonString.substring(0, jsonString.length > 2000 ? 2000 : jsonString.length)}...');
      }

      final updates = <String, dynamic>{};

      for (final group in inheritedFieldsStr.split('|')) {
        final trimmed = group.trim();
        if (trimmed.isEmpty) continue;

        // Patrón: ref_slug:source,target
        final refMatch = RegExp(r'^(ref_\w+):(\w+),(\w+)$').firstMatch(trimmed);
        if (refMatch != null) {
          final refSlug = refMatch.group(1)!;
          final sourceField = refMatch.group(2)!;
          final targetField = refMatch.group(3)!;

          final refValue = record['json_data']?[refSlug];
          final refId = refValue is Map ? (refValue['value'] ?? refValue['id']) : refValue;
          if (refId == null) continue;

          // Fetch registro referenciado (simplificado: usamos valor directo si está disponible)
          // En una implementación completa se haría otra llamada API aquí.
          // Por ahora, copiamos el valor directo si existe.
          final directValue = record['json_data']?[sourceField] ?? record[sourceField];
          if (directValue != null) {
            updates[targetField] = directValue;
          }
          continue;
        }

        // Patrón directo: source,target
        final directMatch = RegExp(r'^(\w+),(\w+)$').firstMatch(trimmed);
        if (directMatch != null) {
          final sourceField = directMatch.group(1)!;
          final targetField = directMatch.group(2)!;
          final value = record['json_data']?[sourceField] ?? record[sourceField];
          if (value != null) {
            updates[targetField] = value;
          }
          continue;
        }

        // Patrón repeater-relacional: rep_source[source_field],rep_target[target_field]
        final repeaterMatch = RegExp(r'^(rep_\w+)\[(\w+)\],(rep_\w+)\[(\w+)\]$').firstMatch(trimmed);
        if (repeaterMatch != null) {
          final sourceRepeater = repeaterMatch.group(1)!;
          final sourceField = repeaterMatch.group(2)!;
          final targetRepeater = repeaterMatch.group(3)!;
          final targetField = repeaterMatch.group(4)!;
          debugPrint('[INHERITANCE] [REPEATER] Patrón repeater-relacional: source=$sourceRepeater[$sourceField], target=$targetRepeater[$targetField]');

          final sourceValue = record['json_data']?[sourceRepeater];
          if (sourceValue is! List || sourceValue.isEmpty) {
            debugPrint('[INHERITANCE] [REPEATER] Source repeater no es una lista o está vacío: ${sourceValue?.runtimeType}');
            continue;
          }

          final extractedValues = sourceValue.map((item) {
            if (item is Map) {
              final val = item[sourceField];
              debugPrint('[INHERITANCE] [REPEATER] Extrayendo $sourceField de item: $val');
              return val;
            }
            return null;
          }).where((v) => v != null).toList();

          debugPrint('[INHERITANCE] [REPEATER] Valores extraídos: ${extractedValues.length} items');
          if (extractedValues.isNotEmpty) {
            final targetItems = extractedValues.map((val) => {
              targetField: val,
            }).toList();
            updates[targetRepeater] = targetItems;
            debugPrint('[INHERITANCE] [REPEATER] → Agregado update: $targetRepeater = ${targetItems.length} items');
          }
        }
      }

      if (updates.isNotEmpty && widget.onBatchUpdate != null) {
        widget.onBatchUpdate!(updates, index: widget.index, mainSlug: widget.mainSlug);
      }
    } catch (e) {
      debugPrint('Inheritance error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _isMultiple ? _buildMultiField() : _buildSingleField();
  }

  Widget _buildSingleField() {
    final selected = _selectedValues.isNotEmpty ? _selectedValues.first : null;

    return InkWell(
      onTap: widget.isEdit && !widget.onlyView ? _openSearchSheet : null,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48, maxHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          border: Border.all(
            color: FlutterFlowTheme.of(context).accent1,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              if (selected.avatar != null && selected.avatar!.isNotEmpty)
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(
                    buildMediaUrl(selected.avatar!),
                  ),
                  onBackgroundImageError: (_, __) {},
                )
              else
                Icon(
                  selected.type == 'user' ? Icons.person : Icons.folder,
                  size: 20,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected.label,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        letterSpacing: 0.0,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isEdit && !widget.onlyView)
                InkWell(
                  onTap: _removeSingle,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
            ] else
              Expanded(
                child: Text(
                  'Seleccionar...',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        letterSpacing: 0.0,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ),
            if (selected == null)
              Icon(
                Icons.arrow_drop_down,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
          ],
        ),
      ),
    );
  }

  void _removeSingle() {
    _selectedValues = [];
    _updateValue(null);
  }

  Widget _buildMultiField() {
    return InkWell(
      onTap: widget.isEdit && !widget.onlyView ? _openSearchSheet : null,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          border: Border.all(
            color: FlutterFlowTheme.of(context).accent1,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ..._selectedValues.map((v) => _buildChip(v)),
            if (_selectedValues.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No hay relaciones configuradas',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        letterSpacing: 0.0,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(RelationalValue v) {
    final isUser = v.type == 'user';
    return Chip(
      avatar: isUser && v.avatar != null && v.avatar!.isNotEmpty
          ? CircleAvatar(
              backgroundImage: NetworkImage(
                buildMediaUrl(v.avatar!),
              ),
              onBackgroundImageError: (_, __) {},
            )
          : null,
      label: Text(
        v.label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      deleteIcon: widget.isEdit && !widget.onlyView
          ? const Icon(Icons.close, size: 14)
          : null,
      onDeleted: widget.isEdit && !widget.onlyView ? () => _removeValue(v) : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Bottom Sheet de búsqueda
  // ─────────────────────────────────────────────────────────────

  void _openSearchSheet() {
    _searchController.clear();
    _searchResults = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          _sheetSetState = setSheetState;
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: FlutterFlowTheme.of(context).accent1,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isMultiple
                              ? 'Seleccionar registros'
                              : 'Seleccionar registro',
                          style: FlutterFlowTheme.of(context).titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _onSearchChanged(),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                // Results
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults.isEmpty
                          ? Center(
                              child: Text(
                                _searchController.text.isEmpty
                                    ? 'Escribe para buscar...'
                                    : 'No se encontraron resultados',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final result = _searchResults[i];
                                return ListTile(
                                  leading: result.avatar != null && result.avatar!.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            buildMediaUrl(result.avatar!),
                                          ),
                                          onBackgroundImageError: (_, __) {},
                                        )
                                      : Icon(
                                          result.type == 'user'
                                              ? Icons.person
                                              : Icons.folder,
                                          color: FlutterFlowTheme.of(context).secondaryText,
                                        ),
                                  title: Text(
                                    result.label,
                                    style: FlutterFlowTheme.of(context).bodyMedium,
                                  ),
                                  subtitle: result.subtitle != null
                                      ? Text(
                                          result.subtitle!,
                                          style: FlutterFlowTheme.of(context).bodySmall,
                                        )
                                      : null,
                                  onTap: () {
                                    _selectValue(_resultToValue(result));
                                    if (_isMultiple) {
                                      setSheetState(() {});
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => _sheetSetState = null);
  }
}
