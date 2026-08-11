import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:html/parser.dart' show parse;
import 'package:transport_app/components/certificadora_modal/certificadora_modal_cumplimiento_widget.dart';
import 'package:transport_app/components/default_boolean/default_boolean_widget.dart';
import 'package:transport_app/components/default_calculator_advanced/default_calculator_advanced_widget.dart';
import 'package:transport_app/components/default_firma/default_firma_widget.dart';
import 'package:transport_app/components/default_firmaext/default_firmaext_widget.dart';
import 'package:transport_app/components/default_georeference/default_georeference_widget.dart';
import 'package:transport_app/components/default_image_view/default_image_view_widget.dart';
import 'package:transport_app/components/default_rich_text/default_rich_text_widget.dart';
import 'package:transport_app/flutter_flow/flutter_flow_expanded_image_view.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import '../../flutter_flow/form_field_controller.dart';
import '../../controllers/field_controllers.dart';
import '../acordeon_categories/tab_page/tab_page_widget.dart';
import '../default_calculator/default_calculator_widget.dart';
import '../default_calendar/default_calendar_widget.dart';
import '../default_checkbox/default_checkbox_widget.dart';
import '../default_datetime/default_datetime_widget.dart';
import '../default_dropdown/default_dropdown_widget.dart';
import '../default_creatable_dropdown/default_creatable_dropdown_widget.dart';
import '../default_creatable_dropdown_advance/default_creatable_dropdown_advance_widget.dart';
import '../default_external_value/default_external_value_widget.dart';
import '../default_file_pdf/default_file_pdf_widget.dart';
import '../default_formato/default_formato_widget.dart';
import '../default_new_image/default_new_image_widget.dart';
import '../default_relational/default_relational_widget.dart';
import '../default_relational/relational_field.dart';
import '../default_relational/relational_field_config.dart';
import '../default_repeater/default_repeater_widget.dart';
import '../default_inverse_relational/inverse_relational_field.dart';
import 'form_data_notifier.dart';
import '../default_status/default_status_widget.dart';
import '../default_text_area/default_text_area_widget.dart';
import '../default_text_field/default_text_field_widget.dart';
import '../default_text_radio_button/default_text_radio_button_widget.dart';
import '../mercado_pago_field/mercado_pago_field.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import '/flutter_flow/custom_functions.dart' as functions;

import '../../utils/evaluate_condition.dart';
import 'acordeon_model.dart';
export 'acordeon_model.dart';

class AcordeonWidget extends StatefulWidget {
  AcordeonWidget({
    super.key,
    required this.campos,
    required this.originalCampos,
    required this.canEdit,
    required this.generalId,
    required this.originalJsonToSend,
    required this.updateJsonConfigToSend,
    this.hasTitleTemplateConfigured = false,
    this.general,
  });

  dynamic campos;
  dynamic originalCampos;
  Map<String, dynamic> originalJsonToSend = {};
  bool canEdit;
  String generalId;
  Function(Map<String, dynamic>) updateJsonConfigToSend;
  final bool hasTitleTemplateConfigured;
  final dynamic general;

  @override
  State<AcordeonWidget> createState() => AcordeonWidgetState();
}

