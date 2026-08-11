import 'dart:convert';
import 'package:math_expressions/math_expressions.dart';

/// Evalúa una expresión aritmética directa reemplazando slugs por valores
double evaluateArithmetic(String expression, Map<String, dynamic> values) {
  if (expression.isEmpty) return 0;

  try {
    // Limpiar expresión
    String expr = expression.trim();

    // Reemplazar today() por fecha ISO actual
    final now = DateTime.now();
    final todayStr = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
    expr = expr.replaceAll('today()', todayStr);

    // Reemplazar aproximarEntero(x)
    expr = expr.replaceAllMapped(
      RegExp(r'aproximarEntero\s*\(\s*([^)]+)\s*\)'),
      (m) {
        final inner = evaluateArithmetic(m.group(1)!, values);
        return inner.round().toString();
      },
    );

    // Reemplazar AproximaRedondeo(x)
    expr = expr.replaceAllMapped(
      RegExp(r'AproximaRedondeo\s*\(\s*([^)]+)\s*\)'),
      (m) {
        final val = evaluateArithmetic(m.group(1)!, values);
        return _aproximaRedondeo(val).toString();
      },
    );

    // Reemplazar if(cond|true_val|false_val)
    expr = expr.replaceAllMapped(
      RegExp(r'if\s*\(\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^)]+)\s*\)'),
      (m) {
        final condition = m.group(1)!.trim();
        final trueVal = m.group(2)!.trim();
        final falseVal = m.group(3)!.trim();

        if (_evaluateCondition(condition, values)) {
          return evaluateArithmetic(trueVal, values).toString();
        } else {
          return evaluateArithmetic(falseVal, values).toString();
        }
      },
    );

    // Reemplazar slug_ prefix
    expr = expr.replaceAllMapped(
      RegExp(r'slug_(\w+)'),
      (m) => _resolveFieldValue(m.group(1)!, values),
    );

    // Reemplazar nombres de campos por valores numéricos
    expr = expr.replaceAllMapped(
      RegExp(r'\b([a-zA-Z_]\w*)\b'),
      (m) {
        final word = m.group(1)!;
        // Palabras clave que NO son slugs
        if ([
          'round',
          'ceil',
          'floor',
          'abs',
          'min',
          'max',
          'sqrt',
          'pow',
          'sin',
          'cos',
          'tan',
          'pi',
          'e',
          'true',
          'false',
          'null',
          'mod',
          'and',
          'or',
          'not',
          'if',
          'else',
          'today'
        ].contains(word)) {
          return word;
        }
        // Intentar reemplazar por valor numérico
        return _resolveFieldValue(word, values);
      },
    );

    // Verificar que solo tenga caracteres seguros
    if (!RegExp(r'^[\d\s+\-*/().,%\w]+$').hasMatch(expr)) {
      return 0;
    }

    // Evaluar con math_expressions
    final parser = Parser();
    final expressionModel = parser.parse(expr);
    return expressionModel.evaluate(EvaluationType.REAL, ContextModel());
  } catch (e) {
    return 0;
  }
}

String _resolveFieldValue(String slug, Map<String, dynamic> values) {
  final value = values[slug];
  if (value == null) return '0';
  if (value is num) return value.toString();
  if (value is String) {
    // Intentar parsear tal cual (maneja "1", "2.5", "-3" etc.)
    final asIs = double.tryParse(value);
    if (asIs != null) return asIs.toString();
    // Formato latinoamericano: "1.023,45" → "1023.45"
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    final parsed = double.tryParse(cleaned);
    return parsed != null ? parsed.toString() : '0';
  }
  return '0';
}

String _pad(int n) => n.toString().padLeft(2, '0');

/// Evalúa [sum(a|b)] bracket syntax
double evaluateSum(String a, String b, Map<String, dynamic> values) {
  final valA = _getNumericValue(a, values);
  final valB = _getNumericValue(b, values);
  return valA + valB;
}

/// Evalúa [res(a|b)] bracket syntax
double evaluateRes(String a, String b, Map<String, dynamic> values) {
  final valA = _getNumericValue(a, values);
  final valB = _getNumericValue(b, values);
  return valA - valB;
}

