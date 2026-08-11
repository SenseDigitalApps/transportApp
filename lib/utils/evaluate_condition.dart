import 'package:flutter/foundation.dart';
import 'package:transport_app/app_state.dart';

class ConditionContext {
  final String? currentUserRole;
  final List<String> currentUserRoles;

  ConditionContext({
    this.currentUserRole,
    this.currentUserRoles = const [],
  });
}

bool _isNumeric(String s) {
  return double.tryParse(s) != null;
}

/// Split formula into top-level tokens at bracket depth 0
List<String> _splitTopLevel(String formula) {
  final tokens = <String>[];
  final current = StringBuffer();
  int depth = 0;
  for (int i = 0; i < formula.length; i++) {
    final ch = formula[i];
    if (ch == ',' && depth == 0) {
      final token = current.toString().trim();
      if (token.isNotEmpty) tokens.add(token);
      current.clear();
    } else {
      if (ch == '[') depth++;
      if (ch == ']') depth--;
      current.write(ch);
    }
  }
  final last = current.toString().trim();
  if (last.isNotEmpty) tokens.add(last);
  return tokens;
}

bool _isGroupCondition(String s) {
  final trimmed = s.trim();
  return trimmed.startsWith('AND[') || trimmed.startsWith('OR[');
}

/// Evaluate AND/OR group condition recursively
bool _evaluateGroup(String groupStr, Map<String, dynamic> jsonData, {
  Map<String, dynamic>? field,
  ConditionContext? context,
}) {
  final trimmed = groupStr.trim();
  final match = RegExp(r'^(AND|OR)\[(.+)\]$', dotAll: true).firstMatch(trimmed);
  if (match == null) return true;

  final logic = match.group(1)!;
  final content = match.group(2)!;
  final items = _splitTopLevel(content);

  if (logic == 'AND') {
    return items.every((item) =>
        evaluateConditions(item, jsonData, field: field, context: context));
  }
  // OR
  return items.any((item) =>
      evaluateConditions(item, jsonData, field: field, context: context));
}

/// Parse subfield from dotted key
/// "ref_biller.nombre" → (["ref_biller"], "nombre")
/// "user.ref_empresa.nombre" → (["user.ref_empresa"], "nombre")
(List<String>, String?) _parseSubfield(String key) {
  final parts = key.split('.');
  if (parts.length == 3 && parts[1].startsWith('ref_')) {
    return (['${parts[0]}.${parts[1]}'], parts[2]);
  }
  if (parts.length == 2 && parts[0].startsWith('ref_')) {
    return ([parts[0]], parts[1]);
  }
  return ([key], null);
}

/// Extract display label from relational field value map
String _extractRelationalLabel(Map<String, dynamic> relationalValue, String? relationsType) {
  if (relationsType == 'user') {
    return (relationalValue['label'] ?? '').toString().trim().toLowerCase();
  }

  final label = (relationalValue['label'] ?? '').toString();
  if (label.isNotEmpty) {
    final parts = label.split('-');
    if (parts.length > 1) {
      // Strip consecutivo prefix: "123 - Biller 3" → "Biller 3"
      return parts.sublist(1).join('-').trim().toLowerCase();
    }
    return label.trim().toLowerCase();
  }

  return (relationalValue['value'] ?? '').toString().trim().toLowerCase();
}

/// Check if user has a specific role
bool _userHasRole(String roleName, ConditionContext? context) {
  final expected = roleName.trim().toLowerCase();
  if (expected.isEmpty) return false;

  final roleSet = <String>{};
  final mainRole = (context?.currentUserRole ?? '').trim().toLowerCase();
  if (mainRole.isNotEmpty) roleSet.add(mainRole);
  for (final r in (context?.currentUserRoles ?? [])) {
    final normalized = r.trim().toLowerCase();
    if (normalized.isNotEmpty) roleSet.add(normalized);
  }

  if (roleSet.isEmpty && FFAppState().role.isNotEmpty) {
    roleSet.add(FFAppState().role.trim().toLowerCase());
    for (final r in FFAppState().roleGroups) {
      if (r is String) roleSet.add(r.trim().toLowerCase());
    }
  }

  return roleSet.contains(expected);
}

