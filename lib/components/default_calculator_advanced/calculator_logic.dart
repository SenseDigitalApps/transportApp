import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:math_expressions/math_expressions.dart';

/// Operadores de fecha y hora soportados en modo calculadora
const List<String> dateTimeOperators = [
  'timeRes',
  'timeResHours',
  'timeResCo',
  'dateAddDays',
  'dateAddMonths',
  'dateDiff',
  'today',
  'extractYear',
  'extractMonth',
  'extractDay',
  'first',
  'aproximarEntero',
  'AproximaRedondeo',
  'consecutivo',
];

/// Formatea un valor con separador de miles (punto) y decimales (coma)
String formatWithThousandSeparator(String? value) {
  if (value == null || value.isEmpty) return '';

  final onlyNumsCommasDots = RegExp(r'^[0-9.,-]*$');
  if (!onlyNumsCommasDots.hasMatch(value)) {
    return '0';
  }

  if (value.isEmpty) return '';

  final parts = value.split(',');
  final intPart = parts[0];
  final decPart = parts.length > 1 ? parts[1] : null;

  final intClean = intPart.replaceAll('.', '');
  final intFormatted = intClean.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  return decPart != null ? '$intFormatted,$decPart' : intFormatted;
}

/// Formatea un número con máximo 2 decimales
String formatNumber(double value) {
  // Redondear a 2 decimales
  final rounded = (value * 100).round() / 100;

  // Convertir a string y reemplazar punto por coma
  String result = rounded.toString().replaceAll('.', ',');

  return result;
}

/// Detecta si la fórmula contiene operadores de fecha/hora
bool containsDateTimeOperator(String formula) {
  return dateTimeOperators.any((op) => formula.contains(op));
}

/// Parsea una función de fecha/hora
Map<String, String>? parseDateTimeFunction(String formula) {
  for (final op in dateTimeOperators) {
    final regex = RegExp('$op\\(([^,]+),?([^)]*)\\)', caseSensitive: false);
    final match = regex.firstMatch(formula);

    if (match != null) {
      return {
        'operator': op,
        'firstValue': match.group(1)?.trim() ?? '',
        'secondValue': match.group(2)?.trim() ?? '',
      };
    }
  }
  return null;
}

/// Obtiene una lista de repeater desde values
List _getRepeaterList(Map<String, dynamic> values, String slug) {
  final raw = values[slug];
  if (raw is List) return raw;
  if (raw is String) {
    try {
      final parsed = jsonDecode(raw);
      return parsed is List ? parsed : [];
    } catch (_) {}
  }
  return [];
}

/// Parsea un número desde dynamic, soportando formato latinoamericano
double _parseNumber(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) {
    // Intentar parsear tal cual (maneja "1", "2.5", "-3" etc.)
    final asIs = double.tryParse(value);
    if (asIs != null) return asIs;
    // Formato latinoamericano: "1.023,45" → "1023.45"
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }
  return 0;
}

/// Resuelve el valor de un campo desde values
dynamic _resolveFieldValue(
  String field,
  Map<String, dynamic> values, {
  int? index,
  String? mainSlug,
}) {
  bool accessMainRecord = false;
  String fieldName = field;

  if (field.startsWith('reg_')) {
    fieldName = field.substring(4);
    accessMainRecord = true;
  }

  if (index != null && mainSlug != null && !accessMainRecord) {
    final repeater = values[mainSlug];
    if (repeater is List && index < repeater.length) {
      final item = repeater[index];
      if (item is Map) {
        return item[fieldName];
      }
    }
  }

  return values[fieldName];
}

