import 'dart:async';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:transport_app/components/default_calculator/default_calculator_widget.dart';
import 'package:transport_app/components/default_formato/default_formato_widget.dart';
import 'package:transport_app/components/default_new_image/default_new_image_widget.dart';
import 'package:transport_app/components/default_relational/default_relational_widget.dart';
import 'package:transport_app/components/default_relational/relational_field.dart';
import 'package:transport_app/components/default_relational/relational_field_config.dart';
import 'package:transport_app/components/default_repeater/default_repeater_widget.dart';
import 'package:transport_app/components/default_rich_text/default_rich_text_widget.dart';
import 'package:transport_app/components/empty_component/empty_component_widget.dart';
import 'package:transport_app/controllers/field_controllers.dart';
import 'package:signature/signature.dart';
import '../../components/default_boolean/default_boolean_widget.dart';
import '../../components/default_datetime/default_datetime_widget.dart';
import '../../components/default_file_pdf/default_file_pdf_widget.dart';
import '../../components/default_firma/default_firma_widget.dart';
import '../../components/default_firmaext/default_firmaext_widget.dart';
import '../../flutter_flow/custom_functions.dart';
import '../../flutter_flow/flutter_flow_expanded_image_view.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';
import '../../flutter_flow/form_field_controller.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'new_registers_modules_model.dart';
import 'package:flutter/scheduler.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/components/default_text_field/default_text_field_widget.dart';
import '/components/default_text_area/default_text_area_widget.dart';
import '/components/default_external_value/default_external_value_widget.dart';
import '/components/default_creatable_dropdown/default_creatable_dropdown_widget.dart';
import '/components/default_creatable_dropdown_advance/default_creatable_dropdown_advance_widget.dart';
import '/components/default_status/default_status_widget.dart';
import 'package:transport_app/components/default_calendar/default_calendar_widget.dart';
import 'package:transport_app/components/default_checkbox/default_checkbox_widget.dart';
import 'package:transport_app/components/default_dropdown/default_dropdown_widget.dart';
import 'package:transport_app/components/default_file_image/default_file_image_widget.dart';
import 'package:transport_app/components/default_text_radio_button/default_text_radio_button_widget.dart';
import 'package:transport_app/components/mercado_pago_field/mercado_pago_field.dart';
import '../../components/page_components/screens_background/background_widget.dart';
import '../../utils/evaluate_condition.dart';

class NewRegistersModules extends StatefulWidget {
  const NewRegistersModules({
    super.key,
    this.general,
    this.moduleName,
    this.moduleId,
    this.moduleType,
  });

  final dynamic general;
  final String? moduleName;
  final int? moduleId;
  final String? moduleType;

  @override
  State<NewRegistersModules> createState() => _NewRegistersModulesState();
}

class _NewRegistersModulesState extends State<NewRegistersModules> {
  late NewRegistersModulesModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool isLoading = true;

  //Controladores
  Map<int, TextControllerNotifier> textControllersNotifierTextField = {};
  Map<int, TextAreaControllerNotifier> textControllersNotifierTextArea = {};
  Map<int, TextControllerNotifier> textControllersCalendarNotifier = {};
  Map<int, TextControllerNotifier> textControllersNumberNotifier = {};

  Map<int, TextEditingController> textControllersDatetime = {};
  Map<int, TextEditingController> textControllersNumber = {};
  Map<int, FormFieldController<Map<String, bool>>> checkboxControllers = {};
  Map<int, FormFieldController<String>> dropdownControllers = {};
  Map<int, FormFieldController<String>> radioButtonControllers = {};
  Map<int, FFUploadedFile> fileControllers = {};
  Map<int, String> utilsVar = {};
  Map<int, RelationalController> relationalControllers = {};
  Map<int, TextEditingController> textControllersCalculator = {};

  final Map<String, GlobalKey<DefaultRepeaterWidgetState>> repeaterKeys = {};
  List<Map<String, dynamic>> jsonRepeaterToSend = [];
  Map<int, SignatureController> signatureControllers = {};
  Map<int, Map<String, dynamic>> firmaControllers = {};
  final Map<String, GlobalKey<DefaultRichTextWidgetState>> richTextKeys = {};
  Map<int, QuillController> richTextControllers = {};
  Map<int, BooleanControllerNotifier> booleanControllers = {};

  ApiCallResponse? moduleConfig;
  List<dynamic>? dataModuleConfig = [];
  Map<String, dynamic> jsonConfigToSend = {};
  Map<String, dynamic> orderedJsonConfigToSend = {};
  List<Map<String, dynamic>> relationalFields = [];
  Map<String, bool> _fieldVisibility = {};

  final ValueNotifier<bool> isDisabledButton = ValueNotifier<bool>(false);
  Timer? _jsonDataDebounceTimer;

