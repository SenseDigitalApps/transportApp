import 'dart:convert';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';

class OptionType {
  String label;
  String value;
  String? formula;

  OptionType({required this.label, required this.value, this.formula});

  factory OptionType.fromJson(Map<String, dynamic> json) => OptionType(
        label: json['label'] ?? '',
        value: json['value'] ?? json['label'] ?? '',
        formula: json['formula'],
      );
}

class SelectOption {
  String value;
  String label;
  SelectOption({required this.value, required this.label});
}

String normalizeFieldValue(dynamic raw) {
  if (raw == null) return '';
  if (raw is Map) {
    if (raw['value'] != null) return raw['value'].toString().trim();
    if (raw['label'] != null) return raw['label'].toString().trim();
    return '';
  }
  return raw.toString().trim();
}

bool evaluateFormula(String? formula, Map<String, dynamic> jsonData) {
  if (formula == null || formula.trim().isEmpty) return true;

  final orGroups = formula.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty);

  return orGroups.any((group) {
    final andConditions = group.split('^').map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (andConditions.isEmpty) return false;

    return andConditions.every((condition) {
      final eqIndex = condition.indexOf('=');
      if (eqIndex == -1) return false;
      final slug = condition.substring(0, eqIndex).trim();
      final expected = condition.substring(eqIndex + 1).trim();
      final actual = normalizeFieldValue(jsonData[slug]);
      return actual == expected;
    });
  });
}

Set<String> extractParentSlugs(List<OptionType> options) {
  final slugs = <String>{};
  for (final opt in options) {
    if (opt.formula == null || opt.formula!.isEmpty) continue;
    for (final part in opt.formula!.split(RegExp(r'[|^]'))) {
      final cond = part.trim();
      if (cond.isEmpty) continue;
      final idx = cond.indexOf('=');
      if (idx > -1) slugs.add(cond.substring(0, idx).trim());
    }
  }
  return slugs;
}

({List<OptionType> options, String source}) parseDropdownOptions(String raw) {
  if (raw.isEmpty) return (options: <OptionType>[], source: 'csv');

  try {
    final parsed = jsonDecode(raw);
    if (parsed is List) {
      final opts = parsed.map((item) {
        if (item is String) {
          final t = item.trim();
          return OptionType(label: t, value: t, formula: '');
        }
        if (item is Map) {
          return OptionType.fromJson(item as Map<String, dynamic>);
        }
        return OptionType(label: '', value: '', formula: '');
      }).where((o) => o.value.isNotEmpty).toList();
      return (options: opts, source: 'json');
    }
  } catch (_) {}

  final opts = raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map((s) => OptionType(label: s, value: s, formula: ''))
      .toList();
  return (options: opts, source: 'csv');
}

List<OptionType> parseDropdownAdvanceOptions(String raw) {
  if (raw.isEmpty) return [];
  try {
    final parsed = jsonDecode(raw);
    if (parsed is List) {
      return parsed
          .map((item) => item is Map ? OptionType.fromJson(item as Map<String, dynamic>) : OptionType(label: '', value: '', formula: ''))
          .where((o) => o.value.isNotEmpty)
          .toList();
    }
  } catch (_) {}
  return [];
}

String serializeDropdownOptions(List<OptionType> options, String source) {
  final hasFormula = options.any((o) => o.formula != null && o.formula!.isNotEmpty);
  if (source == 'json' || hasFormula) {
    return jsonEncode(options.map((o) => {
          'label': o.label,
          'value': o.value,
          'formula': o.formula ?? '',
        }).toList());
  }
  return options.map((o) => o.label).join(',');
}

String serializeDropdownAdvanceOptions(List<OptionType> options) {
  return jsonEncode(options.map((o) => {
        'label': o.label,
        'value': o.value,
        'formula': o.formula ?? '',
      }).toList());
}

