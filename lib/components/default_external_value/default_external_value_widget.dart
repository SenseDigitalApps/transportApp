import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Helper para leer tanto camelCase como snake_case del JSON
T? _read<T>(Map<String, dynamic> json, String camelKey, String snakeKey) {
  if (json.containsKey(camelKey)) return json[camelKey] as T?;
  if (json.containsKey(snakeKey)) return json[snakeKey] as T?;
  return null;
}

class AuthConfig {
  String type;
  String? usernameKey;
  String? passwordKey;
  AuthConfig({required this.type, this.usernameKey, this.passwordKey});
  factory AuthConfig.fromJson(Map<String, dynamic> json) => AuthConfig(
        type: json['type'] ?? 'none',
        usernameKey: _read<String>(json, 'usernameKey', 'username_key'),
        passwordKey: _read<String>(json, 'passwordKey', 'password_key'),
      );
}

class ResponseConfig {
  String format;
  String itemsPath;
  String valueField;
  String labelField;
  Map<String, String>? filterBy;
  Map<String, List<String>>? fieldAliases;
  ResponseConfig({
    required this.format,
    required this.itemsPath,
    required this.valueField,
    required this.labelField,
    this.filterBy,
    this.fieldAliases,
  });
  factory ResponseConfig.fromJson(Map<String, dynamic> json) => ResponseConfig(
        format: _read<String>(json, 'format', 'format') ?? 'json',
        itemsPath: _read<String>(json, 'itemsPath', 'items_path') ?? '',
        valueField: _read<String>(json, 'valueField', 'value_field') ?? '',
        labelField: _read<String>(json, 'labelField', 'label_field') ?? '',
        filterBy: _read<Map<String, dynamic>>(json, 'filterBy', 'filter_by') != null
            ? Map<String, String>.from(_read<Map<String, dynamic>>(json, 'filterBy', 'filter_by')!)
            : null,
        fieldAliases: _read<Map<String, dynamic>>(json, 'fieldAliases', 'field_aliases') != null
            ? (_read<Map<String, dynamic>>(json, 'fieldAliases', 'field_aliases')! as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, List<String>.from(v)),
              )
            : null,
      );
}

class BodyVariant {
  String matchParam;
  String matchPrefix;
  bool isDefault;
  String bodyTemplate;
  ResponseConfig? response;
  BodyVariant({
    required this.matchParam,
    required this.matchPrefix,
    required this.isDefault,
    required this.bodyTemplate,
    this.response,
  });
  factory BodyVariant.fromJson(Map<String, dynamic> json) => BodyVariant(
        matchParam: _read<String>(json, 'matchParam', 'match_param') ?? '',
        matchPrefix: _read<String>(json, 'matchPrefix', 'match_prefix') ?? '',
        isDefault: _read<bool>(json, 'isDefault', 'is_default') ?? false,
        bodyTemplate: _read<String>(json, 'bodyTemplate', 'body_template') ?? '',
        response: json['response'] != null
            ? ResponseConfig.fromJson(json['response'])
            : null,
      );
}

class RequestConfig {
  String method;
  Map<String, String> headers;
  Map<String, String> params;
  String bodyTemplate;
  List<BodyVariant> bodyVariants;
  List<String>? paramsFromRecord;
  RequestConfig({
    required this.method,
    required this.headers,
    required this.params,
    required this.bodyTemplate,
    required this.bodyVariants,
    this.paramsFromRecord,
  });
  factory RequestConfig.fromJson(Map<String, dynamic> json) => RequestConfig(
        method: json['method'] ?? 'GET',
        headers: json['headers'] != null
            ? Map<String, String>.from(json['headers'])
            : {},
        params: json['params'] != null
            ? Map<String, String>.from(json['params'])
            : {},
        bodyTemplate: _read<String>(json, 'bodyTemplate', 'body_template') ?? '',
        bodyVariants: (_read<List<dynamic>>(json, 'bodyVariants', 'body_variants') ?? [])
            .map((e) => BodyVariant.fromJson(e as Map<String, dynamic>))
            .toList(),
        paramsFromRecord: _read<List<dynamic>>(json, 'paramsFromRecord', 'params_from_record') != null
            ? List<String>.from(_read<List<dynamic>>(json, 'paramsFromRecord', 'params_from_record')!)
            : null,
      );
}

