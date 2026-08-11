/// Configuración inmutable de un campo relacional.
/// Reemplaza la List<String> options con índices mágicos.
class RelationalFieldConfig {
  final String relationType;        // 'user', 'module', 'master'
  final int relatedModuleId;        // ID del módulo relacionado (0 si es user)
  final String relatedModuleName;   // Nombre del módulo (de related_module_name)
  final String slugFormula;         // De relations_formula: parte slug
  final String valueFormula;        // De relations_formula: parte valor
  final String typeFormula;         // De relations_formula: parte condición

  const RelationalFieldConfig({
    required this.relationType,
    this.relatedModuleId = 0,
    this.relatedModuleName = '',
    this.slugFormula = '',
    this.valueFormula = '',
    this.typeFormula = '',
  });

  // ── Factories ──────────────────────────────────────────────

  /// Desde la configuración cruda del backend (usa tanto processField
  /// como el repeater). Soporta tanto claves explícitas como lista legacy
  /// en `config['options']`.
  factory RelationalFieldConfig.fromRawConfig(Map<String, dynamic> config) {
    String type = normalizeType(config['relations_type']);
    int moduleId = int.tryParse(config['related_module']?.toString() ?? '') ?? 0;
    String moduleName = config['related_module_name']?.toString() ?? '';

    // Fallback: si el tipo quedó 'master' pero hay options legacy,
    // extraer type, moduleId y moduleName de ahí.
    final rawOptions = config['options'];
    if (type == 'master' && rawOptions is List && rawOptions.isNotEmpty) {
      final opts = rawOptions.map((e) => e.toString()).toList();
      type = normalizeType(opts[0]);
      if (opts.length > 1) {
        moduleId = int.tryParse(opts[1]) ?? moduleId;
      }
      if (opts.length > 2) {
        moduleName = opts[2];
      }
    }

    // Parsear relations_formula: "slug,value,tipo"
    String slugF = '', valueF = '', typeF = '';
    final formula = config['relations_formula']?.toString() ?? '';
    if (formula.isNotEmpty) {
      final parts = formula.split(',');
      slugF = parts.isNotEmpty ? parts[0] : '';
      valueF = parts.length > 1 ? parts[1] : '';
      typeF = parts.length > 2 ? parts[2] : '';
    }

    return RelationalFieldConfig(
      relationType: type,
      relatedModuleId: moduleId,
      relatedModuleName: moduleName,
      slugFormula: slugF,
      valueFormula: valueF,
      typeFormula: typeF,
    );
  }

  /// Desde los datos guardados de un registro (json_data[slug]).
  factory RelationalFieldConfig.fromSavedData(Map<String, dynamic> data) {
    return RelationalFieldConfig(
      relationType: normalizeType(data['type']),
      relatedModuleId: int.tryParse(data['module']?.toString() ?? '') ?? 0,
      relatedModuleName: data['module_name']?.toString() ?? '',
    );
  }

  /// Para migración gradual: convierte la lista legacy.
  factory RelationalFieldConfig.fromLegacy(List<String> options) {
    final type = options.isNotEmpty ? normalizeType(options[0]) : 'master';
    final moduleId =
        options.length > 1 ? int.tryParse(options[1]) ?? 0 : 0;
    final moduleName = options.length > 2 ? options[2] : '';
    return RelationalFieldConfig(
      relationType: type,
      relatedModuleId: moduleId,
      relatedModuleName: moduleName,
    );
  }

  // ── Derivadas ──────────────────────────────────────────────

  bool get isUserRelation => relationType == 'user';
  bool get needsModule => !isUserRelation;

  /// Parámetro URL para la API de búsqueda.
  String get urlParam {
    switch (relationType) {
      case 'user':
        return 'users';
      case 'module':
        return 'register';
      default:
        return 'master';
    }
  }

  /// Tipo para almacenar en el JSON de respuesta.
  String get storageType {
    switch (relationType) {
      case 'user':
        return 'user';
      case 'module':
        return 'register';
      default:
        return 'master';
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  static String normalizeType(dynamic raw) {
    final s = raw?.toString().toLowerCase() ?? '';
    if (s == 'user') return 'user';
    if (s == 'module' || s == 'register') return 'module';
    if (s == 'master') return 'master';
    return 'master';
  }

  // ── Serialización ──────────────────────────────────────────

  /// Para guardar en el campo 'options' del mapa campo (backward compat).
  List<String> toLegacyOptions() {
    if (isUserRelation) {
      return ['user', ''];
    }
    return [relationType, relatedModuleId.toString(), relatedModuleName];
  }

  /// Para inicializar json_data[slug] en modo create.
  Map<String, dynamic> toEmptyJsonValue() {
    if (isUserRelation) {
      return {
        'type': 'user',
        'label': '',
        'value': 0,
        'avatar': '',
        'full_name': '',
      };
    }
    return {
      'type': storageType,
      'label': '',
      'value': 0,
      'module': relatedModuleId,
    };
  }

  /// Para serializar al guardar (view mode).
  Map<String, dynamic> toJsonValue({
    required String label,
    required int value,
    String? avatar,
    String? fullName,
  }) {
    if (isUserRelation) {
      return {
        'type': 'user',
        'label': label,
        'value': value,
        'avatar': avatar ?? '',
        'full_name': fullName ?? '',
      };
    }
    return {
      'type': storageType,
      'label': label,
      'value': value,
      'module': relatedModuleId,
      'module_name': relatedModuleName,
    };
  }
}