class CreatableDropdown extends StatefulWidget {
  final String? text;
  final List<String> options;
  final bool isEdit;
  final FormFieldController<String> controller;
  final Map<String, dynamic> jsonData;
  final String? slug;
  final Function(String slug, dynamic value, int? index, String? mainSlug)? handleDynamicFieldChanges;
  final bool onlyView;
  final int? index;
  final String? mainSlug;
  final Function(String newOptionsString)? onOptionsUpdate;

  const CreatableDropdown({
    super.key,
    this.text,
    required this.options,
    required this.isEdit,
    required this.controller,
    required this.jsonData,
    this.slug,
    this.handleDynamicFieldChanges,
    this.onlyView = false,
    this.index,
    this.mainSlug,
    this.onOptionsUpdate,
  });

  @override
  State<CreatableDropdown> createState() => _CreatableDropdownState();
}

class _CreatableDropdownState extends State<CreatableDropdown> {
  late List<OptionType> _localOptions;
  late String _optionsSource;
  String _currentValue = '';
  bool _skipNextClear = false;
  Map<String, String> _parentValueSnapshot = {};

  @override
  void initState() {
    super.initState();
    _initFromProps();
    _updateSnapshot();
  }

  void _initFromProps() {
    final parsed = parseDropdownOptions(widget.options.join(','));
    _localOptions = parsed.options;
    _optionsSource = parsed.source;
    _currentValue = widget.controller.value ?? '';
  }

  Map<String, dynamic> _getEffectiveJsonData() {
    if (widget.mainSlug != null && widget.index != null) {
      final mainData = widget.jsonData[widget.mainSlug];
      if (mainData is List && widget.index! < mainData.length) {
        final item = mainData[widget.index!];
        if (item is Map<String, dynamic>) return item;
      }
    }
    return widget.jsonData;
  }

  void _updateSnapshot() {
    final effectiveData = _getEffectiveJsonData();
    final parentSlugs = extractParentSlugs(_localOptions);
    _parentValueSnapshot = {
      for (final slug in parentSlugs) slug: normalizeFieldValue(effectiveData[slug]),
    };
  }

  bool _hasParentValuesChanged() {
    final effectiveData = _getEffectiveJsonData();
    final parentSlugs = extractParentSlugs(_localOptions);
    for (final slug in parentSlugs) {
      final currentValue = normalizeFieldValue(effectiveData[slug]);
      final lastValue = _parentValueSnapshot[slug] ?? '';
      if (currentValue != lastValue) {
        return true;
      }
    }
    return false;
  }

  List<SelectOption> _getVisibleOptions() {
    final effectiveData = _getEffectiveJsonData();
    final parentSlugs = extractParentSlugs(_localOptions);
    final parentFieldHasValue = parentSlugs.isNotEmpty &&
        parentSlugs.any((s) => normalizeFieldValue(effectiveData[s]).isNotEmpty);

    return _localOptions
        .where((opt) {
          if (!parentFieldHasValue) return true;
          return evaluateFormula(opt.formula, effectiveData);
        })
        .map((opt) => SelectOption(value: opt.value, label: opt.label))
        .toList();
  }

  void _checkAndClearInvalidSelection(List<SelectOption> visibleOptions) {
    if (_skipNextClear) {
      _skipNextClear = false;
      return;
    }
    if (_currentValue.isEmpty) return;

    final parentSlugs = extractParentSlugs(_localOptions);
    if (parentSlugs.isEmpty) return;

    final parentFieldHasValue = parentSlugs.any(
      (s) => normalizeFieldValue(_getEffectiveJsonData()[s]).isNotEmpty,
    );
    if (!parentFieldHasValue) return;

    final stillValid = visibleOptions.any((o) => o.value == _currentValue);
    if (!stillValid && widget.slug != null && widget.handleDynamicFieldChanges != null) {
      widget.handleDynamicFieldChanges!(widget.slug!, '', widget.index, widget.mainSlug);
      if (mounted) {
        setState(() {
          _currentValue = '';
        });
      }
    }
  }

