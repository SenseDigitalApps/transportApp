import '../../backend/api_requests/api_calls.dart';
import 'default_relational_controller.dart';
import 'relational_field_config.dart';
import 'services/relational_search_service.dart';
import 'services/relational_cache_service.dart';
import 'widgets/relational_search_bar.dart';
import 'widgets/relational_dropdown.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'default_relational_model.dart';
export 'default_relational_model.dart';

class RelationalWidget extends StatefulWidget {
  const RelationalWidget({
    required this.isEdit,
    required this.text,
    required this.controller,
    this.options,
    this.config,
    required this.onRegisterSelected,
    this.inheritedFields,
    this.onBatchUpdate,
    super.key,
  });

  final String? text;
  final bool isEdit;
  final RelationalController controller;
  final List<String>? options;
  final RelationalFieldConfig? config;
  final Function(int, String, String, String, String, String, int)
      onRegisterSelected;
  final String? inheritedFields;
  final void Function(Map<String, dynamic> updates)? onBatchUpdate;

  @override
  State<RelationalWidget> createState() => _RelationalWidgetState();
}

class _RelationalWidgetState extends State<RelationalWidget> {
  late RelationalModel _model;
  late final FocusNode _focusNode = FocusNode();
  bool _isDropdownVisible = false;

  String? _nameModule;
  String? _typeRelation;
  int _relatedModuleId = 0;
  String _slugFormula = '';
  String _valueFormula = '';
  String _typeFormula = '';

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  final RelationalCacheService _cacheService = RelationalCacheService();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RelationalModel());
    _focusNode.addListener(() {
      final hasFocus = _focusNode.hasFocus;
      if (_isDropdownVisible != hasFocus) {
        _isDropdownVisible = hasFocus;
        _updateOverlay();
        if (hasFocus &&
            widget.isEdit &&
            widget.controller.textController.text.isEmpty &&
            !_hasSelection) {
          _onSearchChanged('');
        }
      }
    });
    _determineUrlParam();
    _findModuleName();
    _extractRelationsFormula();
    _initializeSelectedVariables();
    _preloadInitialData();
  }

  @override
  void didUpdateWidget(covariant RelationalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.config != widget.config ||
        oldWidget.options != widget.options ||
        oldWidget.controller != widget.controller) {
      _determineUrlParam();
      _findModuleName();
      _extractRelationsFormula();
      _initializeSelectedVariables();
    }
  }

  void _determineUrlParam() {
    // El tipo de búsqueda sale de la configuración del campo. El controller
    // puede contener el tipo guardado del valor seleccionado ("register").
    if (widget.config != null) {
      _typeRelation = widget.config!.relationType;
    } else if (widget.controller.fieldConfig != null) {
      _typeRelation = widget.controller.fieldConfig!.relationType;
    } else {
      _typeRelation = widget.controller.type;

      if ((_typeRelation == null || _typeRelation!.isEmpty) &&
          widget.options != null &&
          widget.options!.isNotEmpty) {
        _typeRelation = widget.options![0];
      }
    }

    _typeRelation = RelationalFieldConfig.normalizeType(_typeRelation);
  }

  void _findModuleName() {
    _nameModule = null;
    _relatedModuleId = 0;

    if (_typeRelation == 'user') return;

    // 1. Del config del campo
    if (widget.config != null) {
      _relatedModuleId = widget.config!.relatedModuleId;
      _nameModule = widget.config!.relatedModuleName;
    }

    // 2. Del config que viaja en el controller
    if ((_nameModule == null || _nameModule!.isEmpty) &&
        widget.controller.fieldConfig != null) {
      _relatedModuleId = widget.controller.fieldConfig!.relatedModuleId;
      _nameModule = widget.controller.fieldConfig!.relatedModuleName;
    }

    // 3. Fallback legacy desde options: [type, moduleId, moduleName]
    if ((_nameModule == null || _nameModule!.isEmpty) &&
        widget.options != null &&
        widget.options!.length > 1) {
      _relatedModuleId =
          int.tryParse(widget.options![1].toString()) ?? _relatedModuleId;
    }

    if ((_nameModule == null || _nameModule!.isEmpty) &&
        widget.options != null &&
        widget.options!.length > 2) {
      _nameModule = widget.options![2];
    }

    // 4. Del controller/saved data
    if ((_nameModule == null || _nameModule!.isEmpty) &&
        widget.controller.moduleName?.isNotEmpty == true) {
      _nameModule = widget.controller.moduleName;
    }
    if (_relatedModuleId == 0) {
      _relatedModuleId = widget.controller.module ?? 0;
    }

    // 5. Buscar en moduleList por ID de módulo
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

  void _extractRelationsFormula() {
    _slugFormula = '';
    _valueFormula = '';
    _typeFormula = '';

    if (widget.config != null) {
      _slugFormula = widget.config!.slugFormula;
      _valueFormula = widget.config!.valueFormula;
      _typeFormula = widget.config!.typeFormula;
      return;
    }

    if (widget.controller.relationsFormula != null &&
        widget.controller.relationsFormula!.isNotEmpty) {
      final parts = widget.controller.relationsFormula!.split(',');
      if (parts.length == 3) {
        _slugFormula = parts[0];
        _valueFormula = parts[1];
        _typeFormula = parts[2];
      }
    }
  }

  void _initializeSelectedVariables() {
    final label = widget.controller.relationalLabel;
    final value = widget.controller.relationalValue;

    if (label.isNotEmpty && value != 0) {
      _model.selectedItem = SelectedItem(
        value: value,
        label: label,
        avatar: widget.controller.relationalAvatar,
        fullName: widget.controller.relationalFullName,
        nameModule: widget.controller.moduleName,
        type: widget.controller.type ?? '',
        module: widget.controller.module ?? 0,
      );
      widget.controller.textController.text = label;
    }
  }

  bool get _hasSelection => _model.selectedItem != null;

  void _preloadInitialData() {
    if (_typeRelation == null || _typeRelation!.isEmpty) {
      return;
    }
    if (_typeRelation == 'user' &&
        (_nameModule == null || _nameModule!.isEmpty)) {
      return;
    }

    _ensureModuleNameResolved().then((_) {
      if (!mounted) return;
      _cacheService.preload(
        typeRelation: _typeRelation!,
        nameModule: _nameModule,
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        slugFormula: _slugFormula,
        valueFormula: _valueFormula,
        typeFormula: _typeFormula,
      );
    });
  }

  Future<void> _onSearchChanged(String query) async {
    _model.loadingState = true;
    _model.getInfoRelational = null;
    if (_model.selectedItem != null) {
      _model.selectedItem = null;
      widget.controller.relationalLabel = '';
      widget.controller.relationalValue = 0;
      widget.controller.type = null;
    }
    setState(() {});
    if (_isDropdownVisible) {
      _updateOverlay();
    }

    await _ensureModuleNameResolved();
    if (!mounted) return;

    _model.getInfoRelational = await _cacheService.search(
      query: query,
      typeRelation: _typeRelation ?? 'master',
      nameModule: _nameModule,
      tenant: FFAppState().organizacion,
      token: FFAppState().token,
      slugFormula: _slugFormula,
      valueFormula: _valueFormula,
      typeFormula: _typeFormula,
    );

    if (!mounted) return;

    if (!(_model.getInfoRelational?.succeeded ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron obtener los datos',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).tertiary,
        ),
      );
    }

    _model.loadingState = false;
    setState(() {});
    if (_isDropdownVisible) {
      _updateOverlay();
    }
  }

  Future<void> _ensureModuleNameResolved() async {
    if (_typeRelation == 'user' ||
        (_nameModule != null && _nameModule!.isNotEmpty) ||
        _relatedModuleId <= 0) {
      return;
    }

    _nameModule = _resolveModuleNameFromList(_relatedModuleId);
    if (_nameModule != null && _nameModule!.isNotEmpty) {
      return;
    }

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

  void _onItemSelected(dynamic item) {
    if (_typeRelation == 'user') {
      final avatar = getJsonField(item, r'''$.avatar''')?.toString() ?? '';
      final fullName = getJsonField(item, r'''$.full_name''')?.toString() ?? '';
      final idStr = getJsonField(item, r'''$.id''')?.toString() ?? '0';
      final id = int.tryParse(idStr) ?? 0;
      final label = '$idStr - $fullName';

      _model.selectedItem = SelectedItem(
        value: id,
        label: label,
        avatar: avatar,
        fullName: fullName,
        type: 'user',
        module: 0,
      );

      widget.controller.textController.text = label;
      widget.controller.relationalLabel = label;
      widget.controller.relationalValue = id;
    } else {
      final consecutivo =
          getJsonField(item, r'''$.consecutivo''')?.toString() ?? '';
      final title = getJsonField(item, r'''$.title''')?.toString() ?? '';
      final moduleIdStr =
          getJsonField(item, r'''$.modulo_info.id''')?.toString() ?? '0';
      final moduleName =
          getJsonField(item, r'''$.modulo_info.name''')?.toString() ?? '';
      final idStr = getJsonField(item, r'''$.id''')?.toString() ?? '0';
      final id = int.tryParse(idStr) ?? 0;
      final moduleId = int.tryParse(moduleIdStr) ?? 0;
      final label = '$consecutivo - $title';
      final type = (_typeRelation == 'module') ? 'register' : 'master';

      _model.selectedItem = SelectedItem(
        value: id,
        label: label,
        nameModule: moduleName,
        type: type,
        module: moduleId,
      );

      widget.controller.textController.text = label;
      widget.controller.relationalLabel = label;
      widget.controller.relationalValue = id;
    }

    final selected = _model.selectedItem!;
    widget.onRegisterSelected(
      selected.value,
      selected.avatar ?? '',
      selected.fullName ?? '',
      selected.nameModule ?? '',
      selected.label,
      selected.type,
      selected.module,
    );

    // Procesar campos heredados si están configurados
    if (widget.inheritedFields != null &&
        widget.inheritedFields!.isNotEmpty &&
        widget.onBatchUpdate != null) {
      _processInheritance(selected);
    }

    FocusScope.of(context).unfocus();
    setState(() {});
  }

  Future<void> _processInheritance(SelectedItem selected) async {
    try {
      final type = selected.type;
      final id = selected.value.toString();
      debugPrint('[INHERITANCE] Iniciando herencia para registro id=$id type=$type');
      debugPrint('[INHERITANCE] inheritedFields crudo: ${widget.inheritedFields}');

      final response = await RelationalSearchService.fetchDetail(
        type: type,
        id: id,
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      if (response.statusCode != 200) {
        debugPrint('[INHERITANCE] ERROR: fetchDetail devolvió ${response.statusCode}');
        return;
      }
      final record = response.jsonBody;
      if (record == null) {
        debugPrint('[INHERITANCE] ERROR: record es null');
        return;
      }
      debugPrint('[INHERITANCE] Record obtenido: title=${record['title']}, json_data keys=${(record['json_data'] as Map?)?.keys.toList()}');
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
        // Log del json_data completo (truncado para no saturar)
        final jsonString = jsonEncode(jsonData);
        debugPrint('[INHERITANCE] json_data completo (truncado): ${jsonString.substring(0, jsonString.length > 2000 ? 2000 : jsonString.length)}...');
      }

      final updates = <String, dynamic>{};

      for (final group in widget.inheritedFields!.split('|')) {
        final trimmed = group.trim();
        if (trimmed.isEmpty) continue;
        debugPrint('[INHERITANCE] Procesando grupo: "$trimmed"');

        // Patrón ref_slug:source,target
        final refMatch = RegExp(r'^(ref_\w+):(\w+),(\w+)$').firstMatch(trimmed);
        if (refMatch != null) {
          final refSlug = refMatch.group(1)!;
          final sourceField = refMatch.group(2)!;
          final targetField = refMatch.group(3)!;
          debugPrint('[INHERITANCE] Patrón ref_slug: refSlug=$refSlug, source=$sourceField, target=$targetField');

          final refValue = record['json_data']?[refSlug];
          final refId = refValue is Map ? (refValue['value'] ?? refValue['id']) : refValue;
          if (refId == null) {
            debugPrint('[INHERITANCE] refId es null, saltando');
            continue;
          }

          final directValue = record['json_data']?[sourceField] ?? record[sourceField];
          debugPrint('[INHERITANCE] Valor directo para $sourceField: $directValue');
          if (directValue != null) {
            updates[targetField] = directValue;
            debugPrint('[INHERITANCE] → Agregado update: $targetField = $directValue');
          }
          continue;
        }

        // Patrón directo: source,target
        final directMatch = RegExp(r'^(\w+),(\w+)$').firstMatch(trimmed);
        if (directMatch != null) {
          final sourceField = directMatch.group(1)!;
          final targetField = directMatch.group(2)!;
          final value = record['json_data']?[sourceField] ?? record[sourceField];
          debugPrint('[INHERITANCE] Patrón directo: source=$sourceField, target=$targetField, valor=$value');
          if (value != null) {
            updates[targetField] = value;
            debugPrint('[INHERITANCE] → Agregado update: $targetField = $value');
          } else {
            debugPrint('[INHERITANCE] → Valor null, no se agrega');
          }
          continue;
        }

        // Patrón repeater-relacional: rep_source[source_field],rep_target[target_field]
        // Extrae un campo interno de cada item de un repeater origen y lo pasa a otro repeater destino
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

          // Extraer el campo interno de cada item del repeater origen
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
            // Construir array de items para el repeater destino
            final targetItems = extractedValues.map((val) => {
              targetField: val,
            }).toList();
            updates[targetRepeater] = targetItems;
            debugPrint('[INHERITANCE] [REPEATER] → Agregado update: $targetRepeater = ${targetItems.length} items');
          }
        }
      }

      debugPrint('[INHERITANCE] Total updates a aplicar: ${updates.length}');
      debugPrint('[INHERITANCE] Updates: $updates');

      if (updates.isNotEmpty && widget.onBatchUpdate != null) {
        debugPrint('[INHERITANCE] Llamando onBatchUpdate con updates');
        widget.onBatchUpdate!(updates);
      } else {
        debugPrint('[INHERITANCE] No se llamó onBatchUpdate: updates.isEmpty=${updates.isEmpty}, onBatchUpdate=${widget.onBatchUpdate != null}');
      }
    } catch (e, stackTrace) {
      debugPrint('[INHERITANCE] ERROR: $e');
      debugPrint('[INHERITANCE] StackTrace: $stackTrace');
    }
  }

  void _onClear() {
    FocusScope.of(context).unfocus();
    widget.controller.textController.clear();
    _model.selectedItem = null;
    setState(() {});
  }

  Future<void> _onViewDetail() async {
    if (!_hasSelection) return;

    final selected = _model.selectedItem!;
    if (selected.type == 'user') return;

    try {
      final response = await RelationalSearchService.fetchDetail(
        type: selected.type,
        id: selected.value.toString(),
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        _showSnackBar(
          'Error en la solicitud: Código ${response.statusCode}',
          Colors.redAccent,
        );
        return;
      }

      final data = response.jsonBody;
      if (data == null) {
        _showSnackBar('No se pudieron obtener los datos.', Colors.orange);
        return;
      }

      context.pushNamed(
        'detailGrouped',
        queryParameters: {
          'title': serializeParam('a', ParamType.String),
          'body': serializeParam('aa', ParamType.String),
          'general': serializeParam(data, ParamType.JSON),
        }.withoutNulls,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Ocurrió un error inesperado. Intenta de nuevo.',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _updateOverlay() {
    if (_isDropdownVisible && widget.isEdit && mounted) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    _hideOverlay();
    final overlay = Overlay.of(context);

    final items = _model.getInfoRelational != null
        ? (GetInfoModuleForRelationalCall.data(
              _model.getInfoRelational?.jsonBody ?? '',
            )?.toList() ??
            [])
        : <dynamic>[];

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 55),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                child: RelationalDropdown(
                  isVisible: true,
                  loading: _model.loadingState,
                  items: items,
                  typeRelation: _typeRelation ?? 'master',
                  onItemSelected: (item) {
                    _onItemSelected(item);
                    _hideOverlay();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void deactivate() {
    _hideOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _hideOverlay();
    _model.maybeDispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final hintText =
        '${widget.text}${(_typeRelation == 'user') ? ' usuario' : ' registro'}';

    return Align(
      alignment: const AlignmentDirectional(1, -1),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: RelationalSearchBar(
                controller: widget.controller.textController,
                focusNode: _focusNode,
                isEdit: widget.isEdit,
                hintText: hintText,
                onChanged: (value) => EasyDebounce.debounce(
                  '_model.textController',
                  const Duration(milliseconds: 500),
                  () => _onSearchChanged(value),
                ),
                onClear: _onClear,
                onViewDetail: _onViewDetail,
                showSuffixes: widget.controller.textController.text.isNotEmpty,
                showEye: _hasSelection && _model.selectedItem?.type != 'user',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