class ExternalConfig {
  String sourceType;
  String mode;
  String endpoint;
  AuthConfig auth;
  RequestConfig request;
  ResponseConfig response;
  int cacheTtl;
  ExternalConfig({
    required this.sourceType,
    required this.mode,
    required this.endpoint,
    required this.auth,
    required this.request,
    required this.response,
    required this.cacheTtl,
  });
  factory ExternalConfig.fromJson(Map<String, dynamic> json) => ExternalConfig(
        sourceType: _read<String>(json, 'sourceType', 'source_type') ?? 'rest_get',
        mode: json['mode'] ?? 'single_value',
        endpoint: json['endpoint'] ?? '',
        auth: json['auth'] != null
            ? AuthConfig.fromJson(json['auth'])
            : AuthConfig(type: 'none'),
        request: json['request'] != null
            ? RequestConfig.fromJson(json['request'])
            : RequestConfig(method: 'GET', headers: {}, params: {}, bodyTemplate: '', bodyVariants: []),
        response: json['response'] != null
            ? ResponseConfig.fromJson(json['response'])
            : ResponseConfig(format: 'json', itemsPath: '', valueField: '', labelField: ''),
        cacheTtl: _read<int>(json, 'cacheTtl', 'cache_ttl') ?? 0,
      );
}

List<String> extractRecordPlaceholders(List<String> texts) {
  final Set<String> slugs = {};
  final regex = RegExp(r'\{\{(\w+)\}\}');
  final exclude = {'AUTH_USERNAME', 'AUTH_PASSWORD'};
  for (final text in texts) {
    final matches = regex.allMatches(text);
    for (final match in matches) {
      final slug = match.group(1)!;
      if (!exclude.contains(slug)) {
        slugs.add(slug);
      }
    }
  }
  return slugs.toList();
}

class ExternalValueField extends StatefulWidget {
  final Map<String, dynamic> field;
  final Map<String, dynamic> jsonData;
  final Function(String slug, dynamic value, int? index, String? mainSlug) handleDynamicFieldChanges;
  final String? mainSlug;
  final int? index;
  final bool isEdit;
  final bool onlyView;

  const ExternalValueField({
    super.key,
    required this.field,
    required this.jsonData,
    required this.handleDynamicFieldChanges,
    this.mainSlug,
    this.index,
    this.isEdit = false,
    this.onlyView = false,
  });

  @override
  State<ExternalValueField> createState() => _ExternalValueFieldState();
}

class _ExternalValueFieldState extends State<ExternalValueField> {
  String displayValue = '';
  bool isLoading = false;
  String? errorMessage;
  Timer? _debounceTimer;
  late List<String> referencedSlugs;
  ExternalConfig? externalConfig;
  Map<String, dynamic>? _lastParams;
  bool _hasFetchedOnce = false;

