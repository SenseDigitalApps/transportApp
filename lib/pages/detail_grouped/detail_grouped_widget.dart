import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:transport_app/components/acordeon/acordeon_widget.dart';
import 'package:transport_app/components/reverse_relational_sheet.dart';
import '../../components/page_components/screens_background/background_widget.dart';
import '../../components/default_relational/relational_field_config.dart';
import '../../flutter_flow/flutter_flow_expanded_image_view.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'detail_grouped_model.dart';
export 'detail_grouped_model.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter_svg/flutter_svg.dart';

enum FormMode { create, view }

class DetailGroupedWidget extends StatefulWidget {
  const DetailGroupedWidget({
    super.key,
    this.title,
    String? body,
    this.general,
    this.mode = FormMode.view,
    this.moduleName,
    this.moduleId,
    this.moduleType,
    this.template,
    this.moduleData,
    this.moduleConfigData,
  }) : body = body ?? 'No data';

  final String? title;
  final String body;
  final dynamic general;
  final FormMode mode;
  final String? moduleName;
  final int? moduleId;
  final String? moduleType;
  final Map<String, dynamic>? template; // Template data to pre-fill fields
  final dynamic moduleData;
  final dynamic moduleConfigData;

  @override
  State<DetailGroupedWidget> createState() => _DetailGroupedWidgetState();
}

class _DetailGroupedWidgetState extends State<DetailGroupedWidget> {
  late DetailGroupedModel _model;
  List<dynamic>? moduleConfig = [];
  List<Map<String, dynamic>> campos = [];
  dynamic originalCampos = [];
  Map<String, dynamic> jsonConfigToSend = {};
  List<Map<String, dynamic>> jsonRepeaterToSend = [];
  bool canEdit = false;
  bool isLoading = true;
  bool isRecordLocked = false;
  String lockReason = '';
  TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> camposFiltrados = [];
  ApiCallResponse? groupedFields;
  final GlobalKey<AcordeonWidgetState> _acordeonKey =
      GlobalKey<AcordeonWidgetState>();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> canEditNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDisabledButton = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isButtonEnabledNotifier = ValueNotifier<bool>(true);
  void _updateButtonState() {
    isButtonEnabledNotifier.value = !isDisabledButton.value;
  }

  String _resolvedModuleId = '';

  bool get _isCreateMode => widget.mode == FormMode.create;

  String get _moduleLabel {
    final moduleSlug = widget.moduleName?.toString().trim() ?? '';
    if (moduleSlug.isEmpty) return '';

    for (final module in FFAppState().moduleList) {
      if (module is Map<String, dynamic>) {
        final name = module['name']?.toString().trim() ?? '';
        if (name == moduleSlug) {
          final label = module['label']?.toString().trim() ?? '';
          if (label.isNotEmpty) return label;
        }
      } else if (module is Map) {
        final name = module['name']?.toString().trim() ?? '';
        if (name == moduleSlug) {
          final label = module['label']?.toString().trim() ?? '';
          if (label.isNotEmpty) return label;
        }
      }
    }

    return moduleSlug;
  }

  Map<String, dynamic>? get _moduleInfo {
    if (widget.general is! Map) {
      return null;
    }

    final moduloInfo = widget.general['modulo_info'];
    if (moduloInfo is Map<String, dynamic>) {
      return moduloInfo;
    }
    if (moduloInfo is Map) {
      return Map<String, dynamic>.from(moduloInfo);
    }
    if (moduloInfo is List && moduloInfo.isNotEmpty) {
      final firstItem = moduloInfo.first;
      if (firstItem is Map<String, dynamic>) {
        return firstItem;
      }
      if (firstItem is Map) {
        return Map<String, dynamic>.from(firstItem);
      }
    }

    return null;
  }

  // ─── Create Relational helpers ──────────────────────────────────────
  bool get _isCreateRelationalActive {
    final md = widget.moduleData;
    if (md is Map) {
      return md['create_relational'] == true;
    }
    return false;
  }

  String get _createRelationalModuleRaw {
    final md = widget.moduleData;
    if (md is Map) {
      return md['create_relational_module']?.toString() ?? '';
    }
    return '';
  }