/// Evalúa condiciones JSON
/// Retorna dynamic: double para números, Map&lt;String, String&gt; para badges
/// Formato: {"conditions": [{"condition": "campo=valor", "action": "formula"}], "default": "formula"}
dynamic _evaluateConditions(
  List conditions,
  dynamic defaultResult,
  Map<String, dynamic> values,
  Map<String, dynamic> resolvedRefs, {
  int? index,
  String? mainSlug,
}) {
  for (final cond in conditions) {
    if (cond is! Map) continue;
    final conditionExpr = cond['condition'] as String? ?? '';
    final action = cond['action'];

    final bool matched = _evaluateSimpleCondition(conditionExpr, values,
        index: index, mainSlug: mainSlug);

    if (matched) {
      if (action is String) {
        return calcularFormulaSincrona(action, values, resolvedRefs,
            index: index, mainSlug: mainSlug);
      }
      if (action is num) return action.toDouble();
      if (action is Map) {
        // Badge {text, color}
        final text = action['text']?.toString() ?? '';
        final color = action['color']?.toString() ?? 'primary';
        return {'text': text, 'color': color};
      }
      return 0;
    }
  }

  if (defaultResult is String) {
    // Si default no parece fórmula (no tiene operadores ni funciones)
    if (!defaultResult.contains('(') &&
        !RegExp(r'[\+\-\*/]').hasMatch(defaultResult)) {
      return {
        'text': defaultResult,
        'color': 'secondary'
      }; // badge texto simple
    }
    return calcularFormulaSincrona(defaultResult, values, resolvedRefs,
        index: index, mainSlug: mainSlug);
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
  Map<String, dynamic> values, {
  int? index,
  String? mainSlug,
}) {
  // <= y >= primero (2 caracteres)
  final lteMatch = RegExp(r'^(.+?)<=(.+)$').firstMatch(condition);
  if (lteMatch != null) {
    return _compareValues(lteMatch, '<=', values,
        index: index, mainSlug: mainSlug);
  }

  final gteMatch = RegExp(r'^(.+?)>=(.+)$').firstMatch(condition);
  if (gteMatch != null) {
    return _compareValues(gteMatch, '>=', values,
        index: index, mainSlug: mainSlug);
  }

  // = y !=
  final eqMatch = RegExp(r'^([^=!]+)=(.*)$').firstMatch(condition);
  if (eqMatch != null) {
    final field = eqMatch.group(1)!.trim();
    final expected = eqMatch.group(2)!.trim();
    final actual =
        _resolveFieldValue(field, values, index: index, mainSlug: mainSlug);
    return actual?.toString().trim() == expected;
  }

  final neqMatch = RegExp(r'^([^!]+)!=(.*)$').firstMatch(condition);
  if (neqMatch != null) {
    final field = neqMatch.group(1)!.trim();
    final expected = neqMatch.group(2)!.trim();
    final actual =
        _resolveFieldValue(field, values, index: index, mainSlug: mainSlug);
    return actual?.toString().trim() != expected;
  }

  // < y >
  final ltMatch = RegExp(r'^(.+?)<(.*)$').firstMatch(condition);
  if (ltMatch != null) {
    return _compareValues(ltMatch, '<', values,
        index: index, mainSlug: mainSlug);
  }

  final gtMatch = RegExp(r'^(.+?)>(.*)$').firstMatch(condition);
  if (gtMatch != null) {
    return _compareValues(gtMatch, '>', values,
        index: index, mainSlug: mainSlug);
  }

  return false;
}

/// Compara dos valores numéricamente
bool _compareValues(
  RegExpMatch match,
  String operator,
  Map<String, dynamic> values, {
  int? index,
  String? mainSlug,
}) {
  final field = match.group(1)!.trim();
  final expected = match.group(2)!.trim();

  final actual =
      _resolveFieldValue(field, values, index: index, mainSlug: mainSlug);
  final actualNum = _parseNumber(actual);
  final expectedNum = double.tryParse(expected.replaceAll(',', '.')) ?? 0;

  switch (operator) {
    case '<=':
      return actualNum <= expectedNum;
    case '>=':
      return actualNum >= expectedNum;
    case '<':
      return actualNum < expectedNum;
    case '>':
      return actualNum > expectedNum;
    default:
      return false;
  }
}

/// Evalúa operadores de fecha/hora y funciones especiales
/// Retorna null si no pudo evaluar (para que siga con math_expressions)
double? _evaluateDateOperators(
  String formula,
  Map<String, dynamic> values, {
  int? index,
  String? mainSlug,
}) {
  final now = DateTime.now();

  // today()
  if (formula.contains('today()')) {
    return now.millisecondsSinceEpoch.toDouble();
  }

  // extractYear(fecha)
  final extractYearMatch =
      RegExp(r'extractYear\(([^)]+)\)').firstMatch(formula);
  if (extractYearMatch != null) {
    final field = extractYearMatch.group(1)!.trim();
    final val =
        _resolveFieldValue(field, values, index: index, mainSlug: mainSlug);
    final date = _parseDate(val);
    if (date != null) return date.year.toDouble();
    return 0;
  }

  // extractMonth(fecha)
  final extractMonthMatch =
      RegExp(r'extractMonth\(([^)]+)\)').firstMatch(formula);
  if (extractMonthMatch != null) {
    final field = extractMonthMatch.group(1)!.trim();
    final val =
        _resolveFieldValue(field, values, index: index, mainSlug: mainSlug);
    final date = _parseDate(val);
    if (date != null) return date.month.toDouble();
    return 0;
  }

  // extractDay(fecha)
  final extractDayMatch = RegExp(r'extractDay\(([^)]+)\)').firstMatch(formula);
  if (extractDayMatch != null) {
    final field = extractDayMatch.group(1)!.trim();
    final val =
        _resolveFieldValue(field, values, index: index, mainSlug: mainSlug);
    final date = _parseDate(val);
    if (date != null) return date.day.toDouble();
    return 0;
  }

  // first(slug, n)
  final firstMatch = RegExp(r'first\(([^,]+),\s*(\d+)\)').firstMatch(formula);
  if (firstMatch != null) {
    final field = firstMatch.group(1)!.trim();
    final n = int.tryParse(firstMatch.group(2)!) ?? 0;
    final val =
        _resolveFieldValue(field, values, index: index, mainSlug: mainSlug);
    final str = val?.toString() ?? '';
    if (n >= str.length) return 0;
    // Retorna como número si es posible, sino 0
    final result = str.substring(0, n);
    return double.tryParse(result) ?? 0;
  }

  // dateDiff(fecha1, fecha2)
  final dateDiffMatch =
      RegExp(r'dateDiff\(([^,]+),\s*([^)]+)\)').firstMatch(formula);
  if (dateDiffMatch != null) {
    final f1 = _resolveFieldValue(dateDiffMatch.group(1)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final f2 = _resolveFieldValue(dateDiffMatch.group(2)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final d1 = _parseDate(f1);
    final d2 = _parseDate(f2);
    if (d1 != null && d2 != null) {
      return d2.difference(d1).inDays.toDouble();
    }
    return 0;
  }

  // dateAddDays(fecha, n)
  final dateAddDaysMatch =
      RegExp(r'dateAddDays\(([^,]+),\s*([^)]+)\)').firstMatch(formula);
  if (dateAddDaysMatch != null) {
    final f = _resolveFieldValue(dateAddDaysMatch.group(1)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final nStr = dateAddDaysMatch.group(2)!.trim();
    final n = double.tryParse(nStr)?.toInt() ?? 0;
    final date = _parseDate(f);
    if (date != null) {
      final result = date.add(Duration(days: n));
      return result.millisecondsSinceEpoch.toDouble();
    }
    return 0;
  }

  // dateAddMonths(fecha, n)
  final dateAddMonthsMatch =
      RegExp(r'dateAddMonths\(([^,]+),\s*([^)]+)\)').firstMatch(formula);
  if (dateAddMonthsMatch != null) {
    final f = _resolveFieldValue(dateAddMonthsMatch.group(1)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final nStr = dateAddMonthsMatch.group(2)!.trim();
    final n = double.tryParse(nStr)?.toInt() ?? 0;
    final date = _parseDate(f);
    if (date != null) {
      final result = DateTime(date.year, date.month + n, date.day);
      return result.millisecondsSinceEpoch.toDouble();
    }
    return 0;
  }

  // timeRes(fecha1, fecha2)
  final timeResMatch =
      RegExp(r'timeRes\(([^,]+),\s*([^)]+)\)').firstMatch(formula);
  if (timeResMatch != null) {
    final f1 = _resolveFieldValue(timeResMatch.group(1)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final f2 = _resolveFieldValue(timeResMatch.group(2)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final d1 = _parseDate(f1);
    final d2 = _parseDate(f2);
    if (d1 != null && d2 != null) {
      return d2.difference(d1).inDays.toDouble();
    }
    return 0;
  }

  // timeResHours(fecha1, fecha2)
  final timeResHoursMatch =
      RegExp(r'timeResHours\(([^,]+),\s*([^)]+)\)').firstMatch(formula);
  if (timeResHoursMatch != null) {
    final f1 = _resolveFieldValue(timeResHoursMatch.group(1)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final f2 = _resolveFieldValue(timeResHoursMatch.group(2)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final d1 = _parseDate(f1);
    final d2 = _parseDate(f2);
    if (d1 != null && d2 != null) {
      return d2.difference(d1).inHours.toDouble();
    }
    return 0;
  }

  // aproximarEntero(x)
  final aproxMatch = RegExp(r'aproximarEntero\(([^)]+)\)').firstMatch(formula);
  if (aproxMatch != null) {
    final xStr = aproxMatch.group(1)!.trim();
    final x = double.tryParse(xStr) ?? 0;
    return x.ceil().toDouble();
  }

  // AproximaRedondeo(x)
  final aproxRedMatch =
      RegExp(r'AproximaRedondeo\(([^)]+)\)').firstMatch(formula);
  if (aproxRedMatch != null) {
    final xStr = aproxRedMatch.group(1)!.trim();
    final x = double.tryParse(xStr) ?? 0;
    return _aproximaRedondeo(x);
  }

  // consecutivo()
  if (formula.contains('consecutivo()')) {
    final id = values['id'] ?? values['consecutivo'];
    if (id != null) {
      return double.tryParse(id.toString()) ?? 0;
    }
    return 0;
  }

  // timeResCo(fecha1, fecha2) - días hábiles Colombia (sin festivos por ahora)
  final timeResCoMatch =
      RegExp(r'timeResCo\(([^,]+),\s*([^)]+)\)').firstMatch(formula);
  if (timeResCoMatch != null) {
    final f1 = _resolveFieldValue(timeResCoMatch.group(1)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final f2 = _resolveFieldValue(timeResCoMatch.group(2)!.trim(), values,
        index: index, mainSlug: mainSlug);
    final d1 = _parseDate(f1);
    final d2 = _parseDate(f2);
    if (d1 != null && d2 != null) {
      int businessDays = 0;
      DateTime current = d1.isBefore(d2) ? d1 : d2;
      final end = d1.isBefore(d2) ? d2 : d1;
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        if (current.weekday != DateTime.saturday &&
            current.weekday != DateTime.sunday) {
          businessDays++;
        }
        current = current.add(const Duration(days: 1));
      }
      return businessDays.toDouble();
    }
    return 0;
  }

  return null;
}

/// Parsea una fecha desde dynamic (ISO, yyyy-MM-dd, dd/MM/yyyy, etc.)
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    // Intentar ISO 8601
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;
    // Intentar dd/MM/yyyy
    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    // Intentar dd-MM-yyyy
    final parts2 = trimmed.split('-');
    if (parts2.length == 3) {
      final d = int.tryParse(parts2[0]);
      final m = int.tryParse(parts2[1]);
      final y = int.tryParse(parts2[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
  }
  if (value is num) {
    // Asumir timestamp en milisegundos
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
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

/// Calcula una fórmula de forma síncrona
/// Retorna dynamic: double para valores numéricos, Map para badges
///
/// [formula] - La fórmula a calcular
/// [values] - Valores del registro actual
/// [resolvedRefs] - Referencias ya resueltas
/// [index] - Índice si está en un repeater
/// [mainSlug] - Slug del campo repeater principal
dynamic calcularFormulaSincrona(
  String formula,
  Map<String, dynamic> values,
  Map<String, dynamic> resolvedRefs, {
  int? index,
  String? mainSlug,
}) {
  if (formula.isEmpty) {
    return 0;
  }

  try {
    String resolvedFormula = formula;

    // === Parsear JSON condicional (mejorado) ===
    final trimmed = formula.trim();
    if (trimmed.startsWith('{')) {
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is Map && parsed['conditions'] is List) {
          final conditionsResult = _evaluateConditions(
            parsed['conditions'] as List,
            parsed['default'],
            values,
            resolvedRefs,
            index: index,
            mainSlug: mainSlug,
          );
          return conditionsResult;
        }
        // Si es JSON pero no tiene conditions,
        // podría ser un badge directo (text + color)
        if (parsed is Map &&
            parsed.containsKey('text') &&
            parsed.containsKey('color')) {
          return parsed;
        }
      } catch (e) {
        // JSON parse error, continuar con evaluación normal
      }
    }
    // === FIN condiciones ===

    // === sumRepeaterColumn(slug_repeater.slug_columna) ===
    resolvedFormula = resolvedFormula.replaceAllMapped(
      RegExp(r'sumRepeaterColumn\(([\w-]+)\.([\w-]+)\)'),
      (match) {
        final repSlug = match.group(1)!;
        final colSlug = match.group(2)!;
        final list = _getRepeaterList(values, repSlug);
        double sum = 0;
        for (final item in list) {
          sum += _parseNumber(item is Map ? item[colSlug] : null);
        }
        return sum.toStringAsFixed(2);
      },
    );

    // === averageRepeaterColumn(slug_repeater.slug_columna) ===
    resolvedFormula = resolvedFormula.replaceAllMapped(
      RegExp(r'averageRepeaterColumn\(([\w-]+)\.([\w-]+)\)'),
      (match) {
        final repSlug = match.group(1)!;
        final colSlug = match.group(2)!;
        final list = _getRepeaterList(values, repSlug);
        if (list.isEmpty) return '0';
        double sum = 0;
        for (final item in list) {
          sum += _parseNumber(item is Map ? item[colSlug] : null);
        }
        return (sum / list.length).toStringAsFixed(2);
      },
    );

    // === countTrue(campo1, campo2, ...) ===
    resolvedFormula = resolvedFormula.replaceAllMapped(
      RegExp(r'countTrue\(([^)]+)\)'),
      (match) {
        final args = match.group(1)!.split(',').map((s) => s.trim());
        int count = 0;
        for (final arg in args) {
          final val =
              _resolveFieldValue(arg, values, index: index, mainSlug: mainSlug);
          if (val == true ||
              val == 'true' ||
              val == 1 ||
              val == '1' ||
              val == 'SI' ||
              val == 'si') {
            count++;
          }
        }
        return count.toString();
      },
    );

    // === countTrueRepeaterColumn(slug_repeater.slug_columna) ===
    resolvedFormula = resolvedFormula.replaceAllMapped(
      RegExp(r'countTrueRepeaterColumn\(([\w-]+)\.([\w-]+)\)'),
      (match) {
        final repSlug = match.group(1)!;
        final colSlug = match.group(2)!;
        final list = _getRepeaterList(values, repSlug);
        int count = 0;
        for (final item in list) {
          final val = item is Map ? item[colSlug] : null;
          if (val == true ||
              val == 'true' ||
              val == 1 ||
              val == '1' ||
              val == 'SI' ||
              val == 'si') {
            count++;
          }
        }
        return count.toString();
      },
    );

    // === NUEVO: Operadores de fecha/hora y funciones especiales ===
    if (containsDateTimeOperator(resolvedFormula)) {
      final dateResult = _evaluateDateOperators(resolvedFormula, values,
          index: index, mainSlug: mainSlug);
      if (dateResult != null) return dateResult;
    }
    // === FIN NUEVO ===

    // Reemplazar las referencias complejas con los valores ya resueltos
    resolvedRefs.forEach((key, value) {
      resolvedFormula = resolvedFormula.replaceAll(key, value.toString());
    });

    // Procesar campos simples
    final fieldPattern = RegExp(r'\b[a-zA-Z_][\w-]*\b');
    resolvedFormula = resolvedFormula.replaceAllMapped(fieldPattern, (match) {
      final matchStr = match.group(0)!;

      // Evitar procesar campos que ya fueron resueltos
      if (resolvedRefs.keys.any((key) => key.contains(matchStr))) {
        return matchStr;
      }

      // Evitar procesar operadores de fecha/hora y funciones ya manejadas
      if (dateTimeOperators.contains(matchStr)) {
        return matchStr;
      }

      // Evitar reemplazar funciones matemáticas conocidas de math_expressions
      const mathFunctions = [
        'sin',
        'cos',
        'tan',
        'log',
        'ln',
        'sqrt',
        'exp',
        'pi',
        'e'
      ];
      if (mathFunctions.contains(matchStr.toLowerCase())) {
        return matchStr;
      }

      final dynamic value = _resolveFieldValue(
        matchStr,
        values,
        index: index,
        mainSlug: mainSlug,
      );

      if (value == null) {
        return '0';
      }

      if (value is num) {
        return value.toString();
      }

      final valueString = value.toString().trim();
      if (valueString.isEmpty) {
        return '0';
      }

      if (RegExp(r'^-?[0-9.,]+$').hasMatch(valueString)) {
        return _parseNumber(valueString).toString();
      }

      return valueString;
    });

    // Reemplazar coma por punto para la evaluación matemática
    resolvedFormula = resolvedFormula.replaceAll(',', '.');

    // Evaluar la expresión matemática
    Parser parser = Parser();
    Expression exp = parser.parse(resolvedFormula);
    ContextModel contextModel = ContextModel();

    double result = exp.evaluate(EvaluationType.REAL, contextModel);

    if (result.isNaN || result.isInfinite) {
      return 0;
    }

    return result;
  } catch (err) {
    debugPrint('Error evaluating formula: $err');
    return 0;
  }
}

/// Clase para manejar el resultado del cálculo de fórmulas
class FormulaCalculationResult {
  final double result;
  final bool isLoading;
  final bool hasError;
  final List<dynamic> errors;

  FormulaCalculationResult({
    required this.result,
    required this.isLoading,
    required this.hasError,
    required this.errors,
  });
}

/// Extrae referencias complejas de una fórmula
/// Formato: ref_nombreCampo:subCampo
List<Map<String, dynamic>> extractComplexRefs(
  String formula,
  Map<String, dynamic> jsonData, {
  int? index,
  String? mainSlug,
}) {
  if (formula.isEmpty) return [];

  final pattern = RegExp(r'\b(ref_[\w-]+):([\w-]+)\b');
  final matches = pattern.allMatches(formula);

  final List<Map<String, dynamic>> complexRefs = [];

  for (final match in matches) {
    final refField = match.group(1)!; // ej: "ref_nombre"
    final subField = match.group(2)!; // ej: "impuesto"
    final fullMatch = match.group(0)!; // ej: "ref_nombre:impuesto"

    dynamic refObject;

    if (index != null && mainSlug != null) {
      refObject = jsonData[mainSlug]?[index]?[refField];
    } else {
      refObject = jsonData[refField];
    }

    if (refObject == null || refObject is! Map) {
      continue;
    }

    final String tableName =
        refObject['type'] == 'module' ? 'register/' : 'masters/';

    complexRefs.add({
      'refField': refField,
      'subField': subField,
      'fullMatch': fullMatch,
      'id': refObject['value'],
      'tableName': tableName,
      'enabled': refObject['value'] != null && tableName.isNotEmpty,
    });
  }

  return complexRefs;
}

/// Resuelve el valor de un campo
String resolveFieldValue(
  String value,
  Map<String, dynamic> jsonData,
  Map<String, dynamic> resolvedRefs, {
  int? index,
  String? mainSlug,
}) {
  if (value.isEmpty) return '';

  final fieldPattern = RegExp(r'\b[a-zA-Z_][\w-]*\b');
  final resolvedFormula = value.replaceAllMapped(fieldPattern, (match) {
    final matchStr = match.group(0)!;

    // Evitar procesar campos que ya fueron resueltos
    if (resolvedRefs.keys.any((key) => key.contains(matchStr))) {
      return matchStr;
    }

    // Manejar campos con prefijo "reg_"
    String fieldName = matchStr;
    bool accessMainRecord = false;

    if (matchStr.startsWith('reg_')) {
      fieldName = matchStr.substring(4);
      accessMainRecord = true;
    }

    dynamic fieldValue;

    if (index != null && mainSlug != null && !accessMainRecord) {
      fieldValue = jsonData[mainSlug]?[index]?[fieldName];
    } else {
      fieldValue = jsonData[fieldName];
    }

    return (fieldValue != null && fieldValue.toString().isNotEmpty)
        ? fieldValue.toString()
        : '0';
  });

  return resolvedFormula;
}