  void _updateJsonData(String slug, dynamic value) {
    _jsonDataDebounceTimer?.cancel();
    _jsonDataDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          final newJsonData = Map<String, dynamic>.from(orderedJsonConfigToSend.isNotEmpty ? orderedJsonConfigToSend[0]["json_data"] ?? {} : {});
          newJsonData[slug] = value;
          if (orderedJsonConfigToSend.isNotEmpty) {
            orderedJsonConfigToSend[0]["json_data"] = newJsonData;
          }
          // Sincronizar jsonConfigToSend para que widgets como ExternalValueField
          // detecten cambios via didUpdateWidget (comparación de referencias de Map)
          jsonConfigToSend["json_data"] = newJsonData;
        });
        _reEvaluateVisibility();
      }
    });
  }

  void _reEvaluateVisibility() {
    if (!mounted) return;
    final jsonData = jsonConfigToSend['json_data'] is Map
        ? Map<String, dynamic>.from(jsonConfigToSend['json_data'] as Map)
        : <String, dynamic>{};
    final newVis = <String, bool>{};
    for (final campo in dataModuleConfig ?? []) {
      if (campo is! Map) continue;
      final slug = campo['slug']?.toString();
      if (slug == null || slug.isEmpty) continue;
      final cond = campo['conditional_value']?.toString() ?? '';
      newVis[slug] = evaluateConditions(cond, jsonData, field: Map<String, dynamic>.from(campo), context: _buildConditionContext());
    }
    setState(() {
      _fieldVisibility = newVis;
    });
  }

  ConditionContext _buildConditionContext() {
    return ConditionContext(
      currentUserRole: FFAppState().role,
      currentUserRoles: FFAppState().roleGroups
          .map((r) => r is String ? r : r.toString())
          .toList(),
    );
  }

  void _updateControllerBySlug(String slug, dynamic value) {
    for (int i = 0; i < dataModuleConfig!.length; i++) {
      if (dataModuleConfig![i]['slug'] == slug) {
        final type = dataModuleConfig![i]['field_type'];
        final stringValue = value?.toString() ?? '';
        switch (type) {
          case 'text':
            textControllersNotifierTextField[i]?.updateText(stringValue);
            dataModuleConfig![i]['default_value'] = stringValue;
            break;
          case 'textarea':
            textControllersNotifierTextArea[i]?.updateText(stringValue);
            dataModuleConfig![i]['default_value'] = stringValue;
            break;
          case 'number':
            textControllersNumberNotifier[i]?.updateText(stringValue);
            dataModuleConfig![i]['default_value'] = stringValue;
            break;
          case 'calendar':
            textControllersCalendarNotifier[i]?.updateText(stringValue);
            dataModuleConfig![i]['default_value'] = stringValue;
            break;
          case 'datetime':
            textControllersDatetime[i]?.text = stringValue;
            dataModuleConfig![i]['default_value'] = stringValue;
            break;
          case 'checkbox':
            if (value is Map<String, bool>) {
              checkboxControllers[i]?.value = value;
            }
            break;
          case 'dropdown':
          case 'dropdown_advance':
          case 'status':
            dropdownControllers[i]?.value = stringValue;
            break;
          case 'radio':
            radioButtonControllers[i]?.value = stringValue;
            break;
          case 'boolean':
            booleanControllers[i]?.updateValue(value == true || value == 'true');
            break;
          default:
            break;
        }
        return;
      }
    }
  }

  String get _watermarkModuleName {
    final moduleSlug = widget.moduleName?.toString().trim() ?? '';
    if (moduleSlug.isEmpty) return '';

    for (final module in FFAppState().moduleList) {
      if (module is Map<String, dynamic>) {
        final name = module['name']?.toString().trim() ?? '';
        if (name == moduleSlug) {
          final label = module['label']?.toString().trim() ?? '';
          if (label.isNotEmpty) return label;
        }
      } else if (module is Map) {
        final name = module['name']?.toString().trim() ?? '';
        if (name == moduleSlug) {
          final label = module['label']?.toString().trim() ?? '';
          if (label.isNotEmpty) return label;
        }
      }
    }

    return moduleSlug;
  }

  List<Map<String, dynamic>> transformData(List<dynamic> rawData) {
    List<Map<String, dynamic>> transformedData = rawData.map((item) {
      // Procesar opciones
      List<dynamic> options = [];
      String? relationsFormula;
      if (item["options"] != null) {
        if (item['field_type'] == 'external_value' ||
            item['field_type'] == 'mercadopago') {
          options = item['options'];
        } else {
          options = (item["options"] as String)
              .split(',')
              .map((e) => e.trim())
              .toList();
        }
      }

      if (item['is_relational'] == true) {
        options = [item["relations_type"], item["related_module"].toString()];
        relationsFormula = item['relations_formula'];
        relationalFields.add(item);
      }

      if (item['field_type'] == 'repeater') {
        dynamic repeatersRaw = item['repeaters_item'];
        List<dynamic> repeatersItems = [];
        if (repeatersRaw is String && repeatersRaw.isNotEmpty) {
          try {
            repeatersItems = jsonDecode(repeatersRaw);
          } catch (_) {
            repeatersItems = [];
          }
        } else if (repeatersRaw is List) {
          repeatersItems = repeatersRaw;
        }
        repeatersItems = repeatersItems.map((repeaterItem) {
          if (repeaterItem is Map<String, dynamic>) {
            if (repeaterItem['field_type'] == 'firma') {
              repeaterItem['rol_sign'] = repeaterItem['rol_sign'] ?? repeaterItem['field_rol_sign'] ?? [];
            }
          }
          return repeaterItem;
        }).toList();
        options = repeatersItems;
      }

      if (item['field_type'] == 'image_view') {
        options = item['image_url'] ?? [];
      }

      // Definir slug
      String slug = item['slug'];

      return {
        "label": item["label"],
        "slug": slug,
        "default_value": '',
        "options": options,
        "field_type": item["field_type"],
        "module": item["module"],
        'relations_formula': relationsFormula,
        "inherited_fields": item["inherited_fields"],
        "is_relational": item["is_relational"] ?? false,
        "relations_type": item["relations_type"],
        "related_module": item["related_module"],
        "related_module_name": item["related_module_name"],
        "conditional_value": item["conditional_value"]?.toString() ?? '',
      };
    }).toList();

    // Insertar elemento inicial
    transformedData.insert(0, {
      "label": "Titulo",
      "slug": "titulo",
      "default_value": "",
      "options": null,
      "field_type": "text",
      "module":
          transformedData.isNotEmpty ? transformedData[0]["module"] : null,
    });

    setState(() => isLoading = false);

    return transformedData;
  }

  void generateJsonConfigToSend() {
    if (dataModuleConfig!.isEmpty) {
      return;
    }

    // Preservar json_data existente para no perder valores de campos sin controller (external_value, etc.)
    final existingJsonData = jsonConfigToSend["json_data"] is Map
        ? Map<String, dynamic>.from(jsonConfigToSend["json_data"])
        : <String, dynamic>{};

    jsonConfigToSend = {
      "title": dataModuleConfig!.isNotEmpty
          ? dataModuleConfig![0]["label"]
          : (widget.moduleName ?? ""),
      "modulo":
          dataModuleConfig!.isNotEmpty ? dataModuleConfig![0]["module"] : null,
      "json_data": existingJsonData,
    };

    // Asegurar que todos los slugs existan (inicializar solo los faltantes)
    dataModuleConfig?.forEach((campo) {
      final slug = campo["slug"];
      if (!jsonConfigToSend["json_data"].containsKey(slug)) {
        jsonConfigToSend["json_data"][slug] = "";
      }
    });

    // Inicializar campos relacionales solo si aún no tienen valor estructurado
    for (var field in relationalFields) {
      String slug = field["slug"];
      final current = jsonConfigToSend["json_data"][slug];
      if (current == null || current == "" || current == '' || current is! Map) {
        if (field["relations_type"] == 'user') {
          jsonConfigToSend["json_data"][slug] = {
            "type": field["relations_type"],
            "label": "",
            "value": "",
            "avatar": "",
            "full_name": ""
          };
        } else {
          jsonConfigToSend["json_data"][slug] = {
            "type": field["relations_type"],
            "label": '',
            "value": '',
            "module": field["related_module"]
          };
        }
      }
    }

    setState(() {});
  }

  void orderJsonToSend() {
    orderedJsonConfigToSend = Map.from(jsonConfigToSend);

    if (orderedJsonConfigToSend["json_data"] != null) {
      orderedJsonConfigToSend["json_data"].remove("titulo");
    }
    if (dataModuleConfig != null && dataModuleConfig!.isNotEmpty) {
      orderedJsonConfigToSend["modulo"] = dataModuleConfig![0]["module"];
    }
  }

  Future<void> updateJsonConfigToSend() async {
    generateJsonConfigToSend();

    for (int index = 0; index < dataModuleConfig!.length; index++) {
      String slug = dataModuleConfig![index]['slug'];
      final type = dataModuleConfig![index]['field_type'];

      jsonConfigToSend["title"] =
          textControllersNotifierTextField[0]?.value ?? '';

      switch (type) {
        case 'text':
          //print('$index TEXT $slug , ${textControllersNotifierTextField[index]?.value}');
          if (textControllersNotifierTextField.containsKey(index)) {
            if (jsonConfigToSend["json_data"] == null) {
              jsonConfigToSend["json_data"] = {};
            }
            jsonConfigToSend["json_data"][slug] =
                textControllersNotifierTextField[index]?.value ?? '';
          }
          break;
        case 'textarea':
          if (textControllersNotifierTextArea.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                textControllersNotifierTextArea[index]?.value ?? '';
          }
          break;
        case 'number':
          if (textControllersNumberNotifier.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                textControllersNumberNotifier[index]?.value!;
          }
          break;
        case 'calendar':
          if (textControllersCalendarNotifier.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                (textControllersCalendarNotifier[index]!.value != 'Sin fecha' &&
                        textControllersCalendarNotifier[index]!.value != "")
                    ? dateTimeFormat(
                        'yyyy-MM-dd',
                        DateTime.parse(
                            textControllersCalendarNotifier[index]!.value))
                    : '';
          }
          break;
        case 'datetime':
          if (textControllersDatetime.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                (textControllersDatetime[index]!.text != 'Sin fecha' &&
                        textControllersDatetime[index]!.text != "")
                    ? dateTimeFormat('yyyy-MM-ddThh:mm',
                        DateTime.parse(textControllersDatetime[index]!.text))
                    : '';
          }
        case 'checkbox':
          if (checkboxControllers.containsKey(index)) {
            Map<String, bool>? checkboxValues =
                checkboxControllers[index]?.value;
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
          if (dropdownControllers.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                dropdownControllers[index]?.value ?? '';
          }
          break;
        case 'status':
          if (dropdownControllers.containsKey(index)) {
            if (jsonConfigToSend["json_data"] == null) {
              jsonConfigToSend["json_data"] = {};
            }
            jsonConfigToSend["json_data"][slug] =
                dropdownControllers[index]?.value ?? '';
          }
          break;
        case 'radio':
          if (radioButtonControllers.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                radioButtonControllers[index]?.value ?? '';
          }
          break;
        case 'image':
          if (fileControllers.containsKey(index)) {
            String encodeImage;
            String imgSend = 'data:image/jpg;base64,';
            if (fileControllers[index]?.bytes?.isNotEmpty == true) {
              encodeImage =
                  base64Encode(fileControllers[index]!.bytes!.toList()) ?? '';
              imgSend += encodeImage;
              slug = '$slug';
              jsonConfigToSend["json_data"][slug] = imgSend;
            }
          }
          break;
        case 'file':
          if (fileControllers.containsKey(index)) {
            String encodeImage;
            String imgSend = 'data:application/pdf;base64,';
            if (fileControllers[index]?.bytes?.isNotEmpty == true) {
              encodeImage =
                  base64Encode(fileControllers[index]!.bytes!.toList()) ?? '';
              imgSend += encodeImage;
              slug = '$slug';
              jsonConfigToSend["json_data"][slug] = imgSend;
            }
          }
          break;
        case 'relational':
          if (relationalControllers.containsKey(index)) {
            String fullText =
                relationalControllers[index]?.textController.text ?? '';
            // Usamos una expresiÃ³n regular para capturar el texto antes del guion
            RegExp regExp = RegExp(r'^(\S+)\s*-');
            Match? match = regExp.firstMatch(fullText);
            String extractedText = match != null ? match.group(1) ?? '' : '';

            if (jsonConfigToSend["json_data"] != null &&
                jsonConfigToSend["json_data"][slug] != null &&
                jsonConfigToSend["json_data"][slug]["label"] != null) {
              jsonConfigToSend["json_data"][slug]["label"] = fullText;
            } else {}
            if (jsonConfigToSend["json_data"] != null &&
                jsonConfigToSend["json_data"][slug] != null &&
                jsonConfigToSend["json_data"][slug]["value"] != null) {
              jsonConfigToSend["json_data"][slug]["value"] = extractedText;
            } else {}

            if (jsonConfigToSend["json_data"][slug]["type"] == 'user') {}
          }
          break;
        case 'multiple_relational_select':
          // El valor ya se mantiene en jsonConfigToSend desde onChanged
          break;
        case 'calculator':
          jsonConfigToSend["json_data"][slug] =
              textControllersCalculator[index]?.text ?? '';
          break;
        case 'repeater':
          // final fieldId = '$index-${campo['slug']}';
          final fieldId = '$index-$slug';

          jsonConfigToSend["json_data"][slug] =
              repeaterKeys[fieldId]?.currentState?.updateJsonRepeater() ?? [];
          break;
        case 'formato':
          //jsonConfigToSend["json_data"][slug] = _formatoKey[index].currentState?.updateJsonFormato();
          break;
        case 'firma':
          if (firmaControllers[index]?.containsKey('firmado') == true &&
              firmaControllers[index]?['firmado'] == true) {
            jsonConfigToSend["json_data"][slug] = FFAppState().firma;
          } else {
            jsonConfigToSend["json_data"][slug] = '';
          }
          break;
        case 'firmaext':
          if (signatureControllers.containsKey(index)) {
            String b64Sign =
                functions.isSignatureEmpty(signatureControllers[index]!)
                    ? ''
                    : await functions
                        .convertSignToB64(signatureControllers[index]!);
            jsonConfigToSend["json_data"][slug] = b64Sign;
          }
          break;
        case 'boolean':
          jsonConfigToSend["json_data"][slug] =
              booleanControllers[index]?.value ?? false;
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
    }

    /* dataModuleConfig?.asMap().forEach((index, campo) async {
      var slug = campo['slug'];
      final type = campo['field_type'];




    });*/

    orderJsonToSend();
  }

  @override
  void initState() {
    _model = createModel(context, () => NewRegistersModulesModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      moduleConfig = await GetCustomFieldsPerModuleCall.call(
        tenant: FFAppState().organizacion,
        moduleName: widget.moduleName,
        token: FFAppState().token,
      );

      List<dynamic>? rawData = getJsonField(
        (moduleConfig?.jsonBody ?? ''),
        r'''$.data''',
      );

      if (rawData != null) {
        setState(() {
          dataModuleConfig = transformData(rawData);
        });
        generateJsonConfigToSend();
        _reEvaluateVisibility();
      }
    });

    super.initState();
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

    // Agrega el texto restante despuÃ©s de la Ãºltima coincidencia
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  void getController(typeField, fieldIndex, campo, fieldId) {
    final slug = campo['slug']?.toString() ?? '';
    switch (typeField) {
      case 'text':
        {
          final wasNew = !textControllersNotifierTextField.containsKey(fieldIndex);
          textControllersNotifierTextField[fieldIndex] ??= TextControllerNotifier(campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersNotifierTextField[fieldIndex]!.addListener(() {
              _updateJsonData(slug, textControllersNotifierTextField[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'textarea':
        {
          final wasNew = !textControllersNotifierTextArea.containsKey(fieldIndex);
          textControllersNotifierTextArea[fieldIndex] ??= TextAreaControllerNotifier(campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersNotifierTextArea[fieldIndex]!.addListener(() {
              _updateJsonData(slug, textControllersNotifierTextArea[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'calendar':
        {
          final wasNew = !textControllersCalendarNotifier.containsKey(fieldIndex);
          textControllersCalendarNotifier[fieldIndex] ??= TextControllerNotifier(campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersCalendarNotifier[fieldIndex]!.addListener(() {
              _updateJsonData(slug, textControllersCalendarNotifier[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'datetime':
        {
          final wasNew = !textControllersDatetime.containsKey(fieldIndex);
          textControllersDatetime[fieldIndex] ??= TextEditingController(text: campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersDatetime[fieldIndex]!.addListener(() {
              _updateJsonData(slug, textControllersDatetime[fieldIndex]!.text);
            });
          }
        }
        // intentional fallthrough
      case 'number':
        {
          final wasNew = !textControllersNumberNotifier.containsKey(fieldIndex);
          textControllersNumberNotifier[fieldIndex] ??= TextControllerNotifier(campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersNumberNotifier[fieldIndex]!.addListener(() {
              _updateJsonData(slug, textControllersNumberNotifier[fieldIndex]!.value);
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FFAppState().addToTextoControlador(campo["slug"], textControllersNumberNotifier[fieldIndex]!);
          });
        }
        break;
      case 'checkbox':
        {
          final wasNew = !checkboxControllers.containsKey(fieldIndex);
          if (campo['data'] is String) {
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
            checkboxControllers[fieldIndex] ??= FormFieldController<Map<String, bool>>(checkboxData);
          } else {
            checkboxControllers[fieldIndex] ??= FormFieldController<Map<String, bool>>({});
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
          dropdownControllers[fieldIndex] ??= FormFieldController<String>(campo['default_value']);
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
          dropdownControllers[fieldIndex] ??= FormFieldController<String>(campo['default_value']);
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
          radioButtonControllers[fieldIndex] ??= FormFieldController<String>(campo['data']);
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
        fileControllers[fieldIndex] ??= FFUploadedFile(bytes: Uint8List.fromList([]));
        break;
      case 'status':
        {
          final wasNew = !dropdownControllers.containsKey(fieldIndex);
          dropdownControllers[fieldIndex] ??= FormFieldController<String>(campo['data']);
          if (wasNew) {
            dropdownControllers[fieldIndex]!.addListener(() {
              _updateJsonData(slug, dropdownControllers[fieldIndex]!.value);
            });
          }
        }
        break;
      case 'relational':
        {
          final wasNew = !relationalControllers.containsKey(fieldIndex);
          final rConfig = RelationalFieldConfig.fromRawConfig(Map<String, dynamic>.from(campo));
          relationalControllers[fieldIndex] ??= RelationalController(
            textController: TextEditingController(text: ''),
            relationalLabel: '',
            relationalValue: 0,
            type: rConfig.relationType,
            module: rConfig.relatedModuleId,
            moduleName: rConfig.relatedModuleName,
            relationalAvatar: '',
            relationalFullName: '',
            relationsFormula: campo['relations_formula'],
            fieldConfig: rConfig,
          );
          if (wasNew) {
            relationalControllers[fieldIndex]!.textController.addListener(() {
              _updateJsonData(slug, relationalControllers[fieldIndex]!.textController.text);
            });
          }
        }
        break;
      case 'calculator':
        {
          final wasNew = !textControllersCalculator.containsKey(fieldIndex);
          textControllersCalculator[fieldIndex] ??= TextEditingController(text: campo['data']?.toString() ?? '');
          if (wasNew) {
            textControllersCalculator[fieldIndex]!.addListener(() {
              _updateJsonData(slug, textControllersCalculator[fieldIndex]!.text);
            });
          }
        }
        break;
      case 'repeater':
        if (!repeaterKeys.containsKey(fieldId)) {
          repeaterKeys[fieldId] = GlobalKey<DefaultRepeaterWidgetState>();
        }
        break;
      case 'firma':
        firmaControllers[fieldIndex] ??= {
          'firmado': (campo['data'].toString() != '' && campo['data'] != null)
              ? true
              : false,
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
        booleanControllers[fieldIndex] ??= BooleanControllerNotifier(false);
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _jsonDataDebounceTimer?.cancel();
    for (var controller in textControllersNotifierTextField.values) {
      controller.dispose();
    }

    for (var controller in textControllersNotifierTextArea.values) {
      controller.dispose();
    }

    for (var controller in textControllersCalendarNotifier.values) {
      controller.dispose();
    }

    for (var controller in textControllersNumber.values) {
      controller.dispose();
    }

    for (var controller in checkboxControllers.values) {
      controller.dispose();
    }

    for (var controller in dropdownControllers.values) {
      controller.dispose();
    }

    for (var controller in radioButtonControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Widget Function(BuildContext, Map<String, dynamic>, int, String)
      getFieldWidget(String typeField) {
    final Map<String,
            Widget Function(BuildContext, Map<String, dynamic>, int, String)>
        fieldWidgets = {
      'text': (context, campo, index, fieldId) => DefaultTextFieldWidget(
            text: campo['default_value'],
            isEdit: true,
            controllerNotifier: textControllersNotifierTextField[index]!,
            type: campo["field_type"],
            slug: campo["slug"],
          ),
      'text_view': (context, campo, index, fieldId) => Container(
            padding: EdgeInsetsDirectional.fromSTEB(30, 10, 30, 10),
            child: RichText(
              text: TextSpan(
                children:
                    parseTextWithFormatting(campo['options']?.toString() ?? ''),
                style: DefaultTextStyle.of(context).style,
              ),
            ),
          ),
      'image_view': (context, campo, index, fieldId) => Container(
            padding: EdgeInsetsDirectional.fromSTEB(30, 10, 30, 10),
            child: Align(
              alignment: AlignmentDirectional(0, 0),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: AlignmentDirectional(0, 0),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(12),
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
                                  'https://${FFAppState().organizacion}.itsquery.com${campo["options"]}',
                                  fit: BoxFit.contain,
                                ),
                                allowRotation: false,
                                tag:
                                    'https://${FFAppState().organizacion}.itsquery.com${campo["options"]}',
                                useHeroAnimation: true,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag:
                              'https://${FFAppState().organizacion}.itsquery.com${campo["options"]}',
                          transitionOnUserGestures: true,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://${FFAppState().organizacion}.itsquery.com${campo["options"]}',
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // Align(
                      //     alignment: AlignmentDirectional(0, 0),
                      //     child: Text(
                      //       'Sin Imagen',
                      //       style:
                      //       FlutterFlowTheme.of(context).bodyMedium.override(
                      //         fontFamily: 'Outfit',
                      //         fontSize: 16,
                      //         letterSpacing: 0,
                      //         fontWeight: FontWeight.w500,
                      //         color:
                      //         FlutterFlowTheme.of(context).primary,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      'textarea': (context, campo, index, fieldId) => DefaultTextAreaWidget(
            text: campo['default_value'],
            isEdit: true,
            controllerNotifier: textControllersNotifierTextArea[index]!,
          ),
      'status': (context, campo, index, fieldId) => DefaultStatusWidget(
          text: campo['default_value'],
          options: campo['options'],
          isEdit: true,
          controller: dropdownControllers[index]!,
          onChanged: () {}),
      'number': (context, campo, index, fieldId) => DefaultTextFieldWidget(
            text:
                (campo['default_value'] != null) ? campo['default_value'] : '',
            isEdit: true,
            controllerNotifier: textControllersNumberNotifier[index]!,
            type: campo["field_type"],
            slug: campo["slug"],
          ),
      'dropdown': (context, campo, index, fieldId) => CreatableDropdown(
            text: campo['default_value'],
            options: campo['options']?.toList() ?? [],
            isEdit: true,
            controller: dropdownControllers[index]!,
            jsonData: orderedJsonConfigToSend.isNotEmpty
                ? orderedJsonConfigToSend[0]["json_data"] ?? {}
                : {},
            slug: campo["slug"],
          ),
      'dropdown_advance': (context, campo, index, fieldId) => CreatableDropdownAdvance(
            text: campo['default_value'],
            options: campo['options']?.toList() ?? [],
            isEdit: true,
            controller: dropdownControllers[index]!,
            jsonData: orderedJsonConfigToSend.isNotEmpty
                ? orderedJsonConfigToSend[0]["json_data"] ?? {}
                : {},
            slug: campo["slug"],
          ),
      'radio': (context, campo, index, fieldId) => DefaultTextRadioButtonWidget(
            text: campo['default_value'],
            options: campo['options'].toList(),
            isEdit: true,
            controller: radioButtonControllers[index]!,
            onChanged: (val) {},
          ),
      'checkbox': (context, campo, index, fieldId) => DefaultCheckboxWidget(
            text: campo['default_value'],
            options: campo['options'].toList(),
            isEdit: true,
            controller: checkboxControllers[index]!,
          ),
      'calendar': (context, campo, index, fieldId) => DefaultCalendarWidget(
            text: campo['default_value'],
            isEdit: true,
            controllerNotifier: textControllersCalendarNotifier[index]!,
          ),
      'datetime': (context, campo, index, fieldId) => DefaultDateTimeWidget(
            text: campo['default_value'],
            controller: textControllersDatetime[index]!,
            isEdit: true,
          ),
      'image': (context, campo, index, fieldId) => DefaultNewImageWidget(
            text: campo['default_value'] ?? '',
            isEdit: true,
            controller: fileControllers[index]!,
            watermarkUser: FFAppState().fullName,
            watermarkModule: _watermarkModuleName,
            onFileSelected: (selectedFile) {
              setState(() {
                fileControllers[index] = selectedFile;
              });
            },
          ),
      'file': (context, campo, index, fieldId) => DefaultFilePdfWidget(
            controller: fileControllers[index]!,
            isEdit: true,
            pdfUrl: campo["default_value"],
            onFileSelected: (selectedFile) {
              setState(() {
                fileControllers[index] = selectedFile;
              });
            },
          ),
      'relational': (context, campo, index, fieldId) => RelationalWidget(
          text: 'Selecciona un ',
          controller: relationalControllers[index]!,
          isEdit: true,
          options: campo['options'] != null
              ? List<String>.from(
                  campo['options'].map((item) => item.toString()))
              : null,
          config: (campo['relationalConfig'] as RelationalFieldConfig?) ??
              RelationalFieldConfig.fromRawConfig(Map<String, dynamic>.from(campo)),
          inheritedFields: campo['inherited_fields']?.toString(),
          onBatchUpdate: (updates) {
            setState(() {
              final newMap = Map<String, dynamic>.from(jsonConfigToSend["json_data"] ?? {});
              for (final entry in updates.entries) {
                newMap[entry.key] = entry.value;
              }
              jsonConfigToSend["json_data"] = newMap;
            });
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
          }),
      'multiple_relational_select': (context, campo, index, fieldId) => RelationalField(
            field: campo,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            isEdit: true,
            isUpdate: false,
            onChanged: (slug, value, idx, mainSlug) {
              setState(() {
                final newMap = Map<String, dynamic>.from(jsonConfigToSend["json_data"] ?? {});
                newMap[slug] = value;
                jsonConfigToSend["json_data"] = newMap;
              });
            },
            onBatchUpdate: (updates, {index, mainSlug}) {
              setState(() {
                final newMap = Map<String, dynamic>.from(jsonConfigToSend["json_data"] ?? {});
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
            text: campo['default_value'],
            isEdit: false,
            controller: textControllersCalculator[index]!,
            options: campo['options'].toString(),
            idRegister: '0',
          ),
      'repeater': (context, campo, index, fieldId) => DefaultRepeaterWidget(
          key: repeaterKeys[fieldId],
          data: '',
          isEdit: true,
          options: campo['options'],
          watermarkUser: FFAppState().fullName,
          watermarkModule: _watermarkModuleName,
          idRegister: '0',
          repeaterSlug: campo['slug']?.toString(),
          updateJsonRepeater: (jsonRepeater) {
            safeSetState(() {
              jsonRepeaterToSend = jsonRepeater;
            });
          },
          onChanged: ((value, changeIndex) {})),
      'firma': (context, campo, index, fieldId) => DefaultFirmaWidget(
            text: campo['default_value'],
            isEdit: true,
            controller: firmaControllers[index]!,
            rolSign: const [],
          ),
      'firmaext': (context, campo, index, fieldId) => DefaultFirmaExt(
          controller: signatureControllers[index]!,
          isEdit: true,
          text: campo['default_value'],
          height: 150,
          width: MediaQuery.sizeOf(context).width * 1.0,
          onSignatureChanged: (base64Signature) {
            print(' [DEBUG] Firma externa dibujada para index $index');
          },
        ),
      'formato': (context, campo, index, fieldId) => DefaultFormatoWidget(
            text: campo['default_value'],
          ),
      'text_editor': (context, campo, index, fieldId) => DefaultRichTextWidget(
            key: richTextKeys[fieldId],
            text: campo['default_value'],
            isEdit: true,
            controller: richTextControllers[index]!,
          ),
      'boolean': (context, campo, index, fieldId) => DefaultBooleanWidget(
            text: campo['default_value'],
            isEdit: true,
            controllerNotifier: booleanControllers[index]!,
          ),
      'external_value': (context, campo, index, fieldId) => ExternalValueField(
            field: campo,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
              _updateJsonData(slug, value);
            },
          ),
      'mercadopago': (context, campo, index, fieldId) => MercadoPagoField(
            field: campo,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
              _updateJsonData(slug, value);
            },
            moduleName: widget.moduleName ?? '',
            recordId: widget.general is Map ? widget.general['id'] : null,
            recordType: widget.moduleType ?? 'register',
            onlyView: false,
            canEdit: true,
          ),
    };

    return fieldWidgets[typeField] ??
        ((context, campo, index, fieldId) => ListTile(
              title: Text(campo['label']),
              subtitle: Text(campo['default_value'] ?? ''),
            ));
  }

  Future<void> _submitCreate() async {
    final isDisabled = isDisabledButton.value;
    if (isDisabled) return;

    isDisabledButton.value = true;

    await updateJsonConfigToSend();

    debugPrint('=== SUBMIT CREATE === orderedJsonConfigToSend=${jsonEncode(orderedJsonConfigToSend)}');

    if (validateTextField(textControllersNotifierTextField[0]?.value) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Â¡El campo tÃ­tulo no puede estar vacÃ­o, mÃ­nimo 3 caracteres!',
            style: TextStyle(color: FlutterFlowTheme.of(context).white),
          ),
          duration: const Duration(milliseconds: 6000),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      isDisabledButton.value = false;
      return;
    }

    final bodyJson = jsonEncode(orderedJsonConfigToSend);

    ApiCallResponse? postResult = await PostNewRegister.call(
      tenant: FFAppState().organizacion,
      moduleName: widget.moduleName,
      moduleType: widget.moduleType,
      token: FFAppState().token,
      body: bodyJson,
    );

    debugPrint('=== SUBMIT CREATE === postResult status=${postResult.statusCode} body=${postResult.jsonBody}');

    if ((postResult.statusCode).toString() == '400') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Algo saliÃ³ mal al crear el registro, intentalo de nuevo. ${postResult.jsonBody}',
            style: TextStyle(color: FlutterFlowTheme.of(context).white),
          ),
          duration: const Duration(milliseconds: 6000),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      isDisabledButton.value = false;
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Â¡Registro creado!',
          style: TextStyle(color: FlutterFlowTheme.of(context).white),
        ),
        duration: const Duration(milliseconds: 6000),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context, true);
      isDisabledButton.value = false;
    });
  }

  Widget _buildBottomStickyBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground, // blanco theme
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x22000000),
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
          child: ValueListenableBuilder<bool>(
            valueListenable: isDisabledButton,
            builder: (context, isDisabled, _) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isDisabled ? null : _submitCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    foregroundColor: FlutterFlowTheme.of(context).white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isDisabled
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Guardar',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w600,
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bottomLeftColor = const Color(0xFFD7D7D7).withOpacity(0.98);
    final Color topRightColor = FlutterFlowTheme.of(context).primary;

    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        bottomNavigationBar: _buildBottomStickyBar(context),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          iconTheme: IconThemeData(color: FlutterFlowTheme.of(context).primary),
          automaticallyImplyLeading: true,
          toolbarHeight: 74.0,
          title: Align(
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Creación para',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  _watermarkModuleName.isNotEmpty
                      ? _watermarkModuleName
                      : (widget.moduleName ?? ''),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        color: FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 5.0, 5.0),
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary,
                      shape: BoxShape.circle,
                    ),
                    child: Align(
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: Text(
                        functions.getShortName(FFAppState().fullName),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Outfit',
                              color: FlutterFlowTheme.of(context).white,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          centerTitle: true,
          elevation: 1.0,
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              // Fondo (igual que SinglePageWidget)
              Positioned.fill(
                child: DynamicBackground(
                  bottomLeftColor: bottomLeftColor,
                  topRightColor: topRightColor,
                ),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      isLoading == true
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).primary),
                              ),
                            )
                          : Container(
                              height: MediaQuery.sizeOf(context).height * 0.89,
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(0, 0, 0, 100),
                              child: ListView.builder(
                                shrinkWrap: false,
                                primary: false,
                                itemCount: dataModuleConfig?.length,
                                itemBuilder: (context, index) {
                                  final campo = dataModuleConfig?[index];
                                  if (campo == null) return const SizedBox.shrink();
                                  final slug = campo['slug']?.toString() ?? '';
                                  final isVisible = _fieldVisibility[slug] ?? true;
                                  if (!isVisible) return const SizedBox.shrink();

                                  final typeField = campo["field_type"];
                                  final widgetBuilder =
                                      getFieldWidget(typeField);
                                  final fieldId = '$index-${campo['slug']}';

                                  getController(
                                      typeField, index, campo, fieldId);

                                  if (widgetBuilder != null) {
                                    return AnimatedSize(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: Column(
                                        children: [
                                          Container(
                                            width:
                                                MediaQuery.sizeOf(context).width,
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context)
                                                  .primaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(0.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  blurRadius: 8.0,
                                                  color: Color(0x33000000),
                                                  offset: Offset(
                                                    1.0,
                                                    1.0,
                                                  ),
                                                  spreadRadius: 1.0,
                                                )
                                              ],
                                            ),
                                            alignment: const AlignmentDirectional(
                                                0.0, 0.0),
                                            child: Padding(
                                              padding: const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                  30.0, 20.0, 30.0, 20.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    campo['label'],
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Outfit',
                                                          letterSpacing: 0.0,
                                                          fontSize: 16,
                                                          color:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primaryText,
                                                        ),
                                                  ),
                                                  widgetBuilder(context, campo,
                                                      index, fieldId),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                      SizedBox(height: 20),
                    ].addToEnd(SizedBox(height: 20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