double _getNumericValue(String raw, Map<String, dynamic> values) {
  raw = raw.trim();
  // Slug directo
  if (values.containsKey(raw)) {
    final v = values[raw];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }
  // Número directo
  return double.tryParse(raw.replaceAll(',', '.')) ?? 0;
}

/// AproximaRedondeo: redondeo especial (5→10, 50→100, etc.)
double _aproximaRedondeo(double x) {
  if (x <= 0) return 0;
  if (x <= 5) return 5;
  if (x <= 10) return 10;
  if (x <= 50) return 50;
  if (x <= 100) return 100;
  if (x <= 500) return 500;
  if (x <= 1000) return 1000;
  if (x <= 5000) return 5000;
  if (x <= 10000) return 10000;
  return (x / 10000).ceil() * 10000;
}

bool _evaluateCondition(String condition, Map<String, dynamic> values) {
  // Soporta: campo=valor, campo!=valor, campo>valor, campo<valor
  final match = RegExp(r'^(\w+)\s*(=|!=|>|<|>=|<=)\s*(.+)$').firstMatch(condition);
  if (match == null) return false;

  final slug = match.group(1)!;
  final op = match.group(2)!;
  final expected = match.group(3)!.trim();

  final actual = values[slug]?.toString().trim() ?? '';

  switch (op) {
    case '=':
      return actual == expected;
    case '!=':
      return actual != expected;
    case '>':
      return (double.tryParse(actual) ?? 0) > (double.tryParse(expected) ?? 0);
    case '<':
      return (double.tryParse(actual) ?? 0) < (double.tryParse(expected) ?? 0);
    case '>=':
      return (double.tryParse(actual) ?? 0) >= (double.tryParse(expected) ?? 0);
    case '<=':
      return (double.tryParse(actual) ?? 0) <= (double.tryParse(expected) ?? 0);
    default:
      return false;
  }
}

/// Obtiene una lista de un repeater desde los values (maneja List y JSON string)
List _getRepeaterList(Map<String, dynamic> values, String slug) {
  final raw = values[slug];
  if (raw is List) return raw;
  if (raw is String) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is List) return parsed;
    } catch (_) {}
  }
  return [];
}

/// Parsea un valor a número
double _parseNumber(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }
  return 0;
}

/// Punto de entrada único para evaluar cualquier fórmula de calculator
/// Retorna el resultado como String (para display), double (para cálculo), o Map (para badges)
dynamic evaluateFormula(String formula, Map<String, dynamic> values) {
  if (formula.isEmpty) return '';

  // === NUEVO: Detectar JSON condicional ===
  final trimmed = formula.trim();
  if (trimmed.startsWith('{')) {
    try {
      final parsed = jsonDecode(trimmed);
      if (parsed is Map && parsed['conditions'] is List) {
        final conditionsResult = _evaluateConditions(
          parsed['conditions'] as List,
          parsed['default'],
          values,
        );
        return conditionsResult;
      }
      if (parsed is Map && parsed.containsKey('text') && parsed.containsKey('color')) {
        return parsed;
      }
    } catch (e) {
      // JSON parse error, continuar con evaluación normal
    }
  }
  // === FIN NUEVO ===

  // === sumRepeaterColumn(slug_repeater|slug_columna) o sumRepeaterColumn(slug_repeater.slug_columna) ===
  // Soporta ambas sintaxis: pipe (|) y dot (.)
  final repColMatch = RegExp(r'sumRepeaterColumn\(([\w-]+)[|. ]([\w-]+)\)').firstMatch(formula);
  if (repColMatch != null) {
    final repSlug = repColMatch.group(1)!;
    final colSlug = repColMatch.group(2)!;
    final list = _getRepeaterList(values, repSlug);
    double sum = 0;
    for (final item in list) {
      sum += _parseNumber(item is Map ? item[colSlug] : null);
    }
    return sum.toStringAsFixed(2);
  }

  // Detectar bracket syntax legacy
  final sumMatch = RegExp(r'\[sum\(([^|]+)\|([^|]+)\)\]').firstMatch(formula);
  if (sumMatch != null) {
    return evaluateSum(sumMatch.group(1)!, sumMatch.group(2)!, values).toStringAsFixed(2);
  }

  final resMatch = RegExp(r'\[res\(([^|]+)\|([^|]+)\)\]').firstMatch(formula);
  if (resMatch != null) {
    return evaluateRes(resMatch.group(1)!, resMatch.group(2)!, values).toStringAsFixed(2);
  }

  // timeRes y sumRel se manejan en el widget (requieren llamada API o parseo de fecha)
  // Para estos, devolver null para que el widget maneje
  if (formula.contains('[timeRes') || formula.contains('[sumRel')) {
    return null; // Señal para que el widget maneje aparte
  }

  // Si la fórmula es solo today(), retornar fecha directamente
  if (formula.trim() == 'today()') {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  }

  // Aritmética directa
  final result = evaluateArithmetic(formula, values);
  return result.toStringAsFixed(2);
}

