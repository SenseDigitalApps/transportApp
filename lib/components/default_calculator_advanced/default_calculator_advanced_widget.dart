import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'calculator_logic.dart';
import '../../services/formula_api_service.dart';
import '../acordeon/form_data_notifier.dart';

class DefaultCalculatorAdvancedWidget extends StatefulWidget {
  const DefaultCalculatorAdvancedWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controller,
    required this.options,
    required this.idRegister,
    this.jsonData,
    this.mainSlug,
    this.index,
    this.fieldSlug,
    this.onFieldChange,
    this.formDataNotifier,
  });

  final String? text;
  final bool isEdit;
  final TextEditingController? controller;
  final String options;
  final String idRegister;
  final Map<String, dynamic>? jsonData;
  final String? mainSlug;
  final int? index;
  final String? fieldSlug;
  final Function(String fieldSlug, dynamic value,
      {int? index, String? mainSlug})? onFieldChange;
  final dynamic formDataNotifier;

  @override
  State<DefaultCalculatorAdvancedWidget> createState() =>
      _DefaultCalculatorAdvancedWidgetState();
}

class _DefaultCalculatorAdvancedWidgetState
    extends State<DefaultCalculatorAdvancedWidget> {
  bool _isCalculating = false;
  bool _hasError = false;
  String _visualValue = '';
  double? _previousValue;
  late bool _isEditable;
  late bool _alwaysRecalculate;
  late String _formula;
  String? _fieldSlug;
  Timer? _debounceTimer;
  bool _isBadgeMode = false;
  String _badgeText = '';
  Color _badgeColor = Colors.grey.shade100;

  Map<String, dynamic>? _scopedRowFrom(Map<String, dynamic> fullData) {
    if (widget.mainSlug != null && widget.index != null) {
      final repeaterData = fullData[widget.mainSlug];
      if (repeaterData is List && widget.index! < repeaterData.length) {
        final row = repeaterData[widget.index!];
        if (row is Map) {
          return Map<String, dynamic>.from(row);
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _parseOptions();
    _initializeValue();

    // Suscribirse a cambios en json_data para re-evaluar (herencia relacional)
    widget.formDataNotifier?.addListener(_onFormDataChanged);
  }

  void _onFormDataChanged() {
    if (_alwaysRecalculate) {
      _calculateValue();
    } else if (!_isEditable) {
      _calculateValue();
    }
  }

  @override
  void didUpdateWidget(DefaultCalculatorAdvancedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.formDataNotifier != widget.formDataNotifier) {
      oldWidget.formDataNotifier?.removeListener(_onFormDataChanged);
      widget.formDataNotifier?.addListener(_onFormDataChanged);
    }

    // Si cambiaron las opciones, volver a parsear
    if (oldWidget.options != widget.options) {
      _parseOptions();
    }

    // Recalcular si cambió jsonData O mainSlug (scoping cambió)
    final dataChanged = oldWidget.jsonData != widget.jsonData;
    final slugChanged = oldWidget.mainSlug != widget.mainSlug;
    final indexChanged = oldWidget.index != widget.index;
    if ((dataChanged || slugChanged || indexChanged) && !_isEditable) {
      _calculateValue();
    }
  }

  /// Parsea las opciones del campo
  void _parseOptions() {
    try {
      final parsed = jsonDecode(widget.options);

      if (parsed is Map<String, dynamic>) {
        // Si hay "conditions", pasar todo el JSON como fórmula
        if (parsed.containsKey('conditions')) {
          _formula = widget.options; // el JSON completo como string
          _isEditable = parsed['editable'] ?? false;
          _alwaysRecalculate = parsed['always_recalculate'] ?? false;
          _fieldSlug = parsed['slug']?.toString() ?? widget.fieldSlug;
          if (_fieldSlug == null) {
          }
          return;
        }

        // Si hay key "formula", extraer
        _formula = parsed['formula'] ?? '';
        _isEditable = parsed['editable'] ?? false;
        _alwaysRecalculate = parsed['always_recalculate'] ?? false;
        _fieldSlug = parsed['slug']?.toString() ?? widget.fieldSlug;
      } else {
        _formula = widget.options;
        _isEditable = false;
        _alwaysRecalculate = false;
        _fieldSlug = widget.fieldSlug;
      }
    } catch (e) {
      // Si no es JSON, asumir que es la fórmula directamente
      _formula = widget.options;
      _isEditable = false;
      _alwaysRecalculate = false;
      _fieldSlug = widget.fieldSlug;
    }
  }

  /// Inicializa el valor visual
  void _initializeValue() {
    if (_isEditable) {
      // Para campos editables, mostrar el valor actual
      if (widget.text != null && widget.text!.isNotEmpty) {
        _visualValue = formatWithThousandSeparator(widget.text!);
        widget.controller?.text = _visualValue;
      }
    } else {
      // Para campos no editables, calcular automáticamente
      _calculateValue();
    }
  }

  /// Detecta si la fórmula requiere llamadas al backend
  bool _needsBackend(String formula) {
    return formula.contains('sumExternal') ||
        formula.contains('countExternal') ||
        formula.contains('repeaterRelatedExternalSum') ||
        RegExp(r'\bfilter\s*\(').hasMatch(formula);
  }

  /// Detecta si una fórmula con sumExternal/countExternal es "compleja"
  /// (tiene operadores aritméticos fuera de las funciones)
  bool _isComplexFormula(String formula) {
    // Quitar sumExternal, countExternal, repeaterRelatedExternalSum
    String withoutFunctions = formula
        .replaceAll(RegExp(r'sumExternal\([^)]+\)'), '')
        .replaceAll(RegExp(r'countExternal\([^)]+\)'), '')
        .replaceAll(RegExp(r'repeaterRelatedExternalSum\([^)]+\)'), '');

    // Si quedan operadores aritméticos, es compleja
    return RegExp(r'[\+\-\*/]').hasMatch(withoutFunctions.trim());
  }

  /// Extrae el primer sumExternal simple para usar fetchFormula (GET)
  /// Formato esperado: sumExternal(modulo,campo;[filtros])
  Map<String, String>? _parseSimpleSumExternal(String formula) {
    final match =
        RegExp(r'sumExternal\(([\w-]+)\s*,\s*([\w-]+)\s*;?\s*\[?([^\]]*)\]?\)')
            .firstMatch(formula.trim());
    if (match == null) return null;

    final moduleName = match.group(1)!;
    final fieldSlug = match.group(2)!;
    final filters = match.group(3)?.trim() ?? '';

    return {
      'moduleName': moduleName,
      'fieldSlug': fieldSlug,
      'filters': filters
    };
  }

  /// Calcula el valor de la fórmula
  Future<void> _calculateValue() async {
    Map<String, dynamic>? evaluationData;
    Map<String, dynamic>? scopedData;

    if (widget.formDataNotifier is FormDataNotifier) {
      final fullData = Map<String, dynamic>.from(
          (widget.formDataNotifier as FormDataNotifier).data);
      scopedData = _scopedRowFrom(fullData);
      if (scopedData == null && widget.jsonData != null) {
        scopedData = Map<String, dynamic>.from(widget.jsonData!);
      }

      final hasRepeaterData =
          widget.mainSlug != null && fullData[widget.mainSlug] is List;
      evaluationData = hasRepeaterData ? fullData : (scopedData ?? fullData);
    } else {
      evaluationData = widget.jsonData != null
          ? Map<String, dynamic>.from(widget.jsonData!)
          : null;
      scopedData = evaluationData;
    }

    await _calculateValueWithData(evaluationData,
        scopedData: scopedData ?? widget.jsonData);
  }

  Future<void> _calculateValueWithData(
    Map<String, dynamic>? data, {
    Map<String, dynamic>? scopedData,
  }) async {
    if (_formula.isEmpty || data == null) {
      setState(() {
        _visualValue = '0';
        widget.controller?.text = _visualValue;
      });
      return;
    }

    setState(() {
      _isCalculating = true;
      _hasError = false;
    });

    try {
      if (_needsBackend(_formula)) {
        await _calculateWithBackend(scopedData ?? data);
      } else {
        await _calculateLocal(data, scopedData: scopedData);
      }
    } catch (e, stack) {
      setState(() {
        _hasError = true;
        _visualValue = '0';
        widget.controller?.text = _visualValue;
      });
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<void> _calculateWithBackend(Map<String, dynamic> data) async {
    final cleanedFormula =
        _formula.trim().replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');

    // ESTRATEGIA 1: Si tenemos un registerId real y un slug, intentar
    // fetchBackendFormula (el backend conoce la fórmula completa del CustomField)
    final regIdNum = int.tryParse(widget.idRegister);
    if (regIdNum != null &&
        regIdNum > 0 &&
        _fieldSlug != null &&
        _fieldSlug!.isNotEmpty) {
      try {
        final result = await FormulaApiService.fetchBackendFormula(
          registerId: widget.idRegister,
          slug: _fieldSlug!,
        );
        _updateValue(result);
        return;
      } catch (e) {
      }
    }

    // ESTRATEGIA 2: Si es un sumExternal SIMPLE (sin operadores aritméticos
    // adicionales), usar fetchFormula (GET) que es más directo
    if (!_isComplexFormula(cleanedFormula)) {
      final simpleSum = _parseSimpleSumExternal(cleanedFormula);
      if (simpleSum != null && regIdNum != null && regIdNum > 0) {
        try {
          await FormulaApiService.fetchFormula(
            moduleName: simpleSum['moduleName']!,
            fieldSlug: simpleSum['fieldSlug']!,
            registerId: widget.idRegister,
            customFieldSlug: _fieldSlug ?? '',
            filters: simpleSum['filters']!,
          );
        } catch (e) {
        }
      }
    }

    // ESTRATEGIA 3: fetchComplexFormula (POST) para fórmulas complejas
    try {
      final dynamic result = await FormulaApiService.fetchComplexFormula(
        formula: cleanedFormula,
        registerId: widget.idRegister,
        slug: _fieldSlug ?? '',
        jsonData: data,
      );
      // Detectar si el resultado es un badge
      if (result is Map &&
          result.containsKey('text') &&
          result.containsKey('color')) {
        _updateBadge(Map<String, dynamic>.from(result));
      } else {
        _updateValue((result as num?)?.toDouble() ?? 0);
      }
    } catch (e) {
      // Si falla el backend, intentar cálculo local como fallback
      await _calculateLocal(data, scopedData: data);
    }
  }

  Future<void> _calculateLocal(
    Map<String, dynamic> data, {
    Map<String, dynamic>? scopedData,
  }) async {

    // Extraer referencias complejas
    final complexRefs = extractComplexRefs(
      _formula,
      data,
      index: widget.index,
      mainSlug: widget.mainSlug,
    );

    // Resolver referencias complejas vía API
    final Map<String, dynamic> resolvedRefs = {};
    for (final ref in complexRefs) {
      try {
        final id = ref['id'];
        final tableName = ref['tableName'] as String? ?? '';
        final subField = ref['subField'] as String? ?? '';
        final fullMatch = ref['fullMatch'] as String? ?? '';

        if (id != null && id.toString().isNotEmpty) {
          final registerData = await FormulaApiService.getRegisterById(
            id: int.parse(id.toString()),
            tableName: tableName,
          );
          final jsonData =
              registerData['json_data'] as Map<String, dynamic>? ?? {};
          resolvedRefs[fullMatch] = jsonData[subField] ?? 0;
        }
      } catch (_) {
        resolvedRefs[ref['fullMatch'] as String? ?? ''] = 0;
      }
    }

    // Calcular el valor — ahora retorna dynamic
    final result = calcularFormulaSincrona(
      _formula,
      data,
      resolvedRefs,
      index: widget.index,
      mainSlug: widget.mainSlug,
    );

    // Detectar si el resultado es un badge
    if (result is Map &&
        result.containsKey('text') &&
        result.containsKey('color')) {
      _updateBadge(Map<String, dynamic>.from(result));
    } else {
      _updateValue((result as num?)?.toDouble() ?? 0);
    }
  }

  /// Actualiza el valor calculado
  void _updateValue(double value) {
    final previousValue = _previousValue;
    if (value != _previousValue) {
      _previousValue = value;

      final formattedValue = formatNumber(value);
      final displayValue = formatWithThousandSeparator(formattedValue);

      setState(() {
        _visualValue = displayValue;
        widget.controller?.text = displayValue;
      });

      // Notificar el cambio si hay callback
      if (widget.onFieldChange != null && _fieldSlug != null) {
        widget.onFieldChange!(
          _fieldSlug!,
          formattedValue,
          index: widget.index,
          mainSlug: widget.mainSlug,
        );
      }
    }
  }

  /// Actualiza el campo con un badge visual
  void _updateBadge(Map<String, dynamic> badge) {
    final text = badge['text']?.toString() ?? '';
    final colorName = badge['color']?.toString() ?? 'primary';

    setState(() {
      _isBadgeMode = true;
      _badgeText = text;
      _badgeColor = _parseBadgeColor(colorName);
      // También guardar como string en el controller para que el save funcione
      widget.controller?.text = jsonEncode({'text': text, 'color': colorName});
    });

    // Notificar cambio
    if (widget.onFieldChange != null && _fieldSlug != null) {
      widget.onFieldChange!(
        _fieldSlug!,
        jsonEncode({'text': text, 'color': colorName}),
        index: widget.index,
        mainSlug: widget.mainSlug,
      );
    }
  }

  /// Convierte nombre de color a Color
  Color _parseBadgeColor(String name) {
    switch (name.toLowerCase()) {
      case 'danger':
      case 'red':
      case 'error':
        return Colors.red.shade100;
      case 'warning':
      case 'orange':
      case 'yellow':
        return Colors.orange.shade100;
      case 'success':
      case 'green':
        return Colors.green.shade100;
      case 'info':
      case 'blue':
      case 'primary':
        return Colors.blue.shade100;
      case 'secondary':
      case 'gray':
      case 'grey':
        return Colors.grey.shade200;
      default:
        return Colors.grey.shade100;
    }
  }

  /// Maneja el clic en el botón de calcular (solo para campos editables)
  void _handleCalculateClick() {
    if (_isEditable && _formula.isNotEmpty) {
      _calculateValue();
    }
  }

  /// Maneja los cambios en el input (solo para campos editables)
  void _handleInputChange(String value) {
    if (!_isEditable) return;

    // Permitir solo números, coma, punto y signo negativo
    String inputValue = value.replaceAll(RegExp(r'[^0-9,.-]'), '');

    // Quitar puntos de miles para quedarnos con el valor "crudo"
    final numericInput = inputValue.replaceAll('.', '');

    // Formatear para mostrar
    final visual = formatWithThousandSeparator(numericInput);

    setState(() {
      _visualValue = visual;
      widget.controller?.text = visual;
    });

    // Guardar el valor sin separadores de miles y con '.' como separador decimal
    final numericToSave = numericInput.replaceAll(',', '.');

    // Notificar el cambio
    if (widget.onFieldChange != null && _fieldSlug != null) {
      widget.onFieldChange!(
        _fieldSlug!,
        numericToSave,
        index: widget.index,
        mainSlug: widget.mainSlug,
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.formDataNotifier?.removeListener(_onFormDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCalculating && !_isEditable) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Calculando...'),
        ),
      );
    }

    // Renderizar badge si corresponde
    if (_isBadgeMode && !_isEditable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _badgeColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _badgeText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _badgeColor.computeLuminance() > 0.5
                ? Colors.black87
                : Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        // Ícono de calculadora
        if (_isEditable)
          GestureDetector(
            onTap: _handleCalculateClick,
            child: const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.calculate,
                color: Colors.blue,
                size: 20,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.calculate,
              color: _hasError ? Colors.red : Colors.grey,
              size: 20,
            ),
          ),

        // Campo de texto
        Expanded(
          child: TextField(
            controller: widget.controller,
            readOnly: !_isEditable,
            keyboardType: _isEditable
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.none,
            style: TextStyle(
              fontSize: 14,
              color: _visualValue.startsWith('-') ? Colors.red : null,
            ),
            decoration: InputDecoration(
              filled: false,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            onChanged: _isEditable ? _handleInputChange : null,
          ),
        ),
      ],
    );
  }
}