  void _openDropdownSheet() {
    final visibleOptions = _getVisibleOptions();
    _checkAndClearInvalidSelection(visibleOptions);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DropdownSheet(
        options: visibleOptions,
        selectedValue: _currentValue,
        isEditable: widget.isEdit,
        onSelect: (value) {
          _skipNextClear = true;
          setState(() {
            _currentValue = value;
            widget.controller.value = value;
          });
          if (widget.slug != null && widget.handleDynamicFieldChanges != null) {
            widget.handleDynamicFieldChanges!(widget.slug!, value, widget.index, widget.mainSlug);
          }
          Navigator.pop(context);
        },
        onCreate: widget.isEdit ? (query) {
          final newOpt = OptionType(label: query, value: query, formula: '');
          setState(() {
            _localOptions.add(newOpt);
          });
          _skipNextClear = true;
          setState(() {
            _currentValue = query;
            widget.controller.value = query;
          });
          if (widget.slug != null && widget.handleDynamicFieldChanges != null) {
            widget.handleDynamicFieldChanges!(widget.slug!, query, widget.index, widget.mainSlug);
          }
          if (widget.onOptionsUpdate != null) {
            widget.onOptionsUpdate!(serializeDropdownOptions(_localOptions, _optionsSource));
          }
          Navigator.pop(context);
        } : null,
      ),
    );
  }

  @override
  void didUpdateWidget(CreatableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      final parsed = parseDropdownOptions(widget.options.join(','));
      setState(() {
        _localOptions = parsed.options;
        _optionsSource = parsed.source;
      });
    }
    if (_hasParentValuesChanged()) {
      _updateSnapshot();
      final visibleOptions = _getVisibleOptions();
      _checkAndClearInvalidSelection(visibleOptions);
    }
    final newValue = widget.controller.value ?? '';
    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleOptions = _getVisibleOptions();

    final hasSelected = _currentValue.isNotEmpty;
    final valueExistsInOptions = hasSelected &&
        visibleOptions.any((opt) => opt.value.trim() == _currentValue.trim());

    final hintItem = Text(
      'Buscar o crear opción...',
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Outfit',
            fontSize: 13,
            letterSpacing: 0.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 45, maxHeight: 65),
        child: InkWell(
          onTap: widget.isEdit ? _openDropdownSheet : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 12.0, 0.0),
            child: Row(
              children: [
                Expanded(
                  child: hasSelected && valueExistsInOptions
                      ? Text(
                          _currentValue,
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                letterSpacing: 0.0,
                                decoration: TextDecoration.none,
                              ),
                        )
                      : hintItem,
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 24.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownSheet extends StatefulWidget {
  final List<SelectOption> options;
  final String selectedValue;
  final bool isEditable;
  final Function(String) onSelect;
  final Function(String)? onCreate;

  const _DropdownSheet({
    required this.options,
    required this.selectedValue,
    required this.isEditable,
    required this.onSelect,
    this.onCreate,
  });

  @override
  State<_DropdownSheet> createState() => _DropdownSheetState();
}

class _DropdownSheetState extends State<_DropdownSheet> {
  String _searchQuery = '';

  List<SelectOption> get _filteredOptions {
    if (_searchQuery.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.label.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool get _canCreate {
    if (!widget.isEditable || _searchQuery.isEmpty) return false;
    return !widget.options.any((o) => o.label.toLowerCase() == _searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _filteredOptions.isEmpty && !_canCreate
                ? Center(
                    child: Text(
                      'No hay opciones disponibles',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredOptions.length + (_canCreate ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredOptions.length && _canCreate) {
                        return ListTile(
                          leading: Icon(Icons.add, color: theme.colorScheme.primary),
                          title: Text(
                            'Crear "$_searchQuery"',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          onTap: () => widget.onCreate!(_searchQuery),
                        );
                      }
                      final option = _filteredOptions[index];
                      final isSelected = option.value == widget.selectedValue;
                      return ListTile(
                        title: Text(option.label),
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primaryContainer,
                        onTap: () => widget.onSelect(option.value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}