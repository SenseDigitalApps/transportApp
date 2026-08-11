import 'package:flutter/scheduler.dart';

import '../../backend/api_requests/api_calls.dart';
import '../../services/formula_api_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'default_calculator_model.dart';
import 'calculator_logic.dart' as calculator_logic;
export 'default_calculator_model.dart';

class DefaultCalculatorWidget extends StatefulWidget {
  const DefaultCalculatorWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controller,
    required this.options,
    required this.idRegister,
    this.formDataNotifier,
    this.jsonData,
    this.mainSlug,
    this.index,
  });

  final String? text;
  final bool isEdit;
  final TextEditingController? controller;
  final String options;
  final String idRegister;
  final dynamic formDataNotifier;
  final Map<String, dynamic>? jsonData;
  final String? mainSlug;
  final int? index;

  @override
  State<DefaultCalculatorWidget> createState() =>
      _DefaultCalculatorWidgetState();
}

class _DefaultCalculatorWidgetState extends State<DefaultCalculatorWidget> {
  late DefaultCalculatorModel _model;
  ApiCallResponse? totalRes;

  // === Parseo de options ===
  String _formula = '';
  bool _isEditable = false;
  bool _isPercentage = false;
  bool _isBadgeMode = false;
  String _badgeText = '';
  Color _badgeColor = Colors.grey.shade100;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultCalculatorModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _parseOptions();

    // Suscribirse a cambios en FormDataNotifier para re-evaluar
    widget.formDataNotifier?.addListener(_onFormDataChanged);

