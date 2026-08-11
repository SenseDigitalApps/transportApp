import 'package:transport_app/flutter_flow/form_field_controller.dart';
import '/components/default_text_field/default_text_field_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import '/models/filter_model.dart';
import '/providers/filter_provider.dart';
import 'pop_up_filter_model.dart';
export 'pop_up_filter_model.dart';

class PopUpFilterWidget extends StatefulWidget {
  const PopUpFilterWidget({
    super.key,
    required this.filterProvider,
    required this.optionsFilter,
    this.onApply,
  });

  final FilterProvider filterProvider;
  final List<Map<String, String>> optionsFilter;
  final VoidCallback? onApply;

  @override
  State<PopUpFilterWidget> createState() => _PopUpFilterWidgetState();
}

class _PopUpFilterWidgetState extends State<PopUpFilterWidget>
    with TickerProviderStateMixin {
  late PopUpFilterModel _model;
  late TabController _tabController;

  // ─── Filter form state ────────────────────────────────
  late FormFieldController<String> _fieldController;
  late FormFieldController<String> _conditionController;
  late TextControllerNotifier _valueController;
  String _selectedFieldType = '';
  String _selectedSlug = '';
  String _selectedRelation = 'AND';
  int? _editingIndex;

  List<Map<String, String>> _availableConditions = [
    {'label': 'Contiene', 'value': 'igual'},
    {'label': 'Es exactamente', 'value': 'exacto'},
    {'label': 'Es diferente de', 'value': 'diferente'},
  ];

  // ─── Date range form state ────────────────────────────
  late FormFieldController<String> _dateFieldController;
  String _dateRangeSlug = '';
  DateTime? _startDate;
  DateTime? _endDate;

  // Date fields derived from optionsFilter
  // Built-in date fields (always available) + dynamic calendar/datetime fields
  static const _builtinDateFields = [
    {'label': 'Fecha de Publicación', 'slug': 'published_date', 'type': 'datetime'},
    {'label': 'Última Actualización', 'slug': 'last_updated', 'type': 'datetime'},
  ];

  List<Map<String, String>> get _dateFields {
    final dynamic = widget.optionsFilter
        .where((o) => o['type'] == 'calendar' || o['type'] == 'datetime')
        .toList();
    // Deduplicate: skip built-in if already in dynamic
    final dynamicSlugs = dynamic.map((o) => o['slug']).toSet();
    final builtin = _builtinDateFields
        .where((o) => !dynamicSlugs.contains(o['slug']))
        .toList();
    return [...builtin, ...dynamic];
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PopUpFilterModel());
    _tabController = TabController(length: 2, vsync: this);
    _fieldController = FormFieldController('');
    _conditionController = FormFieldController('igual');
    _valueController = TextControllerNotifier('');
    _dateFieldController = FormFieldController('');

    // Pre-fill date range if provider has one
    final existing = widget.filterProvider.dateRange;
    if (existing != null && existing.isNotEmpty) {
      _dateRangeSlug = existing.fieldKey;
      _startDate = existing.start;
      _endDate = existing.end;
      // Find matching label
      final match = _dateFields.where((o) => o['slug'] == _dateRangeSlug);
      if (match.isNotEmpty) {
        _dateFieldController.value = match.first['label']!;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _model.maybeDispose();
    _fieldController.dispose();
    _conditionController.dispose();
    _valueController.dispose();
    _dateFieldController.dispose();
    super.dispose();
  }

  // ─── Filter helpers ───────────────────────────────────

  List<Map<String, String>> _buildConditionsForType(String fieldType) {
    final List<Map<String, String>> conditions = [
      {'label': 'Contiene', 'value': 'igual'},
      {'label': 'Es exactamente', 'value': 'exacto'},
      {'label': 'Es diferente de', 'value': 'diferente'},
    ];
    if (FilterConditions.numericFieldTypes.contains(fieldType)) {
      conditions.addAll([
        {'label': 'Mayor que', 'value': 'mayor'},
        {'label': 'Menor que', 'value': 'menor'},
        {'label': 'Mayor o igual que', 'value': 'mayor_igual'},
        {'label': 'Menor o igual que', 'value': 'menor_igual'},
      ]);
    }
    return conditions;
  }

  String _getConditionLabel(String value) {
    return FilterConditions.labels[value] ?? value;
  }

  String _getFieldLabel(String slug) {
    final match = widget.optionsFilter.where((o) => o['slug'] == slug);
    if (match.isNotEmpty) return match.first['label']!;
    final builtin = _builtinDateFields.where((o) => o['slug'] == slug);
    if (builtin.isNotEmpty) return builtin.first['label']!;
    return slug;
  }

  bool get _isDateField =>
      _selectedFieldType == 'calendar' || _selectedFieldType == 'datetime';

  bool get _isAuthorField => _selectedFieldType == 'author';

  // ─── Filter form actions ──────────────────────────────

  void _resetForm() {
    _fieldController.value = '';
    _conditionController.value = 'igual';
    _valueController.updateText('');
    _selectedFieldType = '';
    _selectedSlug = '';
    _selectedRelation = 'AND';
    _editingIndex = null;
  }

  void _populateFormForEdit(int index) {
    final f = widget.filterProvider.filters[index];
    _editingIndex = index;

    final option = widget.optionsFilter.where((o) => o['slug'] == f.key);
    if (option.isNotEmpty) {
      _fieldController.value = option.first['label']!;
      _selectedSlug = f.key;
      _selectedFieldType = option.first['type'] ?? '';
    } else {
      _fieldController.value = f.key;
      _selectedSlug = f.key;
      _selectedFieldType = '';
    }

    _conditionController.value = f.condition;
    _valueController.updateText(f.value);
    _selectedRelation = f.relation.isNotEmpty ? f.relation : 'AND';
    _availableConditions = _buildConditionsForType(_selectedFieldType);
  }

  void _submitFilter() {
    final slug = _selectedSlug.isNotEmpty
        ? _selectedSlug
        : _fieldController.value ?? '';
    final value = _valueController.value;
    final condition = _conditionController.value ?? 'igual';

    if (slug.isEmpty || value.isEmpty) return;

    final filter = FilterModel(
      key: slug,
      value: value,
      condition: condition,
      relation: '',
    );

    if (_editingIndex != null) {
      widget.filterProvider.updateFilter(_editingIndex!, filter);
      if (_editingIndex! > 0) {
        widget.filterProvider.setRelation(_editingIndex! - 1, _selectedRelation);
      }
    } else {
      if (widget.filterProvider.filters.isNotEmpty) {
        final lastIndex = widget.filterProvider.filters.length - 1;
        widget.filterProvider.setRelation(lastIndex, _selectedRelation);
      }
      widget.filterProvider.addFilter(filter);
    }

    _resetForm();
    setState(() {});
  }

  void _deleteFilter(int index) {
    widget.filterProvider.removeFilter(index);
    if (_editingIndex == index) {
      _resetForm();
    } else if (_editingIndex != null && _editingIndex! > index) {
      _editingIndex = _editingIndex! - 1;
    }
    setState(() {});
  }

  void _cancelEdit() {
    _resetForm();
    setState(() {});
  }

  // ─── Date range actions ───────────────────────────────

  Future<void> _pickStartDate() async {
    await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      onConfirm: (date) {
        setState(() => _startDate = date);
      },
      currentTime: _startDate ?? DateTime.now(),
      minTime: DateTime(2020),
      maxTime: DateTime(2030),
    );
  }

  Future<void> _pickEndDate() async {
    await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      onConfirm: (date) {
        setState(() => _endDate = date);
      },
      currentTime: _endDate ?? _startDate ?? DateTime.now(),
      minTime: _startDate ?? DateTime(2020),
      maxTime: DateTime(2030),
    );
  }

  void _applyDateRange() {
    if (_dateRangeSlug.isEmpty) return;
    if (_startDate == null && _endDate == null) return;

    widget.filterProvider.setDateRange(DateRangeFilter(
      fieldKey: _dateRangeSlug,
      start: _startDate,
      end: _endDate,
    ));
    setState(() {});
  }

  void _clearDateRange() {
    setState(() {
      _dateRangeSlug = '';
      _startDate = null;
      _endDate = null;
      _dateFieldController.value = '';
    });
    widget.filterProvider.clearDateRange();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('dd/MM/yyyy').format(d);
  }

  // ─── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(context),

          // ── Tab bar ─────────────────────────────────────
          _buildTabBar(context),

          // ── Tab content ─────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Filters
                _buildFiltersTab(context),
                // Tab 2: Date range
                _buildDateRangeTab(context),
              ],
            ),
          ),

          // ── Action buttons ──────────────────────────────
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'FILTROS',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  fontSize: 20.0,
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (widget.filterProvider.count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.filterProvider.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (widget.filterProvider.dateRange?.isNotEmpty ?? false) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.date_range,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        border: Border(
          bottom: BorderSide(
            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: FlutterFlowTheme.of(context).primary,
        unselectedLabelColor: FlutterFlowTheme.of(context).secondaryText,
        indicatorColor: FlutterFlowTheme.of(context).primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Filtros'),
          Tab(text: 'Rango de fechas'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB 1: FILTERS
  // ══════════════════════════════════════════════════════

  Widget _buildFiltersTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildActiveFiltersList(context),
          if (widget.filterProvider.hasFilters) const SizedBox(height: 16),
          _buildAddEditForm(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Active filters list ───────────────────────────────

  Widget _buildActiveFiltersList(BuildContext context) {
    final filters = widget.filterProvider.filters;
    if (filters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'Sin filtros activos',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 14,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filters.length,
      itemBuilder: (context, index) {
        final filter = filters[index];
        final isEditing = _editingIndex == index;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (index > 0) _buildConnectorChip(context, index - 1),
            _buildFilterCard(context, index, filter, isEditing),
          ],
        );
      },
    );
  }

  Widget _buildConnectorChip(BuildContext context, int filterIndex) {
    final currentRelation =
        widget.filterProvider.filters[filterIndex].relation;
    final isAnd = currentRelation == 'AND';

    return Center(
      child: GestureDetector(
        onTap: () {
          widget.filterProvider.setRelation(
            filterIndex,
            isAnd ? 'OR' : 'AND',
          );
          setState(() {});
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isAnd
                ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12)
                : FlutterFlowTheme.of(context).tertiary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAnd
                  ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3)
                  : FlutterFlowTheme.of(context).tertiary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            isAnd ? 'Y' : 'O',
            style: TextStyle(
              color: isAnd
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).tertiary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    int index,
    FilterModel filter,
    bool isEditing,
  ) {
    final fieldLabel = _getFieldLabel(filter.key);
    final conditionLabel = _getConditionLabel(filter.condition);
    final displayValue = filter.value == FilterTokens.empty
        ? '(vacío)'
        : filter.value == FilterTokens.notEmpty
            ? '(no vacío)'
            : filter.value;

    return GestureDetector(
      onTap: () {
        if (_editingIndex == index) {
          _cancelEdit();
        } else {
          _populateFormForEdit(index);
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isEditing
              ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.06)
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEditing
                ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.4)
                : FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
            width: isEditing ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldLabel,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$conditionLabel  "$displayValue"',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isEditing)
              Icon(
                Icons.edit,
                size: 16,
                color: FlutterFlowTheme.of(context).primary,
              ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _deleteFilter(index),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add/Edit form ─────────────────────────────────────

  Widget _buildAddEditForm(BuildContext context) {
    final isEditing = _editingIndex != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'EDITAR FILTRO' : 'AGREGAR FILTRO',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FlutterFlowTheme.of(context).primary,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 12),

          // Field selector
          _buildFieldDropdown(context),
          const SizedBox(height: 10),

          // Condition selector
          _buildConditionDropdown(context),
          const SizedBox(height: 10),

          // Value input
          _buildValueInput(context),
          const SizedBox(height: 10),

          // Special value buttons
          if (_isDateField) _buildDateShortcuts(context),
          if (_isAuthorField) _buildMeButton(context),
          _buildSpecialValueButtons(context),

          const SizedBox(height: 12),

          // Relation selector
          if (widget.filterProvider.filters.isNotEmpty &&
              (_editingIndex == null || _editingIndex! > 0))
            _buildRelationSelector(context),

          // Submit / Cancel row
          Row(
            children: [
              if (isEditing)
                TextButton(
                  onPressed: _cancelEdit,
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _submitFilter,
                icon: Icon(isEditing ? Icons.check : Icons.add, size: 18),
                label: Text(isEditing ? 'Guardar' : 'Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldDropdown(BuildContext context) {
    return FlutterFlowDropDown<String>(
      controller: _fieldController,
      options: widget.optionsFilter.map((o) => o['label']!).toList(),
      onChanged: (label) {
        final option =
            widget.optionsFilter.firstWhere((o) => o['label'] == label);
        setState(() {
          _selectedSlug = option['slug']!;
          _selectedFieldType = option['type'] ?? '';
          _availableConditions = _buildConditionsForType(_selectedFieldType);
          if (!_availableConditions
              .any((c) => c['value'] == _conditionController.value)) {
            _conditionController.value = 'igual';
          }
        });
      },
      width: double.infinity,
      height: 50.0,
      textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
      hintText: 'Selecciona un campo',
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: FlutterFlowTheme.of(context).secondaryText,
        size: 24.0,
      ),
      fillColor: FlutterFlowTheme.of(context).primaryBackground,
      elevation: 1.0,
      borderColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
      borderWidth: 1.0,
      borderRadius: 10.0,
      margin: const EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 12.0, 4.0),
      hidesUnderline: true,
      isOverButton: true,
      isSearchable: false,
      isMultiSelect: false,
      disabled: false,
    );
  }

  Widget _buildConditionDropdown(BuildContext context) {
    return FlutterFlowDropDown<String>(
      controller: _conditionController,
      options: _availableConditions.map((c) => c['label']!).toList(),
      onChanged: (label) {
        final item =
            _availableConditions.firstWhere((c) => c['label'] == label);
        setState(() {
          _conditionController.value = item['value']!;
        });
      },
      width: double.infinity,
      height: 50.0,
      textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
      hintText: 'Condición',
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: FlutterFlowTheme.of(context).secondaryText,
        size: 24.0,
      ),
      fillColor: FlutterFlowTheme.of(context).primaryBackground,
      elevation: 1.0,
      borderColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
      borderWidth: 1.0,
      borderRadius: 10.0,
      margin: const EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 12.0, 4.0),
      hidesUnderline: true,
      isOverButton: true,
      isSearchable: false,
      isMultiSelect: false,
      disabled: false,
    );
  }

  Widget _buildValueInput(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DefaultTextFieldWidget(
          text: 'Escribe el valor a filtrar',
          controllerNotifier: _valueController,
          isEdit: true,
          type: _selectedFieldType == 'number' ? 'number' : '',
          slug: _selectedSlug,
        ),
      ),
    );
  }

  // ── Date shortcuts ────────────────────────────────────

  Widget _buildDateShortcuts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: FilterTokens.dateKeywords.entries.map((entry) {
          final isSelected = _valueController.value == entry.key;
          return GestureDetector(
            onTap: () {
              setState(() {
                _valueController.updateText(entry.key);
                _conditionController.value = 'igual';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? FlutterFlowTheme.of(context)
                        .primary
                        .withValues(alpha: 0.12)
                    : FlutterFlowTheme.of(context).primaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? FlutterFlowTheme.of(context).primary
                      : FlutterFlowTheme.of(context)
                          .primary
                          .withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? FlutterFlowTheme.of(context).primary
                      : FlutterFlowTheme.of(context).primaryText,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Author "me" button ────────────────────────────────

  Widget _buildMeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _valueController.updateText('me');
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                FlutterFlowTheme.of(context).primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person,
                  size: 14, color: FlutterFlowTheme.of(context).primary),
              const SizedBox(width: 4),
              Text(
                'Yo (usuario actual)',
                style: TextStyle(
                  fontSize: 12,
                  color: FlutterFlowTheme.of(context).primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Special value buttons ─────────────────────────────

  Widget _buildSpecialValueButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _buildSpecialTokenButton(
            context,
            label: 'Vacío',
            token: FilterTokens.empty,
            icon: Icons.remove_circle_outline,
          ),
          const SizedBox(width: 8),
          _buildSpecialTokenButton(
            context,
            label: 'No vacío',
            token: FilterTokens.notEmpty,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialTokenButton(
    BuildContext context, {
    required String label,
    required String token,
    required IconData icon,
  }) {
    final isSelected = _valueController.value == token;
    return GestureDetector(
      onTap: () {
        setState(() {
          _valueController.updateText(token);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12)
              : FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context)
                    .primary
                    .withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: FlutterFlowTheme.of(context).primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: FlutterFlowTheme.of(context).primary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Relation selector ─────────────────────────────────

  Widget _buildRelationSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            'Conector:',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
          const SizedBox(width: 12),
          _buildRelationChip(context, 'AND', 'Y'),
          const SizedBox(width: 8),
          _buildRelationChip(context, 'OR', 'O'),
        ],
      ),
    );
  }

  Widget _buildRelationChip(
    BuildContext context,
    String value,
    String label,
  ) {
    final isSelected = _selectedRelation == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRelation = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (value == 'AND'
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).tertiary)
              : FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (value == 'AND'
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).tertiary)
                : FlutterFlowTheme.of(context)
                    .primary
                    .withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                isSelected ? Colors.white : FlutterFlowTheme.of(context).primaryText,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB 2: DATE RANGE
  // ══════════════════════════════════════════════════════

  Widget _buildDateRangeTab(BuildContext context) {
    if (_dateFields.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: FlutterFlowTheme.of(context).secondaryText.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No hay campos de fecha disponibles',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current date range display
          if (widget.filterProvider.dateRange?.isNotEmpty ?? false)
            _buildActiveDateRangeCard(context),

          // Date field selector
          _buildDateFieldDropdown(context),
          const SizedBox(height: 16),

          // Date pickers row
          if (_dateRangeSlug.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDatePickerButton(
                    context,
                    label: 'Desde',
                    date: _startDate,
                    onTap: _pickStartDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePickerButton(
                    context,
                    label: 'Hasta',
                    date: _endDate,
                    onTap: _pickEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick date range shortcuts
            _buildDateRangeShortcuts(context),
            const SizedBox(height: 20),

            // Apply / Clear buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearDateRange,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FlutterFlowTheme.of(context).primary,
                      side: BorderSide(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_startDate != null || _endDate != null) ? _applyDateRange : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Aplicar rango'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveDateRangeCard(BuildContext context) {
    final range = widget.filterProvider.dateRange!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 18,
            color: FlutterFlowTheme.of(context).primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFieldLabel(range.fieldKey),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${range.start != null ? _formatDate(range.start) : '...'} → ${range.end != null ? _formatDate(range.end) : '...'}',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              _clearDateRange();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFieldDropdown(BuildContext context) {
    return FlutterFlowDropDown<String>(
      controller: _dateFieldController,
      options: _dateFields.map((o) => o['label']!).toList(),
      onChanged: (label) {
        final option = _dateFields.firstWhere((o) => o['label'] == label);
        setState(() {
          _dateRangeSlug = option['slug']!;
        });
      },
      width: double.infinity,
      height: 50.0,
      textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Outfit',
            fontSize: 14,
          ),
      hintText: 'Selecciona campo de fecha',
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: FlutterFlowTheme.of(context).secondaryText,
        size: 24.0,
      ),
      fillColor: FlutterFlowTheme.of(context).primaryBackground,
      elevation: 1.0,
      borderColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
      borderWidth: 1.0,
      borderRadius: 10.0,
      margin: const EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 12.0, 4.0),
      hidesUnderline: true,
      isOverButton: true,
      isSearchable: false,
      isMultiSelect: false,
      disabled: false,
    );
  }

  Widget _buildDatePickerButton(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null
                ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.4)
                : FlutterFlowTheme.of(context).primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: date != null
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).secondaryText,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
                Text(
                  date != null ? _formatDate(date) : 'Seleccionar',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight:
                            date != null ? FontWeight.w600 : FontWeight.w400,
                        color: date != null
                            ? FlutterFlowTheme.of(context).primaryText
                            : FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeShortcuts(BuildContext context) {
    final now = DateTime.now();
    final shortcuts = [
      {
        'label': 'Hoy',
        'start': DateTime(now.year, now.month, now.day),
        'end': DateTime(now.year, now.month, now.day),
      },
      {
        'label': 'Ayer',
        'start': DateTime(now.year, now.month, now.day - 1),
        'end': DateTime(now.year, now.month, now.day - 1),
      },
      {
        'label': 'Esta semana',
        'start': DateTime(now.year, now.month, now.day - now.weekday + 1),
        'end': now,
      },
      {
        'label': 'Este mes',
        'start': DateTime(now.year, now.month, 1),
        'end': now,
      },
      {
        'label': 'Mes pasado',
        'start': DateTime(now.year, now.month - 1, 1),
        'end': DateTime(now.year, now.month, 0),
      },
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: shortcuts.map((s) {
        final start = s['start'] as DateTime;
        final end = s['end'] as DateTime;
        final isSelected =
            _startDate == start && _endDate == end;
        return GestureDetector(
          onTap: () {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.12)
                  : FlutterFlowTheme.of(context).primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context)
                        .primary
                        .withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              s['label'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).primaryText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ══════════════════════════════════════════════════════

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                widget.filterProvider.clearAll();
                _resetForm();
                _clearDateRange();
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: FlutterFlowTheme.of(context).primary,
                side: BorderSide(
                  color: FlutterFlowTheme.of(context)
                      .primary
                      .withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'LIMPIAR TODO',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'APLICAR',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
