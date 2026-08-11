class FilterModel {
  final String key; // field slug (e.g. "nombre", "author", "fecha_creacion")
  final String value; // filter value (e.g. "juan", "100", "today")
  final String
      condition; // operator: igual|exacto|diferente|mayor|menor|mayor_igual|menor_igual
  final String relation; // "" | "AND" | "OR" — connector to NEXT filter

  const FilterModel({
    required this.key,
    required this.value,
    this.condition = 'igual',
    this.relation = '',
  });

  FilterModel copyWith({
    String? key,
    String? value,
    String? condition,
    String? relation,
  }) {
    return FilterModel(
      key: key ?? this.key,
      value: value ?? this.value,
      condition: condition ?? this.condition,
      relation: relation ?? this.relation,
    );
  }

  bool get isEmpty => key.isEmpty || value.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() =>
      'FilterModel(key: $key, value: $value, condition: $condition, relation: $relation)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterModel &&
          key == other.key &&
          value == other.value &&
          condition == other.condition &&
          relation == other.relation;

  @override
  int get hashCode => Object.hash(key, value, condition, relation);
}

/// Known filter conditions (operators).
class FilterConditions {
  FilterConditions._();

  static const String igual = 'igual'; // contains/equals (default)
  static const String exacto = 'exacto'; // exact match
  static const String diferente = 'diferente'; // not equal
  static const String mayor = 'mayor'; // greater than
  static const String menor = 'menor'; // less than
  static const String mayorIgual = 'mayor_igual'; // >=
  static const String menorIgual = 'menor_igual'; // <=

  static const List<String> general = [igual, exacto, diferente];

  static const List<String> numeric = [mayor, menor, mayorIgual, menorIgual];

  static const List<String> all = [
    igual,
    exacto,
    diferente,
    mayor,
    menor,
    mayorIgual,
    menorIgual
  ];

  static const Map<String, String> labels = {
    igual: 'Contiene',
    exacto: 'Es exactamente',
    diferente: 'Es diferente de',
    mayor: 'Mayor que',
    menor: 'Menor que',
    mayorIgual: 'Mayor o igual que',
    menorIgual: 'Menor o igual que',
  };

  static const List<String> numericFieldTypes = [
    'number',
    'datetime',
    'time',
    'calendar',
    'calculator',
  ];

  static List<String> forFieldType(String? fieldType) {
    if (fieldType != null && numericFieldTypes.contains(fieldType)) {
      return all;
    }
    return general;
  }
}

class FilterTokens {
  FilterTokens._();

  static const String empty = '__query__empty__';
  static const String notEmpty = '__query__not_empty__';
  static const String me = 'me';
  static const String multiPrefix = '__query_multi__:';
  static const String multiSeparator = '__qms__';

  static const Map<String, String> dateKeywords = {
    'today': 'Hoy',
    'yesterday': 'Ayer',
    'thisweek': 'Esta semana',
    'lastweek': 'Semana pasada',
    'thismonth': 'Este mes',
    'lastmonth': 'Mes pasado',
  };
}

/// Serializes [FilterModel] list into the 3-string backend format.
///
/// Output: `{ json_key, json_value, json_condition }`
/// Separators: `^` = AND, `|` = OR.
class FilterSerializer {
  FilterSerializer._();

  static Map<String, String> serialize(List<FilterModel> filters) {
    final valid = filters.where((f) => f.isNotEmpty).toList();
    if (valid.isEmpty) {
      return {'json_key': '', 'json_value': '', 'json_condition': ''};
    }

    final jsonKey = _buildString(valid, (f) => f.key);
    final jsonValue = _buildString(valid, (f) => f.value);
    final jsonCondition = _buildString(valid, (f) => f.condition);

    return {
      'json_key': jsonKey,
      'json_value': jsonValue,
      'json_condition': jsonCondition,
    };
  }

  /// Build a single separator-joined string from filters.
  static String _buildString(
    List<FilterModel> filters,
    String Function(FilterModel) extractor,
  ) {
    return filters.asMap().entries.map((entry) {
      final i = entry.key;
      final f = entry.value;
      if (i == 0) return extractor(f);
      final sep = filters[i - 1].relation == 'OR' ? '|' : '^';
      return '$sep${extractor(f)}';
    }).join('');
  }

  /// Parse a process `filtros` string (from backend config) into FilterModel list.
  ///
  /// Format: `"key1,value1^key2,value2|key3,value3"`
  /// or with filter() prefix: `"filter(key1,value1^key2,value2)"`
  static List<FilterModel> parseProcessFilters(String filtros) {
    if (filtros.isEmpty) return [];

    String raw = filtros;
    final filterPrefix = RegExp(r'^filter\((.+)\)$');
    final prefixMatch = filterPrefix.firstMatch(raw);
    if (prefixMatch != null) {
      raw = prefixMatch.group(1)!;
    }

    final regex = RegExp(r'([^,^\|]+),([^,^\|]+)|([\^|])');
    final matches = regex.allMatches(raw).toList();

    final List<FilterModel> result = [];
    String currentRelation = '';

    for (final match in matches) {
      if (match.group(3) != null) {
        // Separator captured
        currentRelation = match.group(3) == '^' ? 'AND' : 'OR';
      } else {
        // Key-value pair captured
        String key = match.group(1)!.trim();
        String value = match.group(2)!.trim();

        // Remap "usuario" → "author"
        if (key == 'usuario') key = 'author';

        if (value == 'me') {
          value = '__me__'; // Marker; actual resolution happens in provider
        }

        result.add(FilterModel(
          key: key,
          value: value,
          condition: 'igual',
          relation: currentRelation,
        ));

        // Reset relation after use
        currentRelation = '';
      }
    }

    // Fix relations: each filter's relation connects it to the NEXT filter
    // The parsed separators are between filters, so reassign correctly
    if (result.length > 1) {
      final separators = <String>[];
      for (final match in matches) {
        if (match.group(3) != null) {
          separators.add(match.group(3) == '^' ? 'AND' : 'OR');
        }
      }
      for (int i = 0; i < result.length - 1; i++) {
        final sep = i < separators.length ? separators[i] : 'AND';
        result[i] = result[i].copyWith(relation: sep);
      }
      result[result.length - 1] =
          result[result.length - 1].copyWith(relation: '');
    }

    return result;
  }
}