  @override
  void initState() {
    super.initState();
    _parseConfig();
    _initDisplayValue();
    debugPrint('=== EXTERNAL_VALUE initState === slug=${widget.field['slug']} jsonDataHash=${identityHashCode(widget.jsonData)} displayValue=$displayValue');
    // Fetch inicial si hay params disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('=== EXTERNAL_VALUE postFrameCallback === slug=${widget.field['slug']} calling _checkAndFetch');
      _checkAndFetch();
    });
  }

  void _parseConfig() {
    final options = widget.field['options'];
    if (options == null || options.toString().isEmpty) {
      externalConfig = null;
      referencedSlugs = [];
      debugPrint('=== EXTERNAL_VALUE parseConfig === NO OPTIONS, aborting');
      return;
    }
    try {
      final json = jsonDecode(options.toString()) as Map<String, dynamic>;
      debugPrint('=== EXTERNAL_VALUE parseConfig === RAW JSON: $json');
      externalConfig = ExternalConfig.fromJson(json);
      _computeReferencedSlugs();
      debugPrint('=== EXTERNAL_VALUE parseConfig === SUCCESS slugs=$referencedSlugs endpoint=${externalConfig?.endpoint}');
    } catch (e, st) {
      externalConfig = null;
      referencedSlugs = [];
      debugPrint('=== EXTERNAL_VALUE parseConfig === ERROR: $e');
      debugPrint('=== EXTERNAL_VALUE parseConfig === STACK: $st');
    }
  }

  void _computeReferencedSlugs() {
    if (externalConfig == null) return;
    final texts = <String>[externalConfig!.endpoint];
    texts.add(externalConfig!.request.bodyTemplate);
    texts.addAll(externalConfig!.request.params.values);
    for (final variant in externalConfig!.request.bodyVariants) {
      texts.add(variant.bodyTemplate);
      if (variant.response?.filterBy != null) {
        texts.addAll(variant.response!.filterBy!.values);
      }
    }

    // Fallback directo al JSON raw por si el parsing de ExternalConfig falló
    // con alguna key en snake_case que no cubrimos arriba
    List<String>? rawLegacyParams;
    String? rawBodyTemplate;
    try {
      final raw = widget.field['options'];
      if (raw != null) {
        final json = jsonDecode(raw.toString()) as Map<String, dynamic>;
        final req = json['request'] as Map<String, dynamic>?;
        if (req != null) {
          rawLegacyParams = req['params_from_record'] != null
              ? List<String>.from(req['params_from_record'])
              : null;
          rawBodyTemplate = req['body_template']?.toString();
        }
      }
    } catch (_) {}

    if (rawBodyTemplate != null && rawBodyTemplate.isNotEmpty) {
      texts.add(rawBodyTemplate);
    }

    final legacyParams = externalConfig!.request.paramsFromRecord ?? rawLegacyParams;

    if (legacyParams != null) {
      referencedSlugs = [
        ...extractRecordPlaceholders(texts),
        ...legacyParams,
      ];
    } else {
      referencedSlugs = extractRecordPlaceholders(texts);
    }
    debugPrint('=== EXTERNAL_VALUE _computeReferencedSlugs === texts=$texts slugs=$referencedSlugs legacyParams=$legacyParams');
  }

  void _initDisplayValue() {
    final record = _getRecord();
    final slug = widget.field['slug'];
    if (record[slug] != null && displayValue.isEmpty) {
      displayValue = record[slug].toString();
    }
  }

  Map<String, dynamic> _getRecord() {
    if (widget.mainSlug != null && widget.index != null) {
      final mainData = widget.jsonData[widget.mainSlug];
      if (mainData is List && widget.index! < mainData.length) {
        final item = mainData[widget.index!];
        if (item is Map<String, dynamic>) return item;
      }
    }
    return widget.jsonData;
  }

  Map<String, dynamic> _buildParams() {
    final record = _getRecord();
    final params = <String, dynamic>{};
    for (final slug in referencedSlugs) {
      params[slug] = record[slug] ?? '';
    }
    return params;
  }

  /// Comparar params actuales con _lastParams para evitar fetches duplicados
  bool _paramsChanged(Map<String, dynamic> params) {
    if (_lastParams == null) return true;
    final lastKey = jsonEncode(_lastParams);
    final currentKey = jsonEncode(params);
    return lastKey != currentKey;
  }

  bool _allParamsEmpty(Map<String, dynamic> params) {
    if (params.isEmpty) return false;
    return params.values.every((v) => v == null || v.toString().isEmpty);
  }

  int? get _fieldId {
    final id = widget.field['id'] ?? widget.field['field_id'] ?? widget.field['custom_field_id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  void _checkAndFetch() {
    if (externalConfig == null) {
      debugPrint('=== EXTERNAL_VALUE _checkAndFetch === externalConfig is null, aborting');
      return;
    }
    final fieldId = _fieldId;
    if (fieldId == null) {
      debugPrint('=== EXTERNAL_VALUE _checkAndFetch === fieldId is null, aborting');
      return;
    }

    final params = _buildParams();
    debugPrint('=== EXTERNAL_VALUE _checkAndFetch === slug=${widget.field['slug']} params=$params referencedSlugs=$referencedSlugs');

    // No re-fetch si los params no cambiaron
    if (!_paramsChanged(params)) {
      debugPrint('=== EXTERNAL_VALUE _checkAndFetch === params did not change, skipping fetch');
      return;
    }

    // No fetch si todos los params están vacíos y tenemos dependencias
    if (referencedSlugs.isNotEmpty && _allParamsEmpty(params)) {
      debugPrint('=== EXTERNAL_VALUE _checkAndFetch === all params empty and has dependencies, skipping fetch');
      return;
    }

    // Si no hay slugs referenciados y ya tenemos un valor almacenado, no hacer fetch
    // vacío que sobrescriba el valor existente (por ej. al editar un registro)
    if (referencedSlugs.isEmpty) {
      final currentStored = _getRecord()[widget.field['slug']];
      if (currentStored != null && currentStored.toString().isNotEmpty) {
        debugPrint('=== EXTERNAL_VALUE _checkAndFetch === no referenced slugs and value already exists ($currentStored), skipping fetch');
        return;
      }
    }

    debugPrint('=== EXTERNAL_VALUE _checkAndFetch === triggering fetch');
    _triggerFetch(params);
  }

  void _triggerFetch(Map<String, dynamic> params) {
    debugPrint('=== EXTERNAL_VALUE _triggerFetch === slug=${widget.field['slug']} scheduling fetch in 500ms');
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) {
        debugPrint('=== EXTERNAL_VALUE _triggerFetch === not mounted, aborting');
        return;
      }
      _executeFetch(params);
    });
  }

  Future<void> _executeFetch(Map<String, dynamic> params) async {
    final fieldId = _fieldId;
    if (fieldId == null) return;

    debugPrint('=== EXTERNAL_VALUE _executeFetch === slug=${widget.field['slug']} fieldId=$fieldId params=$params');

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await FetchExternalFieldOptionsCall.call(
        tenant: FFAppState().organizacion,
        customFieldId: fieldId,
        params: params,
        token: FFAppState().token,
      );

      if (!mounted) return;

      debugPrint('=== EXTERNAL_VALUE _executeFetch === slug=${widget.field['slug']} result.succeeded=${result.succeeded} statusCode=${result.statusCode} jsonBody=${result.jsonBody}');

      if (!result.succeeded) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error del servidor: ${result.statusCode}';
        });
        return;
      }

      final value = getJsonField(result.jsonBody, r'''$.value''')?.toString() ?? '';
      debugPrint('=== EXTERNAL_VALUE _executeFetch === slug=${widget.field['slug']} extracted value=$value');

      final slug = widget.field['slug'];
      final currentStored = _getRecord()[slug];
      debugPrint('=== EXTERNAL_VALUE _executeFetch === slug=$slug currentStored=$currentStored value=$value');

      // Protección: si la API devuelve vacío pero ya teníamos un valor, no borrarlo
      if (value.isEmpty && currentStored != null && currentStored.toString().isNotEmpty) {
        debugPrint('=== EXTERNAL_VALUE _executeFetch === API returned empty but value exists, preserving currentStored');
        setState(() {
          displayValue = currentStored.toString();
          isLoading = false;
          _hasFetchedOnce = true;
        });
        _lastParams = Map<String, dynamic>.from(params);
        return;
      }

      setState(() {
        displayValue = value;
        isLoading = false;
        _hasFetchedOnce = true;
      });

      // Guardar params como "últimos params exitosos"
      _lastParams = Map<String, dynamic>.from(params);

      // Persistir valor en jsonData si cambió
      if (slug != null && value != currentStored?.toString()) {
        debugPrint('=== EXTERNAL_VALUE _executeFetch === persisting value via handleDynamicFieldChanges');
        widget.handleDynamicFieldChanges(slug, value, widget.index, widget.mainSlug);
      } else {
        debugPrint('=== EXTERNAL_VALUE _executeFetch === value unchanged or slug null, not persisting');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('=== EXTERNAL_VALUE _executeFetch === slug=${widget.field['slug']} ERROR: $e');
      setState(() {
        isLoading = false;
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('502') || errorStr.contains('bad gateway')) {
          errorMessage = 'El servicio externo no respondió (502)';
        } else if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
          errorMessage = 'Tiempo de espera agotado';
        } else if (errorStr.contains('socket') || errorStr.contains('connection')) {
          errorMessage = 'Error de conexión';
        } else {
          errorMessage = 'Error al obtener el valor externo';
        }
      });
    }
  }

  /// Construir params desde un jsonData arbitrario (para didUpdateWidget)
  Map<String, dynamic> _buildParamsFrom(Map<String, dynamic> jsonData) {
    Map<String, dynamic> record;
    if (widget.mainSlug != null && widget.index != null) {
      final mainData = jsonData[widget.mainSlug];
      if (mainData is List && widget.index! < mainData.length) {
        final item = mainData[widget.index!];
        if (item is Map<String, dynamic>) {
          record = item;
        } else {
          record = jsonData;
        }
      } else {
        record = jsonData;
      }
    } else {
      record = jsonData;
    }
    final params = <String, dynamic>{};
    for (final slug in referencedSlugs) {
      params[slug] = record[slug] ?? '';
    }
    return params;
  }

  @override
  void didUpdateWidget(covariant ExternalValueField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldParams = _buildParamsFrom(oldWidget.jsonData);
    final newParams = _buildParamsFrom(widget.jsonData);
    final oldKey = jsonEncode(oldParams);
    final newKey = jsonEncode(newParams);
    final lastKey = _lastParams != null ? jsonEncode(_lastParams) : null;

    debugPrint('=== EXTERNAL_VALUE didUpdateWidget === slug=${widget.field['slug']} oldKey=$oldKey newKey=$newKey lastKey=$lastKey jsonDataHash=${identityHashCode(widget.jsonData)} oldJsonDataHash=${identityHashCode(oldWidget.jsonData)}');

    // Caso 1: los params visibles del widget cambiaron (referencia nueva de Map)
    if (oldKey != newKey) {
      debugPrint('=== EXTERNAL_VALUE didUpdateWidget === PARAMS CHANGED -> _checkAndFetch');
      _checkAndFetch();
    }
    // Caso 2: el padre mutó el mismo Map sin crear nueva referencia,
    // pero los params actuales difieren de los del último fetch exitoso
    else if (lastKey != null && lastKey != newKey) {
      debugPrint('=== EXTERNAL_VALUE didUpdateWidget === PARAMS CHANGED (silent mutation) -> _checkAndFetch');
      _checkAndFetch();
    }

    // Si cambió la config del campo, re-parsear
    if (oldWidget.field['options']?.toString() != widget.field['options']?.toString()) {
      _parseConfig();
      _checkAndFetch();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final label = widget.field['label']?.toString() ?? 'Valor externo';

    if (externalConfig == null) {
      return _buildTextField(
        theme: theme,
        value: displayValue,
        hint: 'Configuración incompleta',
        label: label,
      );
    }

    if (widget.onlyView) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayValue.isNotEmpty ? displayValue : '-',
                style: theme.bodyMedium,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          theme: theme,
          value: displayValue,
          hint: isLoading ? 'Consultando...' : 'Valor calculado externamente',
          label: label,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 16, color: theme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: theme.bodySmall.copyWith(
                      color: theme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (referencedSlugs.isNotEmpty && !widget.onlyView) ...[
          const SizedBox(height: 4),
          Text(
            'Depende de: ${referencedSlugs.join(", ")}',
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required FlutterFlowTheme theme,
    required String value,
    required String hint,
    required String label,
  }) {
    return TextField(
      enabled: false,
      readOnly: true,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: false,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: isLoading
            ? Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : (_hasFetchedOnce && !isLoading)
                ? Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: theme.success,
                    ),
                  )
                : null,
      ),
      style: theme.bodyMedium,
    );
  }
}