/// Evalúa una condición simple: "slug|operator|valor"
/// Retorna true si la condición se cumple (o si no hay condición)
bool evaluateCondition(
  String? conditionString,
  Map<String, dynamic> jsonData, {
  Map<String, dynamic>? field,
  ConditionContext? context,
}) {
  try {
    if (conditionString == null || conditionString.trim().isEmpty) {
      return true;
    }

    if (conditionString.contains('templateCondition(')) {
      return true;
    }

    final trimmed = conditionString.trim();

    // Handle AND/OR groups
    if (_isGroupCondition(trimmed)) {
      return _evaluateGroup(trimmed, jsonData, field: field, context: context);
    }

    final validationMatch = RegExp(r'^([a-zA-Z0-9_]+)?\((.+)\)$')
        .firstMatch(trimmed);

    var validationType = 'simpleValidation';
    var validationExpression = trimmed;
    if (validationMatch != null) {
      validationType = validationMatch.group(1) ?? 'simpleValidation';
      validationExpression = validationMatch.group(2) ?? trimmed;
    }

    if (validationType == 'simpleValidation' || validationMatch == null) {
      final parts = validationExpression.split('|').map((p) => p.trim()).toList();
      if (parts.length < 3) {
        return true;
      }

      final key = parts[0];
      final operator = parts[1];
      final value = parts[2];

      // Role restriction on regular conditions: field|op|value|roleName|permission
      final restrictionRole = parts.length > 3 ? parts[3]?.trim() : null;
      if (restrictionRole != null && restrictionRole.isNotEmpty) {
        if (!_userHasRole(restrictionRole, context)) {
          return false;
        }
      }

      // __current_role__ handling
      if (key == '__current_role__') {
        final expectedRole = value.toLowerCase();
        final roleSet = <String>{};

        final mainRole = (context?.currentUserRole ?? '').trim().toLowerCase();
        if (mainRole.isNotEmpty) roleSet.add(mainRole);

        for (final r in (context?.currentUserRoles ?? [])) {
          final normalized = r.trim().toLowerCase();
          if (normalized.isNotEmpty) roleSet.add(normalized);
        }

        if (roleSet.isEmpty && FFAppState().role.isNotEmpty) {
          roleSet.add(FFAppState().role.trim().toLowerCase());
          for (final r in FFAppState().roleGroups) {
            if (r is String) roleSet.add(r.trim().toLowerCase());
          }
        }

        if (expectedRole.isEmpty) {
          return false;
        }

        final hasRole = roleSet.contains(expectedRole);

        switch (operator) {
          case '=':
            return hasRole;
          case '!=':
            return !hasRole;
          case '~':
            return roleSet.any((r) => r.contains(expectedRole));
          default:
            return false;
        }
      }

      // Parse subfield from dotted key
      final (parsedMainField, subfield) = _parseSubfield(key);
      final mainField = parsedMainField.length == 1
          ? parsedMainField[0]
          : parsedMainField.join('.');

      final keyValue = jsonData[mainField];

      // Relational field check
      final isRelational = mainField.startsWith('ref_') ||
          (mainField.startsWith('user.') &&
              mainField.substring(5).startsWith('ref_'));

      // Multi-relational list check: refm_* or any ref_ holding a List
      if (keyValue is List && isRelational) {
        final normalizedValue = value.toLowerCase();
        final labels = <String>[];
        for (final item in keyValue) {
          if (item is Map) {
            labels.add(_extractRelationalLabel(
                Map<String, dynamic>.from(item),
                field?['relations_type']?.toString()));
          }
        }
        switch (operator) {
          case '=':
            return labels.any((l) => l == normalizedValue);
          case '!=':
            return !labels.any((l) => l == normalizedValue);
          case '~':
            return labels.any((l) => l.contains(normalizedValue));
          default:
            return false;
        }
      }

      // String value for relational field: normalize label to match
      // _extractRelationalLabel behavior. Try both full value and stripped
      // prefix (consecutivo) so formulas comparing against either label or
      // raw value/ID work.
      if (keyValue is String && isRelational) {
        final strValue = keyValue.trim();
        if (strValue.isEmpty) {
          // Empty relational — only matches != operator
          switch (operator) {
            case '!=': return true;
            default: return false;
          }
        }
        // Full value lowercased (matches user-type formulas that use full label)
        final fullLower = strValue.toLowerCase();
        // Stripped label (matches register/master formulas: "123 - Bill" → "bill")
        String strippedLabel = fullLower;
        final parts = strValue.split('-');
        if (parts.length > 1) {
          strippedLabel = parts.sublist(1).join('-').trim().toLowerCase();
        }
        final normalizedValue = value.toLowerCase();
        switch (operator) {
          case '=':
            return fullLower == normalizedValue || strippedLabel == normalizedValue;
          case '!=':
            return fullLower != normalizedValue && strippedLabel != normalizedValue;
          case '~':
            return fullLower.contains(normalizedValue) || strippedLabel.contains(normalizedValue);
          default:
            return false;
        }
      }

      if (keyValue is Map && isRelational) {
        final relationalMap = Map<String, dynamic>.from(keyValue);
        String compareValue;
        if (subfield != null) {
          // Subfield: check json_data for dotted path first
          final subfieldValue = jsonData['$mainField.$subfield'];
          if (subfieldValue != null) {
            compareValue = subfieldValue.toString().trim().toLowerCase();
          } else {
            compareValue = _extractRelationalLabel(
                relationalMap, field?['relations_type']?.toString());
          }
        } else {
          compareValue =
              _extractRelationalLabel(relationalMap, field?['relations_type']?.toString());
        }

        final normalizedValue = value.toLowerCase();

        switch (operator) {
          case '=':
            return compareValue == normalizedValue;
          case '!=':
            return compareValue != normalizedValue;
          case '~':
            return compareValue.contains(normalizedValue);
          default:
            return false;
        }
      }

      // Checkbox object check
      if (keyValue is Map) {
        if (operator == '=') return keyValue[value] == true;
        if (operator == '!=') return keyValue[value] != true;
        return false;
      }

      // Normal comparison
      dynamic resolvedValue = value;
      if (!_isNumeric(value) &&
          value != 'true' &&
          value != 'false' &&
          jsonData.containsKey(value)) {
        resolvedValue = jsonData[value];
      }

      final keyValueStr = keyValue?.toString() ?? '';
      final keyValueNum = double.tryParse(keyValueStr);
      final valueNum = double.tryParse(resolvedValue.toString());
      final isNumericKey = keyValueNum != null && keyValueNum.isFinite;
      final isNumericValue = valueNum != null && valueNum.isFinite;

      switch (operator) {
        case '=':
          if (isNumericKey && isNumericValue) {
            return keyValueNum == valueNum;
          }
          return keyValueStr == resolvedValue.toString();
        case '!=':
          if (isNumericKey && isNumericValue) {
            return keyValueNum != valueNum;
          }
          return keyValueStr != resolvedValue.toString();
        case '~':
          return keyValueStr.contains(resolvedValue.toString());
        case '>':
          return (double.tryParse(keyValueStr) ?? 0) >
              (double.tryParse(resolvedValue.toString()) ?? 0);
        case '<':
          return (double.tryParse(keyValueStr) ?? 0) <
              (double.tryParse(resolvedValue.toString()) ?? 0);
        case '>=':
          return (double.tryParse(keyValueStr) ?? 0) >=
              (double.tryParse(resolvedValue.toString()) ?? 0);
        case '<=':
          return (double.tryParse(keyValueStr) ?? 0) <=
              (double.tryParse(resolvedValue.toString()) ?? 0);
        default:
          return true;
      }
    }

    if (validationType == 'repeaterMax') {
      return true;
    }

    return true;
  } catch (e) {
    return true;
  }
}

