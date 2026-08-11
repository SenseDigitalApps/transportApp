import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../backend/api_requests/api_calls.dart';
import '../../backend/api_requests/api_manager.dart';
import '../../flutter_flow/flutter_flow_expanded_image_view.dart';
import '../../flutter_flow/form_field_controller.dart';
import '../../controllers/field_controllers.dart';
import '../default_calculator/default_calculator_widget.dart';
import '../default_calculator_advanced/default_calculator_advanced_widget.dart';
import '../default_calendar/default_calendar_widget.dart';
import '../default_checkbox/default_checkbox_widget.dart';
import '../default_datetime/default_datetime_widget.dart';
import '../default_dropdown/default_dropdown_widget.dart';
import '../default_file_pdf/default_file_pdf_widget.dart';
import '../default_formato/default_formato_widget.dart';
import '../default_image_view/default_image_view_widget.dart';
import '../default_new_image/default_new_image_widget.dart';
import '../default_relational/default_relational_widget.dart';
import '../default_relational/relational_field_config.dart';
import '../default_rich_text/default_rich_text_widget.dart';
import '../default_status/default_status_widget.dart';
import '../default_text_area/default_text_area_widget.dart';
import '../default_text_field/default_text_field_widget.dart';
import '../default_text_radio_button/default_text_radio_button_widget.dart';
import '../default_firma/default_firma_widget.dart';
import '../default_firmaext/default_firmaext_widget.dart';
import '../default_external_value/default_external_value_widget.dart';
import '../default_relational/relational_field.dart';
import '../default_creatable_dropdown/default_creatable_dropdown_widget.dart';
import '../default_creatable_dropdown_advance/default_creatable_dropdown_advance_widget.dart';
import '../default_georeference/default_georeference_widget.dart';
import 'package:signature/signature.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class DefaultRepeaterWidget extends StatefulWidget {
  const DefaultRepeaterWidget({
    super.key,
    //Key? key,
    required this.data,
    required this.isEdit,
    required this.options,
    required this.updateJsonRepeater,
    this.onChanged,
    this.watermarkUser,
    this.watermarkModule,
    this.idRegister,
    this.formDataNotifier,
    this.repeaterSlug,
  });
  final dynamic data;
  final bool isEdit;
  final dynamic options;
  final Function(List<Map<String, dynamic>>) updateJsonRepeater;
  final Function(String value, int index)? onChanged;
  final String? watermarkUser;
  final String? watermarkModule;
  final String? idRegister;
  final dynamic formDataNotifier;
  final String? repeaterSlug;

  @override
  DefaultRepeaterWidgetState createState() => DefaultRepeaterWidgetState();
}

class DefaultRepeaterWidgetState extends State<DefaultRepeaterWidget> {
  List<Map<String, dynamic>> dataListed = [];
  List<List<Map<String, dynamic>>> combinedList = [];
  List<String> repeaterConfig = [];
  List<Map<String, dynamic>> jsonRepeaterToSend = [];
  Map<int, Map<int, TextControllerNotifier>> textControllersNotifierTextField =
      {};
  Map<int, Map<int, TextAreaControllerNotifier>>
      textControllersNotifierTextArea = {};
  Map<int, Map<int, TextControllerNotifier>> textControllersCalendarNotifier =
      {};
  Map<int, Map<int, TextControllerNotifier>> textControllersNumberNotifier = {};
  Map<int, Map<int, TextEditingController>> textControllersDatetime = {};
  Map<int, Map<int, TextEditingController>> textControllersNumber = {};
  Map<int, Map<int, FormFieldController<Map<String, bool>>>>
      checkboxControllers = {};
  Map<int, Map<int, FormFieldController<String>>> dropdownControllers = {};
  Map<int, Map<int, FormFieldController<String>>> radioButtonControllers = {};
  Map<int, Map<int, FFUploadedFile>> fileControllers = {};
  Map<int, Map<int, RelationalController>> relationalControllers = {};
  Map<int, Map<int, TextEditingController>> textControllersCalculator = {};
  Map<int, Map<int, TextEditingController>> textControllersCalculatorAdvanced =
      {};
  Map<int, Map<int, QuillController>> richTextControllers = {};
  Map<int, Map<int, Map<String, dynamic>>> firmaControllers = {};
  Map<int, Map<int, SignatureController>> firmaExtControllers = {};
  Map<int, Map<int, String>> firmaExtBase64Data = {};
  Map<int, Map<int, GeoReferenceController>> geoReferenceControllers = {};
  final List<GlobalKey<DefaultRepeaterWidgetState>> _repeaterKeys = [];
  final List<GlobalKey<DefaultFormatoWidgetState>> _formatosKeys = [];
  final List<GlobalKey<DefaultRichTextWidgetState>> _richTextKeys = [];
  final Map<String, GlobalKey<DefaultRichTextWidgetState>> richTextKeys = {};
  late dynamic data;
  final ScrollController _scrollController = ScrollController();
  bool _useAccordionView = true;

  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  Timer? _jsonDataDebounceTimer;