/// Evalúa condiciones JSON
/// Retorna dynamic: double para números, Map&lt;String, String&gt; para badges
dynamic _evaluateConditions(
  List conditions,
  dynamic defaultResult,
  Map<String, dynamic> values,
) {
  for (final cond in conditions) {
    if (cond is! Map) continue;
    final conditionExpr = cond['condition'] as String? ?? '';
    final action = cond['action'];

    final bool matched = _evaluateSimpleCondition(conditionExpr, values);

    if (matched) {
      if (action is String) {
        return evaluateFormula(action, values);
      }
      if (action is num) return action.toDouble();
      if (action is Map) {
        final text = action['text']?.toString() ?? '';
        final color = action['color']?.toString() ?? 'primary';
        return {'text': text, 'color': color};
      }
      return 0;
    }
  }

  if (defaultResult is String) {
    if (!defaultResult.contains('(') && !RegExp(r'[\+\-\*/]').hasMatch(defaultResult)) {
      return {'text': defaultResult, 'color': 'secondary'};
    }
    return evaluateFormula(defaultResult, values);
  }
  if (defaultResult is num) return defaultResult.toDouble();
  if (defaultResult is Map) {
    final text = defaultResult['text']?.toString() ?? '';
    final color = defaultResult['color']?.toString() ?? 'primary';
    return {'text': text, 'color': color};
  }
  return 0;
}

bool _evaluateSimpleCondition(
  String condition,
  Map<String, dynamic> values,
) {
  // <= y >= primero (2 caracteres)
  final lteMatch = RegExp(r'^(.+?)<=(.+)$').firstMatch(condition);
  if (lteMatch != null) {
    return _compareValues(lteMatch, '<=', values);
  }

  final gteMatch = RegExp(r'^(.+?)>=(.+)$').firstMatch(condition);
  if (gteMatch != null) {
    return _compareValues(gteMatch, '>=', values);
  }

  // = y !=
  final eqMatch = RegExp(r'^([^=!]+)=(.*)$').firstMatch(condition);
  if (eqMatch != null) {
    final field = eqMatch.group(1)!.trim();
    final expected = eqMatch.group(2)!.trim();
    final actual = values[field]?.toString().trim() ?? '';
    return actual == expected;
  }

  final neqMatch = RegExp(r'^([^!]+)!=(.*)$').firstMatch(condition);
  if (neqMatch != null) {
    final field = neqMatch.group(1)!.trim();
    final expected = neqMatch.group(2)!.trim();
    final actual = values[field]?.toString().trim() ?? '';
    return actual != expected;
  }

  // < y >
  final ltMatch = RegExp(r'^(.+?)<(.*)$').firstMatch(condition);
  if (ltMatch != null) {
    return _compareValues(ltMatch, '<', values);
  }

  final gtMatch = RegExp(r'^(.+?)>(.*)$').firstMatch(condition);
  if (gtMatch != null) {
    return _compareValues(gtMatch, '>', values);
  }

  return false;
}

/// Compara dos valores numéricamente
bool _compareValues(
  RegExpMatch match,
  String operator,
  Map<String, dynamic> values,
) {
  final field = match.group(1)!.trim();
  final expected = match.group(2)!.trim();

  final actual = values[field]?.toString().trim() ?? '';
  final actualNum = double.tryParse(actual.replaceAll(',', '.')) ?? 0;
  final expectedNum = double.tryParse(expected.replaceAll(',', '.')) ?? 0;

  switch (operator) {
    case '<=': return actualNum <= expectedNum;
    case '>=': return actualNum >= expectedNum;
    case '<':  return actualNum < expectedNum;
    case '>':  return actualNum > expectedNum;
    default: return false;
  }
}