/// Evalúa condiciones múltiples separadas por coma (OR)
/// Soporta AND[...] y OR[...] groups
/// Retorna true si ALGUNA condición se cumple
bool evaluateConditions(
  String? conditionString,
  Map<String, dynamic> jsonData, {
  Map<String, dynamic>? field,
  ConditionContext? context,
}) {
  if (conditionString == null || conditionString.trim().isEmpty) return true;

  final trimmed = conditionString.trim();

  // Check for AND[/OR[ group markers
  if (RegExp(r'\b(AND|OR)\[').hasMatch(trimmed)) {
    // Split at bracket depth 0
    final tokens = _splitTopLevel(trimmed);
    // Return TRUE if ANY top-level token matches (OR at top level)
    return tokens.any((token) {
      if (_isGroupCondition(token)) {
        return _evaluateGroup(token, jsonData, field: field, context: context);
      }
      return evaluateCondition(token, jsonData, field: field, context: context);
    });
  }

  // Legacy comma-separated OR
  final conditions = trimmed
      .split(',')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();
  if (conditions.isEmpty) return true;
  return conditions
      .any((c) => evaluateCondition(c, jsonData, field: field, context: context));
}

/// Extrae los slugs de los que depende una condición
/// Soporta AND[...] y OR[...] groups
List<String> extractConditionDependencies(String conditionString) {
  if (conditionString.isEmpty) return [];
  final deps = <String>{};

  final trimmed = conditionString.trim();

  // Handle AND[/OR[ groups
  if (_isGroupCondition(trimmed)) {
    final match = RegExp(r'^(AND|OR)\[(.+)\]$', dotAll: true).firstMatch(trimmed);
    if (match != null) {
      final content = match.group(2)!;
      final items = _splitTopLevel(content);
      for (final item in items) {
        deps.addAll(extractConditionDependencies(item));
      }
      return deps.toList();
    }
  }

  // Legacy comma-separated
  for (final part in trimmed.split(',')) {
    final trimmedPart = part.trim();
    if (trimmedPart.isEmpty) continue;

    if (trimmedPart.contains('templateCondition(')) {
      continue;
    }

    var expression = trimmedPart;
    final funcMatch =
        RegExp(r'^([a-zA-Z0-9_]+)?\((.+)\)$').firstMatch(trimmedPart);
    if (funcMatch != null) {
      expression = funcMatch.group(2) ?? trimmedPart;
    }

    final segments = expression.split('|');
    if (segments.length >= 1) {
      final key = segments[0].trim();
      if (key.isNotEmpty && key != '__current_role__') {
        final (mainField, _) = _parseSubfield(key);
        deps.add(mainField.length == 1 ? mainField[0] : mainField.join('.'));
      }
    }
    if (segments.length >= 3) {
      final key = segments[0].trim();
      final value = segments[2].trim();
      if (key != '__current_role__' &&
          value.isNotEmpty &&
          !_isNumeric(value) &&
          value != 'true' &&
          value != 'false' &&
          !value.contains('(')) {
        deps.add(value);
      }
    }
  }
  return deps.toList();
}
