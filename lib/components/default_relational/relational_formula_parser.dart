/// Modelo de valor relacional almacenado en json_data[slug].
/// Soporta tanto single como multiple relational select.
class RelationalValue {
  final dynamic value; // ID (int o string)
  final String label;
  final String type; // 'user' | 'module' | 'master' | 'register'
  final dynamic module; // Module ID
  final String? moduleName;
  final String? avatar; // Para user relations
  final String? fullName; // Para user relations

  const RelationalValue({
    required this.value,
    required this.label,
    required this.type,
    this.module,
    this.moduleName,
    this.avatar,
    this.fullName,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'type': type,
        'module': module,
        if (moduleName != null) 'module_name': moduleName,
        if (avatar != null) 'avatar': avatar,
        if (fullName != null) 'full_name': fullName,
      };

  factory RelationalValue.fromJson(Map<String, dynamic> json) => RelationalValue(
        value: json['value'] ?? json['id'],
        label: json['label']?.toString() ?? '',
        type: json['type']?.toString() ?? 'module',
        module: json['module'],
        moduleName: json['module_name']?.toString(),
        avatar: json['avatar']?.toString(),
        fullName: json['full_name']?.toString() ?? json['label']?.toString(),
      );

  @override
  String toString() => 'RelationalValue(value: $value, label: $label, type: $type)';
}

/// Resultado de búsqueda para mostrar en la UI.
class RelationalSearchResult {
  final dynamic id;
  final String label;
  final String? subtitle;
  final String? avatar;
  final String? type;
  final dynamic moduleId;
  final String? moduleName;
  final Map<String, dynamic>? rawData;

  const RelationalSearchResult({
    required this.id,
    required this.label,
    this.subtitle,
    this.avatar,
    this.type,
    this.moduleId,
    this.moduleName,
    this.rawData,
  });
}

/// Resultado del parseo de relations_formula.
class FormulaParseResult {
  final String? advancedFilter;
  final String? normalFilter;
  final String? roleFilter;
  final String? dynamicSlugValue;

  const FormulaParseResult({
    this.advancedFilter,
    this.normalFilter,
    this.roleFilter,
    this.dynamicSlugValue,
  });

  bool get hasFilters =>
      (advancedFilter != null && advancedFilter!.isNotEmpty) ||
      (normalFilter != null && normalFilter!.isNotEmpty) ||
      (roleFilter != null && roleFilter!.isNotEmpty) ||
      (dynamicSlugValue != null && dynamicSlugValue!.isNotEmpty);
}

/// Resuelve el valor de un slug desde jsonData, respetando contexto de repeater.
dynamic resolveSlugValue(
  String slug,
  Map<String, dynamic> jsonData, {
  String? mainSlug,
  int? index,
}) {
  final effectiveData = _getEffectiveJsonData(jsonData, mainSlug: mainSlug, index: index);
  final raw = effectiveData?[slug];
  if (raw == null) return null;

  if (raw is Map) {
    return raw['value'] ?? raw['label'] ?? raw;
  }
  return raw;
}

Map<String, dynamic>? _getEffectiveJsonData(
  Map<String, dynamic> jsonData, {
  String? mainSlug,
  int? index,
}) {
  if (mainSlug != null && index != null) {
    final mainData = jsonData[mainSlug];
    if (mainData is List && index < mainData.length) {
      final item = mainData[index];
      if (item is Map<String, dynamic>) return item;
    }
  }
  return jsonData;
}

/// Parsea una relations_formula compleja del backend.
///
/// Soporta:
/// - Condiciones separadas por `&&`
/// - `=slug_xxx` → resuelve valor dinámico desde jsonData
/// - `FiltrarPorRol(refSlug|role1,role2)` → resuelve refSlug
/// - `FiltrarPorUsuarioEnModulo(src|tgtSlug)` → resuelve src
/// - `FiltrarPorCampoRolYUsuario(...)` → advanced filter
/// - `FiltrarPorRolModulo(...)` → advanced filter
/// - `ExcluirPorNovedad(fieldSlug)` → advanced filter
/// - Filtros simples separados por coma → normalFilter
FormulaParseResult parseRelationsFormula(
  String? formula,
  Map<String, dynamic> jsonData, {
  String? mainSlug,
  int? index,
}) {
  if (formula == null || formula.trim().isEmpty) {
    return const FormulaParseResult();
  }

  String? advancedFilter;
  String? normalFilter;
  String? roleFilter;
  String? dynamicSlugValue;

  final parts = formula
      .split('&&')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);