class AcordeonWidgetState extends State<AcordeonWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late AcordeonModel _model;

  String? _safeModuleLabel(dynamic general) {
    if (general is Map) {
      final mi = general['modulo_info'];
      if (mi is Map) {
        return mi['label']?.toString();
      }
    }
    return null;
  }

  Map<String, dynamic>? _reverseRelationalModuleInfo() {
    if (widget.general is! Map) return null;
    final rawInfo = widget.general['modulo_info'];
    if (rawInfo is Map) return Map<String, dynamic>.from(rawInfo);
    if (rawInfo is List && rawInfo.isNotEmpty && rawInfo.first is Map) {
      return Map<String, dynamic>.from(rawInfo.first);
    }
    return null;
  }

  List<String> _parseReverseRelationalSlugs(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  dynamic _parseReverseRelationalOptions() {
    final raw = _reverseRelationalModuleInfo()?['reverse_relational_options'];
    if (raw is! String) return raw;
    final value = raw.trim();
    if (value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value.split('|').map((item) {
        final parts = item.split(':');
        if (parts.length < 2) return <String, dynamic>{};
        return <String, dynamic>{
          'module': parts[0].trim(),
          'field': parts[1].trim(),
          if (parts.length > 2)
            'slugs': _parseReverseRelationalSlugs(parts[2]),
        };
      }).where((item) => item.isNotEmpty).toList();
    }
  }

  List<String> _displayFieldsFromReverseOptions(
      dynamic options, String fieldSlug) {
    final entries = options is List ? options : [options];
    for (final entry in entries) {
      if (entry is! Map) continue;
      final optionField = entry['field']?.toString().trim() ?? '';
      if (optionField.isNotEmpty && optionField != fieldSlug) continue;

      for (final key in ['display_fields', 'displayFields', 'slugs', 'fields']) {
        final slugs = _parseReverseRelationalSlugs(entry[key]);
        if (slugs.isNotEmpty) return slugs;
      }
      final nested = _displayFieldsFromReverseOptions(entry['options'], fieldSlug);
      if (nested.isNotEmpty) return nested;
    }
    return [];
  }

  Map<String, dynamic> _inverseRelationalFieldConfig(
      Map<String, dynamic> campo) {
    final config = Map<String, dynamic>.from(campo);
    final options = _parseReverseRelationalOptions();
    if (options == null) return config;

    config['reverse_relational_options'] = options;
    final displayFields = _parseReverseRelationalSlugs(
        config['inverse_relation_display_fields']);
    if (displayFields.isEmpty) {
      final optionFields = _displayFieldsFromReverseOptions(
        options,
        config['inverse_relation_field']?.toString() ?? '',
      );
      if (optionFields.isNotEmpty) {
        config['inverse_relation_display_fields'] = optionFields;
      }
    }
    return config;
  }

  bool isVisible = true;
  late final FormDataNotifier _formData = FormDataNotifier();
  // Tracking de campos heredados para highlight visual
  final Set<String> _inheritedSlugs = {};
  // Tracking de categorías/secciones que tienen campos heredados
  final Set<String> _inheritedCategories = {};
  // Tracking de errores de validación inline (slugs)
  final Set<String> _validationErrors = {};
  // Visibilidad condicional
  Map<String, bool> _fieldVisibility = {};
  Map<String, bool> _categoryVisibility = {};
  int _categoryVisibilityHash = 0;
  int _currentTabIndex = 0;
  TabController? _lastTabController;
  Timer? _highlightTimer;
  Map<int, TextControllerNotifier> textControllersNotifierTextField = {};
  Map<int, TextControllerNotifier> textControllersNumberNotifier = {};
  Map<int, TextAreaControllerNotifier> textControllersNotifierTextArea = {};
  Map<int, TextControllerNotifier> textControllersCalendarNotifier = {};
  Map<int, TextEditingController> textControllersCalendar = {};
  Map<int, TextEditingController> textControllersDatetime = {};
  Map<int, TextEditingController> textControllersNumber = {};
  Map<int, FormFieldController<Map<String, bool>>> checkboxControllers = {};
  Map<int, FormFieldController<String>> dropdownControllers = {};
  Map<int, FormFieldController<String>> radioButtonControllers = {};
  Map<int, FFUploadedFile> fileControllers = {};
  Map<int, RelationalController> relationalControllers = {};
  Map<int, GeoReferenceController> geoReferenceControllers = {};
  Map<int, TextEditingController> textControllersCalculator = {};
  Map<int, TextEditingController> textControllersCalculatorAdvanced = {};
  Map<int, SignatureController> signatureControllers = {};
  Map<int, QuillController> richTextControllers = {};
  final List<GlobalKey<DefaultRepeaterWidgetState>> _repeaterKeys = [];
  final Map<String, GlobalKey<DefaultRepeaterWidgetState>> repeaterKeys = {};
  final Map<String, GlobalKey<DefaultRichTextWidgetState>> richTextKeys = {};
  Map<int, BooleanControllerNotifier> booleanControllers = {};
  List<Map<String, dynamic>> jsonRepeaterToSend = [];
  Map<String, dynamic> jsonConfigToSend = {};
  Map<int, Map<String, dynamic>> firmaControllers = {};
  List<Map<String, dynamic>> campo = [];
  List<Map<String, dynamic>> loadedCategories = [];
  bool isLoadingCategories = true;


  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AcordeonModel());
    jsonConfigToSend = widget.originalJsonToSend;
    // Poblar notifier con datos iniciales
    if (jsonConfigToSend["json_data"] is Map) {
      _formData
          .replaceAll(Map<String, dynamic>.from(jsonConfigToSend["json_data"]));
    }
    _formData.addListener(_onFormDataChanged);
    _loadCategoriesInBatches();
  }

  void _onFormDataChanged() {
    _reEvaluateVisibility();
  }

  void _tabControllerListener() {
    final tabController = _lastTabController;
    if (tabController == null || !mounted) return;
    if (tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = tabController.index;
        final regularCategories = loadedCategories
            .where((cat) => cat['category'] != 'unique_title_slug_field000111')
            .toList();
        final visibleCategories = regularCategories.where((cat) {
          final slug =
              cat['slug']?.toString() ?? cat['category']?.toString() ?? '';
          return _categoryVisibility[slug] ?? true;
        }).toList();
        final categoryName = _currentTabIndex < visibleCategories.length
            ? visibleCategories[_currentTabIndex]['category']?.toString() ?? ''
            : '';
        if (_inheritedCategories.contains(categoryName)) {
          _inheritedCategories.remove(categoryName);
        }
      });
    }
  }

  void _reEvaluateVisibility() {
    if (!mounted) return;
    final jsonData = _formData.data;
    final newFieldVis = <String, bool>{};
    final newCatVis = <String, bool>{};

    for (final category in widget.campos) {
      if (category is! Map) continue;
      final viewsFormula = category['views_formula']?.toString() ?? '';
      // Use same key as build(): slug ?? category (never empty)
      final catSlug = category['slug']?.toString() ??
          category['category']?.toString() ??
          '';
      if (viewsFormula.isNotEmpty && catSlug.isNotEmpty) {
        final result = evaluateConditions(viewsFormula, jsonData,
            context: _buildConditionContext());
        debugPrint(
            '[VIS] CAT slug=$catSlug formula="$viewsFormula" '
            'deps=${extractConditionDependencies(viewsFormula).map((d) => '$d=${jsonData[d]}').join(',')} '
            'result=$result');
        newCatVis[catSlug] = result;
      }

      final fields = category['fields'] as List? ?? [];
      for (final field in fields) {
        if (field is! Map) continue;
        final slug = field['slug']?.toString();
        if (slug == null || slug.isEmpty) continue;
        final cond = field['conditional_value']?.toString() ?? '';
        if (cond.isNotEmpty) {
          final result = evaluateConditions(cond, jsonData,
              field: Map<String, dynamic>.from(field),
              context: _buildConditionContext());
          debugPrint(
              '[VIS] FIELD slug=$slug formula="$cond" '
              'deps=${extractConditionDependencies(cond).map((d) => '$d=${jsonData[d]}').join(',')} '
              'result=$result');
          newFieldVis[slug] = result;
        }
      }
    }

    final newHash = _computeVisibilityHash(newFieldVis, newCatVis);
    debugPrint(
        '[VIS] hash old=$_categoryVisibilityHash new=$newHash '
        'cats=${newCatVis.length} fields=${newFieldVis.length} '
        'changed=${newHash != _categoryVisibilityHash}');
    if (newHash != _categoryVisibilityHash) {
      _categoryVisibilityHash = newHash;
      setState(() {
        _fieldVisibility = newFieldVis;
        _categoryVisibility = newCatVis;
      });
    }
  }

  int _computeVisibilityHash(
      Map<String, bool> fieldVis, Map<String, bool> catVis) {
    int hash = 17;
    final sortedCatKeys = catVis.keys.toList()..sort();
    for (final key in sortedCatKeys) {
      hash = hash * 31 + key.hashCode;
      hash = hash * 31 + (catVis[key]! ? 1 : 0);
    }
    final sortedFieldKeys = fieldVis.keys.toList()..sort();
    for (final key in sortedFieldKeys) {
      hash = hash * 31 + key.hashCode;
      hash = hash * 31 + (fieldVis[key]! ? 1 : 0);
    }
    return hash;
  }

  ConditionContext _buildConditionContext() {
    final role = FFAppState().role;
    final roleGroups = FFAppState()
        .roleGroups
        .map((r) => r is String ? r : r.toString())
        .toList();
    // debugPrint('[VISIBILITY] [CONTEXT] role="$role" roleGroups=$roleGroups');
    return ConditionContext(
      currentUserRole: role,
      currentUserRoles: roleGroups,
    );
  }

  @override
  void didUpdateWidget(covariant AcordeonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalJsonToSend != widget.originalJsonToSend) {
      jsonConfigToSend = widget.originalJsonToSend;
      final newJsonData = jsonConfigToSend["json_data"];
      if (newJsonData is Map && newJsonData.isNotEmpty) {
        _formData.replaceAll(Map<String, dynamic>.from(newJsonData));
      }
      _reEvaluateVisibility();
    }
  }

  Future<void> _loadCategoriesInBatches() async {
    const int batchSize = 5; // Número de categorías por lote
    int? currentBatchStart = 0;
    while (currentBatchStart! < widget.campos.length) {
      num currentBatchEnd =
          (currentBatchStart + batchSize).clamp(0, widget.campos.length);
      List<dynamic> batch =
          widget.campos.sublist(currentBatchStart, currentBatchEnd);
      setState(() {
        loadedCategories.addAll(batch as Iterable<Map<String, dynamic>>);
      });
      await Future.delayed(
          Duration.zero); //Permite que el frame dibuje antes de continuar.
      currentBatchStart = currentBatchEnd as int?;
    }
    setState(() {
      isLoadingCategories = false;
    });
    _reEvaluateVisibility();
  }

  @override
  void dispose() {
    for (final timer in _slugDebounceTimers.values) {
      timer.cancel();
    }
    _slugDebounceTimers.clear();
    _formData.removeListener(_onFormDataChanged);
    _lastTabController?.removeListener(_tabControllerListener);
    _lastTabController = null;
    _model.maybeDispose();
    _formData.dispose();
    super.dispose();
  }

  List<InlineSpan> parseTextWithFormatting(String text) {
    // Limpia espacios y caracteres no deseados al inicio y al final
    text = text.trim().replaceAll(RegExp(r'^\[|\]$'), '');
    final regex = RegExp(r'\*\*(.*?)\*\*'); // Encuentra texto entre ** **
    final List<InlineSpan> spans = [];
    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      final start = match.start;
      final end = match.end;
      final boldText = match.group(1); // Captura el texto entre **
      // Agrega el texto normal antes del texto en negrita
      if (start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, start)));
      }
      // Agrega el texto en negrita
      spans.add(TextSpan(
        text: boldText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastIndex = end;
    }
    // Agrega el texto restante después de la última coincidencia
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }
    return spans;
  }

  /// Convierte HTML simple a lista de InlineSpan para mostrar en RichText
  List<InlineSpan> parseHtmlToSpans(String htmlString, BuildContext context) {
    final List<InlineSpan> spans = [];

    // Si el string está vacío, retornar texto indicando que no hay contenido
    if (htmlString.trim().isEmpty) {
      return [const TextSpan(text: '')];
    }

    try {
      final document = parse(htmlString);
      final body = document.body;

      if (body == null || body.nodes.isEmpty) {
        // Si no hay body o está vacío, mostrar el texto plano
        return [TextSpan(text: htmlString.replaceAll(RegExp(r'<[^>]*>'), ''))];
      }

      void processNode(dynamic node, TextStyle? parentStyle) {
        if (node == null) return;

        if (node.nodeType == 3) {
          // Text node
          final text = node.text;
          if (text != null && text.isNotEmpty) {
            spans.add(TextSpan(
              text: text,
              style: parentStyle,
            ));
          }
          return;
        }

        if (node.nodeType == 1) {
          // Element node
          final element = node;
          final tagName = element.localName?.toLowerCase() ?? '';
          TextStyle? currentStyle = parentStyle;

          switch (tagName) {
            case 'strong':
            case 'b':
              currentStyle =
                  (parentStyle ?? DefaultTextStyle.of(context).style).copyWith(
                fontWeight: FontWeight.bold,
              );
              break;
            case 'em':
            case 'i':
              currentStyle =
                  (parentStyle ?? DefaultTextStyle.of(context).style).copyWith(
                fontStyle: FontStyle.italic,
              );
              break;
            case 'u':
              currentStyle =
                  (parentStyle ?? DefaultTextStyle.of(context).style).copyWith(
                decoration: TextDecoration.underline,
              );
              break;
            case 'br':
              spans.add(const TextSpan(text: '\n'));
              return;
            case 'p':
              // Los párrafos añaden salto de línea al final
              for (var child in element.nodes) {
                processNode(
                    child, currentStyle ?? DefaultTextStyle.of(context).style);
              }
              spans.add(const TextSpan(text: '\n\n'));
              return;
            case 'img':
              final src = element.attributes['src'] ?? '';
              if (src.isNotEmpty) {
                spans.add(WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Builder(
                    builder: (context) {
                      final imageHeight =
                          (DefaultTextStyle.of(context).style.fontSize ?? 14) *
                              8;
                      final bool isDataUri = src.startsWith('data:');

                      Uint8List? imageBytes;
                      String? networkUrl;

                      if (isDataUri) {
                        final uriParts = src.substring(5).split(';base64,');
                        if (uriParts.length == 2) {
                          try {
                            imageBytes = base64Decode(uriParts[1]);
                          } catch (_) {}
                        }
                      } else {
                        networkUrl = src.startsWith('http')
                            ? src
                            : 'https://${FFAppState().organizacion}.itsquery.com$src';
                      }

                      if (imageBytes == null && networkUrl == null) {
                        return const SizedBox.shrink();
                      }

                      Widget buildImageWidget() {
                        if (imageBytes != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              imageBytes,
                              height: imageHeight,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            networkUrl!,
                            height: imageHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                width: 20,
                                height: 20,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.fade,
                              child: imageBytes != null
                                  ? FlutterFlowExpandedImageView(
                                      image: Image.memory(imageBytes,
                                          fit: BoxFit.contain),
                                      allowRotation: false,
                                      useHeroAnimation: false,
                                    )
                                  : FlutterFlowExpandedImageView(
                                      image: Image.network(networkUrl!,
                                          fit: BoxFit.contain),
                                      allowRotation: false,
                                      useHeroAnimation: false,
                                    ),
                            ),
                          );
                        },
                        child: buildImageWidget(),
                      );
                    },
                  ),
                ));
              }
              return;
            case 'div':
            case 'span':
              // Contenedores sin estilo especial
              break;
          }

          // Procesar hijos recursivamente
          for (var child in element.nodes) {
            processNode(
                child, currentStyle ?? DefaultTextStyle.of(context).style);
          }

          // Añadir salto de línea después de ciertos elementos
          if (['p', 'div', 'br'].contains(tagName)) {
            spans.add(const TextSpan(text: '\n'));
          }
        }
      }

      for (var node in body.nodes) {
        processNode(node, DefaultTextStyle.of(context).style);
      }

      // Si después de procesar todo no hay spans, mostrar texto plano
      if (spans.isEmpty) {
        return [TextSpan(text: htmlString.replaceAll(RegExp(r'<[^>]*>'), ''))];
      }

      return spans;
    } catch (e) {
      print('Error parseando HTML en text_view: $e');
      // Si hay error al parsear, mostrar el texto original sin tags HTML
      return [TextSpan(text: htmlString.replaceAll(RegExp(r'<[^>]*>'), ''))];
    }
  }

  /// Valida campos requeridos y actualiza _validationErrors.
  /// Retorna true si todos los requeridos tienen valor.
  bool _validateRequiredFields() {
    final newErrors = <String>{};
    final jsonData = jsonConfigToSend["json_data"];
    if (jsonData is! Map) return false;

    for (int i = 0; i < widget.campos.length; i++) {
      final fields = widget.campos[i]['fields'];
      if (fields is! List) continue;
      for (int j = 0; j < fields.length; j++) {
        final campo = fields[j];
        if (campo['is_required'] != true) continue;

        final slug = campo['slug']?.toString() ?? '';
        if (slug.isEmpty) continue;
        if (_fieldVisibility[slug] == false) continue;

        final value = jsonData[slug];

        // Determinar si está vacío
        bool isEmpty = false;
        if (value == null) {
          isEmpty = true;
        } else if (value is String && value.trim().isEmpty) {
          isEmpty = true;
        } else if (value is Map) {
          if (value.isEmpty) {
            isEmpty = true;
          } else if (value['value'] != null &&
              (value['value'] == 0 || value['value'] == '')) {
            isEmpty = true; // Relational con valor por defecto
          }
        } else if (value is List && value.isEmpty) {
          isEmpty = true;
        }

        if (isEmpty) {
          newErrors.add(slug);
        }
      }
    }

    setState(() {
      _validationErrors.clear();
      _validationErrors.addAll(newErrors);
    });

    return newErrors.isEmpty;
  }

  Future<Map<String, dynamic>> updateJsonConfigToSend() async {
    int globalIndex = 0;
    for (int i = 0; i < widget.campos.length; i++) {
      var fields = widget.campos[i]['fields'];
      for (int j = 0; j < fields.length; j++) {
        String slug = fields[j]['slug'];
        final type = fields[j]['type'];
        final int gi = globalIndex;
        switch (type) {
          case 'text':
            if (textControllersNotifierTextField.containsKey(gi)) {
              if (slug == 'titulo') {
                jsonConfigToSend["title"] =
                    textControllersNotifierTextField[gi]?.value ?? '';
                jsonConfigToSend["json_data"]["titulo"] =
                    textControllersNotifierTextField[gi]?.value ?? '';
              } else {
                if (jsonConfigToSend["json_data"] == null) {
                  jsonConfigToSend["json_data"] = {};
                }

                jsonConfigToSend["json_data"][slug] =
                    textControllersNotifierTextField[gi]?.value ?? '';
              }
            }
            break;
          case 'textarea':
            if (textControllersNotifierTextArea.containsKey(gi)) {
              jsonConfigToSend["json_data"][slug] =
                  textControllersNotifierTextArea[gi]?.value ?? '';
            }
            break;
          case 'number':
            if (textControllersNumberNotifier.containsKey(gi)) {
              jsonConfigToSend["json_data"][slug] =
                  textControllersNumberNotifier[gi]?.value;
            }
            break;
          case 'calendar':
            if (textControllersCalendarNotifier.containsKey(gi)) {
              jsonConfigToSend["json_data"][slug] =
                  (textControllersCalendarNotifier[gi]!.value != 'Sin fecha' &&
                          textControllersCalendarNotifier[gi]!.value != null &&
                          textControllersCalendarNotifier[gi]!.value != "")
                      ? dateTimeFormat(
                          'yyyy-MM-dd',
                          DateTime.parse(
                              textControllersCalendarNotifier[gi]!.value))
                      : '';
            }
            break;
          case 'datetime':
            if (textControllersDatetime.containsKey(gi)) {
              jsonConfigToSend["json_data"][slug] =
                  (textControllersDatetime[gi]!.text != 'Sin fecha' &&
                          textControllersDatetime[gi]!.text != null &&
                          textControllersDatetime[gi]!.text != "")
                      ? dateTimeFormat('yyyy-MM-ddThh:mm',
                          DateTime.parse(textControllersDatetime[gi]!.text))
                      : '';
            }
          case 'checkbox':
            if (checkboxControllers.containsKey(gi)) {
              Map<String, bool>? checkboxValues =
                  checkboxControllers[gi]?.value;
              if (checkboxValues != null) {
                jsonConfigToSend["json_data"][slug] = checkboxValues;
              } else {
                jsonConfigToSend["json_data"][slug] = {};
              }
            } else {
              jsonConfigToSend["json_data"][slug] = {};
            }
            break;
          case 'dropdown':
            if (dropdownControllers.containsKey(gi)) {
              jsonConfigToSend["json_data"][slug] =
                  dropdownControllers[gi]?.value ?? '';
            }
            break;
          case 'status':
            if (dropdownControllers.containsKey(gi)) {
              if (jsonConfigToSend["json_data"] == null) {
                jsonConfigToSend["json_data"] = {};
              }
              jsonConfigToSend["json_data"][slug] =
                  dropdownControllers[gi]?.value ?? '';
            }
            break;
          case 'radio':
            if (radioButtonControllers.containsKey(gi)) {
              jsonConfigToSend["json_data"][slug] =
                  radioButtonControllers[gi]?.value ?? '';
            }
            break;
          case 'image':
            if (fileControllers.containsKey(gi) &&
                fileControllers[gi]?.bytes?.isNotEmpty == true &&
                fileControllers[gi]?.bytes != null) {
              String encodeImage;
              String imgSend = 'data:image/jpg;base64,';
              encodeImage =
                  base64Encode(fileControllers[gi]!.bytes!.toList()) ?? '';
              imgSend += encodeImage;
              slug = '$slug';
              jsonConfigToSend["json_data"][slug] = imgSend;
            } else if (fields[j]['data'] != '' && fields[j]['data'] != null) {
              jsonConfigToSend["json_data"][slug] = fields[j]['data'];
            } else {
              jsonConfigToSend["json_data"][slug] = '';
            }
            break;
          case 'file':
            if (fileControllers.containsKey(gi) &&
                fileControllers[gi]?.bytes?.isNotEmpty == true &&
                fileControllers[gi]?.bytes != null) {
              String encodeImage;
              String imgSend = 'data:application/pdf;base64,';
              encodeImage =
                  base64Encode(fileControllers[gi]!.bytes!.toList()) ?? '';
              imgSend += encodeImage;
              slug = '$slug';
              jsonConfigToSend["json_data"][slug] = imgSend;
            } else if (fields[j]['data'] != '' && fields[j]['data'] != null) {
              jsonConfigToSend["json_data"][slug] = fields[j]['data'];
            } else {
              jsonConfigToSend["json_data"][slug] = '';
            }
            break;
          case 'relational':
            if (relationalControllers.containsKey(gi)) {
              String? relationType = relationalControllers[gi]?.type;

              // Asegurar que el valor sea un Map (en creación puede ser "" o null)
              if (jsonConfigToSend["json_data"] != null &&
                  jsonConfigToSend["json_data"][slug] is! Map) {
                jsonConfigToSend["json_data"][slug] = <String, dynamic>{};
              }

              if (relationType == 'user') {
                jsonConfigToSend["json_data"][slug]["avatar"] =
                    relationalControllers[gi]?.relationalAvatar;
                jsonConfigToSend["json_data"][slug]["full_name"] =
                    relationalControllers[gi]?.relationalFullName;
                jsonConfigToSend["json_data"][slug]["label"] =
                    relationalControllers[gi]?.relationalLabel;
                jsonConfigToSend["json_data"][slug]["type"] =
                    relationalControllers[gi]?.type;
                jsonConfigToSend["json_data"][slug]["value"] =
                    relationalControllers[gi]?.relationalValue?.toString();
              } else {
                jsonConfigToSend["json_data"][slug]["label"] =
                    relationalControllers[gi]?.relationalLabel;
                jsonConfigToSend["json_data"][slug]["module"] =
                    relationalControllers[gi]?.module;
                jsonConfigToSend["json_data"][slug]["module_name"] =
                    relationalControllers[gi]?.moduleName;
                jsonConfigToSend["json_data"][slug]["type"] =
                    relationalControllers[gi]?.type;
                jsonConfigToSend["json_data"][slug]["value"] =
                    relationalControllers[gi]?.relationalValue;
              }
            }
            break;
          case 'multiple_relational_select':
            // El valor ya se mantiene en jsonConfigToSend desde onChanged
            break;
          case 'calculator':
            if (textControllersCalculator.containsKey(gi)) {
              jsonConfigToSend["json_data"][slug] =
                  textControllersCalculator[gi]!.text;
            }
            break;
          case 'calculator_advanced':
            if (textControllersCalculatorAdvanced.containsKey(gi)) {
              jsonConfigToSend["json_data"][slug] =
                  textControllersCalculatorAdvanced[gi]!.text;
            }
            break;
          case 'repeater':
            final category = widget.campos[i];
            final campo = category['fields'][j];
            final fieldId = '${category['category']}-${campo['slug']}';
            jsonConfigToSend["json_data"][slug] =
                repeaterKeys[fieldId]?.currentState?.updateJsonRepeater() ?? [];
            break;
          case 'firma':
            if (firmaControllers[gi]?.containsKey('firmado') == true &&
                firmaControllers[gi]?['firmado'] == true &&
                firmaControllers[gi]?['firma'] != null) {
              jsonConfigToSend["json_data"][slug] = {
                'url': firmaControllers[gi]?['firma'],
                'name': firmaControllers[gi]?['name'],
                'datetime': firmaControllers[gi]?['datetime'],
              };
            } else {
              jsonConfigToSend["json_data"][slug] = '';
            }
            break;
          case 'firmaext':
            if (signatureControllers.containsKey(gi)) {
              String b64Sign = functions
                      .isSignatureEmpty(signatureControllers[gi]!)
                  ? ''
                  : await functions.convertSignToB64(signatureControllers[gi]!);
              jsonConfigToSend["json_data"][slug] = b64Sign;
            } else {
              if (fields[j]['data'] != null &&
                  fields[j]['data'].toString().isNotEmpty) {
                jsonConfigToSend["json_data"][slug] = fields[j]['data'];
              } else {
                jsonConfigToSend["json_data"][slug] = '';
              }
            }
            break;
          case 'text_editor':
            final category = widget.campos[i];
            final campo = category['fields'][j];
            final fieldId = '${category['category']}-${campo['slug']}';
            jsonConfigToSend["json_data"][slug] =
                richTextKeys[fieldId]?.currentState?.getString();
            break;
          case 'relational_from_repeater':
            jsonConfigToSend["json_data"][slug] = '';
            break;
          case 'relational_sub_categories':
            jsonConfigToSend["json_data"][slug] = '';
            break;
          case 'boolean':
            jsonConfigToSend["json_data"][slug] =
                booleanControllers[gi]?.value ?? false;
            break;
          case 'external_value':
            // El valor ya se mantiene en jsonConfigToSend desde handleDynamicFieldChanges
            break;
          case 'multiple_relational_select':
            // El valor ya se mantiene en jsonConfigToSend desde onChanged
            break;
          default:
            break;
        }
        globalIndex++;
      }
    }
    if (jsonConfigToSend["json_data"] != null) {
      jsonConfigToSend["title"] = jsonConfigToSend["json_data"]["titulo"];
      jsonConfigToSend["json_data"].remove("titulo");
    }

    // Validar campos requeridos
    final isValid = _validateRequiredFields();

    widget.updateJsonConfigToSend(jsonConfigToSend);

    if (!isValid) {
      return {
        "success": false,
        "data": jsonConfigToSend,
        "errors": _validationErrors.toList(),
      };
    }

    return {
      "success": true,
      "data": jsonConfigToSend,
      "errors": [],
    };
  }

  // Per-slug debounce timers para evitar que campos se sobreescriban
  final Map<String, Timer> _slugDebounceTimers = {};

  void _updateJsonData(String slug, dynamic value) {
    // IMMEDIATE: update _formData so _reEvaluateVisibility runs NOW.
    // Guard: don't overwrite Map (relational onBatchUpdate) with String.
    final currentVal = _formData.get(slug);
    if (currentVal is Map && value is String) {
      // Map from onBatchUpdate has richer data (label/value/module).
      // Skip — onBatchUpdate already set correct value.
    } else {
      _formData.set(slug, value); // triggers _onFormDataChanged → _reEvaluateVisibility
    }

    // DEBOUNCED: setState + jsonConfigToSend sync (throttle rebuilds)
    _slugDebounceTimers[slug]?.cancel();
    _slugDebounceTimers[slug] = Timer(const Duration(milliseconds: 50), () {
      _slugDebounceTimers.remove(slug);
      if (mounted) {
        setState(() {
          _validationErrors.remove(slug);
          final newJsonData =
              Map<String, dynamic>.from(jsonConfigToSend["json_data"] ?? {});
          newJsonData[slug] = value;
          jsonConfigToSend = Map<String, dynamic>.from(jsonConfigToSend)
            ..["json_data"] = newJsonData;
        });
      }
    });
  }

  /// Agrega un highlight visual al campo que fue actualizado por herencia.
  /// El highlight dura 2.5 segundos.
  void _highlightInheritedField(String slug) {
    if (!mounted) return;
    setState(() {
      _inheritedSlugs.add(slug);
    });
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _inheritedSlugs.clear();
        });
      }
    });
  }

  void _updateControllerBySlug(String slug, dynamic value) {
    int globalIndex = 0;
    for (int i = 0; i < widget.campos.length; i++) {
      var fields = widget.campos[i]['fields'];
      for (int j = 0; j < fields.length; j++) {
        if (fields[j]['slug'] == slug) {
          final type = fields[j]['type'];
          final stringValue = value?.toString() ?? '';
          switch (type) {
            case 'text':
              textControllersNotifierTextField[globalIndex]
                  ?.updateText(stringValue);
              fields[j]['data'] = stringValue;
              break;
            case 'textarea':
              textControllersNotifierTextArea[globalIndex]
                  ?.updateText(stringValue);
              fields[j]['data'] = stringValue;
              break;
            case 'number':
              textControllersNumberNotifier[globalIndex]
                  ?.updateText(stringValue);
              fields[j]['data'] = stringValue;
              break;
            case 'calendar':
              textControllersCalendarNotifier[globalIndex]
                  ?.updateText(stringValue);
              fields[j]['data'] = stringValue;
              break;
            case 'datetime':
              textControllersDatetime[globalIndex]?.text = stringValue;
              fields[j]['data'] = stringValue;
              break;
            case 'checkbox':
              if (value is Map<String, bool>) {
                checkboxControllers[globalIndex]?.value = value;
              }
              break;
            case 'dropdown':
            case 'dropdown_advance':
            case 'status':
              dropdownControllers[globalIndex]?.value = stringValue;
              break;
            case 'radio':
              radioButtonControllers[globalIndex]?.value = stringValue;
              break;
            case 'boolean':
              booleanControllers[globalIndex]
                  ?.updateValue(value == true || value == 'true');
              break;
            case 'calculator':
              if (textControllersCalculator.containsKey(globalIndex)) {
                textControllersCalculator[globalIndex]!.text = stringValue;
              }
              fields[j]['data'] = stringValue;
              break;
            case 'calculator_advanced':
              if (textControllersCalculatorAdvanced.containsKey(globalIndex)) {
                textControllersCalculatorAdvanced[globalIndex]!.text =
                    stringValue;
              }
              fields[j]['data'] = stringValue;
              break;
            case 'georeference':
              if (geoReferenceControllers.containsKey(globalIndex)) {
                final parts = stringValue.split('|');
                if (parts.length >= 2) {
                  geoReferenceControllers[globalIndex]!.latLng.text = parts[0];
                  geoReferenceControllers[globalIndex]!.address.text = parts[1];
                } else {
                  geoReferenceControllers[globalIndex]!.latLng.text =
                      stringValue;
                }
              }
              fields[j]['data'] = stringValue;
              break;
            case 'image':
            case 'file':
              // Para image/file, la herencia solo puede venir como URL string
              if (stringValue.isNotEmpty) {
                fileControllers[globalIndex] = FFUploadedFile();
                fields[j]['data'] = stringValue;
              }
              break;
            case 'firma':
              if (firmaControllers.containsKey(globalIndex)) {
                firmaControllers[globalIndex] = {
                  'firmado': true,
                  'firma': stringValue,
                  'name': fields[j]['label'] ?? '',
                  'datetime': DateTime.now().toIso8601String(),
                };
              }
              fields[j]['data'] = stringValue;
              break;
            case 'firmaext':
              // Las firmas externas no se pueden heredar (requieren interacción del usuario)
              break;
            case 'repeater':
              // Para repeaters, el valor heredado sería un array JSON
              // Siempre reemplazar completamente, sin importar si estaba vacío o tenía datos
              // debugPrint(
              //     '[ACORDEON] [REPEATER] Procesando herencia para repeater slug=$slug');
              // debugPrint(
              //     '[ACORDEON] [REPEATER] Valor recibido (raw): $value (type: ${value.runtimeType})');
              try {
                List<dynamic> items;
                if (value is List) {
                  // El valor ya viene como lista (del json_data del registro fuente)
                  items = value;
                  // debugPrint(
                  //     '[ACORDEON] [REPEATER] Valor ya es una List, longitud=${items.length}');
                } else {
                  // El valor viene como string JSON, decodificar
                  items = jsonDecode(stringValue);
                  // debugPrint(
                  //     '[ACORDEON] [REPEATER] jsonDecode result: $items (type: ${items.runtimeType})');
                }
                if (items is List) {
                  jsonRepeaterToSend = List<Map<String, dynamic>>.from(items);
                  fields[j]['data'] = items;
                  // debugPrint(
                     //  '[ACORDEON] [REPEATER] Repeater reemplazado con ${items.length} items');
                } else {
                  // debugPrint(
                      // '[ACORDEON] [REPEATER] ERROR: valor no es una List, es ${items.runtimeType}');
                }
              } catch (e) {
                // debugPrint(
                //     '[ACORDEON] [REPEATER] ERROR: No se pudo heredar valor al repeater $slug: $e');
                // debugPrint('[ACORDEON] [REPEATER] Valor que falló: $value');
              }
              break;
            case 'external_value':
              // external_value se maneja aparte, no necesita actualización directa
              break;
            default:
              break;
          }
          // Track categoría para highlight de tab/sección
          final categoryName = widget.campos[i]['category']?.toString() ?? '';
          if (categoryName.isNotEmpty &&
              categoryName != 'unique_title_slug_field000111' &&
              categoryName != 'otros') {
            _inheritedCategories.add(categoryName);
          }
          // Highlight visual para campos heredados
          _highlightInheritedField(slug);
          return;
        }
        globalIndex++;
      }
    }
  }

  void getController(typeField, fieldIndex, campo, fieldId) {
    final slug = campo['slug']?.toString() ?? '';
    switch (typeField) {
      case 'text':
        {
          final wasNew =
              !textControllersNotifierTextField.containsKey(fieldIndex);
          textControllersNotifierTextField[fieldIndex] ??=
              TextControllerNotifier(campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersNotifierTextField[fieldIndex]!.addListener(() {
              _updateJsonData(
                  slug, textControllersNotifierTextField[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'textarea':
        {
          final wasNew =
              !textControllersNotifierTextArea.containsKey(fieldIndex);
          textControllersNotifierTextArea[fieldIndex] ??=
              TextAreaControllerNotifier(campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersNotifierTextArea[fieldIndex]!.addListener(() {
              _updateJsonData(
                  slug, textControllersNotifierTextArea[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'calendar':
        {
          final wasNew =
              !textControllersCalendarNotifier.containsKey(fieldIndex);
          textControllersCalendarNotifier[fieldIndex] ??=
              TextControllerNotifier(campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersCalendarNotifier[fieldIndex]!.addListener(() {
              _updateJsonData(
                  slug, textControllersCalendarNotifier[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'datetime':
        {
          final wasNew = !textControllersDatetime.containsKey(fieldIndex);
          textControllersDatetime[fieldIndex] ??=
              TextEditingController(text: campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersDatetime[fieldIndex]!.addListener(() {
              _updateJsonData(slug, textControllersDatetime[fieldIndex]!.text);
            });
          }
        }
      // intentional fallthrough to number
      case 'number':
        {
          final wasNew = !textControllersNumberNotifier.containsKey(fieldIndex);
          textControllersNumberNotifier[fieldIndex] ??=
              TextControllerNotifier(campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersNumberNotifier[fieldIndex]!.addListener(() {
              _updateJsonData(
                  slug, textControllersNumberNotifier[fieldIndex]!.value);
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FFAppState().addToTextoControlador(
                campo["slug"], textControllersNumberNotifier[fieldIndex]!);
          });
        }
        break;
      case 'checkbox':
        {
          final wasNew = !checkboxControllers.containsKey(fieldIndex);
          if (campo['data'] is Map<String, bool>) {
            Map<String, bool> checkboxData =
                Map<String, bool>.from(campo['data']);
            checkboxControllers[fieldIndex] ??=
                FormFieldController<Map<String, bool>>(checkboxData);
          } else if (campo['data'] is String) {
            String dataString = campo['data'] as String;
            Map<String, bool> checkboxData = {};
            List<String> pairs = dataString.split(',');
            for (String pair in pairs) {
              List<String> keyValue = pair.split(':');
              if (keyValue.length == 2) {
                String key = keyValue[0].trim();
                bool value;
                if (keyValue[1].trim() == 'true') {
                  value = true;
                } else if (keyValue[1].trim() == 'false') {
                  value = false;
                } else {
                  continue;
                }
                checkboxData[key] = value;
              }
            }
            checkboxControllers[fieldIndex] ??=
                FormFieldController<Map<String, bool>>(checkboxData);
          } else {
            checkboxControllers[fieldIndex] ??=
                FormFieldController<Map<String, bool>>({});
          }
          if (wasNew) {
            checkboxControllers[fieldIndex]!.addListener(() {
              _updateJsonData(slug, checkboxControllers[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'dropdown':
        {
          final wasNew = !dropdownControllers.containsKey(fieldIndex);
          dropdownControllers[fieldIndex] ??=
              FormFieldController<String>(campo['data']);
          if (wasNew) {
            dropdownControllers[fieldIndex]!.addListener(() {
              _updateJsonData(slug, dropdownControllers[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'dropdown_advance':
        {
          final wasNew = !dropdownControllers.containsKey(fieldIndex);
          dropdownControllers[fieldIndex] ??=
              FormFieldController<String>(campo['data']);
          if (wasNew) {
            dropdownControllers[fieldIndex]!.addListener(() {
              _updateJsonData(slug, dropdownControllers[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'radio':
        {
          final wasNew = !radioButtonControllers.containsKey(fieldIndex);
          radioButtonControllers[fieldIndex] ??=
              FormFieldController<String>(campo['data']);
          if (wasNew) {
            radioButtonControllers[fieldIndex]!.addListener(() {
              _updateJsonData(slug, radioButtonControllers[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'image':
        fileControllers[fieldIndex] ??= FFUploadedFile();
        break;
      case 'file':
        fileControllers[fieldIndex] ??=
            FFUploadedFile(bytes: Uint8List.fromList([]));
        break;
      case 'status':
        {
          final wasNew = !dropdownControllers.containsKey(fieldIndex);
          dropdownControllers[fieldIndex] ??=
              FormFieldController<String>(campo['data']);
          if (wasNew) {
            dropdownControllers[fieldIndex]!.addListener(() {
              _updateJsonData(slug, dropdownControllers[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'georeference':
        {
          final data = campo['data'] as String?;
          final wasNew = !geoReferenceControllers.containsKey(fieldIndex);
          geoReferenceControllers[fieldIndex] ??=
              GeoReferenceController.fromString(data);
          if (wasNew) {
            geoReferenceControllers[fieldIndex]!.latLng.addListener(() {
              _updateJsonData(slug,
                  '${geoReferenceControllers[fieldIndex]!.latLng.text}|${geoReferenceControllers[fieldIndex]!.address.text}');
            });
            geoReferenceControllers[fieldIndex]!.address.addListener(() {
              _updateJsonData(slug,
                  '${geoReferenceControllers[fieldIndex]!.latLng.text}|${geoReferenceControllers[fieldIndex]!.address.text}');
            });
          }
        }
        break;
      case 'relational':
        {
          final data = campo['data'];
          Map<String, dynamic>? savedData;
          if (data != null && data.isNotEmpty) {
            try {
              savedData = jsonDecode(data);
            } catch (_) {}
          }
          final config = campo['relationalConfig'] as RelationalFieldConfig? ??
              RelationalFieldConfig.fromRawConfig(
                  Map<String, dynamic>.from(campo));
          final wasNew = !relationalControllers.containsKey(fieldIndex);
          relationalControllers[fieldIndex] ??=
              RelationalController.fromSavedData(
            savedData: savedData,
            config: config,
          );
          if (wasNew) {
            relationalControllers[fieldIndex]!.textController.addListener(() {
              _updateJsonData(
                  slug, relationalControllers[fieldIndex]!.textController.text);
            });
          }
        }
        break;
      case 'calculator':
        {
          final wasNew = !textControllersCalculator.containsKey(fieldIndex);
          textControllersCalculator[fieldIndex] ??=
              TextEditingController(text: campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersCalculator[fieldIndex]!.addListener(() {
              _updateJsonData(
                  slug, textControllersCalculator[fieldIndex]!.text);
            });
          }
        }
        break;
      case 'calculator_advanced':
        {
          final wasNew =
              !textControllersCalculatorAdvanced.containsKey(fieldIndex);
          textControllersCalculatorAdvanced[fieldIndex] ??=
              TextEditingController(text: campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersCalculatorAdvanced[fieldIndex]!.addListener(() {
              _updateJsonData(
                  slug, textControllersCalculatorAdvanced[fieldIndex]!.text);
            });
          }
        }
        break;
      case 'repeater':
        while (_repeaterKeys.length <= fieldIndex) {
          _repeaterKeys.add(GlobalKey<DefaultRepeaterWidgetState>());
        }
        if (!repeaterKeys.containsKey(fieldId)) {
          repeaterKeys[fieldId] = GlobalKey<DefaultRepeaterWidgetState>();
        }
        break;
      case 'firma':
        dynamic data;
        final rawData = campo['data'];
        if (rawData != null && rawData.toString().isNotEmpty) {
          try {
            data = jsonDecode(rawData);
          } catch (e) {
            data = null;
          }
        }
        firmaControllers[fieldIndex] ??= {
          'firmado': (campo['data'].toString() != '' && campo['data'] != null)
              ? true
              : false,
          'firma': data?['url'] ?? '',
          'name': data?['name'] ?? '',
          'datetime': data?['datetime'] ?? '',
        };
        break;
      case 'firmaext':
        signatureControllers[fieldIndex] ??= SignatureController(
          penStrokeWidth: 3,
          penColor: Colors.black,
          exportPenColor: Colors.black,
          exportBackgroundColor: Colors.white,
        );
        break;
      case 'text_editor':
        richTextControllers[fieldIndex] ??= QuillController.basic();
        if (!richTextKeys.containsKey(fieldId)) {
          richTextKeys[fieldId] = GlobalKey<DefaultRichTextWidgetState>();
        }
        break;
      case 'boolean':
        {
          final data = campo['data'];
          bool initial;
          if (data is bool) {
            initial = data;
          } else if (data is String) {
            initial = data.toLowerCase() == 'true';
          } else {
            initial = false;
          }
          final wasNew = !booleanControllers.containsKey(fieldIndex);
          booleanControllers[fieldIndex] ??= BooleanControllerNotifier(initial);
          if (wasNew) {
            booleanControllers[fieldIndex]!.addListener(() {
              _updateJsonData(slug, booleanControllers[fieldIndex]!.value);
            });
          }
        }
        break;
      default:
        break;
    }
  }

  Widget Function(BuildContext, Map<String, dynamic>, int, String)
      getFieldWidget(String typeField) {
    final Map<String,
            Widget Function(BuildContext, Map<String, dynamic>, int, String)>
        fieldWidgets = {
      'text': (context, campo, index, fieldId) => DefaultTextFieldWidget(
            text: campo['data']?.toString() ?? '',
            isEdit: widget.canEdit &&
                !(widget.hasTitleTemplateConfigured &&
                    campo['slug']?.toString() == 'titulo'),
            readOnly: widget.canEdit &&
                widget.hasTitleTemplateConfigured &&
                campo['slug']?.toString() == 'titulo',
            controllerNotifier: textControllersNotifierTextField[index]!,
            type: campo["type"],
            slug: campo["slug"],
          ),
      'text_view': (context, campo, index, fieldId) {
        // text_view muestra contenido HTML desde options
        final htmlContent = campo['options']?.toString() ?? '';

        if (htmlContent.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(30, 10, 30, 10),
          child: RichText(
            text: TextSpan(
              children: parseHtmlToSpans(htmlContent, context),
              style: DefaultTextStyle.of(context).style,
            ),
          ),
        );
      },
      'image_view': (context, campo, index, fieldId) => Container(
            padding: const EdgeInsetsDirectional.fromSTEB(30, 10, 30, 10),
            child: Align(
              alignment: const AlignmentDirectional(0, 0),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: const AlignmentDirectional(0, 0),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.fade,
                              child: FlutterFlowExpandedImageView(
                                image: Image.network(
                                  'https://${FFAppState().organizacion}.itsquery.com${campo["data"]}',
                                  fit: BoxFit.contain,
                                ),
                                allowRotation: false,
                                tag:
                                    'https://${FFAppState().organizacion}.itsquery.com${campo["data"]}',
                                useHeroAnimation: true,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag:
                              'https://${FFAppState().organizacion}.itsquery.com${campo["data"]}',
                          transitionOnUserGestures: true,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              'https://${FFAppState().organizacion}.itsquery.com${campo["data"]}',
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      'textarea': (context, campo, index, fieldId) => DefaultTextAreaWidget(
            text: campo['data'],
            isEdit: widget.canEdit,
            controllerNotifier: textControllersNotifierTextArea[index]!,
          ),
      'status': (context, campo, index, fieldId) => DefaultStatusWidget(
          text: campo['data'],
          options: campo['options'],
          isEdit: widget.canEdit,
          controller: dropdownControllers[index]!,
          onChanged: () {}),
      'number': (context, campo, index, fieldId) => DefaultTextFieldWidget(
            text: (campo['data'] != null) ? campo['data'].toString() : '',
            isEdit: widget.canEdit,
            controllerNotifier: textControllersNumberNotifier[index]!,
            type: campo["type"],
            slug: campo["slug"],
          ),
      'dropdown': (context, campo, index, fieldId) => CreatableDropdown(
            text: campo['data'],
            options: campo['options']?.toList() ?? [],
            isEdit: widget.canEdit,
            controller: dropdownControllers[index]!,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            slug: campo["slug"],
          ),
      'dropdown_advance': (context, campo, index, fieldId) =>
          CreatableDropdownAdvance(
            text: campo['data'],
            options: campo['options']?.toList() ?? [],
            isEdit: widget.canEdit,
            controller: dropdownControllers[index]!,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            slug: campo["slug"],
          ),
      'radio': (context, campo, index, fieldId) => DefaultTextRadioButtonWidget(
            text: campo['data'],
            options: campo['options'].toList(),
            isEdit: widget.canEdit,
            controller: radioButtonControllers[index]!,
            onChanged: (val) {},
          ),
      'checkbox': (context, campo, index, fieldId) => DefaultCheckboxWidget(
            text: campo['data'],
            options: campo['options'].toList(),
            isEdit: widget.canEdit,
            controller: checkboxControllers[index]!,
          ),
      'calendar': (context, campo, index, fieldId) => DefaultCalendarWidget(
            text: campo['data'],
            isEdit: widget.canEdit,
            controllerNotifier: textControllersCalendarNotifier[index]!,
          ),
      'datetime': (context, campo, index, fieldId) => DefaultDateTimeWidget(
            text: campo['data'],
            controller: textControllersDatetime[index]!,
            isEdit: widget.canEdit,
          ),
      'image': (
        context,
        campo,
        index,
        fieldId,
      ) =>
          DefaultNewImageWidget(
            text: campo['data'] ?? '',
            isEdit: widget.canEdit,
            controller: fileControllers[index]!,
            watermarkUser: FFAppState().fullName,
            watermarkModule: _safeModuleLabel(widget.general),
            onFileSelected: (selectedFile) {
              setState(() {
                fileControllers[index] = selectedFile;
              });
            },
          ),
      'file': (context, campo, index, fieldId) => DefaultFilePdfWidget(
            controller: fileControllers[index]!,
            isEdit: widget.canEdit,
            pdfUrl: campo["data"],
            onFileSelected: (selectedFile) {
              setState(() {
                fileControllers[index] = selectedFile;
              });
            },
          ),
      'georeference': (context, campo, index, fieldId) =>
          DefaultGeoreferenceWidget(
              text: '',
              isEdit: widget.canEdit,
              geoReferenceController: geoReferenceControllers[index]!),
      'relational': (context, campo, index, fieldId) => RelationalWidget(
          text: 'Selecciona un ',
          controller: relationalControllers[index]!,
          isEdit: widget.canEdit,
          options: campo['options'] != null
              ? List<String>.from(
                  campo['options'].map((item) => item.toString()))
              : null,
          config: (campo['relationalConfig'] as RelationalFieldConfig?) ??
              RelationalFieldConfig.fromRawConfig(
                  Map<String, dynamic>.from(campo)),
          inheritedFields: campo['inherited_fields']?.toString(),
          onBatchUpdate: (updates) {
            // Cancel pending debounced text updates to prevent string overwriting Map
            for (final k in updates.keys) {
              _slugDebounceTimers[k]?.cancel();
              _slugDebounceTimers.remove(k);
            }
            // 1. Actualizar notifier (dispara listeners)
            _formData.setAll(updates);
            // 2. Actualizar jsonConfigToSend (compatibilidad legacy)
            setState(() {
              final newMap = Map<String, dynamic>.from(
                  jsonConfigToSend["json_data"] ?? {});
              for (final entry in updates.entries) {
                newMap[entry.key] = entry.value;
              }
              jsonConfigToSend["json_data"] = newMap;
            });
            // 3. Actualizar controllers individuales
            for (final entry in updates.entries) {
              _updateControllerBySlug(entry.key, entry.value);
            }
          },
          onRegisterSelected: (selectedValue, selectedAvatar, selectedFullName,
              selectedNameModule, selectedLabel, selectedType, selectedModule) {
            setState(() {
              relationalControllers[index]!.relationalValue = selectedValue;
              relationalControllers[index]!.relationalLabel = selectedLabel;
              relationalControllers[index]!.type = selectedType;

              if (selectedNameModule != '') {
                relationalControllers[index]!.moduleName = selectedNameModule;
              }
              if (selectedAvatar != '') {
                relationalControllers[index]!.relationalAvatar = selectedAvatar;
              }
              if (selectedFullName != '') {
                relationalControllers[index]!.relationalFullName =
                    selectedFullName;
              }
              if (selectedModule != 0) {
                relationalControllers[index]!.module = selectedModule;
              }
            });
            // Push structured Map into _formData so evaluator gets full
            // relational data (label/value/type/module) — not just the
            // textController string. This ensures visibility formulas that
            // compare against label OR value both work.
            final relMap = <String, dynamic>{
              'label': selectedLabel,
              'value': selectedValue,
              'type': selectedType,
            };
            if (selectedNameModule.isNotEmpty) {
              relMap['module_name'] = selectedNameModule;
            }
            if (selectedModule != 0) {
              relMap['module'] = selectedModule;
            }
            if (selectedAvatar.isNotEmpty) {
              relMap['avatar'] = selectedAvatar;
            }
            if (selectedFullName.isNotEmpty) {
              relMap['full_name'] = selectedFullName;
            }
            // Cancel pending debounced text update to prevent String overwrite
            final relSlug = campo['slug']?.toString() ?? '';
            _slugDebounceTimers[relSlug]?.cancel();
            _slugDebounceTimers.remove(relSlug);
            _formData.set(relSlug, relMap);
          }),
      'multiple_relational_select': (context, campo, index, fieldId) =>
          RelationalField(
            field: campo,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            isEdit: widget.canEdit,
            isUpdate: widget.generalId.isNotEmpty,
            onlyView: !widget.canEdit,
            onChanged: (slug, value, idx, mainSlug) {
              _updateJsonData(slug, value);
            },
            onBatchUpdate: (updates, {index, mainSlug}) {
              // Cancel pending debounced text updates to prevent overwrite
              for (final k in updates.keys) {
                _slugDebounceTimers[k]?.cancel();
                _slugDebounceTimers.remove(k);
              }
              if (mainSlug != null) {
                _slugDebounceTimers[mainSlug]?.cancel();
                _slugDebounceTimers.remove(mainSlug);
              }
              // Sync _formData so visibility re-evaluates with fresh data
              _formData.setAll(updates);
              setState(() {
                final newMap = Map<String, dynamic>.from(
                    jsonConfigToSend["json_data"] ?? {});
                for (final entry in updates.entries) {
                  newMap[entry.key] = entry.value;
                }
                jsonConfigToSend["json_data"] = newMap;
              });
              for (final entry in updates.entries) {
                _updateControllerBySlug(entry.key, entry.value);
              }
            },
          ),
      'calculator': (context, campo, index, fieldId) => DefaultCalculatorWidget(
            text: campo['data'],
            isEdit: false,
            controller: textControllersCalculator[index]!,
            options: campo['options'].toString(),
            idRegister: widget.generalId,
            formDataNotifier: _formData,
          ),
      'calculator_advanced': (context, campo, index, fieldId) {
        // print(
            // '[AcordeonFactory] Creando calculator_advanced index=$index slug=${campo['slug']} options=${campo['options']} generalId=${widget.generalId}');
        return DefaultCalculatorAdvancedWidget(
          text: campo['data'],
          isEdit: false,
          controller: textControllersCalculatorAdvanced[index]!,
          options: campo['options'].toString(),
          idRegister: widget.generalId,
          jsonData: jsonConfigToSend['json_data'] as Map<String, dynamic>?,
          fieldSlug: campo['slug']?.toString(),
          formDataNotifier: _formData,
        );
      },
      'repeater': (context, campo, index, fieldId) => DefaultRepeaterWidget(
          key: repeaterKeys[fieldId],
          data: campo['data'],
          isEdit: widget.canEdit,
          options: campo['options'],
          watermarkUser: FFAppState().fullName,
          watermarkModule: _safeModuleLabel(widget.general),
          idRegister: widget.generalId,
          formDataNotifier: _formData,
          repeaterSlug: campo['slug']?.toString(),
          updateJsonRepeater: (jsonRepeater) {
            safeSetState(() {
              jsonRepeaterToSend = jsonRepeater;
            });
          },
          onChanged: ((value, changeIndex) {})),
      'firma': (context, campo, index, fieldId) => DefaultFirmaWidget(
            text: campo['data'],
            isEdit: widget.canEdit,
            controller: firmaControllers[index]!,
            rolSign: campo['rol_sign'],
          ),
      'firmaext': (context, campo, index, fieldId) => DefaultFirmaExt(
          controller: signatureControllers[index]!,
          isEdit: widget.canEdit,
          text: campo['data'],
          height: 150,
          width: MediaQuery.sizeOf(context).width * 1.0,
          onSignatureChanged: (base64Signature) {
            print(' [DEBUG] Firma externa dibujada para index $index');
          },
        ),
      'formato': (context, campo, index, fieldId) => DefaultFormatoWidget(
            text: campo['data'],
          ),
      'text_editor': (context, campo, index, fieldId) => DefaultRichTextWidget(
            key: richTextKeys[fieldId],
            text: campo['data'],
            isEdit: widget.canEdit,
            controller: richTextControllers[index]!,
          ),
      'boolean': (context, campo, index, fieldId) => DefaultBooleanWidget(
            text: campo['data'],
            isEdit: widget.canEdit,
            controllerNotifier: booleanControllers[index]!,
          ),
      'vista': (context, campo, index, fieldId) => DefaultImageViewWidget(
            image: campo['data'] ?? '',
          ),
      'external_value': (context, campo, index, fieldId) => ExternalValueField(
            field: campo,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
              _updateJsonData(slug, value);
            },
          ),
      'mercadopago': (context, campo, index, fieldId) {
        final generalMap = widget.general is Map<String, dynamic>
            ? widget.general as Map<String, dynamic>
            : null;
        final moduloInfo = generalMap?['modulo_info'] is Map<String, dynamic>
            ? generalMap!['modulo_info'] as Map<String, dynamic>
            : null;
        return MercadoPagoField(
          field: campo,
          jsonData: jsonConfigToSend["json_data"] ?? {},
          handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
            _updateJsonData(slug, value);
          },
          moduleName: moduloInfo?['name']?.toString() ?? '',
          recordId: generalMap?['id'] as int?,
          recordType: moduloInfo?['type']?.toString() ?? 'register',
          onlyView: !widget.canEdit,
          canEdit: widget.canEdit,
        );
      },
      'inverse_relational': (context, campo, index, fieldId) =>
          InverseRelationalField(
            key: ValueKey('inv_rel_$fieldId'),
            campo: _inverseRelationalFieldConfig(campo),
            generalId: widget.generalId,
            general: widget.general,
          ),
    };

    return fieldWidgets[typeField] ??
        ((context, campo, index, fieldId) => ListTile(
              title: Text(campo['label']),
              subtitle: Text(campo['data'] ?? 'No data'),
            ));
  }

  int _computeStartFieldIndex(int categoryIndex) {
    int offset = 0;
    for (int i = 0; i < categoryIndex; i++) {
      offset += (loadedCategories[i]['fields'] as List).length;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (loadedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final titleCategory = loadedCategories.firstWhere(
      (cat) => cat['category'] == 'unique_title_slug_field000111',
      orElse: () => <String, dynamic>{},
    );
    final regularCategories = loadedCategories
        .where((cat) => cat['category'] != 'unique_title_slug_field000111')
        .toList();

    // Filtrar categorías invisibles
    final visibleCategories = regularCategories.where((cat) {
      final slug = cat['slug']?.toString() ?? cat['category']?.toString() ?? '';
      return _categoryVisibility[slug] ?? true;
    }).toList();

    final otrosCategory = visibleCategories.firstWhere(
      (cat) => cat['category'] == 'otros',
      orElse: () => <String, dynamic>{},
    );
    final realCategories =
        visibleCategories.where((cat) => cat['category'] != 'otros').toList();

    final bool soloOtros = realCategories.isEmpty && otrosCategory.isNotEmpty;

    if (soloOtros) {
      return Column(
        children: [
          if (titleCategory.isNotEmpty) _buildTitleSection(titleCategory),
          TabPageWidget(
            category: otrosCategory,
            getController: getController,
            getFieldWidget: getFieldWidget,
            startFieldIndex: titleCategory.isNotEmpty ? 1 : 0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            inheritedSlugs: _inheritedSlugs,
            validationErrors: _validationErrors,
            fieldVisibility: _fieldVisibility,
          ),
        ],
      );
    }

    if (visibleCategories.isEmpty) {
      return Column(
        children: [
          if (titleCategory.isNotEmpty) _buildTitleSection(titleCategory),
          const SizedBox(height: 100),
          Center(
            child: Text(
              'No hay campos visibles',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
          ),
        ],
      );
    }

    return DefaultTabController(
      key:
          ValueKey('tabs_${visibleCategories.length}_$_categoryVisibilityHash'),
      length: visibleCategories.length,
      initialIndex:
          _currentTabIndex < visibleCategories.length ? _currentTabIndex : 0,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          // Registrar listener solo una vez por instancia de TabController
          if (tabController != _lastTabController) {
            _lastTabController?.removeListener(_tabControllerListener);
            _lastTabController = tabController;
            tabController.addListener(_tabControllerListener);
          }
          return Column(
            children: [
              if (titleCategory.isNotEmpty) _buildTitleSection(titleCategory),
              _buildTabBar(visibleCategories),
              _buildTabBarView(visibleCategories),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(Map<String, dynamic> titleCategory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: MediaQuery.sizeOf(context).width,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Título',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          const SizedBox(height: 4),
          _buildFieldWidget(titleCategory['fields'][0], 0, 'titulo'),
          if (widget.hasTitleTemplateConfigured)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(30, 8, 30, 0),
              child: Text(
                'Se genera automaticamente segun la plantilla del modulo.',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(dynamic campo, int globalIndex, String fieldId) {
    final typeField = campo["type"];
    final widgetBuilder = getFieldWidget(typeField);
    getController(typeField, globalIndex, campo, fieldId);

    final slug = campo['slug']?.toString() ?? '';
    final label = campo['label']?.toString() ?? slug;
    final isRequired = campo['is_required'] == true;
    final hasError = _validationErrors.contains(slug);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label con asterisco si es requerido
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(30, 10, 30, 4),
            child: Row(
              children: [
                Text(
                  label,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (isRequired)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        // Widget del campo (envuelto en contenedor rojo si hay error)
        if (hasError)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widgetBuilder(context, campo, globalIndex, fieldId),
                const Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 4, top: 2),
                  child: Text(
                    'Este campo es obligatorio',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          widgetBuilder(context, campo, globalIndex, fieldId),
      ],
    );
  }

  Widget _buildTabBar(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.6),
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: FlutterFlowTheme.of(context).primary,
            unselectedLabelColor: FlutterFlowTheme.of(context).secondaryText,
            indicatorColor: FlutterFlowTheme.of(context).primary,
            indicatorWeight: 3,
            labelStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                ),
            unselectedLabelStyle:
                FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                    ),
            tabs: categories.asMap().entries.map((entry) {
              final index = entry.key;
              final cat = entry.value;
              final categoryName = cat['category']?.toString() ?? '';
              final isCurrentTab = index == _currentTabIndex;
              final hasInherited =
                  _inheritedCategories.contains(categoryName) && !isCurrentTab;
              return Tab(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: hasInherited
                      ? BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.amber.shade600, width: 2),
                        )
                      : null,
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontWeight: hasInherited ? FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) {
      return SizedBox(height: MediaQuery.of(context).size.height * 0.5);
    }
    // Render ONLY the active section — no TabBarView, no inner scroll.
    // This lets the outer SingleChildScrollView continue past the fields
    // into the metadata section (fecha publicación, autor, etc.).
    final activeIndex =
        _currentTabIndex.clamp(0, categories.length - 1);
    final category = categories[activeIndex];
    return TabPageWidget(
      category: category,
      getController: getController,
      getFieldWidget: getFieldWidget,
      startFieldIndex: _computeStartFieldIndexForRegular(activeIndex, categories),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      inheritedSlugs: _inheritedSlugs,
      validationErrors: _validationErrors,
      fieldVisibility: _fieldVisibility,
    );
  }

  int _computeStartFieldIndexForRegular(
      int categoryIndex, List<Map<String, dynamic>> categories) {
    int offset = 1;
    for (int i = 0; i < categoryIndex; i++) {
      offset += (categories[i]['fields'] as List).length;
    }
    return offset;
  }
}