  List<Map<String, String>> get _parsedCreateRelationalOptions {
    final raw = _createRelationalModuleRaw;
    if (raw.isEmpty) return [];
    return raw
        .split('|')
        .map((item) {
          final parts = item.split(':');
          if (parts.length >= 2) {
            return {
              'field': parts[0].trim(),
              'module': parts[1].trim(),
            };
          }
          return <String, String>{};
        })
        .where((o) =>
            o.isNotEmpty &&
            o['field']!.isNotEmpty &&
            o['module']!.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _findModuleByName(String moduleName) {
    for (final m in FFAppState().moduleList) {
      if (m is Map<String, dynamic>) {
        if (m['name']?.toString().trim() == moduleName) return m;
      } else if (m is Map) {
        final map = Map<String, dynamic>.from(m);
        if (map['name']?.toString().trim() == moduleName) return map;
      }
    }
    return null;
  }

  Future<void> _navigateToCreateRelational(
      Map<String, String> option) async {
    final targetModuleName = option['module']!;
    final targetFieldSlug = option['field']!;

    final targetModule = _findModuleByName(targetModuleName);
    if (targetModule == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No se encontró el módulo "$targetModuleName"'),
          duration: const Duration(milliseconds: 3000),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }

    final currentModuleName = getJsonField(
            widget.general, r'''$.modulo_info.name''')
        .toString();
    final currentModuleId =
        getJsonField(widget.general, r'''$.modulo_info.id''');
    final currentModuleType = getJsonField(
            widget.general, r'''$.modulo_info.type''')
        .toString();
    final currentRegisterId = widget.general['id'];
    final currentConsecutivo = getJsonField(
            widget.general, r'''$.consecutivo''')
        .toString();
    final currentTitle =
        getJsonField(widget.general, r'''$.title''').toString();

    final relationalValue = {
      'label': '$currentConsecutivo - $currentTitle',
      'module': currentModuleId,
      'type': currentModuleType,
      'value': currentRegisterId,
      'module_name': currentModuleName,
    };

    final template = {
      targetFieldSlug: relationalValue,
    };

    final moduleId = targetModule['id'];
    final moduleType =
        targetModule['type']?.toString() ?? 'registers';

    final result = await context.pushNamed(
      'newRegistersModule',
      queryParameters: {
        'moduleName':
            serializeParam(targetModuleName, ParamType.String),
        'moduleId': serializeParam(
          moduleId is int
              ? moduleId
              : int.tryParse(moduleId?.toString() ?? ''),
          ParamType.int,
        ),
        'moduleType':
            serializeParam(moduleType, ParamType.String),
        'moduleData':
            serializeParam(targetModule, ParamType.JSON),
        'template':
            serializeParam(template, ParamType.JSON),
      }.withoutNulls,
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showCreateRelationalSheet() {
    final options = _parsedCreateRelationalOptions;
    if (options.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark =
            Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E2E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey
                          .withValues(alpha: 0.4),
                      borderRadius:
                          BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Crear registro en',
                  style: FlutterFlowTheme.of(ctx)
                      .titleMedium
                      .override(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 12),
                ...options.map((option) {
                  final targetModule =
                      _findModuleByName(option['module']!);
                  final moduleLabel = targetModule?['label']
                          ?.toString() ??
                      option['module']!;
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(ctx);
                          _navigateToCreateRelational(
                              option);
                        },
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white
                                    .withValues(
                                        alpha: 0.06)
                                : FlutterFlowTheme.of(
                                        ctx)
                                    .primaryBackground,
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                            border: Border.all(
                              color: FlutterFlowTheme
                                      .of(ctx)
                                  .primary
                                  .withValues(
                                      alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .add_circle_outline,
                                color:
                                    FlutterFlowTheme
                                            .of(ctx)
                                        .primary,
                                size: 22,
                              ),
                              const SizedBox(
                                  width: 12),
                              Expanded(
                                child: Text(
                                  moduleLabel,
                                  style: FlutterFlowTheme
                                          .of(ctx)
                                      .bodyMedium
                                      .override(
                                        fontFamily:
                                            'Outfit',
                                        fontWeight:
                                            FontWeight
                                                .w500,
                                        fontSize: 15,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons
                                    .arrow_forward_ios,
                                color: FlutterFlowTheme
                                        .of(ctx)
                                    .secondaryText,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
  // ─── End Create Relational ──────────────────────────────────────────

  // ─── Reverse Relational (Ver Relaciones) helpers ────────────────────
  bool get _isReverseRelationalActive {
    final md = widget.moduleData;
    if (md is Map) {
      return md['reverse_relational'] == true;
    }
    return false;
  }

  String get _reverseRelationalOptionsRaw {
    final md = widget.moduleData;
    if (md is Map) {
      return md['reverse_relational_options']?.toString() ?? '';
    }
    return '';
  }

  List<Map<String, dynamic>> get _parsedReverseRelationalOptions {
    final raw = _reverseRelationalOptionsRaw;
    if (raw.isEmpty) return [];
    return raw.split('|').map((item) {
      final parts = item.split(':');
      if (parts.length >= 2) {
        final result = <String, dynamic>{
          'module': parts[0].trim(),
          'field': parts[1].trim(),
        };
        // Optional third param: column slugs to display
        if (parts.length >= 3 && parts[2].trim().isNotEmpty) {
          result['slugs'] = parts[2].trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
        return result;
      }
      return <String, dynamic>{};
    }).where((o) =>
        o.isNotEmpty &&
        o['module']?.toString().isNotEmpty == true &&
        o['field']?.toString().isNotEmpty == true)
        .toList();
  }

  void _showReverseRelationalSheet() {
    final options = _parsedReverseRelationalOptions;
    if (options.isEmpty) return;

    final currentRecordId = widget.general['id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ReverseRelationalSheet(
          options: options,
          currentRecordId: currentRecordId,
        );
      },
    );
  }
  // ─── End Reverse Relational ─────────────────────────────────────────

  dynamic get _moduleDefinitionFromAppState {
    final currentModuleName = (_isCreateMode
            ? widget.moduleName
            : _moduleInfo?['name']?.toString())
        ?.trim();
    final currentModuleId = (_isCreateMode
            ? (widget.moduleId?.toString())
            : _moduleInfo?['id']?.toString())
        ?.trim();

    for (final module in FFAppState().moduleList) {
      if (module is! Map) {
        continue;
      }

      final moduleMap = module is Map<String, dynamic>
          ? module
          : Map<String, dynamic>.from(module);
      final moduleName = moduleMap['name']?.toString().trim();
      final moduleId = moduleMap['id']?.toString().trim();

      if ((currentModuleName?.isNotEmpty == true &&
              moduleName == currentModuleName) ||
          (currentModuleId?.isNotEmpty == true && moduleId == currentModuleId)) {
        return moduleMap;
      }
    }

    return null;
  }

  Map<String, dynamic> get _namedModuleConfigSources => {
        'moduleData': widget.moduleData,
        'moduleConfigData': widget.moduleConfigData,
        'moduleConfigJsonBody': _model.moduleConfig?.jsonBody,
        'groupedFieldsJsonBody': groupedFields?.jsonBody,
        'general': widget.general,
        'moduleInfo': _moduleInfo,
        'appStateModule': _moduleDefinitionFromAppState,
      };

  List<dynamic> get _moduleConfigSources =>
      _namedModuleConfigSources.values.toList();

  dynamic _decodeJsonIfNeeded(dynamic value) {
    if (value is! String) {
      return value;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return null;
    }

    final looksLikeJson =
        (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'));
    if (!looksLikeJson) {
      return value;
    }

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return value;
    }
  }

  bool _hasMeaningfulConfigValue(dynamic value) {
    if (value == null) {
      return false;
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty && trimmed.toLowerCase() != 'null';
    }
    if (value is Iterable) {
      return value.isNotEmpty;
    }
    if (value is Map) {
      return value.isNotEmpty;
    }
    return true;
  }

  dynamic _findFirstNestedValue(dynamic source, String key) {
    final normalized = _decodeJsonIfNeeded(source);

    if (normalized is Map) {
      if (normalized.containsKey(key) &&
          _hasMeaningfulConfigValue(normalized[key])) {
        return normalized[key];
      }

      for (final value in normalized.values) {
        final nestedValue = _findFirstNestedValue(value, key);
        if (_hasMeaningfulConfigValue(nestedValue)) {
          return nestedValue;
        }
      }
    }

    if (normalized is List) {
      for (final item in normalized) {
        final nestedValue = _findFirstNestedValue(item, key);
        if (_hasMeaningfulConfigValue(nestedValue)) {
          return nestedValue;
        }
      }
    }

    return null;
  }

  String _extractConfigString(String key) {
    for (final source in _moduleConfigSources) {
      final value = _findFirstNestedValue(source, key);
      if (!_hasMeaningfulConfigValue(value)) {
        continue;
      }

      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty && stringValue.toLowerCase() != 'null') {
        return stringValue;
      }
    }

    return '';
  }

  String _findConfigSourceName(String key) {
    for (final entry in _namedModuleConfigSources.entries) {
      final value = _findFirstNestedValue(entry.value, key);
      if (_hasMeaningfulConfigValue(value)) {
        return entry.key;
      }
    }

    return 'not_found';
  }

  int? _extractConfigInt(String key) {
    for (final source in _moduleConfigSources) {
      final value = _findFirstNestedValue(source, key);
      if (!_hasMeaningfulConfigValue(value)) {
        continue;
      }

      if (value is num && value > 0) {
        return value.toInt();
      }

      final parsedValue = int.tryParse(value.toString());
      if (parsedValue != null && parsedValue > 0) {
        return parsedValue;
      }
    }

    return null;
  }

  String get _initialTemplateTitle {
    final templateTitle = widget.template?['title'];
    return templateTitle?.toString() ?? '';
  }

  bool get _hasTitleTemplateConfigured =>
      _extractConfigString('title_template').isNotEmpty;

  int get _titleMinChars => _extractConfigInt('title_min_chars') ?? 3;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  void joinObjectsNew() {
    setState(() {
      isLoading = true;
    });
    try {
      final originalModuleConfig = getJsonField(
        (_model.moduleConfig?.jsonBody ?? ''),
        r'''$.data''',
      );
      originalCampos = _stripFieldTypeChoices(originalModuleConfig);

      final moduleConfig = getJsonField(
        (groupedFields?.jsonBody ?? ''),
        r'''$''',
      );

      if (moduleConfig != null) {
        final List<Map<String, dynamic>> result = [];
        dynamic jsonDataRaw;
        if (_isCreateMode) {
          jsonDataRaw = null;
        } else {
          jsonDataRaw =
              widget.general is Map ? widget.general["json_data"] : null;
        }

        final jsonDataKeys = _isCreateMode
            ? _getEmptyJsonDataKeys(originalModuleConfig)
            : (jsonDataRaw is Map ? jsonDataRaw.keys.toList() : <dynamic>[]);

        _processGroupedFields(moduleConfig, result);
        _processUngroupedFields(moduleConfig, result);
        _addTitle(result);
        campos = result;
        camposFiltrados = result;
        _buildJsonConfigToSend(jsonDataKeys, result);
      }
    } catch (_) {
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  dynamic _stripFieldTypeChoices(dynamic config) {
    if (config is List) {
      return config.map((item) => _stripFieldTypeChoices(item)).toList();
    } else if (config is Map) {
      final cleaned = {};
      config.forEach((key, value) {
        if (key != 'field_type_choices') {
          cleaned[key] = _stripFieldTypeChoices(value);
        }
      });
      return cleaned;
    }
    return config;
  }

  List<String> _getEmptyJsonDataKeys(dynamic originalModuleConfig) {
    final List<String> keys = [];
    if (originalModuleConfig is List) {
      for (var item in originalModuleConfig) {
        if (item is Map && item.containsKey('slug')) {
          keys.add(item['slug'].toString());
        }
      }
    }
    return keys;
  }

  void _processGroupedFields(
      dynamic moduleConfig, List<Map<String, dynamic>> result) {
    final groupedFieldsRaw =
        moduleConfig is Map ? moduleConfig['grouped_fields'] : null;
    if (groupedFieldsRaw is! List) {
      return;
    }
    for (var group in groupedFieldsRaw) {
      if (group is! Map) continue;
      final dynamic category = group['category'];
      final dynamic isExpandible = group['views_expadible'];
      final categoryFields = <Map<String, dynamic>>[];
      final fieldsRaw = group['fields'];
      if (fieldsRaw is List) {
        for (var field in fieldsRaw) {
          if (field is Map) {
            if (field['field_type'] == 'external_value') {
            }
            categoryFields.add(processField(field));
          }
        }
      }
      result.add({
        'category': category?.toString() ?? '',
        'isExpandible':
            isExpandible == true || isExpandible.toString() == 'true',
        'views_formula': group['views_formula']?.toString() ?? '',
        'slug': group['slug']?.toString() ?? (category?.toString() ?? ''),
        'fields': categoryFields,
      });
    }
  }

  void _processUngroupedFields(
      dynamic moduleConfig, List<Map<String, dynamic>> result) {
    final ungroupedFieldsRaw =
        moduleConfig is Map ? moduleConfig['ungrouped_fields'] : null;
    if (ungroupedFieldsRaw is! List) {
      return;
    }
    final ungroupedFields = <Map<String, dynamic>>[];

    for (var field in ungroupedFieldsRaw) {
      if (field is Map) {
        ungroupedFields.add(processField(field));
      }
    }

    if (ungroupedFields.isNotEmpty) {
      result.add({
        'category': 'otros',
        'fields': ungroupedFields,
      });
    }
  }

  void _addTitle(List<Map<String, dynamic>> result) {
    String titleData = '';
    if (_isCreateMode) {
      titleData = _initialTemplateTitle;
    } else {
      titleData = widget.general is Map ? (widget.general["title"] ?? "") : "";
    }
    result.insert(0, {
      'category': 'unique_title_slug_field000111',
      'fields': [
        {
          "slug": "titulo",
          "type": "text",
          "data": titleData,
          "label": "Titulo",
          "is_visible": true,
        }
      ]
    });
  }

  void _buildJsonConfigToSend(
      List<dynamic> jsonDataKeys, List<Map<String, dynamic>> result) {
    if (_isCreateMode) {
      final templateTitle = _initialTemplateTitle;

      jsonConfigToSend = {
        "title": templateTitle,
        "modulo": _resolvedModuleId.isNotEmpty
            ? int.tryParse(_resolvedModuleId)
            : widget.moduleId,
        "json_data": <String, dynamic>{},
      };

      for (var key in jsonDataKeys) {
        final keyStr = key.toString();
        if (keyStr != 'titulo' &&
            widget.template is Map &&
            (widget.template as Map).containsKey(keyStr)) {
          jsonConfigToSend["json_data"][keyStr] = widget.template![keyStr];
        } else if (keyStr == 'titulo') {
          jsonConfigToSend["json_data"][keyStr] = templateTitle;
        } else {
          jsonConfigToSend["json_data"][keyStr] = "";
        }
      }
    } else {
      dynamic moduloId;
      if (widget.general is Map) {
        final moduloInfo = widget.general["modulo_info"];
        if (moduloInfo is Map) {
          moduloId = moduloInfo["id"];
        } else if (moduloInfo is List && moduloInfo.isNotEmpty) {
          moduloId = moduloInfo[0]["id"];
        }
      }

      jsonConfigToSend = {
        "id": getJsonField(widget.general, r'''$.id'''),
        "title": widget.general is Map ? (widget.general["title"] ?? "") : "",
        "json_data": <String, dynamic>{},
        "modulo": moduloId,
      };
      for (var key in jsonDataKeys) {
        final keyStr = key.toString();
        final rawValue = widget.general is Map && widget.general["json_data"] is Map
            ? widget.general["json_data"][keyStr]
            : null;
        jsonConfigToSend["json_data"][keyStr] = rawValue ?? "";
      }
    }
    _processRelationalFields(result);
  }

  void _processRelationalFields(List<Map<String, dynamic>> result) {
    for (var category in result) {
      final fieldsRaw = category['fields'];
      if (fieldsRaw is! List) continue;
      for (var field in fieldsRaw) {
        if (field is! Map) continue;
        if (field['type'] != 'relational') continue;

        final slug = field['slug']?.toString();
        if (slug == null) continue;

        // Only initialize if the key is missing or holds non-Map data
        // (empty string, null). Never overwrite a real Map that already
        // contains the record's relational data (label, value, etc.).
        final existingValue = jsonConfigToSend["json_data"][slug];
        if (existingValue is Map) continue;

        if (!jsonConfigToSend["json_data"].containsKey(slug)) {
          jsonConfigToSend["json_data"][slug] = null;
        }

        final config = field['relationalConfig'] as RelationalFieldConfig?;
        if (config != null) {
          jsonConfigToSend["json_data"][slug] = config.toEmptyJsonValue();
        } else {
          final options = field['options'];
          if (options is List &&
              options.isNotEmpty &&
              options[0].toString() == 'user') {
            jsonConfigToSend["json_data"][slug] = {
              "type": 'user',
              "label": "",
              "value": 0,
              "avatar": "",
              "full_name": ""
            };
          } else {
            jsonConfigToSend["json_data"][slug] = {
              "type": options is List && options.isNotEmpty ? options[0] : '',
              "label": '',
              "value": 0,
              "module": 0,
            };
          }
        }
      }
    }
  }

  Map<String, dynamic> processField(dynamic config) {
    if (config is! Map) {
      return {
        "slug": "",
        "type": "text",
        "data": "",
        "label": "",
        "options": [],
        "relations_formula": '',
        "rol_sign": [],
        "is_visible": true
      };
    }

    final dynamic slug = config["slug"];
    dynamic data;
    dynamic optionsList = [];
    String parsedText = '';
    String relationsFormula = '';
    List<dynamic> rolSign = [];

    if (_isCreateMode) {
      if (widget.template is Map &&
          (widget.template as Map).containsKey(slug)) {
        data = widget.template![slug];
      } else if (widget.template is Map &&
          (widget.template as Map).containsKey('json_data')) {
        final dynamic jsonData = widget.template!['json_data'];
        if (jsonData is Map && jsonData.containsKey(slug)) {
          data = jsonData[slug];
        } else {
          data = '';
        }
      } else {
        data = '';
      }
    } else {
      final dynamic jsonData =
          widget.general is Map ? widget.general["json_data"] : null;
      if (jsonData is Map && jsonData.containsKey(slug)) {
        data = jsonData[slug];
      } else {
        String? matchingKey;
        if (jsonData is Map) {
          try {
            matchingKey = jsonData.keys.firstWhere(
                (key) => key.toString().contains(slug.toString()),
                orElse: () => '');
          } catch (_) {
            matchingKey = '';
          }
        }
        if (matchingKey != null && matchingKey.toString().isNotEmpty) {
          data = jsonData[matchingKey];
        }
      }
    }

    if (config['options'] != null) {
      if (config['field_type'] == 'calculator_advanced' ||
          config['field_type'] == 'calculator' ||
          config['field_type'] == 'text_view' ||
          config['field_type'] == 'external_value' ||
          config['field_type'] == 'mercadopago') {
        optionsList = config["options"];
      } else {
        final optionsRaw = config["options"];
        if (optionsRaw is String) {
          optionsList = optionsRaw.split(',').map((e) => e.trim()).toList();
        } else if (optionsRaw is List) {
          optionsList = optionsRaw;
        } else {
          optionsList = [];
        }
      }
    } else if (config['is_relational'] == true) {
      dynamic value = '';
      dynamic module = config["related_module"];
      int moduleId =
          module is int ? module : int.tryParse(module?.toString() ?? '') ?? 0;
      optionsList = (config["relations_type"] == 'user')
          ? [config["relations_type"], value.toString()]
          : (value != null && moduleId != 0)
              ? [
                  config["relations_type"],
                  moduleId.toString(),
                  value.toString()
                ]
              : [];
    }

    if (_isCreateMode) {
      switch (config['field_type']) {
        case 'checkbox':
          parsedText = _processCheckboxData(data);
          break;
        case 'repeater':
          parsedText = data != null ? jsonEncode(data) : '';
          dynamic repeatersRaw = config['repeaters_item'];
          List<dynamic> repeatersItems = _processRepeaterItems(repeatersRaw);
          optionsList = repeatersItems;
          break;
        case 'relational':
          if (data != null && data.toString().isNotEmpty) {
            parsedText = jsonEncode(data);
          } else {
            parsedText = '';
          }
          relationsFormula = config['relations_formula'] ?? '';
          break;
        case 'image_view':
          parsedText = config['image_url'] ?? '';
          break;
        case 'text_view':
          parsedText = '';
          break;
        case 'firma':
          rolSign = config['rol_sign'] ?? [];
          parsedText = '';
          break;
        case 'firmaext':
          parsedText = '';
          break;
        case 'calendar':
          parsedText = data?.toString() ?? '';
          break;
        case 'datetime':
          parsedText = data?.toString() ?? '';
          break;
        case 'dropdown':
          parsedText = data?.toString() ?? '';
          break;
        case 'status':
          parsedText = data?.toString() ?? '';
          break;
        case 'radio':
          parsedText = data?.toString() ?? '';
          break;
        case 'image':
          parsedText = data?.toString() ?? '';
          break;
        case 'file':
          parsedText = data?.toString() ?? '';
          break;
        case 'georeference':
          parsedText = data?.toString() ?? '';
          break;
        case 'calculator':
          parsedText = data?.toString() ?? '';
          break;
        case 'calculator_advanced':
          parsedText = '';
          break;
        case 'text':
          parsedText = data?.toString() ?? '';
          break;
        case 'textarea':
          parsedText = data?.toString() ?? '';
          break;
        case 'number':
          parsedText = data?.toString() ?? '';
          break;
        case 'boolean':
          parsedText = '';
          break;
        default:
          parsedText = data?.toString() ?? '';
      }
    } else {
      switch (config['field_type']) {
        case 'checkbox':
          parsedText = _processCheckboxData(data);
          break;
        case 'repeater':
          parsedText = jsonEncode(data ?? '');
          List<dynamic> repeatersItems =
              _processRepeaterItems(config['repeaters_item']);
          optionsList = repeatersItems;
          break;
        case 'relational':
          final dynamic generalJsonData =
              widget.general is Map ? widget.general["json_data"] : null;
          dynamic relationalData;
          if (generalJsonData is Map) {
            relationalData = generalJsonData[slug];
          }
          parsedText = jsonEncode(relationalData);
          relationsFormula = config['relations_formula'];
          break;
        case 'image_view':
          parsedText = config['image_url'];
          break;
        case 'text_view':
          parsedText = '';
          optionsList = config['options'] ?? '';
          break;
        case 'firma':
          dynamic result;
          config['field_type_choices'] = '';
          rolSign = config['rol_sign'] ?? [];
          if (data is String) {
            result = jsonEncode({'url': data});
          } else if (data is Map) {
            result = jsonEncode(data);
          } else {
            result = '';
          }
          parsedText = result;
          break;
        default:
          parsedText = data?.toString().trim() ?? '';
      }
    }

    dynamic finalOptions =
        config["field_type"] == 'text_view' ? config["options"] : optionsList;

    RelationalFieldConfig? relationalConfig;
    if (config['is_relational'] == true) {
      final configMap = Map<String, dynamic>.from(config);
      relationalConfig = RelationalFieldConfig.fromRawConfig(configMap);
      // Construir optionsList para backward compat (otros widgets lo leen)
      finalOptions = relationalConfig.toLegacyOptions();
    }

    return {
      "id": config["id"],
      "slug": slug?.toString() ?? '',
      "type": config["field_type"]?.toString() ?? 'text',
      "data": parsedText,
      "label": config["label"]?.toString() ?? '',
      "options": finalOptions,
      "relationalConfig": relationalConfig,
      "relations_formula": relationsFormula,
      "rol_sign": rolSign,
      "is_visible": true,
      "is_required": config["is_required"] ?? false,
      "conditional_value": config["conditional_value"]?.toString() ?? '',
      "related_module_name": config["related_module_name"]?.toString() ?? '',
      "inherited_fields": config["inherited_fields"],
      "is_relational": config["is_relational"] ?? false,
      "relations_type": config["relations_type"],
      "related_module": config["related_module"],
      "inverse_relation_module": config["inverse_relation_module"],
      "inverse_relation_field": config["inverse_relation_field"],
      "inverse_relation_display_fields": config["inverse_relation_display_fields"],
      "inverse_relation_allow_delete": config["inverse_relation_allow_delete"],
    };
  }

  List<dynamic> _processRepeaterItems(dynamic repeatersRaw) {
    List<dynamic> repeatersItems = [];
    if (repeatersRaw is String && repeatersRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(repeatersRaw);
        repeatersItems = decoded is List ? decoded : [];
      } catch (_) {
        repeatersItems = [];
      }
    } else if (repeatersRaw is List) {
      repeatersItems = repeatersRaw;
    }

    return repeatersItems.map((item) {
      if (item is! Map) {
        return item;
      }

      final itemMap = Map<String, dynamic>.from(item);
      if (itemMap['field_type'] == 'firma') {
        itemMap['rol_sign'] =
            itemMap['rol_sign'] ?? itemMap['field_rol_sign'] ?? [];
      }

      final fieldType = itemMap['field_type']?.toString() ?? '';
      final isRelational = fieldType == 'relational' ||
          fieldType == 'relational_from_repeater' ||
          fieldType == 'relational_sub_categories' ||
          itemMap['is_relational'] == true;
      if (isRelational) {
        final relationalConfig = RelationalFieldConfig.fromRawConfig(itemMap);
        itemMap['relationalConfig'] = relationalConfig;
        itemMap['relations_type'] = relationalConfig.relationType;
        itemMap['related_module'] = relationalConfig.relatedModuleId;
        itemMap['related_module_name'] = relationalConfig.relatedModuleName;
        itemMap['options'] = relationalConfig.toLegacyOptions();
        itemMap['inherited_fields'] = itemMap['inherited_fields'];
      }

      if (itemMap['field_type'] == 'repeater') {
        itemMap['repeaters_item'] =
            _processRepeaterItems(itemMap['repeaters_item']);
      }

      return itemMap;
    }).toList();
  }

  String _processCheckboxData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return '';
  }

  bool verificarYRenderizar(List<Map<String, dynamic>> data) {
    return data.length == 1 &&
        data.first['category'] == 'otros' &&
        data.first['fields'] is List &&
        data.first['fields'].length > 0;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailGroupedModel());

    // Check if record is locked (closed_register)
    // Admin maestro puede editar registros bloqueados
    final bool isAdminMaster =
        FFAppState().permissions.contains('admin.query_-_es_admin_maestro');
    if (!_isCreateMode && widget.general is Map && !isAdminMaster) {
      final closedRegister = widget.general['closed_register'];
      if (closedRegister == true) {
        isRecordLocked = true;
        lockReason = 'Este registro está cerrado y no puede ser editado.';
      }
    }

    if (_isCreateMode) {
      canEditNotifier.value = true;
    }

    canEditNotifier.addListener(_updateButtonState);
    isDisabledButton.addListener(_updateButtonState);
    _updateButtonState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      String moduleName;

      if (_isCreateMode) {
        moduleName = widget.moduleName ?? '';
      } else {
        moduleName = getJsonField(
          widget.general,
          r'''$.modulo_info.name''',
        ).toString().toString();
      }

      bool hasConfigData = widget.moduleConfigData != null &&
          widget.moduleConfigData.toString().isNotEmpty &&
          widget.moduleConfigData.toString() != 'null';

      if (hasConfigData) {
        _model.moduleConfig = ApiCallResponse(
          {'data': widget.moduleConfigData},
          {},
          200,
        );
      } else {
        final cachedJson = FFAppState().getCachedModuleConfigJson(moduleName);
        if (cachedJson != null) {
          _model.moduleConfig = ApiCallResponse(
            cachedJson,
            {},
            200,
          );
        } else {
          _model.moduleConfig = await GetCustomFieldsPerModuleCall.call(
            tenant: FFAppState().organizacion,
            moduleName: moduleName,
            token: FFAppState().token,
          );

          if (_model.moduleConfig?.succeeded == true) {
            final moduleId = getJsonField(_model.moduleConfig?.jsonBody ?? '',
                    r'''$.data[0].module''')
                .toString();
            FFAppState().setCachedModuleConfig(
                moduleName, moduleId, _model.moduleConfig?.jsonBody);
          }
        }
      }

      String moduleId;
      if (_isCreateMode) {
        dynamic moduleIdFromConfig;
        final moduleConfigBody = _model.moduleConfig?.jsonBody;
        if (moduleConfigBody is Map &&
            moduleConfigBody['data'] is List &&
            moduleConfigBody['data'].isNotEmpty) {
          final firstItem = moduleConfigBody['data'][0];
          if (firstItem is Map) {
            moduleIdFromConfig = firstItem['module'];
          }
        }
        moduleId = (widget.moduleId?.toString() ??
            moduleIdFromConfig?.toString() ??
            '');
        _resolvedModuleId = moduleId;
      } else {
        moduleId = getJsonField(
          widget.general,
          r'''$.modulo_info.id''',
        ).toString();
      }

      groupedFields = await GetGroupedFieldsCall.call(
        tenant: FFAppState().organizacion,
        moduleId: moduleId,
        token: FFAppState().token,
      );

      setState(() {
        FFAppState().clearTextoControladores();
      });
      joinObjectsNew();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    canEditNotifier.removeListener(_updateButtonState);
    isDisabledButton.removeListener(_updateButtonState);
    isButtonEnabledNotifier.dispose();
    super.dispose();
  }

  bool _canShowEditButton() {
    if (_isCreateMode) return true;
    if (isRecordLocked) return false;
    return functions.hasPermission(
      FFAppState().permissions.toList(),
      'query_-_editar',
      getJsonField(widget.general, r'''$.modulo_info.name''')
          .toString()
          .toString(),
    );
  }

  Future<void> _handleEditOrSave(bool canEdit, bool isSaving) async {
    if (isSaving) return;

    if (!_isCreateMode && !canEdit) {
      canEditNotifier.value = !canEdit;
      FFAppState().clearTextoControladores();
      return;
    }

    isDisabledButton.value = true;

    try {
      final result =
          await _acordeonKey.currentState!.updateJsonConfigToSend();

      if (result["success"] == false) {
        final errorSlugs = result["errors"] as List<dynamic>;

        // Obtener labels a partir de los slugs para mostrar al usuario
        final errorLabels = <String>[];
        for (var cat in campos) {
          final fields = cat['fields'];
          if (fields is! List) continue;
          for (var field in fields) {
            if (field is Map && errorSlugs.contains(field['slug'])) {
              errorLabels.add(field['label']?.toString() ?? field['slug']?.toString() ?? '');
            }
          }
        }

        isDisabledButton.value = false;

        // Mostrar BottomSheet con lista de errores
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildValidationErrorSheet(errorLabels),
        );
        return;
      }

      final finalJson = result["data"];

      if (_isCreateMode) {
        if (finalJson is Map<String, dynamic>) {
          finalJson.remove('id');
        }

        final String titleValue = finalJson['title']?.toString().trim() ?? '';
        final bool requiresManualTitle = !_hasTitleTemplateConfigured;
        final int titleMinChars = _titleMinChars;

        if (requiresManualTitle && titleValue.length < titleMinChars) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡El campo titulo no puede estar vacio, minimo $titleMinChars caracteres!',
                style: TextStyle(color: FlutterFlowTheme.of(context).white),
              ),
              duration: const Duration(milliseconds: 6000),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
          isDisabledButton.value = false;
          return;
        }

        String bodyJson = jsonEncode(finalJson);
        String moduleName = widget.moduleName ?? '';
        String moduleType = widget.moduleType ?? '';

        ApiCallResponse? postResult = await PostNewRegister.call(
          tenant: FFAppState().organizacion,
          moduleName: moduleName,
          moduleType: moduleType,
          token: FFAppState().token,
          body: bodyJson,
        );

        if ((postResult.statusCode).toString() == '400') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Algo salió mal al crear el registro, intentalo de nuevo. ${postResult.jsonBody}',
                style: TextStyle(color: FlutterFlowTheme.of(context).white),
              ),
              duration: const Duration(milliseconds: 6000),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
          isDisabledButton.value = false;
          return;
        }

        if (postResult.succeeded) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Registro creado exitosamente!',
                style: TextStyle(color: FlutterFlowTheme.of(context).white),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true);
            isDisabledButton.value = false;
          });
          return;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Algo salió mal',
                style: TextStyle(color: FlutterFlowTheme.of(context).white),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
          isDisabledButton.value = false;
          return;
        }
      } else {
        String bodyJson = jsonEncode(finalJson);

        ApiCallResponse? postResult = await EditRegister.call(
          tenant: FFAppState().organizacion,
          moduleName: getJsonField(widget.general, r'''$.modulo_info.name''')
              .toString()
              .toString(),
          moduleType: getJsonField(widget.general, r'''$.modulo_info.type''')
              .toString()
              .toString(),
          token: FFAppState().token,
          body: bodyJson,
          id: widget.general is Map ? widget.general['id'] : null,
        );

        if (postResult.succeeded) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Registro editado exitosamente! ${postResult.jsonBody['message'] ?? ''}',
                style: TextStyle(color: FlutterFlowTheme.of(context).white),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
          );
          canEditNotifier.value = !canEdit;
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true);
            isDisabledButton.value = false;
          });
          return;
        } else if (postResult.statusCode == 409) {
          // Record is locked (time limit expired or closed_register)
          String errorMessage =
              'Este registro está bloqueado y no puede ser editado.';
          if (postResult.jsonBody != null &&
              postResult.jsonBody['detail'] != null) {
            errorMessage = postResult.jsonBody['detail'].toString();
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: TextStyle(color: FlutterFlowTheme.of(context).white),
              ),
              duration: const Duration(milliseconds: 6000),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
          isDisabledButton.value = false;
          return;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Algo salió mal',
                style: TextStyle(color: FlutterFlowTheme.of(context).white),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
          isDisabledButton.value = false;
          return;
        }
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error inesperado: $e',
              style: TextStyle(color: FlutterFlowTheme.of(context).white),
            ),
            duration: const Duration(milliseconds: 6000),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
      isDisabledButton.value = false;
      return;
    } finally {
      isDisabledButton.value = false;
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildBottomStickyBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBackground = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.7);

    if (_isCreateMode) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: barBackground,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isDisabledButton,
                  builder: (context, isSaving, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () => _handleEditOrSave(true, isSaving),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          foregroundColor: FlutterFlowTheme.of(context).white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Guardar',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.w600,
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    final showEdit = _canShowEditButton();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: barBackground,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
              child: ValueListenableBuilder<bool>(
                valueListenable: canEditNotifier,
                builder: (context, canEdit, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: isDisabledButton,
                    builder: (context, isSaving, __) {
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _scrollToTop,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    FlutterFlowTheme.of(context).primary,
                                side: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withValues(alpha: 0.85)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Ir arriba',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          FlutterFlowTheme.of(context).primaryText,
                                    ),
                              ),
                            ),
                          ),
                          if (showEdit) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => _handleEditOrSave(canEdit, isSaving),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      FlutterFlowTheme.of(context).primary,
                                  foregroundColor:
                                      FlutterFlowTheme.of(context).white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSaving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            FlutterFlowTheme.of(context).white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        canEdit ? 'Guardar' : 'Editar',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily: 'Outfit',
                                              fontSize: 14,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bottomLeftColor = Colors.grey.shade300.withOpacity(0.98);
    Color topRightColor = FlutterFlowTheme.of(context).primary;

    String appBarTitle;
    String moduleLabel = '';
    if (_isCreateMode) {
      moduleLabel = _moduleLabel;
      appBarTitle = 'Creación para $moduleLabel';
    } else {
      moduleLabel =
          getJsonField(widget.general, r'''$.modulo_info.label''').toString();
      appBarTitle = 'Detalle de';
    }

    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        bottomNavigationBar: _buildBottomStickyBar(context),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.7),
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
                        'Detalle de',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Outfit',
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                      Text(
                        valueOrDefault<String>(
                          _isCreateMode
                              ? _moduleLabel
                              : getJsonField(
                                  widget.general,
                                  r'''$.modulo_info.label''',
                                ).toString(),
                          'No data',
                        ),
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
                      // Botón "Crear registro relacionado"
                      if (!_isCreateMode && _isCreateRelationalActive && _parsedCreateRelationalOptions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 4.0, 5.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _showCreateRelationalSheet,
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_link,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 20.0,
                              ),
                            ),
                        ),
                      ),
                      // Botón "Ver relaciones"
                      if (!_isCreateMode && _isReverseRelationalActive && _parsedReverseRelationalOptions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 4.0, 5.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _showReverseRelationalSheet,
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_tree_outlined,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 20.0,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 5.0, 5.0),
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.8),
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
                        ),
                      ),
                    ],
                  ),
                ],
                centerTitle: true,
                elevation: 0,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
            ),
            child: Stack(children: [
              if (isRecordLocked)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFFFFC107),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.black87, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lockReason,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              DynamicBackground(
                bottomLeftColor: bottomLeftColor,
                topRightColor: topRightColor,
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!_isCreateMode)
                        Padding(
                          padding:
                              const EdgeInsetsGeometry.fromLTRB(16, 10, 16, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Consecutivo: ',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .override(
                                          fontFamily: 'Outfit',
                                          fontSize: 16.0,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                  TextSpan(
                                    text: valueOrDefault<String>(
                                      getJsonField(
                                        widget.general,
                                        r'''$.consecutivo''',
                                      ).toString(),
                                      'No data',
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .override(
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Outfit',
                                          fontSize: 16.0,
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      isLoading == true
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).primary),
                              ),
                            )
                          : ValueListenableBuilder<bool>(
                              valueListenable: canEditNotifier,
                              builder: (context, canEditValue, child) {
                                String generalId;
                                if (_isCreateMode) {
                                  generalId = '0';
                                } else {
                                  generalId =
                                      getJsonField(widget.general, r'''$.id''')
                                          .toString();
                                }

                                return AcordeonWidget(
                                  key: _acordeonKey,
                                  campos: campos,
                                  originalCampos: originalCampos,
                                  canEdit: _isCreateMode ? true : canEditValue,
                                  generalId: generalId,
                                  originalJsonToSend: jsonConfigToSend,
                                  hasTitleTemplateConfigured:
                                      _hasTitleTemplateConfigured,
                                  updateJsonConfigToSend: (newJson) {
                                    safeSetState(() {
                                      // Crear nueva instancia para que didUpdateWidget detecte el cambio
                                      jsonConfigToSend = Map<String, dynamic>.from(newJson);
                                    });
                                  },
                                  general: widget.general,
                                );
                              },
                            ),
                      if (!_isCreateMode) SizedBox(height: 10.0),
                      if (!_isCreateMode)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Fecha publicación: ',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              fontFamily: 'Outfit',
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                      TextSpan(
                                        text: valueOrDefault<String>(
                                          getJsonField(
                                            widget.general,
                                            r'''$.published_date''',
                                          ).toString(),
                                          'No data',
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              fontWeight: FontWeight.w500,
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              fontFamily: 'Outfit',
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Última actualización: ',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              fontFamily: 'Outfit',
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                      TextSpan(
                                        text: valueOrDefault<String>(
                                          getJsonField(
                                            widget.general,
                                            r'''$.last_updated''',
                                          ).toString(),
                                          'No data',
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .override(
                                              fontWeight: FontWeight.w500,
                                              color: FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                              fontFamily: 'Outfit',
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildAuthorSection(context),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorSection(BuildContext context) {
    final avatarPath =
        getJsonField(widget.general, r'''$.profile_info.avatar''').toString();
    final avatarUrl = avatarPath.startsWith('http')
        ? avatarPath
        : 'https://${FFAppState().organizacion}.itsquery.com$avatarPath';
    final isSvg = avatarUrl.toLowerCase().endsWith('.svg');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).accent1,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primaryBackground,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    final heroTag = avatarUrl.isNotEmpty
                        ? avatarUrl
                        : 'avatar_fallback_${getJsonField(widget.general, r'''$.id''')}';
                    await Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        child: FlutterFlowExpandedImageView(
                          image: isSvg
                              ? SvgPicture.network(
                                  avatarUrl,
                                  fit: BoxFit.contain,
                                  placeholderBuilder: (_) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.person,
                                        color: Colors.grey),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.person,
                                        color: Colors.grey),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error,
                                        color: Colors.red),
                                  ),
                                ),
                          allowRotation: false,
                          tag: heroTag,
                          useHeroAnimation: true,
                        ),
                      ),
                    );
                  },
                  child: isSvg
                      ? SvgPicture.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          placeholderBuilder: (_) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                ),
              ),
            ),
          ),
          Text(
            getJsonField(
              widget.general,
              r'''$.profile_info.full_name''',
            ).toString(),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ].divide(SizedBox(width: 10)),
      ),
    );
  }

  Widget _buildValidationErrorSheet(List<String> errorLabels) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Icon + título
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 24),
              const SizedBox(width: 8),
              Text(
                'Campos obligatorios',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Completa los siguientes campos antes de guardar:',
            style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'Outfit',
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          // Lista de errores
          ...errorLabels.map((label) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: Colors.red.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 20),
          // Botón
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: FlutterFlowTheme.of(context).white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
  }
}