  final advancedRegex = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_-]*)\(([^()]+)\)$');

  for (final part in parts) {
    // 1. Dynamic slug formula: "=slug_xxx"
    if (part.startsWith('=')) {
      final slugKey = part.substring(1); // after "="
      final rawValue = resolveSlugValue(slugKey, jsonData, mainSlug: mainSlug, index: index);
      if (rawValue != null) {
        if (rawValue is Map && rawValue['value'] != null) {
          dynamicSlugValue = rawValue['value'].toString();
        } else {
          dynamicSlugValue = rawValue.toString().toLowerCase();
        }
      }
      continue;
    }

    // 2. FiltrarPorUsuarioEnModulo(source|targetSlug)
    if (part.startsWith('FiltrarPorUsuarioEnModulo(') && part.endsWith(')')) {
      final inner = part.substring('FiltrarPorUsuarioEnModulo('.length, part.length - 1);
      final pipeParts = inner.split('|');
      if (pipeParts.length >= 2) {
        String userSource = pipeParts[0].trim();
        final targetSlug = pipeParts[1].trim();

        if (userSource != '__CURRENT_USER__' && userSource != '__NO_USER__') {
          final resolved = resolveSlugValue(userSource, jsonData, mainSlug: mainSlug, index: index);
          if (resolved != null) {
            if (resolved is Map && resolved['value'] != null) {
              userSource = resolved['value'].toString();
            } else {
              userSource = resolved.toString();
            }
          } else {
            userSource = '__NO_USER__';
          }
        }
        roleFilter = 'FiltrarPorUsuarioEnModulo($userSource|$targetSlug)';
      }
      continue;
    }

    // 3. FiltrarPorRol(refSlug|role1,role2)
    if (part.startsWith('FiltrarPorRol(') && part.endsWith(')')) {
      final inner = part.substring('FiltrarPorRol('.length, part.length - 1);
      final pipeIndex = inner.indexOf('|');
      if (pipeIndex != -1) {
        final refSlug = inner.substring(0, pipeIndex).trim();
        final rulesStr = inner.substring(pipeIndex + 1);

        final userFieldValue = resolveSlugValue(refSlug, jsonData, mainSlug: mainSlug, index: index);
        String? userId;

        if (userFieldValue != null) {
          if (userFieldValue is Map && userFieldValue['value'] != null) {
            userId = userFieldValue['value'].toString();
          } else {
            userId = userFieldValue.toString();
          }
        }

        if (userId != null) {
          roleFilter = 'FiltrarPorRol($userId|$rulesStr)';
        } else {
          roleFilter = 'FiltrarPorRol(__NO_USER__|$rulesStr)';
        }
      }
      continue;
    }

    // 4. FiltrarPorCampoRolYUsuario(...)
    if (part.startsWith('FiltrarPorCampoRolYUsuario(') && part.endsWith(')')) {
      final inner = part.substring('FiltrarPorCampoRolYUsuario('.length, part.length - 1);
      final pipeParts = inner.split('|');
      if (pipeParts.length >= 3) {
        String userSource = pipeParts[0].trim();
        final roleSlug = pipeParts[1].trim();
        final userSlug = pipeParts[2].trim();

        if (userSource != '__CURRENT_USER__' && userSource != '__NO_USER__') {
          final resolved = resolveSlugValue(userSource, jsonData, mainSlug: mainSlug, index: index);
          if (resolved != null) {
            if (resolved is Map && resolved['value'] != null) {
              userSource = resolved['value'].toString();
            } else {
              userSource = resolved.toString();
            }
          } else {
            userSource = '__NO_USER__';
          }
        }
        roleFilter = 'FiltrarPorCampoRolYUsuario($userSource|$roleSlug|$userSlug)';
      }
      continue;
    }

    // 5. FiltrarPorRolModulo(...)
    if (part.startsWith('FiltrarPorRolModulo(') && part.endsWith(')')) {
      final inner = part.substring('FiltrarPorRolModulo('.length, part.length - 1);
      final pipeParts = inner.split('|');
      if (pipeParts.length >= 4) {
        String userSource = pipeParts[0].trim();
        final moduleName = pipeParts[1].trim();
        final userSlug = pipeParts[2].trim();
        final roleSlug = pipeParts[3].trim();

        if (userSource != '__CURRENT_USER__' && userSource != '__NO_USER__') {
          final resolved = resolveSlugValue(userSource, jsonData, mainSlug: mainSlug, index: index);
          if (resolved != null) {
            if (resolved is Map && resolved['value'] != null) {
              userSource = resolved['value'].toString();
            } else {
              userSource = resolved.toString();
            }
          } else {
            userSource = '__NO_USER__';
          }
        }
        roleFilter = 'FiltrarPorRolModulo($userSource|$moduleName|$userSlug|$roleSlug)';
      }
      continue;
    }

    // 6. ExcluirPorNovedad(fieldSlug)
    if (part.startsWith('ExcluirPorNovedad(') && part.endsWith(')')) {
      advancedFilter = part;
      continue;
    }

    // 7. Generic advanced filter (functionName(args))
    if (advancedRegex.hasMatch(part)) {
      advancedFilter = part;
      continue;
    }

    // 8. Normal comma-separated filter → se acumula como normal_filter
    if (part.contains(',')) {
      if (normalFilter != null && normalFilter!.isNotEmpty) {
        normalFilter = '$normalFilter,$part';
      } else {
        normalFilter = part;
      }
    }
  }

  return FormulaParseResult(
    advancedFilter: advancedFilter,
    normalFilter: normalFilter,
    roleFilter: roleFilter,
    dynamicSlugValue: dynamicSlugValue,
  );
}
