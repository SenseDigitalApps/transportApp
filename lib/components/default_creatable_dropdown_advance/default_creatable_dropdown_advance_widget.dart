import 'package:flutter/material.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/form_field_controller.dart';
import '../default_creatable_dropdown/default_creatable_dropdown_widget.dart' show OptionType, SelectOption, parseDropdownAdvanceOptions, serializeDropdownAdvanceOptions, evaluateFormula, extractParentSlugs, normalizeFieldValue;

class CreatableDropdownAdvance extends StatefulWidget {
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

  const CreatableDropdownAdvance({
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
  State<CreatableDropdownAdvance> createState() => _CreatableDropdownAdvanceState();
}

class _CreatableDropdownAdvanceState extends State<CreatableDropdownAdvance> {
  late List<OptionType> _localOptions;
  String _currentValue = '';
  bool _skipNextClear = false;
  Map<String, dynamic>? _lastJsonDataSnapshot;

  @override
  void initState() {
    super.initState();
    _initFromProps();
    _lastJsonDataSnapshot = _getEffectiveJsonData();
  }

  void _initFromProps() {
    _localOptions = parseDropdownAdvanceOptions(widget.options.join(','));
    if (_localOptions.isEmpty && widget.options.isNotEmpty) {
      _localOptions = widget.options
          .map((s) => OptionType(label: s, value: s, formula: ''))
          .toList();
    }
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

  bool _hasJsonDataChanged() {
    final current = _getEffectiveJsonData();
    if (_lastJsonDataSnapshot == null) return true;

    final parentSlugs = extractParentSlugs(_localOptions);
    for (final slug in parentSlugs) {
      if (normalizeFieldValue(_lastJsonDataSnapshot![slug]) != normalizeFieldValue(current[slug])) {
        return true;
      }
    }
    return false;
  }

  void _checkAndClearInvalidSelection(List<SelectOption> visibleOptions) {
    if (_skipNextClear) {
      _skipNextClear = false;
      return;
    }
    if (_currentValue.isEmpty) return;

    final effectiveData = _getEffectiveJsonData();
    final parentSlugs = extractParentSlugs(_localOptions);
    final parentFieldHasValue = parentSlugs.isNotEmpty &&
        parentSlugs.any((s) => normalizeFieldValue(effectiveData[s]).isNotEmpty);

    if (!parentFieldHasValue) return;

    final stillValid = visibleOptions.any((o) => o.value == _currentValue);
    if (!stillValid && widget.slug != null && widget.handleDynamicFieldChanges != null) {
      widget.handleDynamicFieldChanges!(widget.slug!, '', widget.index, widget.mainSlug);
      setState(() {
        _currentValue = '';
      });
    }
  }

  void _updateSnapshot() {
    _lastJsonDataSnapshot = _getEffectiveJsonData();
  }

  void _openDropdownSheet() {
    final visibleOptions = _getVisibleOptions();
    _checkAndClearInvalidSelection(visibleOptions);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DropdownSheetAdvance(
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
            widget.onOptionsUpdate!(serializeDropdownAdvanceOptions(_localOptions));
          }
          Navigator.pop(context);
        } : null,
      ),
    );
  }

  @override
  void didUpdateWidget(CreatableDropdownAdvance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      _localOptions = parseDropdownAdvanceOptions(widget.options.join(','));
      if (_localOptions.isEmpty && widget.options.isNotEmpty) {
        _localOptions = widget.options
            .map((s) => OptionType(label: s, value: s, formula: ''))
            .toList();
      }
    }

    if (_hasJsonDataChanged()) {
      final visibleOptions = _getVisibleOptions();
      _checkAndClearInvalidSelection(visibleOptions);
      _updateSnapshot();
    }

    final newValue = widget.controller.value ?? '';
    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
    }
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

class _DropdownSheetAdvance extends StatefulWidget {
  final List<SelectOption> options;
  final String selectedValue;
  final bool isEditable;
  final Function(String) onSelect;
  final Function(String)? onCreate;

  const _DropdownSheetAdvance({
    required this.options,
    required this.selectedValue,
    required this.isEditable,
    required this.onSelect,
    this.onCreate,
  });

  @override
  State<_DropdownSheetAdvance> createState() => _DropdownSheetAdvanceState();
}

class _DropdownSheetAdvanceState extends State<_DropdownSheetAdvance> {
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