    // Si no editable, calcular al montar
    if (!_isEditable && _formula.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateValue();
      });
    }
  }

  void _parseOptions() {
    final options = widget.options;
    if (options.isEmpty) {
      _formula = '';
      _isEditable = false;
      return;
    }

    try {
      final parsed = jsonDecode(options);
      if (parsed is Map<String, dynamic>) {
        if (parsed.containsKey('conditions')) {
          _formula = options;
          _isEditable = parsed['editable'] ?? false;
          _isPercentage = parsed['is_percentage'] ?? false;
          return;
        }
        _formula = parsed['formula']?.toString() ?? '';
        _isEditable = parsed['editable'] ?? false;
        _isPercentage = parsed['is_percentage'] ?? false;
      } else {
        _formula = options;
      }
    } catch (_) {
      _formula = options;
    }
  }

  void _onFormDataChanged() {
    if (_formula.isEmpty) return;

    if (!_isEditable) {
      _calculateValue();
    }
  }

  Map<String, dynamic> _getCurrentValues() {
    Map<String, dynamic>? _tryScope(Map<String, dynamic> fullData) {
      if (widget.mainSlug != null && widget.index != null) {
        final repeaterData = fullData[widget.mainSlug];
        if (repeaterData is List && widget.index! < repeaterData.length) {
          final repeaterItem = repeaterData[widget.index!];
          if (repeaterItem is Map) {
            return Map<String, dynamic>.from(repeaterItem);
          }
        }
      }
      return null;
    }

    if (widget.formDataNotifier != null) {
      try {
        final notifier = widget.formDataNotifier as dynamic;
        if (notifier.data != null) {
          Map<String, dynamic> fullData = Map<String, dynamic>.from(notifier.data);
          final scoped = _tryScope(fullData);
          if (scoped != null) return scoped;
          return fullData;
        }
      } catch (e) {}
    }
    if (widget.jsonData != null) {
      final scoped = _tryScope(widget.jsonData!);
      if (scoped != null) return scoped;
      return Map<String, dynamic>.from(widget.jsonData!);
    }
    return {};
  }

  /// Detecta si la fórmula requiere llamadas al backend (sumExternal, countExternal, etc.)
  bool _needsBackend(String formula) {
    return formula.contains('sumExternal') ||
        formula.contains('countExternal') ||
        formula.contains('repeaterRelatedExternalSum') ||
        RegExp(r'\bfilter\s*\(').hasMatch(formula);
  }

  void _calculateValue() {
    if (_formula.isEmpty) return;

    final values = _getCurrentValues();

    if (_formula.contains('[timeRes') || _formula.contains('[sumRel')) {
      _handleLegacyBrackets(_formula);
      return;
    }

    if (_needsBackend(_formula)) {
      _calculateWithBackend(values);
      return;
    }

    final result = calculator_logic.evaluateFormula(_formula, values);
    if (result != null) {
      if (result is Map && result.containsKey('text') && result.containsKey('color')) {
        _updateBadge(Map<String, dynamic>.from(result));
      } else {
        String displayValue;
        if (_isPercentage && !result.toString().contains('%')) {
          displayValue = '$result%';
        } else {
          displayValue = result.toString();
        }
        setState(() {
          _isBadgeMode = false;
          widget.controller?.text = displayValue;
        });
      }
    }
  }

  /// Llama al backend para evaluar fórmulas complejas (sumExternal, countExternal, etc.)
  Future<void> _calculateWithBackend(Map<String, dynamic> values) async {
    try {
      final cleanedFormula = _formula.trim().replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
      final dynamic result = await FormulaApiService.fetchComplexFormula(
        formula: cleanedFormula,
        registerId: widget.idRegister,
        slug: '', // calculator básico no siempre tiene slug en options
        jsonData: values,
      );

      if (result is Map && result.containsKey('text') && result.containsKey('color')) {
        _updateBadge(Map<String, dynamic>.from(result));
      } else {
        final doubleValue = (result as num?)?.toDouble() ?? 0;
        String displayValue;
        if (_isPercentage) {
          displayValue = '${doubleValue.toStringAsFixed(2)}%';
        } else {
          displayValue = doubleValue.toStringAsFixed(2);
        }
        setState(() {
          _isBadgeMode = false;
          widget.controller?.text = displayValue;
        });
      }
    } catch (e) {
      // Fallback: intentar cálculo local
      final result = calculator_logic.evaluateFormula(_formula, values);
      if (result != null) {
        setState(() {
          _isBadgeMode = false;
          widget.controller?.text = result.toString();
        });
      }
    }
  }

  void _updateBadge(Map<String, dynamic> badge) {
    final text = badge['text']?.toString() ?? '';
    final colorName = badge['color']?.toString() ?? 'primary';
    setState(() {
      _isBadgeMode = true;
      _badgeText = text;
      _badgeColor = _parseBadgeColor(colorName);
      widget.controller?.text = jsonEncode({'text': text, 'color': colorName});
    });
  }

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

  void _handleLegacyBrackets(String formula) {
    RegExp sumRelPattern = RegExp(r'\[sumRel\(([^|]+)\|([^|]+)\|([^|]+)\)\]');
    RegExp timePattern = RegExp(r'\[timeRes\(([^|]+)\|([^|]+)\)\]');

    final timeMatch = timePattern.firstMatch(formula);
    if (timeMatch != null) {
      _evaluateTimeRes(timeMatch.group(1)!, timeMatch.group(2)!);
      return;
    }

    final sumRelMatch = sumRelPattern.firstMatch(formula);
    if (sumRelMatch != null) {
      _evaluateSumRel(sumRelMatch.group(1)!, sumRelMatch.group(2)!, sumRelMatch.group(3)!);
      return;
    }

    // Mantener compatibilidad con [sum(...)] y [res(...)] legacy
    // que ya son manejados por evaluateFormula, pero si llegamos aquí
    // significa que no se detectaron timeRes ni sumRel
    final values = _getCurrentValues();
    final result = calculator_logic.evaluateFormula(formula, values);
    if (result != null) {
      widget.controller?.text = result.toString();
    }
  }

  void _evaluateTimeRes(String firstValue, String secondValue) {
    if (firstValue.contains('(Terminado)')) {
      widget.controller?.text = firstValue;
    } else {
      try {
        DateTime date1 = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(firstValue);
        DateTime date2 = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(secondValue);

        Duration difference = date2.difference(date1);

        int days = difference.inDays;
        int hours = difference.inHours % 24;

        var finalTime = '$days días, $hours horas (En curso)';

        widget.controller?.text = finalTime;
      } catch (e) {
        widget.controller?.text = '';
      }
    }
  }

  void _evaluateSumRel(String moduleName, String relationalSlug, String comparatedKey) {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      totalRes = await PostCalculatorRelationalSumCall.call(
        token: FFAppState().token,
        tenant: FFAppState().organizacion,
        moduleName: moduleName,
        relationalSlug: relationalSlug,
        comparatedKey: comparatedKey,
        registerId: widget.idRegister,
      );

      var total = getJsonField(
        (totalRes?.jsonBody ?? ''),
        r'''$.total''',
      ).toString().toString();

      widget.controller?.text = total.toString();
    });
  }

  void extractValues(String options) {
    // Legacy: mantener compatibilidad con llamadas antiguas
    // Se usa FFAppState para [sum(...)] y [res(...)] legacy
    RegExp sumPattern = RegExp(r'\[sum\(([^|]+)\|([^|]+)\)\]');
    RegExp resPattern = RegExp(r'\[res\(([^|]+)\|([^|]+)\)\]');
    RegExp sumRelPattern = RegExp(r'\[sumRel\(([^|]+)\|([^|]+)\|([^|]+)\)\]');
    RegExp timePattern = RegExp(r'\[timeRes\(([^|]+)\|([^|]+)\)\]');

    if (sumPattern.hasMatch(options)) {
      var match = sumPattern.firstMatch(options);
      if (match != null) {
        var firstValueSlug = match.group(1);
        var secondValueSlug = match.group(2);

        var firstValue = FFAppState()
            .textoControlador
            .firstWhere((element) => element[0] == firstValueSlug)[1];
        var secondValue = FFAppState()
            .textoControlador
            .firstWhere((element) => element[0] == secondValueSlug)[1];
        var sum = int.parse(firstValue) + int.parse(secondValue);

        widget.controller?.text = sum.toString();
      }
    } else if (resPattern.hasMatch(options)) {
      var match = resPattern.firstMatch(options);
      if (match != null) {
        var firstValueSlug = match.group(1);
        var secondValueSlug = match.group(2);

        var firstValue = FFAppState()
            .textoControlador
            .firstWhere((element) => element[0] == firstValueSlug)[1];
        var secondValue = FFAppState()
            .textoControlador
            .firstWhere((element) => element[0] == secondValueSlug)[1];

        var sum = int.parse(firstValue) - int.parse(secondValue);

        widget.controller?.text = sum.toString();
      }
    } else if (sumRelPattern.hasMatch(options)) {
      var match = sumRelPattern.firstMatch(options);
      if (match != null) {
        var moduleName = match.group(1);
        var firstValue = match.group(2);
        var secondValue = match.group(3);

        SchedulerBinding.instance.addPostFrameCallback((_) async {
          totalRes = await PostCalculatorRelationalSumCall.call(
            token: FFAppState().token,
            tenant: FFAppState().organizacion,
            moduleName: moduleName,
            relationalSlug: firstValue,
            comparatedKey: secondValue,
            registerId: widget.idRegister,
          );

          var total = getJsonField(
            (totalRes?.jsonBody ?? ''),
            r'''$.total''',
          ).toString().toString();

          widget.controller?.text = total.toString();
        });
      }
    } else if (timePattern.hasMatch(options)) {
      var match = timePattern.firstMatch(options);
      if (match != null) {
        var firstValue = match.group(2);
        var secondValue = match.group(3);

        if (firstValue != null && firstValue.contains('(Terminado)')) {
          widget.controller?.text = firstValue;
        } else {
          try {
            DateTime date1 =
                DateFormat("yyyy-MM-ddTHH:mm:ss").parse(firstValue!);
            DateTime date2 =
                DateFormat("yyyy-MM-ddTHH:mm:ss").parse(secondValue!);

            Duration difference = date2.difference(date1);

            int days = difference.inDays;
            int hours = difference.inHours % 24;

            var finalTime = '$days días, $hours horas (En curso)';

            widget.controller?.text = finalTime;
          } catch (e) {
            widget.controller?.text = '';
          }
        }
      }
    }
  }

  @override
  void didUpdateWidget(DefaultCalculatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recalcular si cambió jsonData O mainSlug (scoping cambió)
    final dataChanged = oldWidget.jsonData != widget.jsonData;
    final slugChanged = oldWidget.mainSlug != widget.mainSlug;
    final indexChanged = oldWidget.index != widget.index;
    if ((dataChanged || slugChanged || indexChanged) && !_isEditable && _formula.isNotEmpty) {
      _calculateValue();
    }
  }

  @override
  void dispose() {
    widget.formDataNotifier?.removeListener(_onFormDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    return TextFormField(
      controller: widget.controller,
      focusNode: _model.textFieldFocusNode,
      autofocus: false,
      obscureText: false,
      enabled: _isEditable,
      decoration: InputDecoration(
        hintText: widget.text,
        hintStyle: FlutterFlowTheme.of(context).bodyLarge.override(
              fontFamily: 'Roboto',
              letterSpacing: 0.0,
              color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.5),
            ),
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
      ),
      style: FlutterFlowTheme.of(context).bodyLarge.override(
            fontFamily: 'Roboto',
            letterSpacing: 0.0,
          ),
      keyboardType: TextInputType.number,
      validator: _model.textControllerValidator.asValidator(context),
    );
  }
}