  void _updateRepeaterJsonData(int rowIndex, String slug, dynamic value) {
    _jsonDataDebounceTimer?.cancel();
    _jsonDataDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (jsonRepeaterToSend.isEmpty && dataListed.isNotEmpty) {
        jsonRepeaterToSend =
            dataListed.map((row) => Map<String, dynamic>.from(row)).toList();
      }

      if (mounted && rowIndex < jsonRepeaterToSend.length) {
        setState(() {
          final newRow =
              Map<String, dynamic>.from(jsonRepeaterToSend[rowIndex]);
          newRow[slug] = value;
          jsonRepeaterToSend[rowIndex] = newRow;
        });

        widget.updateJsonRepeater(List<Map<String, dynamic>>.from(
            jsonRepeaterToSend.map((row) => Map<String, dynamic>.from(row))));

        // Notificar al formDataNotifier para que los calculators se recalculen
        if (widget.formDataNotifier != null) {
          try {
            final notifier = widget.formDataNotifier as dynamic;
            if (widget.repeaterSlug != null) {
              notifier.set(widget.repeaterSlug!, List.from(jsonRepeaterToSend));
            }
          } catch (e) {
          }
        }
      }
    });
  }

  void _updateRepeaterControllerBySlug(
      int rowIndex, String slug, dynamic value) {
    for (int colIdx = 0; colIdx < widget.options.length; colIdx++) {
      final option = widget.options[colIdx];
      if (option['slug'] == slug) {
        final type = option['type'] ?? option['field_type'];
        final stringValue = value?.toString() ?? '';
        switch (type) {
          case 'text':
            textControllersNotifierTextField[rowIndex]?[colIdx]
                ?.updateText(stringValue);
            break;
          case 'textarea':
            textControllersNotifierTextArea[rowIndex]?[colIdx]
                ?.updateText(stringValue);
            break;
          case 'number':
            textControllersNumberNotifier[rowIndex]?[colIdx]
                ?.updateText(stringValue);
            break;
          case 'calendar':
            textControllersCalendarNotifier[rowIndex]?[colIdx]
                ?.updateText(stringValue);
            break;
          case 'datetime':
            textControllersDatetime[rowIndex]?[colIdx]?.text = stringValue;
            break;
          case 'checkbox':
            if (value is Map<String, bool>) {
              checkboxControllers[rowIndex]?[colIdx]?.value = value;
            }
            break;
          case 'dropdown':
          case 'dropdown_advance':
          case 'status':
            dropdownControllers[rowIndex]?[colIdx]?.value = stringValue;
            break;
          case 'radio':
            radioButtonControllers[rowIndex]?[colIdx]?.value = stringValue;
            break;
          default:
            break;
        }
        return;
      }
    }
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
  }

  @override
  void initState() {
    super.initState();
    initFunction(false);
  }

  // ✅ para saber qué items están abiertos (y cambiar estilo/ícono)
  final Set<int> _expandedIndexes = <int>{};

  void _clearAllControllers() {
    textControllersNotifierTextField.clear();
    textControllersNotifierTextArea.clear();
    textControllersCalendarNotifier.clear();
    textControllersNumberNotifier.clear();
    textControllersDatetime.clear();
    textControllersNumber.clear();
    checkboxControllers.clear();
    dropdownControllers.clear();
    radioButtonControllers.clear();
    fileControllers.clear();
    relationalControllers.clear();
    textControllersCalculator.clear();
    textControllersCalculatorAdvanced.clear();
    richTextControllers.clear();
    geoReferenceControllers.clear();
    _repeaterKeys.clear();
    _formatosKeys.clear();
    _richTextKeys.clear();
    richTextKeys.clear();
    _expandedIndexes.clear();
  }

  String _stringifyData(dynamic data) {
    if (data == null) return '';
    if (data is String) return data.trim();
    if (data is Map) {
      // Para relational generalmente viene {label:..., value:...}
      final label = data['label'];
      if (label != null && label.toString().trim().isNotEmpty) {
        return label.toString().trim();
      }
      return jsonEncode(data);
    }
    if (data is List) {
      if (data.isEmpty) return '';
      return data
          .map((e) => _stringifyData(e))
          .where((e) => e.isNotEmpty)
          .join(', ');
    }
    return data.toString().trim();
  }

  String _getRowTitle(List<Map<String, dynamic>> itemList, int index) {
    for (final item in itemList) {
      final t = _stringifyData(item['data']);
      if (t.isNotEmpty && t != 'null' && t != '{}' && t != '[]') {
        return t;
      }
    }
    return 'Item ${index + 1}';
  }

  String _getInitials(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return '';
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final first = parts[0];
    final second = parts.length > 1 ? parts[1] : '';
    final a = first.isNotEmpty ? first[0] : '';
    final b = second.isNotEmpty ? second[0] : '';
    return (a + b).toUpperCase();
  }

  static const double _cellWidth = 180.0;
  static const double _cellHeight = 56.0;
  static const double _headerHeight = 44.0;

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ...widget.options.map<Widget>((option) {
            return Container(
              width: _cellWidth,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                option['label'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: const Text(
              'Acciones',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _initializeControllerForItem(
      Map<String, dynamic> item, int index, int idx) {
    final typeField = item['type'];
    final slug = item['slug']?.toString() ?? '';
    switch (typeField) {
      case 'text':
        textControllersNotifierTextField[index] ??= {};
        final wasNew = textControllersNotifierTextField[index]?[idx] == null;
        textControllersNotifierTextField[index]?[idx] ??=
            TextControllerNotifier(item['data']?.toString() ?? '');
        if (wasNew) {
          textControllersNotifierTextField[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(index, slug,
                textControllersNotifierTextField[index]![idx]!.value);
          });
        }
        break;
      case 'textarea':
        textControllersNotifierTextArea[index] ??= {};
        final wasNew = textControllersNotifierTextArea[index]?[idx] == null;
        textControllersNotifierTextArea[index]?[idx] ??=
            TextAreaControllerNotifier(item['data']?.toString() ?? '');
        if (wasNew) {
          textControllersNotifierTextArea[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(index, slug,
                textControllersNotifierTextArea[index]![idx]!.value);
          });
        }
        break;
      case 'calendar':
        textControllersCalendarNotifier[index] ??= {};
        final wasNew = textControllersCalendarNotifier[index]?[idx] == null;
        textControllersCalendarNotifier[index]?[idx] ??=
            TextControllerNotifier(item['data']?.toString() ?? '');
        if (wasNew) {
          textControllersCalendarNotifier[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(index, slug,
                textControllersCalendarNotifier[index]![idx]!.value);
          });
        }
        break;
      case 'datetime':
        textControllersDatetime[index] ??= {};
        final wasNew = textControllersDatetime[index]?[idx] == null;
        textControllersDatetime[index]?[idx] ??=
            TextEditingController(text: item['data']?.toString() ?? '');
        if (wasNew) {
          textControllersDatetime[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(
                index, slug, textControllersDatetime[index]![idx]!.text);
          });
        }
        break;
      case 'number':
        textControllersNumberNotifier[index] ??= {};
        final wasNew = textControllersNumberNotifier[index]?[idx] == null;
        textControllersNumberNotifier[index]?[idx] ??=
            TextControllerNotifier(item['data']?.toString() ?? '');
        if (wasNew) {
          textControllersNumberNotifier[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(
                index, slug, textControllersNumberNotifier[index]![idx]!.value);
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FFAppState().addToTextoControlador(
              item["slug"], textControllersNumberNotifier[index]![idx]!);
        });
        break;
      case 'checkbox':
        checkboxControllers[index] ??= {};
        final wasNew = checkboxControllers[index]?[idx] == null;
        if (wasNew) {
          if (item['data'] is String && (item['data'] as String).isNotEmpty) {
            String dataString = item['data'] as String;
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
            checkboxControllers[index]?[idx] =
                FormFieldController<Map<String, bool>>(checkboxData);
          } else {
            checkboxControllers[index]?[idx] =
                FormFieldController<Map<String, bool>>({});
          }
          checkboxControllers[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(
                index, slug, checkboxControllers[index]![idx]!.value);
          });
        }
        break;
      case 'dropdown':
        dropdownControllers[index] ??= {};
        final wasNew = dropdownControllers[index]?[idx] == null;
        dropdownControllers[index]?[idx] ??=
            FormFieldController<String>(item['data']?.toString());
        if (wasNew) {
          dropdownControllers[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(
                index, slug, dropdownControllers[index]![idx]!.value);
          });
        }
        break;
      case 'dropdown_advance':
        dropdownControllers[index] ??= {};
        final wasNew = dropdownControllers[index]?[idx] == null;
        dropdownControllers[index]?[idx] ??=
            FormFieldController<String>(item['data']?.toString());
        if (wasNew) {
          dropdownControllers[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(
                index, slug, dropdownControllers[index]![idx]!.value);
          });
        }
        break;
      case 'radio':
        radioButtonControllers[index] ??= {};
        final wasNew = radioButtonControllers[index]?[idx] == null;
        radioButtonControllers[index]?[idx] ??=
            FormFieldController<String>(item['data']?.toString());
        if (wasNew) {
          radioButtonControllers[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(
                index, slug, radioButtonControllers[index]![idx]!.value);
          });
        }
        break;
      case 'image':
        fileControllers[index] ??= {};
        fileControllers[index]?[idx] ??= FFUploadedFile();
        break;
      case 'file':
        fileControllers[index] ??= {};
        fileControllers[index]?[idx] ??=
            FFUploadedFile(bytes: Uint8List.fromList([]));
        break;
      case 'status':
        dropdownControllers[index] ??= {};
        final wasNew = dropdownControllers[index]?[idx] == null;
        dropdownControllers[index]?[idx] ??=
            FormFieldController<String>(item['data']?.toString());
        if (wasNew) {
          dropdownControllers[index]![idx]!.addListener(() {
            _updateRepeaterJsonData(
                index, slug, dropdownControllers[index]![idx]!.value);
          });
        }
        break;
      case 'relational':
      case 'relational_from_repeater':
      case 'relational_sub_categories':
        relationalControllers[index] ??= {};
        if (relationalControllers[index]?[idx] == null) {
          final data = item['data'];
          Map<String, dynamic>? savedData;
          if (data != null && data.isNotEmpty) {
            try {
              savedData = jsonDecode(data);
            } catch (_) {
              savedData = data is Map ? Map<String, dynamic>.from(data) : null;
            }
          }

          RelationalFieldConfig? config =
              item['relationalConfig'] as RelationalFieldConfig?;
          if (config == null) {
            config = RelationalFieldConfig.fromRawConfig(
                Map<String, dynamic>.from(item));
          }

          relationalControllers[index]?[idx] =
              RelationalController.fromSavedData(
            savedData: savedData,
            config: config,
          );
        }
        break;
      case 'calculator':
        {
          textControllersCalculator[index] ??= {};
          final wasNew = textControllersCalculator[index]?[idx] == null;
          textControllersCalculator[index]?[idx] ??=
              TextEditingController(text: item['data']?.toString() ?? '');
          if (wasNew) {
            textControllersCalculator[index]![idx]!.addListener(() {
              _updateRepeaterJsonData(
                  index, slug, textControllersCalculator[index]![idx]!.text);
            });
          }
        }
        break;
      case 'calculator_advanced':
        {
          textControllersCalculatorAdvanced[index] ??= {};
          textControllersCalculatorAdvanced[index]?[idx] ??=
              TextEditingController(text: item['data']?.toString() ?? '');
        }
        break;
      case 'repeater':
        while (_repeaterKeys.length <= index) {
          _repeaterKeys.add(GlobalKey<DefaultRepeaterWidgetState>());
        }
        break;
      case 'formato':
        while (_formatosKeys.length <= index) {
          _formatosKeys.add(GlobalKey<DefaultFormatoWidgetState>());
        }
        break;
      case 'text_editor':
        String keyIdentifier = '$index-$idx';
        if (!richTextKeys.containsKey(keyIdentifier)) {
          richTextKeys[keyIdentifier] = GlobalKey<DefaultRichTextWidgetState>();
        }
        richTextControllers[index] ??= {};
        richTextControllers[index]?[idx] ??= QuillController.basic();
        break;
      case 'firma':
        firmaControllers[index] ??= {};
        if (firmaControllers[index]?[idx] == null) {
          if (item['data'] != null && item['data'].toString().isNotEmpty) {
            try {
              firmaControllers[index]?[idx] = Map<String, dynamic>.from(
                  jsonDecode(item['data'].toString()));
            } catch (e) {
              firmaControllers[index]?[idx] = {
                'firma': item['data']?.toString() ?? '',
                'firmado': false,
                'name': '',
                'datetime': '',
              };
            }
          } else {
            firmaControllers[index]?[idx] = {
              'firma': '',
              'firmado': false,
              'name': '',
              'datetime': '',
            };
          }
        }
        break;
      case 'firmaext':
        firmaExtControllers[index] ??= {};
        firmaExtControllers[index]?[idx] ??= SignatureController();
        break;
      case 'georeference':
        geoReferenceControllers[index] ??= {};
        geoReferenceControllers[index]?[idx] ??=
            GeoReferenceController.fromString(item['data']?.toString() ?? '');
        break;
      default:
        break;
    }
  }

  Widget _buildTableCell(BuildContext context, Map<String, dynamic> item,
      int rowIndex, int colIndex) {
    _initializeControllerForItem(item, rowIndex, colIndex);
    final typeField = item['type'];
    final widgetBuilder = getFieldWidget(typeField);

    return Container(
      width: _cellWidth,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: widgetBuilder(context, item, rowIndex, colIndex),
    );
  }

  @override
  void didUpdateWidget(covariant DefaultRepeaterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Verifica si hubo cambios en `widget.data` o `widget.options` y actualiza en consecuencia
    final dataChanged = oldWidget.data != widget.data;
    final optionsChanged =
        _encodeOptions(oldWidget.options) != _encodeOptions(widget.options);
    if (dataChanged || optionsChanged) {
      _clearAllControllers();
      initFunction(true);
      setState(() {});
    }
  }

  String _encodeOptions(dynamic options) {
    return jsonEncode(options, toEncodable: (object) {
      if (object is RelationalFieldConfig) {
        return {
          'relationType': object.relationType,
          'relatedModuleId': object.relatedModuleId,
          'relatedModuleName': object.relatedModuleName,
          'slugFormula': object.slugFormula,
          'valueFormula': object.valueFormula,
          'typeFormula': object.typeFormula,
        };
      }
      return object.toString();
    });
  }

  void initFunction(bool isTotalUpdate) {

    List<dynamic> tempDataListed = [];
    if (widget.data == null || widget.data == '' || widget.data == "[]") {
      tempDataListed = [];
    } else if (widget.data is String) {
      try {
        final decodedData = jsonDecode(widget.data!);
        if (decodedData is List) {
          tempDataListed = decodedData;
        } else if (decodedData is String) {
          tempDataListed = []; // Lo envolvemos en una lista
        } else {
          tempDataListed = [];
        }
      } catch (e) {
        tempDataListed = [];
      }
    } else if (widget.data is List) {
      tempDataListed = widget.data as List<dynamic>;
    } else {
      tempDataListed = [];
    }
    dataListed =
        tempDataListed.map((item) => Map<String, dynamic>.from(item)).toList();
    jsonRepeaterToSend =
        dataListed.map((item) => Map<String, dynamic>.from(item)).toList();
    repeaterConfig.clear();
    if (isTotalUpdate) {
      combinedList = [];
    }

    for (var dataItem in dataListed) {
      List<Map<String, dynamic>> combinedItem = [];
      for (var option in widget.options) {
        String slug = option['slug'];
        dynamic options = option["options"];
        if (option['field_type'] == 'repeater' && options is String) {
          try {
            options = jsonDecode(options);
          } catch (_) {
            options = [];
          }
        }
        var data = dataItem[slug];

        if (option['field_type'] == 'checkbox') {
          if (dataItem[slug] != null) {
            Map<String, dynamic> checkboxData =
                dataItem[slug] as Map<String, dynamic>;
            data = checkboxData.entries
                .map((entry) => '${entry.key}: ${entry.value}')
                .join(', ');
          } else {
            dataItem[slug] = {};
          }
        }

        RelationalFieldConfig? relationalConfig;
        final fieldType = option['field_type']?.toString() ?? '';
        final isRelational = fieldType == 'relational' ||
            fieldType == 'relational_from_repeater' ||
            fieldType == 'relational_sub_categories' ||
            option['is_relational'] == true;

        if (isRelational) {
          int moduleId =
              int.tryParse(option['related_module']?.toString() ?? '') ?? 0;
          String moduleName = option['related_module_name']?.toString() ?? '';

          // Fallback 1: inferir moduleId desde datos guardados
          if (moduleId == 0 && dataItem[slug] is Map) {
            final savedModuleId =
                int.tryParse(dataItem[slug]['module']?.toString() ?? '') ?? 0;
            if (savedModuleId > 0) moduleId = savedModuleId;
          }

          // Fallback 2: buscar moduleName en moduleList
          if (moduleName.isEmpty && moduleId > 0) {
            for (final m in FFAppState().moduleList) {
              if (m is Map && m['id']?.toString() == moduleId.toString()) {
                moduleName = m['name']?.toString() ?? '';
                break;
              }
            }
          }

          final configMap = <String, dynamic>{
            'relations_type': option['relations_type'] ?? '',
            'related_module': moduleId,
            'related_module_name': moduleName,
            'relations_formula': option['relations_formula'] ?? '',
          };
          relationalConfig = RelationalFieldConfig.fromRawConfig(configMap);
          options = relationalConfig.toLegacyOptions();
        }

        combinedItem.add({
          'slug': slug,
          'label': option['label'],
          'type': option['field_type'],
          'data': data,
          'options': options,
          'relationalConfig': relationalConfig,
          'relations_type':
              relationalConfig?.relationType ?? option['relations_type'] ?? '',
          'related_module': relationalConfig?.relatedModuleId ??
              option['related_module'] ??
              0,
          'related_module_name': relationalConfig?.relatedModuleName ??
              option['related_module_name'] ??
              '',
          'relations_formula': option['relations_formula'] ?? '',
          'inherited_fields': option['inherited_fields'],
          'rol_sign': option['rol_sign'] ?? option['field_rol_sign'] ?? [],
        });
      }
      combinedList.add(combinedItem);
    }
    for (var option in widget.options) {
      String fieldType = option["field_type"];
      repeaterConfig.add(fieldType);
    }
    _currentPage = 0;
  }

  List<Map<String, dynamic>> updateJsonRepeater() {
    final previousRows = jsonRepeaterToSend
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    jsonRepeaterToSend = [];
    for (int i = 0; i < combinedList.length; i++) {
      Map<String, dynamic> newObject = {};
      for (int j = 0; j < combinedList[i].length; j++) {
        var item = combinedList[i][j];
        String slug = item['slug'] as String;
        String type = item['type'] as String;
        switch (type) {
          case 'text':
            if (textControllersNotifierTextField.containsKey(i)) {
              newObject[slug] =
                  textControllersNotifierTextField[i]?[j]?.value ?? '';
            }
            break;
          case 'textarea':
            if (textControllersNotifierTextArea.containsKey(i)) {
              newObject[slug] =
                  textControllersNotifierTextArea[i]?[j]?.value ?? '';
            }
            break;
          case 'number':
            if (textControllersNumberNotifier.containsKey(i)) {
              newObject[slug] = textControllersNumberNotifier[i]?[j]!.value;
            }
            break;
          case 'calendar':
            if (textControllersCalendarNotifier.containsKey(i)) {
              newObject[slug] =
                  (textControllersCalendarNotifier[i]?[j]!.value != 'Sin fecha')
                      ? dateTimeFormat(
                          'yyyy-MM-dd',
                          DateTime.tryParse(
                              textControllersCalendarNotifier[i]![j]!.value))
                      : '';
            }
            break;
          case 'datetime':
            if (textControllersDatetime.containsKey(i)) {
              newObject[slug] = (textControllersDatetime[i]?[j]!.text !=
                      'Sin fecha')
                  ? dateTimeFormat('yyyy-MM-ddThh:mm',
                      DateTime.tryParse(textControllersDatetime[i]![j]!.text))
                  : '';
            }
          case 'checkbox':
            if (checkboxControllers.containsKey(i)) {
              Map<String, bool>? checkboxValues =
                  checkboxControllers[i]?[j]?.value;
              if (checkboxValues != null) {
                newObject[slug] = checkboxValues;
              } else {
                newObject[slug] = {};
              }
            } else {
              newObject[slug] = {};
            }
            break;
          case 'dropdown':
            if (dropdownControllers.containsKey(i)) {
              newObject[slug] = dropdownControllers[i]?[j]?.value ?? '';
            }
            break;
          case 'status':
            if (dropdownControllers.containsKey(i)) {
              newObject ??= {};
              newObject[slug] = dropdownControllers[i]?[j]?.value ?? '';
            }
            break;
          case 'radio':
            if (radioButtonControllers.containsKey(i)) {
              newObject[slug] = radioButtonControllers[i]?[j]?.value ?? '';
            }
            break;
          case 'image':
            String? dataField = combinedList[i][j]['data'];
            bool hasDataField =
                dataField != null && dataField.toString().isNotEmpty;
            bool hasController = fileControllers.containsKey(i) &&
                fileControllers[i]?[j]?.bytes?.isNotEmpty == true;

            if (hasController) {
              String encodeImage =
                  base64Encode(fileControllers[i]?[j]!.bytes!.toList() ?? []);
              newObject[slug] = 'data:image/jpg;base64,$encodeImage';
            } else if (hasDataField) {
              newObject[slug] = dataField;
            } else {
              newObject[slug] = '';
            }
            break;
          case 'file':
            if (fileControllers.containsKey(i)) {
              String encodeImage;
              String imgSend = 'data:application/pdf;base64,';
              if (fileControllers[i]?[j]?.bytes?.isNotEmpty == true) {
                encodeImage =
                    base64Encode(fileControllers[i]![j]!.bytes!.toList()) ?? '';
                imgSend += encodeImage;
                slug = '$slug';
                newObject[slug] = imgSend;
              }
            }
            break;
          case 'relational':
            if (relationalControllers.containsKey(i)) {
              String? relationType = relationalControllers[i]?[j]?.type;
              if (relationType == 'user') {
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["avatar"] != null) {
                  newObject[slug]["avatar"] =
                      relationalControllers[i]?[j]?.relationalAvatar;
                }
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["full_name"] != null) {
                  newObject[slug]["full_name"] =
                      relationalControllers[i]?[j]?.relationalFullName;
                }
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["label"] != null) {
                  newObject[slug]["label"] =
                      relationalControllers[i]?[j]?.relationalLabel;
                }
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["type"] != null) {
                  newObject[slug]["type"] = relationalControllers[i]?[j]?.type;
                }
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["value"] != null) {
                  newObject[slug]["value"] =
                      relationalControllers[i]?[j]?.relationalValue;
                }
              } else {
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["label"] != null) {
                  newObject[slug]["label"] =
                      relationalControllers[i]?[j]?.relationalLabel;
                }
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["module"] != null) {
                  newObject[slug]["module"] =
                      relationalControllers[i]?[j]?.module;
                }
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["module_name"] != null) {
                  newObject[slug]["module_name"] =
                      relationalControllers[i]?[j]?.moduleName;
                }
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["type"] != null) {
                  newObject[slug]["type"] = relationalControllers[i]?[j]?.type;
                }
                if (newObject != null &&
                    newObject[slug] != null &&
                    newObject[slug]["value"] != null) {
                  newObject[slug]["value"] =
                      relationalControllers[i]?[j]?.relationalValue;
                }
              }
            }
            break;
          case 'multiple_relational_select':
            // El valor ya se mantiene en jsonRepeaterToSend desde onChanged
            break;
          case 'calculator':
            if (textControllersCalculator.containsKey(i)) {
              newObject[slug] = textControllersCalculator[i]?[j]?.text ?? '';
            }
            break;
          case 'calculator_advanced':
            if (i < previousRows.length && previousRows[i].containsKey(slug)) {
              newObject[slug] = previousRows[i][slug];
            } else if (textControllersCalculatorAdvanced.containsKey(i)) {
              newObject[slug] =
                  textControllersCalculatorAdvanced[i]?[j]?.text ?? '';
            }
            break;
          case 'formato':
            newObject[slug] = _formatosKeys[i].currentState?.getValueForm();
            break;
          case 'text_editor':
            newObject[slug] = richTextKeys['$i-$j']?.currentState?.getString();
            break;
          case 'relational_from_repeater':
            newObject[slug] = '';
            break;
          case 'relational_sub_categories':
            newObject[slug] = '';
            break;
          case 'firma':
            if (firmaControllers.containsKey(i) &&
                firmaControllers[i]?[j] != null) {
              newObject[slug] = firmaControllers[i]![j]!;
            }
            break;
          case 'firmaext':
            if (firmaExtControllers.containsKey(i) &&
                firmaExtControllers[i]?[j] != null) {
              if (firmaExtBase64Data.containsKey(i) &&
                  firmaExtBase64Data[i]?[j] != null) {
                newObject[slug] = firmaExtBase64Data[i]![j]!;
              } else if (combinedList[i][j]['data'] != null &&
                  combinedList[i][j]['data'].toString().isNotEmpty) {
                newObject[slug] = combinedList[i][j]['data'];
              } else {
                newObject[slug] = '';
              }
            }
            break;
          case 'georeference':
            if (geoReferenceControllers.containsKey(i)) {
              final latLng = geoReferenceControllers[i]?[j]?.latLng.text ?? '';
              final address =
                  geoReferenceControllers[i]?[j]?.address.text ?? '';
              newObject[slug] = '$latLng|$address';
            }
            break;
          default:
            break;
        }
      }
      jsonRepeaterToSend.add(newObject);
    }
    widget.updateJsonRepeater(jsonRepeaterToSend);
    return jsonRepeaterToSend ?? [];
  }

  @override
  void dispose() {
    _jsonDataDebounceTimer?.cancel();
    super.dispose();
  }

  void removeAndReorganizeIndex<K, V>(
      Map<int, Map<K, V>> controllersMap, int indexToRemove) {
    // Elimina el índice específico del mapa
    controllersMap.remove(indexToRemove);
    // Reconstruye el mapa con índices consecutivos
    var updatedMap = <int, Map<K, V>>{};
    int newIndex = 0;
    // Recorrer los elementos restantes para reasignar índices
    for (var entry in controllersMap.entries) {
      updatedMap[newIndex] = entry.value;
      newIndex++;
    }
    // Reemplaza el mapa original con el actualizado
    controllersMap
      ..clear()
      ..addAll(updatedMap);
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

  Widget Function(BuildContext p1, Map<String, dynamic> p2, int p3, int p4)
      getFieldWidget(String typeField) {
    final Map<String,
            Widget Function(BuildContext, Map<String, dynamic>, int, int)>
        fieldWidgets = {
      'text': (context, campo, index, idx) => DefaultTextFieldWidget(
            text: campo['data']?.toString() ?? '',
            isEdit: widget.isEdit,
            controllerNotifier: textControllersNotifierTextField[index]![idx]!,
            type: campo["type"],
            slug: campo["slug"],
          ),
      'textarea': (context, campo, index, idx) => DefaultTextAreaWidget(
            text: campo['data']?.toString() ?? '',
            isEdit: widget.isEdit,
            controllerNotifier: textControllersNotifierTextArea[index]![idx]!,
          ),
      'status': (context, campo, index, idx) => DefaultStatusWidget(
          text: campo['data']?.toString(),
          options: List.from(campo['options'].split(',')),
          isEdit: widget.isEdit,
          controller: dropdownControllers[index]![idx]!,
          onChanged: () {}),
      'number': (context, campo, index, idx) => DefaultTextFieldWidget(
            text: (campo['data'] != null) ? campo['data'].toString() : '',
            isEdit: widget.isEdit,
            controllerNotifier: textControllersNumberNotifier[index]![idx]!,
            type: campo["type"],
            slug: campo["slug"],
          ),
      'dropdown': (context, campo, index, idx) => CreatableDropdown(
            text: campo['data']?.toString(),
            options: List.from(campo['options'].split(',')),
            isEdit: widget.isEdit,
            controller: dropdownControllers[index]![idx]!,
            jsonData: jsonRepeaterToSend.isNotEmpty &&
                    index < jsonRepeaterToSend.length
                ? jsonRepeaterToSend[index]
                : {},
            slug: campo["slug"],
            index: idx,
            mainSlug: null,
            handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
              if (jsonRepeaterToSend.isNotEmpty &&
                  index < jsonRepeaterToSend.length) {
                final newRow =
                    Map<String, dynamic>.from(jsonRepeaterToSend[index]);
                newRow[slug] = value;
                jsonRepeaterToSend[index] = newRow;
              }
            },
          ),
      'dropdown_advance': (context, campo, index, idx) =>
          CreatableDropdownAdvance(
            text: campo['data']?.toString(),
            options: List.from(campo['options'].split(',')),
            isEdit: widget.isEdit,
            controller: dropdownControllers[index]![idx]!,
            jsonData: jsonRepeaterToSend.isNotEmpty &&
                    index < jsonRepeaterToSend.length
                ? jsonRepeaterToSend[index]
                : {},
            slug: campo["slug"],
            index: idx,
            mainSlug: null,
            handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
              if (jsonRepeaterToSend.isNotEmpty &&
                  index < jsonRepeaterToSend.length) {
                final newRow =
                    Map<String, dynamic>.from(jsonRepeaterToSend[index]);
                newRow[slug] = value;
                jsonRepeaterToSend[index] = newRow;
              }
            },
          ),
      'radio': (context, campo, index, idx) => DefaultTextRadioButtonWidget(
            text: campo['data']?.toString(),
            options: List.from(campo['options'].split(',')),
            isEdit: widget.isEdit,
            controller: radioButtonControllers[index]![idx]!,
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(value, index);
              }
            },
          ),
      'checkbox': (context, campo, index, idx) => DefaultCheckboxWidget(
            text: campo['data'],
            options: List.from(campo['options'].split(',')),
            isEdit: widget.isEdit,
            controller: checkboxControllers[index]![idx]!,
          ),
      'calendar': (context, campo, index, idx) => DefaultCalendarWidget(
            text: campo['data'],
            isEdit: widget.isEdit,
            controllerNotifier: textControllersCalendarNotifier[index]?[idx]!,
          ),
      'datetime': (context, campo, index, idx) => DefaultDateTimeWidget(
            text: campo['data'],
            controller: textControllersDatetime[index]?[idx]!,
            isEdit: widget.isEdit,
          ),
      'image': (context, campo, index, idx) {
        final textData = campo['data']?.toString() ?? '';
        final hasData = textData.isNotEmpty;

        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                builder: (_, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DefaultNewImageWidget(
                      text: textData,
                      isEdit: widget.isEdit,
                      controller: fileControllers[index]![idx]!,
                      watermarkUser: widget.watermarkUser,
                      watermarkModule: widget.watermarkModule,
                      onFileSelected: (selectedFile) {
                        setState(() {
                          fileControllers[index]?[idx] = selectedFile;
                          combinedList[index][idx]['data'] =
                              selectedFile.bytes?.isNotEmpty == true
                                  ? 'image_data'
                                  : '';
                        });
                      },
                    ),
                  ),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image,
                  size: 18,
                  color: hasData
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    hasData ? 'Imagen cargada' : 'Sin imagen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: hasData
                          ? FlutterFlowTheme.of(context).primaryText
                          : Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isEdit)
                  Icon(Icons.edit, size: 14, color: Colors.grey.shade500),
              ],
            ),
          ),
        );
      },
      'file': (context, campo, index, idx) => DefaultFilePdfWidget(
            controller: fileControllers[index]![idx]!,
            isEdit: widget.isEdit,
            pdfUrl: campo["data"],
            onFileSelected: (selectedFile) {
              setState(() {
                fileControllers[index]?[idx] = selectedFile;
              });
            },
          ),
      'relational': (context, campo, index, idx) {
        final config = campo['relationalConfig'] as RelationalFieldConfig?;
        return RelationalWidget(
          text: (campo['data'] != null && campo['data'] is Map<String, dynamic>)
              ? (campo['data'] as Map<String, dynamic>)['label'] ?? ''
              : campo['data']?.toString() ?? '',
          controller: relationalControllers[index]![idx]!,
          isEdit: widget.isEdit,
          config: config ?? RelationalFieldConfig.fromRawConfig({}),
          inheritedFields: campo['inherited_fields']?.toString(),
          onBatchUpdate: (updates) {
            if (jsonRepeaterToSend.isNotEmpty &&
                index < jsonRepeaterToSend.length) {
              setState(() {
                final newRow =
                    Map<String, dynamic>.from(jsonRepeaterToSend[index]);
                for (final entry in updates.entries) {
                  newRow[entry.key] = entry.value;
                }
                jsonRepeaterToSend[index] = newRow;
              });
            }
            for (final entry in updates.entries) {
              _updateRepeaterControllerBySlug(index, entry.key, entry.value);
            }
          },
          onRegisterSelected: (selectedValue, selectedAvatar, selectedFullName,
              selectedNameModule, selectedLabel, selectedType, selectedModule) {
            setState(() {
              relationalControllers[index]?[idx]!.relationalValue =
                  selectedValue;
              relationalControllers[index]?[idx]!.relationalLabel =
                  selectedLabel;
              relationalControllers[index]?[idx]!.type = selectedType;
              if (selectedNameModule != '') {
                relationalControllers[index]?[idx]!.moduleName =
                    selectedNameModule;
              }
              if (selectedAvatar != '') {
                relationalControllers[index]?[idx]!.relationalAvatar =
                    selectedAvatar;
              }
              if (selectedFullName != '') {
                relationalControllers[index]?[idx]!.relationalFullName =
                    selectedFullName;
              }
              if (selectedModule != 0) {
                relationalControllers[index]?[idx]!.module = selectedModule;
              }
            });
          },
        );
      },
      'calculator': (context, campo, index, idx) {
        return DefaultCalculatorWidget(
          text: campo['data']?.toString(),
          isEdit: false,
          controller: textControllersCalculator[index]?[idx]!,
          options: campo['options'].toString(),
          idRegister: (widget.idRegister ?? "2").toString(),
          formDataNotifier: widget.formDataNotifier,
          jsonData:
              jsonRepeaterToSend.isNotEmpty && index < jsonRepeaterToSend.length
                  ? jsonRepeaterToSend[index]
                  : {},
          mainSlug: widget.repeaterSlug,
          index: index,
        );
      },
      'calculator_advanced': (context, campo, index, idx) {
        final rowIndex = index;
        return DefaultCalculatorAdvancedWidget(
          text: campo['data']?.toString(),
          isEdit: false,
          controller: textControllersCalculatorAdvanced[rowIndex]?[idx]!,
          options: campo['options'].toString(),
          idRegister: (widget.idRegister ?? "2").toString(),
          formDataNotifier: widget.formDataNotifier,
          jsonData: jsonRepeaterToSend.isNotEmpty &&
                  rowIndex < jsonRepeaterToSend.length
              ? jsonRepeaterToSend[rowIndex]
              : {},
          fieldSlug: campo['slug']?.toString(),
          mainSlug: widget.repeaterSlug,
          index: rowIndex,
          onFieldChange: (fieldSlug, value, {int? index, String? mainSlug}) {
            final slugToUpdate = fieldSlug.isNotEmpty
                ? fieldSlug
                : (campo['slug']?.toString() ?? '');
            _updateRepeaterJsonData(index ?? rowIndex, slugToUpdate, value);
          },
        );
      },
      'repeater': (context, campo, index, idx) => DefaultRepeaterWidget(
          key: _repeaterKeys[index],
          data: campo['data'],
          isEdit: widget.isEdit,
          options: campo['options'],
          watermarkUser: widget.watermarkUser,
          watermarkModule: widget.watermarkModule,
          updateJsonRepeater: (jsonRepeater) {
            safeSetState(() {
              jsonRepeaterToSend = jsonRepeater;
            });
          }),
      'formato': (context, campo, index, idx) => DefaultFormatoWidget(
            key: _formatosKeys[index],
            text: campo['data'],
          ),
      'text_editor': (context, campo, index, idx) => DefaultRichTextWidget(
            key: richTextKeys['$index-$idx'],
            text: campo['data'].toString(),
            isEdit: widget.isEdit,
            controller: richTextControllers[index]![idx]!,
          ),
      'relational_from_repeater': (context, campo, index, idx) =>
          RelationalWidget(
              text: (campo['data'] != null &&
                      campo['data'] is Map<String, dynamic>)
                  ? (campo['data'] as Map<String, dynamic>)['label'] ?? ''
                  : campo['data']?.toString() ?? '',
              controller: relationalControllers[index]![idx]!,
              isEdit: widget.isEdit,
              config: campo['relationalConfig'] as RelationalFieldConfig? ??
                  RelationalFieldConfig.fromRawConfig({}),
              onRegisterSelected: (selectedValue,
                  selectedAvatar,
                  selectedFullName,
                  selectedNameModule,
                  selectedLabel,
                  selectedType,
                  selectedModule) {
                setState(() {
                  relationalControllers[index]?[idx]!.relationalValue =
                      selectedValue;
                  relationalControllers[index]?[idx]!.relationalLabel =
                      selectedLabel;
                  relationalControllers[index]?[idx]!.type = selectedType;
                  if (selectedNameModule != '') {
                    relationalControllers[index]?[idx]!.moduleName =
                        selectedNameModule;
                  }
                  if (selectedAvatar != '') {
                    relationalControllers[index]?[idx]!.relationalAvatar =
                        selectedAvatar;
                  }
                  if (selectedFullName != '') {
                    relationalControllers[index]?[idx]!.relationalFullName =
                        selectedFullName;
                  }
                  if (selectedModule != 0) {
                    relationalControllers[index]?[idx]!.module = selectedModule;
                  }
                });
              }),
      'relational_sub_categories': (context, campo, index, idx) =>
          RelationalWidget(
              text: (campo['data'] != null &&
                      campo['data'] is Map<String, dynamic>)
                  ? (campo['data'] as Map<String, dynamic>)['label'] ?? ''
                  : campo['data']?.toString() ?? '',
              controller: relationalControllers[index]![idx]!,
              isEdit: widget.isEdit,
              config: campo['relationalConfig'] as RelationalFieldConfig? ??
                  RelationalFieldConfig.fromRawConfig({}),
              onRegisterSelected: (selectedValue,
                  selectedAvatar,
                  selectedFullName,
                  selectedNameModule,
                  selectedLabel,
                  selectedType,
                  selectedModule) {
                setState(() {
                  relationalControllers[index]?[idx]!.relationalValue =
                      selectedValue;
                  relationalControllers[index]?[idx]!.relationalLabel =
                      selectedLabel;
                  relationalControllers[index]?[idx]!.type = selectedType;
                  if (selectedNameModule != '') {
                    relationalControllers[index]?[idx]!.moduleName =
                        selectedNameModule;
                  }
                  if (selectedAvatar != '') {
                    relationalControllers[index]?[idx]!.relationalAvatar =
                        selectedAvatar;
                  }
                  if (selectedFullName != '') {
                    relationalControllers[index]?[idx]!.relationalFullName =
                        selectedFullName;
                  }
                  if (selectedModule != 0) {
                    relationalControllers[index]?[idx]!.module = selectedModule;
                  }
                });
              }),
      'multiple_relational_select': (context, campo, index, idx) {
        final rowIndex = index;
        return RelationalField(
          field: campo,
          jsonData: jsonRepeaterToSend.isNotEmpty &&
                  rowIndex < jsonRepeaterToSend.length
              ? jsonRepeaterToSend[rowIndex]
              : {},
          isEdit: widget.isEdit,
          isUpdate: true,
          index: idx,
          mainSlug: null,
          onChanged: (slug, value, childIdx, mainSlug) {
            if (jsonRepeaterToSend.isNotEmpty &&
                rowIndex < jsonRepeaterToSend.length) {
              final newRow =
                  Map<String, dynamic>.from(jsonRepeaterToSend[rowIndex]);
              newRow[slug] = value;
              jsonRepeaterToSend[rowIndex] = newRow;
            }
          },
          onBatchUpdate: (updates, {index, mainSlug}) {
            if (jsonRepeaterToSend.isNotEmpty &&
                rowIndex < jsonRepeaterToSend.length) {
              final newRow =
                  Map<String, dynamic>.from(jsonRepeaterToSend[rowIndex]);
              for (final entry in updates.entries) {
                newRow[entry.key] = entry.value;
              }
              jsonRepeaterToSend[rowIndex] = newRow;
            }
            for (final entry in updates.entries) {
              _updateRepeaterControllerBySlug(rowIndex, entry.key, entry.value);
            }
          },
        );
      },
      'image_view': (context, campo, index, idx) => Align(
            alignment: AlignmentDirectional(0, 0),
            child: Container(
              width: 250,
              height: 250,
              alignment: AlignmentDirectional(0, 0),
              child: Container(
                width: 220,
                height: 220,
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
                                'https://${FFAppState().organizacion}.itsquery.com${campo["image_url"]}',
                                fit: BoxFit.contain,
                              ),
                              allowRotation: false,
                              tag:
                                  'https://${FFAppState().organizacion}.itsquery.com${campo["image_url"]}',
                              useHeroAnimation: true,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag:
                            'https://${FFAppState().organizacion}.itsquery.com${campo["image_url"]}',
                        transitionOnUserGestures: true,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://${FFAppState().organizacion}.itsquery.com${campo["image_url"]}',
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
      'text_view': (context, campo, index, idx) => RichText(
            text: TextSpan(
              children:
                  parseTextWithFormatting(campo['options']?.toString() ?? ''),
              style: DefaultTextStyle.of(context).style,
            ),
          ),
      'vista': (context, campo, index, fieldId) => DefaultImageViewWidget(
            image: campo['data'] ?? '',
          ),
      'firma': (context, campo, index, idx) {
        final firmaData = firmaControllers[index]?[idx] ?? {};
        return DefaultFirmaWidget(
          text: jsonEncode(firmaData),
          isEdit: widget.isEdit,
          controller: firmaControllers[index]![idx]!,
          rolSign: List<dynamic>.from(campo['rol_sign'] ?? []),
          onChanged: () {
            // Sincronizar cambios de firma de vuelta a combinedList
            if (firmaControllers.containsKey(index) &&
                firmaControllers[index]?.containsKey(idx) == true) {
              final updatedData = firmaControllers[index]![idx]!;
              combinedList[index][idx]['data'] = jsonEncode(updatedData);
            }
          },
        );
      },
      'firmaext': (context, campo, index, idx) {
        final controller = firmaExtControllers[index]![idx]!;
        final existingData =
            firmaExtBase64Data[index]?[idx] ?? campo['data']?.toString() ?? '';
        final hasData = existingData.isNotEmpty;

        return InkWell(
          onTap: () {
            showDialog(
              context: context,
              useSafeArea: false,
              builder: (ctx) => Scaffold(
                appBar: AppBar(
                  title: const Text('Firma'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  backgroundColor:
                      FlutterFlowTheme.of(context).primaryBackground,
                  foregroundColor: FlutterFlowTheme.of(context).primaryText,
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DefaultFirmaExt(
                    controller: controller,
                    isEdit: widget.isEdit,
                    text: existingData,
                    height: 300,
                    width: double.infinity,
                    onSignatureChanged: (base64Signature) {
                      setState(() {
                        firmaExtBase64Data[index] ??= {};
                        firmaExtBase64Data[index]![idx] = base64Signature;
                        combinedList[index][idx]['data'] = base64Signature;
                      });
                    },
                  ),
                ),
              ),
            );
          },
          child: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.draw,
                  size: 18,
                  color: hasData
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    hasData ? 'Firma registrada' : 'Sin firma',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: hasData
                          ? FlutterFlowTheme.of(context).primaryText
                          : Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isEdit)
                  Icon(Icons.edit, size: 14, color: Colors.grey.shade500),
              ],
            ),
          ),
        );
      },
      'external_value': (context, campo, index, idx) => ExternalValueField(
            field: campo,
            jsonData: jsonRepeaterToSend.isNotEmpty &&
                    index < jsonRepeaterToSend.length
                ? jsonRepeaterToSend[index]
                : {},
            mainSlug: null,
            index: idx,
            handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
              _updateRepeaterJsonData(index, slug, value);
            },
          ),
      'georeference': (context, campo, index, idx) {
        final controller = geoReferenceControllers[index]![idx]!;
        final latLngText = controller.latLng.text;
        final addressText = controller.address.text;
        final hasData = latLngText.isNotEmpty || addressText.isNotEmpty;

        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                builder: (_, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DefaultGeoreferenceWidget(
                      text: '',
                      isEdit: widget.isEdit,
                      geoReferenceController: controller,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: hasData ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (addressText.isNotEmpty)
                        Text(
                          addressText,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (latLngText.isNotEmpty)
                        Text(
                          latLngText,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (!hasData)
                        Text(
                          'Sin ubicacion',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400),
                        ),
                    ],
                  ),
                ),
                if (widget.isEdit)
                  Icon(Icons.edit, size: 14, color: Colors.grey.shade500),
              ],
            ),
          ),
        );
      },
    };
    return fieldWidgets[typeField] ??
        ((context, campo, index, idx) {
          final data = campo['data'];

          return ListTile(
            title: Text((campo['label'] ?? '').toString()),
            subtitle:
                Text((data ?? 'No data').toString()),
          );
        });
  }

  List<Widget> _buildFieldsWidgets(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> itemList, {
    required bool asAccordion,
  }) {
    return itemList.mapIndexed((idx, item) {
      if (combinedList.isEmpty || itemList.isEmpty) {
        return const Center(child: Text('No hay datos para mostrar'));
      }

      final typeField = item['type'];
      final widgetBuilder = getFieldWidget(typeField);

      // ✅ MISMA lógica de init controllers (copiada tal cual de tu build)
      final slug = item['slug']?.toString() ?? '';
      switch (typeField) {
        case 'text':
          {
            textControllersNotifierTextField[index] ??= {};
            final wasNew =
                textControllersNotifierTextField[index]?[idx] == null;
            textControllersNotifierTextField[index]?[idx] ??=
                TextControllerNotifier(item['data']?.toString() ?? '');
            if (wasNew) {
              textControllersNotifierTextField[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(index, slug,
                    textControllersNotifierTextField[index]![idx]!.value);
              });
            }
          }
          break;
        case 'textarea':
          {
            textControllersNotifierTextArea[index] ??= {};
            final wasNew = textControllersNotifierTextArea[index]?[idx] == null;
            textControllersNotifierTextArea[index]?[idx] ??=
                TextAreaControllerNotifier(item['data']?.toString() ?? '');
            if (wasNew) {
              textControllersNotifierTextArea[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(index, slug,
                    textControllersNotifierTextArea[index]![idx]!.value);
              });
            }
          }
          break;
        case 'calendar':
          {
            textControllersCalendarNotifier[index] ??= {};
            final wasNew = textControllersCalendarNotifier[index]?[idx] == null;
            textControllersCalendarNotifier[index]?[idx] ??=
                TextControllerNotifier(item['data']?.toString() ?? '');
            if (wasNew) {
              textControllersCalendarNotifier[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(index, slug,
                    textControllersCalendarNotifier[index]![idx]!.value);
              });
            }
          }
          break;
        case 'datetime':
          {
            textControllersDatetime[index] ??= {};
            final wasNew = textControllersDatetime[index]?[idx] == null;
            textControllersDatetime[index]?[idx] ??=
                TextEditingController(text: item['data']?.toString() ?? '');
            if (wasNew) {
              textControllersDatetime[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(
                    index, slug, textControllersDatetime[index]![idx]!.text);
              });
            }
          }
          break;
        case 'number':
          {
            textControllersNumberNotifier[index] ??= {};
            final wasNew = textControllersNumberNotifier[index]?[idx] == null;
            textControllersNumberNotifier[index]?[idx] ??=
                TextControllerNotifier(item['data']?.toString() ?? '');
            if (wasNew) {
              textControllersNumberNotifier[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(index, slug,
                    textControllersNumberNotifier[index]![idx]!.value);
              });
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              FFAppState().addToTextoControlador(
                  item["slug"], textControllersNumberNotifier[index]![idx]!);
            });
          }
          break;
        case 'checkbox':
          {
            checkboxControllers[index] ??= {};
            final wasNew = checkboxControllers[index]?[idx] == null;
            if (wasNew) {
              if (item['data'] is String &&
                  (item['data'] as String).isNotEmpty) {
                String dataString = item['data'] as String;
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
                checkboxControllers[index]?[idx] =
                    FormFieldController<Map<String, bool>>(checkboxData);
              } else {
                checkboxControllers[index]?[idx] =
                    FormFieldController<Map<String, bool>>({});
              }
              checkboxControllers[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(
                    index, slug, checkboxControllers[index]![idx]!.value);
              });
            }
          }
          break;
        case 'dropdown':
          {
            dropdownControllers[index] ??= {};
            final wasNew = dropdownControllers[index]?[idx] == null;
            dropdownControllers[index]?[idx] ??=
                FormFieldController<String>(item['data']?.toString());
            if (wasNew) {
              dropdownControllers[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(
                    index, slug, dropdownControllers[index]![idx]!.value);
              });
            }
          }
          break;
        case 'dropdown_advance':
          {
            dropdownControllers[index] ??= {};
            final wasNew = dropdownControllers[index]?[idx] == null;
            dropdownControllers[index]?[idx] ??=
                FormFieldController<String>(item['data']?.toString());
            if (wasNew) {
              dropdownControllers[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(
                    index, slug, dropdownControllers[index]![idx]!.value);
              });
            }
          }
          break;
        case 'radio':
          {
            radioButtonControllers[index] ??= {};
            final wasNew = radioButtonControllers[index]?[idx] == null;
            radioButtonControllers[index]?[idx] ??=
                FormFieldController<String>(item['data']?.toString());
            if (wasNew) {
              radioButtonControllers[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(
                    index, slug, radioButtonControllers[index]![idx]!.value);
              });
            }
          }
          break;
        case 'image':
          fileControllers[index] ??= {};
          fileControllers[index]?[idx] ??= FFUploadedFile();
          break;
        case 'file':
          fileControllers[index] ??= {};
          fileControllers[index]?[idx] ??=
              FFUploadedFile(bytes: Uint8List.fromList([]));
          break;
        case 'status':
          {
            dropdownControllers[index] ??= {};
            final wasNew = dropdownControllers[index]?[idx] == null;
            dropdownControllers[index]?[idx] ??=
                FormFieldController<String>(item['data']?.toString());
            if (wasNew) {
              dropdownControllers[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(
                    index, slug, dropdownControllers[index]![idx]!.value);
              });
            }
          }
          break;
        case 'relational':
        case 'relational_from_repeater':
        case 'relational_sub_categories':
          {
            relationalControllers[index] ??= {};
            final wasNew = relationalControllers[index]?[idx] == null;
            if (wasNew) {
              final data = item['data'];
              Map<String, dynamic>? savedData;
              if (data != null && data.isNotEmpty) {
                try {
                  savedData = jsonDecode(data);
                } catch (_) {
                  savedData =
                      data is Map ? Map<String, dynamic>.from(data) : null;
                }
              }

              RelationalFieldConfig? config =
                  item['relationalConfig'] as RelationalFieldConfig?;

              // Fallback 1: desde claves sueltas del item
              if (config == null) {
                config = RelationalFieldConfig.fromRawConfig(
                    Map<String, dynamic>.from(item));
              }

              // Fallback 2: desde options legacy (String o List)
              final isDefault = config.relationType == 'master' &&
                  config.relatedModuleId == 0 &&
                  config.relatedModuleName.isEmpty;
              if (isDefault) {
                final rawOpts = item['options'];
                if (rawOpts is List && rawOpts.isNotEmpty) {
                  config = RelationalFieldConfig.fromLegacy(
                      rawOpts.map((e) => e.toString()).toList());
                } else if (rawOpts is String && rawOpts.isNotEmpty) {
                  config = RelationalFieldConfig.fromLegacy(rawOpts.split(','));
                }
              }

              // Fallback 3: inferir desde datos guardados
              final stillDefault = config.relationType == 'master' &&
                  config.relatedModuleId == 0;
              if (stillDefault && savedData != null) {
                final type = savedData['type']?.toString() ?? '';
                final moduleId =
                    int.tryParse(savedData['module']?.toString() ?? '') ?? 0;
                final moduleName = savedData['module_name']?.toString() ?? '';
                if (type.isNotEmpty || moduleId > 0) {
                  config = RelationalFieldConfig(
                    relationType: RelationalFieldConfig.normalizeType(type),
                    relatedModuleId: moduleId,
                    relatedModuleName: moduleName,
                  );
                }
              }

              relationalControllers[index]?[idx] =
                  RelationalController.fromSavedData(
                savedData: savedData,
                config: config ?? RelationalFieldConfig.fromRawConfig({}),
              );
            }
          }
          break;
        case 'calculator':
          {
            textControllersCalculator[index] ??= {};
            final wasNew = textControllersCalculator[index]?[idx] == null;
            textControllersCalculator[index]?[idx] ??=
                TextEditingController(text: item['data']?.toString() ?? '');
            if (wasNew) {
              textControllersCalculator[index]![idx]!.addListener(() {
                _updateRepeaterJsonData(
                    index, slug, textControllersCalculator[index]![idx]!.text);
              });
            }
          }
          break;
        case 'repeater':
          while (_repeaterKeys.length <= index) {
            _repeaterKeys.add(GlobalKey<DefaultRepeaterWidgetState>());
          }
          break;
        case 'formato':
          while (_formatosKeys.length <= index) {
            _formatosKeys.add(GlobalKey<DefaultFormatoWidgetState>());
          }
          break;
        case 'text_editor':
          String keyIdentifier = '$index-$idx';
          if (!richTextKeys.containsKey(keyIdentifier)) {
            richTextKeys[keyIdentifier] =
                GlobalKey<DefaultRichTextWidgetState>();
          }
          richTextControllers[index] ??= {};
          richTextControllers[index]?[idx] ??= QuillController.basic();
          break;
        case 'firma':
          firmaControllers[index] ??= {};
          if (firmaControllers[index]?[idx] == null) {
            if (item['data'] != null && item['data'].toString().isNotEmpty) {
              try {
                firmaControllers[index]?[idx] = Map<String, dynamic>.from(
                    jsonDecode(item['data'].toString()));
              } catch (e) {
                firmaControllers[index]?[idx] = {
                  'firma': item['data']?.toString() ?? '',
                  'firmado': false,
                  'name': '',
                  'datetime': '',
                };
              }
            } else {
              firmaControllers[index]?[idx] = {
                'firma': '',
                'firmado': false,
                'name': '',
                'datetime': '',
              };
            }
          }
          break;
        case 'firmaext':
          firmaExtControllers[index] ??= {};
          firmaExtControllers[index]?[idx] ??= SignatureController();
          break;
        case 'georeference':
          geoReferenceControllers[index] ??= {};
          geoReferenceControllers[index]?[idx] ??=
              GeoReferenceController.fromString(item['data']?.toString() ?? '');
          break;
        default:
          break;
      }

      // ✅ Render: tabla vs acordeón
      if (asAccordion) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['label']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              widgetBuilder(context, item, index, idx),
            ],
          ),
        );
      }

      // (tu vista actual)
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250.0),
        child: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${item['label']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              widgetBuilder(context, item, index, idx),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPaginatedRows() {
    final int totalPages = (combinedList.length / _itemsPerPage).ceil();
    if (totalPages == 0) return [];

    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage > combinedList.length)
        ? combinedList.length
        : startIndex + _itemsPerPage;

    final List<Widget> rows = [];
    for (int i = startIndex; i < endIndex; i++) {
      final itemList = combinedList[i];
      final String stableKey = 'row_$i';
      rows.add(KeyedSubtree(
        key: ValueKey(stableKey),
        child: _buildTableRow(context, itemList, i),
      ));
    }

    return rows;
  }

  Widget _buildPaginationControls() {
    final int totalPages = (combinedList.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    final int startItem = _currentPage * _itemsPerPage + 1;
    final int endItem =
        ((_currentPage + 1) * _itemsPerPage > combinedList.length)
            ? combinedList.length
            : (_currentPage + 1) * _itemsPerPage;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left),
            color: FlutterFlowTheme.of(context).primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$_currentPage + 1 de $totalPages ($startItem-$endItem de ${combinedList.length})',
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: FlutterFlowTheme.of(context).primary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (combinedList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 48,
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay elementos',
                      style: TextStyle(
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTableHeader(context),
                      const SizedBox(height: 4),
                      ..._buildPaginatedRows(),
                    ],
                  ),
                ),
                _buildPaginationControls(),
              ],
            ),
          const SizedBox(height: 12),
          if (widget.isEdit)
            InkWell(
              onTap: () async {
                var processedList =
                    widget.options.map<Map<String, dynamic>>((item) {
                  final optionMap = Map<String, dynamic>.from(item);
                  final fieldType = optionMap['field_type']?.toString() ?? '';
                  final isRelational = fieldType == 'relational' ||
                      fieldType == 'relational_from_repeater' ||
                      fieldType == 'relational_sub_categories' ||
                      optionMap['is_relational'] == true;
                  RelationalFieldConfig? relationalConfig;
                  dynamic options = optionMap['options'];

                  if (isRelational) {
                    relationalConfig =
                        optionMap['relationalConfig'] as RelationalFieldConfig?;
                    relationalConfig ??=
                        RelationalFieldConfig.fromRawConfig(optionMap);
                    options = relationalConfig.toLegacyOptions();
                  }

                  return {
                    'slug': optionMap['slug'],
                    'label': optionMap['label'],
                    'options': options,
                    'type': fieldType,
                    'data': '',
                    'relationalConfig': relationalConfig,
                    'relations_type': relationalConfig?.relationType ??
                        optionMap['relations_type'] ??
                        '',
                    'related_module': relationalConfig?.relatedModuleId ??
                        optionMap['related_module'] ??
                        0,
                    'related_module_name':
                        relationalConfig?.relatedModuleName ??
                            optionMap['related_module_name'] ??
                            '',
                    'relations_formula': optionMap['relations_formula'] ?? '',
                    'rol_sign': optionMap['rol_sign'] ??
                        optionMap['field_rol_sign'] ??
                        [],
                  };
                }).toList();
                safeSetState(() {
                  combinedList.add(processedList);
                  _currentPage = (combinedList.length / _itemsPerPage).floor();
                  final newRow = <String, dynamic>{};
                  for (final opt in widget.options) {
                    newRow[opt['slug']?.toString() ?? ''] = '';
                  }
                  jsonRepeaterToSend.add(newRow);
                  if (widget.formDataNotifier != null &&
                      widget.repeaterSlug != null) {
                    try {
                      final notifier = widget.formDataNotifier as dynamic;
                      notifier.set(widget.repeaterSlug!,
                          List.from(jsonRepeaterToSend));
                    } catch (_) {}
                  }
                });
                await Future.delayed(Duration.zero);
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
                setState(() {});
              },
              child: Container(
                width: 150,
                height: 35,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Agregar items',
                        style: TextStyle(color: Colors.white)),
                    Icon(Icons.add, color: Colors.white),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
      BuildContext context, List<Map<String, dynamic>> itemList, int index) {
    final bool isEven = index % 2 == 0;
    return Container(
      decoration: BoxDecoration(
        color: isEven
            ? FlutterFlowTheme.of(context).primaryBackground
            : FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: FlutterFlowTheme.of(context).accent1.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...itemList.map<Widget>((item) {
              return SizedBox(
                width: _cellWidth,
                child: _buildTableCell(
                    context, item, index, itemList.indexOf(item)),
              );
            }),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (itemList.any(
                      (item) => item['slug'] == 'ref_formato_diligenciado'))
                    InkWell(
                      onTap: () async {
                        var refFormato = itemList.firstWhere((item) =>
                            item['slug'] == 'ref_formato_diligenciado');
                        ApiCallResponse? actualRegister =
                            await GetDataMastersCall.call(
                          tenant: FFAppState().organizacion,
                          id: refFormato['data']['value'].toString(),
                          token: FFAppState().token,
                        );
                        context.pushNamed(
                          'detailGrouped',
                          queryParameters: {
                            'title': serializeParam('a', ParamType.String),
                            'body': serializeParam('aa', ParamType.String),
                            'general': serializeParam(
                                (actualRegister.jsonBody ?? ''),
                                ParamType.JSON),
                          }.withoutNulls,
                        );
                        setState(() {});
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.remove_red_eye_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  if (widget.isEdit) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        List<Map<String, dynamic>> item = combinedList[index];
                        combinedList.removeAt(index);
                        _expandedIndexes.remove(index);
                        final int totalPages =
                            (combinedList.length / _itemsPerPage).ceil();
                        if (_currentPage >= totalPages && totalPages > 0) {
                          _currentPage = totalPages - 1;
                        }
                        for (var element in item) {
                          var typeField = element['type'];
                          var slug = element['slug'];
                          switch (typeField) {
                            case 'text':
                              if (textControllersNotifierTextField
                                  .containsKey(index)) {
                                removeAndReorganizeIndex(
                                    textControllersNotifierTextField, index);
                              }
                              break;
                            case 'textarea':
                              if (textControllersNotifierTextArea
                                  .containsKey(index)) {
                                removeAndReorganizeIndex(
                                    textControllersNotifierTextArea, index);
                              }
                              break;
                            case 'calendar':
                              if (textControllersCalendarNotifier
                                  .containsKey(index)) {
                                removeAndReorganizeIndex(
                                    textControllersCalendarNotifier, index);
                              }
                              break;
                            case 'datetime':
                              if (textControllersDatetime.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    textControllersDatetime, index);
                              }
                              break;
                            case 'number':
                              if (textControllersNumberNotifier
                                  .containsKey(index)) {
                                removeAndReorganizeIndex(
                                    textControllersNumberNotifier, index);
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  FFAppState().removeFromTextoControlador(slug);
                                });
                              }
                              break;
                            case 'checkbox':
                              removeAndReorganizeIndex(
                                  checkboxControllers, index);
                              break;
                            case 'dropdown':
                              if (dropdownControllers.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    dropdownControllers, index);
                              }
                              break;
                            case 'status':
                              removeAndReorganizeIndex(
                                  dropdownControllers, index);
                              break;
                            case 'radio':
                              removeAndReorganizeIndex(
                                  radioButtonControllers, index);
                              break;
                            case 'image':
                              if (fileControllers.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    fileControllers, index);
                              }
                              break;
                            case 'file':
                              removeAndReorganizeIndex(fileControllers, index);
                              break;
                            case 'relational':
                              if (relationalControllers.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    relationalControllers, index);
                              }
                              break;
                            case 'multiple_relational_select':
                              // No hay controller que limpiar (usa jsonData directamente)
                              break;
                            case 'calculator':
                              if (textControllersCalculator
                                  .containsKey(index)) {
                                removeAndReorganizeIndex(
                                    textControllersCalculator, index);
                              }
                              break;
                            case 'calculator_advanced':
                              if (textControllersCalculatorAdvanced
                                  .containsKey(index)) {
                                removeAndReorganizeIndex(
                                    textControllersCalculatorAdvanced, index);
                              }
                              break;
                            case 'text_editor':
                              if (richTextControllers.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    richTextControllers, index);
                              }
                              break;
                            case 'firma':
                              if (firmaControllers.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    firmaControllers, index);
                              }
                              break;
                            case 'firmaext':
                              if (firmaExtControllers.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    firmaExtControllers, index);
                              }
                              if (firmaExtBase64Data.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    firmaExtBase64Data, index);
                              }
                              break;
                            case 'georeference':
                              if (geoReferenceControllers.containsKey(index)) {
                                removeAndReorganizeIndex(
                                    geoReferenceControllers, index);
                              }
                              break;
                            default:
                              break;
                          }
                        }
                        setState(() {});
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
