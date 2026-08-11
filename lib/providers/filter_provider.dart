import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/filter_model.dart';

/// Date range filter state, serialized as separate channel.
class DateRangeFilter {
  final String fieldKey;   // date field slug
  final DateTime? start;   // start date (nullable)
  final DateTime? end;     // end date (nullable)

  const DateRangeFilter({
    required this.fieldKey,
    this.start,
    this.end,
  });

  bool get isEmpty => start == null && end == null;
  bool get isNotEmpty => !isEmpty;

  DateRangeFilter copyWith({
    String? fieldKey,
    DateTime? start,
    DateTime? end,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return DateRangeFilter(
      fieldKey: fieldKey ?? this.fieldKey,
      start: clearStart ? null : (start ?? this.start),
      end: clearEnd ? null : (end ?? this.end),
    );
  }

  /// Serialize to 3-string format, merged with AND into general filters.
  Map<String, String> serialize() {
    if (isEmpty) return {'json_key': '', 'json_value': '', 'json_condition': ''};

    final dateFormat = DateFormat('yyyy-MM-dd');

    if (start != null && end != null) {
      return {
        'json_key': '$fieldKey^$fieldKey',
        'json_value': '${dateFormat.format(start!)}^${dateFormat.format(end!)}',
        'json_condition': 'mayor_igual^menor_igual',
      };
    } else if (start != null) {
      return {
        'json_key': fieldKey,
        'json_value': dateFormat.format(start!),
        'json_condition': 'mayor_igual',
      };
    } else {
      return {
        'json_key': fieldKey,
        'json_value': dateFormat.format(end!),
        'json_condition': 'menor_igual',
      };
    }
  }
}

/// Manages filter state for a single page (SinglePageWidget).
///
/// Holds manual filters + optional process filters + optional date range.
/// Serializes all into the 3-string backend format.
class FilterProvider extends ChangeNotifier {
  List<FilterModel> _filters = [];
  DateRangeFilter? _dateRange;

  /// Get current filter list (unmodifiable).
  List<FilterModel> get filters => List.unmodifiable(_filters);

  /// Date range filter (separate channel).
  DateRangeFilter? get dateRange => _dateRange;

  /// True if any filters are active.
  bool get hasFilters => _filters.isNotEmpty || (_dateRange?.isNotEmpty ?? false);

  /// Count of active manual filters.
  int get count => _filters.length;

  // ─── CRUD ──────────────────────────────────────────────

  /// Add a filter at end. If list not empty, sets previous last filter's
  /// relation to connect this new one.
  void addFilter(FilterModel filter) {
    if (_filters.isNotEmpty) {
      // Ensure last filter has a relation before adding new one
      final last = _filters.last;
      if (last.relation.isEmpty) {
        _filters[_filters.length - 1] = last.copyWith(relation: 'AND');
      }
    }
    _filters.add(filter.copyWith(relation: '')); // new last has no relation
    notifyListeners();
  }

  /// Insert filter at [index]. Adjusts relations.
  void insertFilter(int index, FilterModel filter) {
    _filters.insert(index, filter);
    _rebuildRelations();
    notifyListeners();
  }

  /// Replace filter at [index].
  void updateFilter(int index, FilterModel filter) {
    if (index < 0 || index >= _filters.length) return;
    _filters[index] = filter;
    notifyListeners();
  }

  /// Remove filter at [index]. Adjusts relations.
  void removeFilter(int index) {
    if (index < 0 || index >= _filters.length) return;
    _filters.removeAt(index);
    _rebuildRelations();
    notifyListeners();
  }

  /// Set relation ("AND" | "OR" | "") on filter at [index].
  /// This determines the connector between filter[index] and filter[index+1].
  void setRelation(int index, String relation) {
    if (index < 0 || index >= _filters.length) return;
    _filters[index] = _filters[index].copyWith(relation: relation);
    notifyListeners();
  }

  /// Replace all filters at once (e.g. from process tab).
  void setFilters(List<FilterModel> filters) {
    _filters = List.from(filters);
    _rebuildRelations();
    notifyListeners();
  }

  /// Clear all manual filters.
  void clearFilters() {
    _filters.clear();
    notifyListeners();
  }

  /// Clear everything including date range.
  void clearAll() {
    _filters.clear();
    _dateRange = null;
    notifyListeners();
  }

  // ─── Date Range ────────────────────────────────────────

  /// Set or update date range filter.
  void setDateRange(DateRangeFilter range) {
    _dateRange = range;
    notifyListeners();
  }

  /// Clear date range filter.
  void clearDateRange() {
    _dateRange = null;
    notifyListeners();
  }

  // ─── Serialization ─────────────────────────────────────

  /// Serialize all filters (manual + date) into the 3-string backend map.
  ///
  /// Date filters are merged with AND (^) after manual filters.
  /// Returns: `{ json_key, json_value, json_condition }`
  Map<String, String> serialize() {
    final general = FilterSerializer.serialize(_filters);

    if (_dateRange == null || _dateRange!.isEmpty) {
      return general;
    }

    final date = _dateRange!.serialize();
    return {
      'json_key': _mergeWithAnd(general['json_key']!, date['json_key']!),
      'json_value': _mergeWithAnd(general['json_value']!, date['json_value']!),
      'json_condition': _mergeWithAnd(general['json_condition']!, date['json_condition']!),
    };
  }

  /// Merge two filter strings with AND separator.
  /// If either is empty, return the other.
  static String _mergeWithAnd(String a, String b) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a^$b';
  }

  // ─── Relation helpers ──────────────────────────────────

  /// Rebuild relations after structural changes.
  /// Ensures: last filter has relation="", all others have "AND" or "OR".
  void _rebuildRelations() {
    if (_filters.isEmpty) return;
    for (int i = 0; i < _filters.length - 1; i++) {
      if (_filters[i].relation.isEmpty) {
        _filters[i] = _filters[i].copyWith(relation: 'AND');
      }
    }
    // Last filter always has empty relation
    _filters[_filters.length - 1] =
        _filters[_filters.length - 1].copyWith(relation: '');
  }

  // ─── "me" token resolution ─────────────────────────────

  /// Resolve "me" token to current user's full name.
  /// Call this before serialization if user is logged in.
  void resolveMeToken(String userFullName) {
    for (int i = 0; i < _filters.length; i++) {
      if (_filters[i].value == '__me__' || _filters[i].value == 'me') {
        _filters[i] = _filters[i].copyWith(value: userFullName);
      }
    }
  }

  // ─── Process filters integration ───────────────────────

  /// Load process filters from backend `filtros` string.
  /// Replaces current manual filters.
  void loadProcessFilters(String filtros) {
    final parsed = FilterSerializer.parseProcessFilters(filtros);
    setFilters(parsed);
  }

  // ─── Debug ─────────────────────────────────────────────

  @override
  String toString() =>
      'FilterProvider(filters: $_filters, dateRange: $_dateRange)';
}
