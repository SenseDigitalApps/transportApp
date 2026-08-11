import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:transport_app/components/certificadora_modal/certificadora_modal_widget.dart';
import 'package:transport_app/components/default_repeater/default_repeater_widget.dart';
import 'package:transport_app/components/default_text_radio_button/default_text_radio_button_model.dart';
import 'package:transport_app/components/empty_component/empty_component_widget.dart';
import 'package:signature/signature.dart';
import '../../components/default_firma/default_firma_widget.dart';
import '../../components/default_firmaext/default_firmaext_widget.dart';
import '../../components/default_formato/default_formato_widget.dart';
import '../../components/searcher_widget.dart';
import '../../flutter_flow/flutter_flow_expanded_image_view.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';
import '../../flutter_flow/form_field_controller.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'detail_model.dart';
export 'detail_model.dart';
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
import 'package:transport_app/components/default_new_image/default_new_image_widget.dart';
import 'package:transport_app/components/default_text_radio_button/default_text_radio_button_widget.dart';
import 'package:transport_app/components/default_relational/default_relational_widget.dart';
import 'package:transport_app/components/default_relational/relational_field.dart';
import 'package:transport_app/components/default_relational/relational_field_config.dart';
import 'package:transport_app/components/default_file_pdf/default_file_pdf_widget.dart';
import 'package:transport_app/components/default_datetime/default_datetime_widget.dart';
import 'package:transport_app/components/default_calculator/default_calculator_widget.dart';
import 'package:transport_app/components/mercado_pago_field/mercado_pago_field.dart';
import '../../controllers/field_controllers.dart';
import '../../utils/evaluate_condition.dart';

class DetailWidget extends StatefulWidget {
  const DetailWidget({
    super.key,
    this.title,
    String? body,
    this.general,
  }) : body = body ?? 'No data';

  final String? title;
  final String body;
  final dynamic general;

  @override
  State<DetailWidget> createState() => _DetailWidgetState();
}

class _DetailWidgetState extends State<DetailWidget> {
  late DetailModel _model;

  String? _safeModuleLabel(dynamic general) {
    if (general is Map) {
      final mi = general['modulo_info'];
      if (mi is Map) {
        return mi['label']?.toString();
      }
    }
    return null;
  }
  List<dynamic>? moduleConfig = [];
  List<Map<String, dynamic>> campos = [];
  Map<String, dynamic> jsonConfigToSend = {};
  List<Map<String, dynamic>> jsonRepeaterToSend = [];
  bool canEdit = false;
  bool isLoading = true;

  //Controladores
  Map<int, TextControllerNotifier> textControllersNotifierTextField = {};
  Map<int, TextAreaControllerNotifier> textControllersNotifierTextArea = {};

  Map<int, TextEditingController> textControllersTextField = {};
  Map<int, TextEditingController> textControllersTextArea = {};
  Map<int, TextEditingController> textControllersCalendar = {};
  Map<int, TextEditingController> textControllersDatetime = {};
  Map<int, TextEditingController> textControllersNumber = {};
  Map<int, FormFieldController<Map<String, bool>>> checkboxControllers = {};
  Map<int, FormFieldController<String>> dropdownControllers = {};
  Map<int, FormFieldController<String>> radioButtonControllers = {};
  Map<int, FFUploadedFile> fileControllers = {};
  Map<int, RelationalController> relationalControllers = {};
  Map<int, TextEditingController> textControllersCalculator = {};
  Map<int, SignatureController> signatureControllers = {};
  Map<int, Map<String, dynamic>> firmaControllers = {};

  TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> camposFiltrados = [];

  final GlobalKey<DefaultRepeaterWidgetState> _repeaterKey =
      GlobalKey<DefaultRepeaterWidgetState>();
  final List<GlobalKey<DefaultRepeaterWidgetState>> _repeaterKeys = [];
  Timer? _jsonDataDebounceTimer;

  void _updateJsonData(String slug, dynamic value) {
    _jsonDataDebounceTimer?.cancel();
    _jsonDataDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          final newJsonData = Map<String, dynamic>.from(jsonConfigToSend["json_data"] ?? {});
          newJsonData[slug] = value;
          jsonConfigToSend["json_data"] = newJsonData;
        });
      }
    });
  }

  void _updateControllerBySlug(String slug, dynamic value) {
    for (int i = 0; i < camposFiltrados.length; i++) {
      if (camposFiltrados[i]['slug'] == slug) {
        final type = camposFiltrados[i]['type'];
        final stringValue = value?.toString() ?? '';
        switch (type) {
          case 'text':
            textControllersNotifierTextField[i]?.updateText(stringValue);
            camposFiltrados[i]['data'] = stringValue;
            break;
          case 'textarea':
            textControllersNotifierTextArea[i]?.updateText(stringValue);
            camposFiltrados[i]['data'] = stringValue;
            break;
          case 'number':
            textControllersNotifierTextField[i]?.updateText(stringValue);
            camposFiltrados[i]['data'] = stringValue;
            break;
          case 'calendar':
            textControllersCalendar[i]?.text = stringValue;
            camposFiltrados[i]['data'] = stringValue;
            break;
          case 'datetime':
            textControllersDatetime[i]?.text = stringValue;
            camposFiltrados[i]['data'] = stringValue;
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
          default:
            break;
        }
        return;
      }
    }
  }

  void _filterFields(String text) {
    final jsonData = jsonConfigToSend['json_data'] is Map
        ? Map<String, dynamic>.from(jsonConfigToSend['json_data'] as Map)
        : <String, dynamic>{};
    final conditionContext = ConditionContext(
      currentUserRole: FFAppState().role,
      currentUserRoles: FFAppState().roleGroups
          .map((r) => r is String ? r : r.toString())
          .toList(),
    );
    setState(() {
      if (text.isEmpty) {
        camposFiltrados = campos.where((campo) {
          final cond = campo['conditional_value']?.toString() ?? '';
          if (cond.isEmpty) return true;
          return evaluateConditions(cond, jsonData, field: campo, context: conditionContext);
        }).toList();
      } else {
        camposFiltrados = campos
                .where(
                  (campo) =>
                      campo['label'].toLowerCase().contains(text.toLowerCase()),
                )
                .where((campo) {
                  final cond = campo['conditional_value']?.toString() ?? '';
                  if (cond.isEmpty) return true;
                  return evaluateConditions(cond, jsonData, field: campo, context: conditionContext);
                })
                .toList() ??
            [];
      }
    });
  }

  void joinObjects() {
    print(' [DEBUG] ========== joinObjects START ==========');
    print(' [DEBUG] widget.general: ${widget.general}');
    setState(() {
      isLoading = true;
    });

    print(' [DEBUG joinObjects] widget.general json_data keys: ${widget.general["json_data"]?.keys?.toList()}');
    print(' [DEBUG joinObjects] widget.general json_data: ${widget.general["json_data"]}');

    moduleConfig = getJsonField(
      (_model.moduleConfig?.jsonBody ?? ''),
      r'''$.data''',
    );

    if (moduleConfig != null) {
      // Lista para almacenar los related_module
      List<int>? relatedModules = [];
      List<String> relationsTypes = [];

      // Lista para campos con field_type 'relational'
      List<Map<String, dynamic>> relationalFields = [];

      // Procesar campos del módulo
      campos = moduleConfig!.map((config) {
        String slug = config["slug"];
        dynamic data;

        print(' [DEBUG] Procesando campo: $slug (type: ${config["field_type"]})');
        print(' [DEBUG] json_data keys: ${widget.general["json_data"]?.keys?.toList()}');

        // Obtener el dato correspondiente según el slug (match exacto)
        String? matchingKey = widget.general["json_data"].keys.firstWhere(
          (key) => key.toString() == slug,
          orElse: () => '',
        );

        print(' [DEBUG] matchingKey para $slug: "$matchingKey"');

        if (matchingKey!.isNotEmpty) {
          data = widget.general["json_data"][matchingKey];
          print(' [DEBUG] data encontrada para $slug: $data (type: ${data.runtimeType})');
        } else {
          data = null;
          print(' [DEBUG] No se encontró data para $slug');
        }

        // Para firmaext: si no hay datos o es vacío, buscar con prefijo sign_ para datos de firma
        if (config["field_type"] == 'firmaext' && (data == null || data.toString().isEmpty)) {
          String signKey = 'sign_$slug';
          print(' [DEBUG] Buscando fallback sign_ para firmaext: $signKey');
          if (widget.general["json_data"].containsKey(signKey)) {
            data = widget.general["json_data"][signKey];
            print(' [DEBUG] Fallback encontrado para $signKey: $data');
          } else {
            print(' [DEBUG] No se encontró fallback para $signKey');
          }
        }

        // Para firmaext: si no hay datos o es vacío, buscar con prefijo sign_ para datos de firma
        if (config["field_type"] == 'firmaext' && (data == null || data.toString().isEmpty)) {
          String signKey = 'sign_$slug';
          print('🔍 [DEBUG] Buscando fallback sign_ para firmaext: $signKey');
          if (widget.general["json_data"].containsKey(signKey)) {
            data = widget.general["json_data"][signKey];
            print('🔍 [DEBUG] Fallback encontrado para $signKey: $data');
          } else {
            print('🔍 [DEBUG] No se encontró fallback para $signKey');
          }
        }

        List<dynamic> optionsList = [];
        if (config['options'] != null) {
          if (config['field_type'] == 'external_value' ||
              config['field_type'] == 'mercadopago') {
            optionsList = config['options'];
          } else {
            optionsList = (config["options"] as String)
                .split(',')
                .map((e) => e.trim())
                .toList();
          }
        } else if (config['is_relational'] == true) {
          dynamic value = '';
          dynamic module = config["related_module"];

          if (config["relations_type"] != 'user') {
            int moduleId = module is int ? module : int.tryParse(module?.toString() ?? '') ?? 0;
            if (value != null && moduleId != 0) {
              optionsList = [
                config["relations_type"],
                moduleId.toString(),
                (value.toString())
              ];
            }
          } else {
            if (value != null) {
              optionsList = [
                config["relations_type"],
                (value.toString()),
              ];
            }
          }
        }

        String parsedText = '';

        if (config['field_type'] != 'relational') {
          if (config['field_type'] == 'checkbox') {
            if (data != null) {
              Map<String, dynamic> checkboxData = data as Map<String, dynamic>;
              parsedText = checkboxData.entries
                  .map((entry) => '${entry.key}: ${entry.value}')
                  .join(', ');
            } else {
              data = {};
            }
          } else if (config["field_type"] == 'repeater') {
            parsedText = jsonEncode(data ?? '');
            dynamic repeatersRaw = config['repeaters_item'];
            if (repeatersRaw is String && repeatersRaw.isNotEmpty) {
              try {
                optionsList = jsonDecode(repeatersRaw);
              } catch (_) {
                optionsList = [];
              }
            } else if (repeatersRaw is List) {
              optionsList = repeatersRaw;
            } else {
              optionsList = [];
            }
          } else if (config["field_type"] == 'firma') {
            // Manejar firma: puede ser string (URL) o Map {url, name, datetime}
            print('🔍 [DEBUG] Procesando firma para $slug, data: $data');
            if (data is Map) {
              parsedText = jsonEncode(data);
              print('🔍 [DEBUG] firma parsedText (Map): $parsedText');
            } else if (data is String) {
              parsedText = data;
              print('🔍 [DEBUG] firma parsedText (String): $parsedText');
            } else {
              parsedText = '';
              print('🔍 [DEBUG] firma parsedText vacío');
            }
          } else if (config["field_type"] == 'firmaext') {
            // Manejar firmaext: puede ser string (URL de imagen) o Map {url, name, datetime}
            print('🔍 [DEBUG] Procesando firmaext para $slug, data: $data');
            if (data is Map) {
              // Si es Map, extraer URL de la imagen
              parsedText = data['url']?.toString() ?? '';
              print('🔍 [DEBUG] firmaext parsedText (Map url): $parsedText');
            } else if (data is String) {
              parsedText = data;
              print('🔍 [DEBUG] firmaext parsedText (String): $parsedText');
            } else {
              parsedText = '';
              print('🔍 [DEBUG] firmaext parsedText vacío');
            }
          } else {
            String newData = (data == null) ? '' : data;
            parsedText = functions.parseText(newData);
          }
        } else if (config["field_type"] == 'relational') {
          if (widget.general["json_data"][slug] != null ||
              widget.general["json_data"][slug] != '') {
            parsedText = widget.general["json_data"]?[slug]?["label"] ?? '';
          } else {
            parsedText = "";
          }
          relatedModules.add((config["related_module"] == null)
              ? 0
              : config["related_module"]);
          relationsTypes.add(config["relations_type"]);
          relationalFields.add(config);
        }

        return {
          "slug": slug,
          "type": config["field_type"],
          "data": parsedText,
          "label": config["label"],
          "options": optionsList,
          "inherited_fields": config["inherited_fields"],
          "is_relational": config["is_relational"] ?? false,
          "relations_type": config["relations_type"],
          "related_module": config["related_module"],
          "related_module_name": config["related_module_name"],
          "relations_formula": config["relations_formula"],
          "conditional_value": config["conditional_value"]?.toString() ?? '',
        };
      }).toList();

      campos.insert(0, {
        "slug": "title",
        "type": "text",
        "data": valueOrDefault<String>(
            getJsonField(widget.general, r'''$.title''').toString(), 'No data'),
        "label": "Title",
        "options": [],
      });

      // Construir el objeto jsonConfigToSend
      jsonConfigToSend = {
        "id": getJsonField(widget.general, r'''$.id'''),
        "title": '',
        "json_data": {},
        "modulo": widget.general["modulo_info"]["id"],
      };

      // Copiar valores reales del backend (preservar external_value, etc.)
      widget.general["json_data"].forEach((key, value) {
        jsonConfigToSend["json_data"][key] = value;
      });

      for (var field in relationalFields) {
        String slug = field["slug"];
        if (field["relations_type"] == 'user') {
          if (jsonConfigToSend["json_data"].containsKey(slug)) {
            jsonConfigToSend["json_data"][slug] = {
              "type": field["relations_type"],
              "label": "",
              "value": "",
              "avatar": "",
              "full_name": ""
            };
          }
        } else {
          if (jsonConfigToSend["json_data"].containsKey(slug)) {
            jsonConfigToSend["json_data"][slug] = {
              "type": field["relations_type"],
              "label": '',
              "value": '',
              "module": field["related_module"]
            };
          }
        }
      }

      camposFiltrados = campos;
    }

    print(' [DEBUG] ========== joinObjects END ==========');
    print(' [DEBUG] campos length: ${campos.length}');

    _filterByVisibility();

    setState(() {
      isLoading = false;
    });
  }

  void _filterByVisibility() {
    final jsonData = jsonConfigToSend['json_data'] is Map
        ? Map<String, dynamic>.from(jsonConfigToSend['json_data'] as Map)
        : <String, dynamic>{};
    final context = ConditionContext(
      currentUserRole: FFAppState().role,
      currentUserRoles: FFAppState().roleGroups
          .map((r) => r is String ? r : r.toString())
          .toList(),
    );
    camposFiltrados = campos.where((campo) {
      final cond = campo['conditional_value']?.toString() ?? '';
      if (cond.isEmpty) return true;
      return evaluateConditions(cond, jsonData, field: campo, context: context);
    }).toList();
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

  Future<void> updateJsonConfigToSend() async {
    for (int index = 0; index < campos.length; index++) {
      final campo = campos[index];
      String slug = campo['slug'];
      final type = campo['type'];

      switch (type) {
        case 'text':
          if (textControllersTextField.containsKey(index)) {
            if (slug == 'title') {
              jsonConfigToSend["title"] =
                  textControllersTextField[index]?.text ?? '';
            } else {
              if (jsonConfigToSend["json_data"] == null) {
                jsonConfigToSend["json_data"] = {};
              }
              jsonConfigToSend["json_data"][slug] =
                  textControllersTextField[index]?.text ?? '';
            }
          }
          break;
        case 'textarea':
          if (textControllersNotifierTextArea.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                textControllersNotifierTextArea[index]?.value ?? '';
          }
          break;
        case 'number':
          if (textControllersNumber.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                textControllersNumber[index]!.text;
          }
          break;
        case 'calendar':
          if (textControllersCalendar.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                (textControllersCalendar[index]!.text != 'Sin fecha')
                    ? dateTimeFormat('yyyy-MM-dd',
                        DateTime.parse(textControllersCalendar[index]!.text))
                    : '';
          }
          break;
        case 'datetime':
          if (textControllersDatetime.containsKey(index)) {
            jsonConfigToSend["json_data"][slug] =
                (textControllersDatetime[index]!.text != 'Sin fecha')
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
            // Usamos una expresión regular para capturar el texto antes del guion
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

            if (jsonConfigToSend["json_data"] != null &&
                jsonConfigToSend["json_data"][slug] != null &&
                jsonConfigToSend["json_data"][slug]["type"] != null &&
                jsonConfigToSend["json_data"][slug]["type"] == 'user') {
              //jsonConfigToSend["json_data"][slug]["value"] = extractedText;
            } else {}
          }
          break;
        case 'multiple_relational_select':
          // El valor ya se mantiene en jsonConfigToSend desde onChanged
          break;
        case 'calculator':
          jsonConfigToSend["json_data"][slug] =
              textControllersCalculator[index]!.text;
          break;
        case 'repeater':
          jsonConfigToSend["json_data"][slug] =
              _repeaterKeys[index].currentState?.updateJsonRepeater();
        //jsonConfigToSend["json_data"][slug] = _repeaterKey.currentState?.updateJsonRepeater();
        case 'firma':
          jsonConfigToSend["json_data"][slug] = FFAppState().firma;
          break;
        case 'firmaext':
          String firmaB64 = '';
          firmaB64 =
              await functions.convertSignToB64(signatureControllers[index]!);
          jsonConfigToSend["json_data"][slug] = firmaB64;
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
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.moduleConfig = await GetCustomFieldsPerModuleCall.call(
        tenant: FFAppState().organizacion,
        moduleName: getJsonField(
          widget.general,
          r'''$.modulo_info.name''',
        ).toString().toString(),
        token: FFAppState().token,
      );

      //await actions.debug(widget.general!,);

      ApiCallResponse? groupedFields = await GetGroupedFieldsCall.call(
        tenant: FFAppState().organizacion,
        moduleId: getJsonField(
          widget.general,
          r'''$.modulo_info.id''',
        ).toString(),
        token: FFAppState().token,
      );

      setState(() {
        FFAppState().clearTextoControladores();
      });

      print(' [DEBUG initState] About to call joinObjects()');
      try {
        joinObjects();
        print(' [DEBUG initState] joinObjects() completed successfully');
      } catch (e, stack) {
        print(' [DEBUG initState] joinObjects() ERROR: $e');
        print(' [DEBUG initState] Stack: $stack');
      }
    });
  }

  @override
  void dispose() {
    _jsonDataDebounceTimer?.cancel();
    _model.dispose();

    for (var controller in textControllersTextField.values) {
      controller.dispose();
    }

    for (var controller in textControllersCalculator.values) {
      controller.dispose();
    }

    for (var controller in textControllersNotifierTextArea.values) {
      controller.dispose();
    }

    for (var controller in textControllersCalendar.values) {
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

  // Aquí llamas a la función para mostrar el diálogo
  void _showNoConformidadDialog(
      BuildContext context, String relational, String label) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NoConformidadDialog(
            relational: relational,
            label: label,
            format: widget.general["modulo_info"]["label"]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Widget Function(BuildContext, Map<String, dynamic>, int)>
        fieldWidgets = {
      'text': (context, campo, index) => DefaultTextFieldWidget(
            text: campo['data'],
            isEdit: canEdit,
            controllerNotifier: textControllersNotifierTextField[index]!,
            type: campo["type"],
            slug: campo["slug"],
          ),
      'text_view': (context, campo, index) => Container(
            padding: EdgeInsetsDirectional.fromSTEB(30, 10, 30, 10),
            child: RichText(
              text: TextSpan(
                children:
                    parseTextWithFormatting(campo['options']?.toString() ?? ''),
                style: DefaultTextStyle.of(context).style,
              ),
            ),
          ),
      'textarea': (context, campo, index) => DefaultTextAreaWidget(
            text: campo['data'],
            isEdit: canEdit,
            controllerNotifier: textControllersNotifierTextArea[index]!,
          ),
      'status': (context, campo, index) => DefaultStatusWidget(
          text: campo['data'],
          options: campo['options'],
          isEdit: canEdit,
          controller: dropdownControllers[index]!,
          onChanged: () {}),
      'number': (context, campo, index) => DefaultTextFieldWidget(
            text: (campo['data'] != null) ? campo['data'] : '',
            isEdit: canEdit,
            controllerNotifier: textControllersNotifierTextField[index]!,
            type: campo["type"],
            slug: campo["slug"],
          ),
      'dropdown': (context, campo, index) => CreatableDropdown(
            text: campo['data'],
            options: campo['options']?.toList() ?? [],
            isEdit: canEdit,
            controller: dropdownControllers[index]!,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            slug: campo["slug"],
          ),
      'dropdown_advance': (context, campo, index) => CreatableDropdownAdvance(
            text: campo['data'],
            options: campo['options']?.toList() ?? [],
            isEdit: canEdit,
            controller: dropdownControllers[index]!,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            slug: campo["slug"],
          ),
      'radio': (context, campo, index) => DefaultTextRadioButtonWidget(
            text: campo['data'],
            options: campo['options'].toList(),
            isEdit: canEdit,
            controller: radioButtonControllers[index]!,
            onChanged: (val) {
              // Si el valor es "No", muestra el popup
              var jsonData = widget.general["json_data"];
              var relational = " ";

              if (jsonData != null && jsonData is Map<String, dynamic>) {
                String slugPrefix = 'ref_inspeccion_relacionada';

                // Asegúrate de que las claves son de tipo String
                var slugKey = jsonData.keys
                    .where((key) => key
                        is String) // Filtra para asegurarse de que key es String
                    .firstWhere(
                        (key) => (key as String).startsWith(
                            slugPrefix), // Asegúrate de que key es String
                        orElse: () => '');

                // Verificar si se encontró una clave que empiece con "slug"
                if (slugKey.isNotEmpty) {
                  relational = jsonData[slugKey]["value"].toString();
                } else {}
              }
              if (val == 'no') {
                _showNoConformidadDialog(
                    context, relational, campo['label']); // Invocar el diálogo
              }
            },
          ),
      'checkbox': (context, campo, index) => DefaultCheckboxWidget(
            text: campo['data'],
            options: campo['options'].toList(),
            isEdit: canEdit,
            controller: checkboxControllers[index]!,
          ),
      'calendar': (context, campo, index) => DefaultCalendarWidget(
            text: campo['data'],
            isEdit: canEdit,
            controllerNotifier:
                textControllersCalendar[index]! as TextControllerNotifier,
          ),
      'datetime': (context, campo, index) => DefaultDateTimeWidget(
            text: campo['data'],
            controller: textControllersDatetime[index]!,
            isEdit: canEdit,
          ),
      'image': (context, campo, index) => DefaultNewImageWidget(
            text: campo['data'] ?? '',
            isEdit: canEdit,
            controller: fileControllers[index]!,
            watermarkUser: FFAppState().fullName,
            watermarkModule:
                _safeModuleLabel(widget.general),
            onFileSelected: (selectedFile) {
              setState(() {
                fileControllers[index] = selectedFile;
              });
            },
          ),
      'file': (context, campo, index) => DefaultFilePdfWidget(
            controller: fileControllers[index]!,
            isEdit: canEdit,
            pdfUrl: campo["data"],
            onFileSelected: (selectedFile) {
              setState(() {
                fileControllers[index] = selectedFile;
              });
            },
          ),
      'relational': (context, campo, index) => RelationalWidget(
          text: 'aa',
          controller: relationalControllers[index]!,
          isEdit: canEdit,
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
              relationalControllers[index]!.relationalAvatar = selectedAvatar;
              relationalControllers[index]!.relationalFullName =
                  selectedFullName;

              if (selectedNameModule != '') {
                relationalControllers[index]!.moduleName = selectedNameModule;
              }
            });
          }),
      'multiple_relational_select': (context, campo, index) => RelationalField(
            field: campo,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            isEdit: canEdit,
            isUpdate: true,
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
      'calculator': (context, campo, index) => DefaultCalculatorWidget(
            text: campo['data'],
            isEdit: false,
            controller: textControllersCalculator[index]!,
            options: campo['options'].toString(),
            idRegister: widget.general["id"].toString(),
          ),
      'repeater': (context, campo, index) => DefaultRepeaterWidget(
          key: _repeaterKeys[index],
          data: campo['data'],
          isEdit: canEdit,
          options: campo['options'],
          watermarkUser: FFAppState().fullName,
          watermarkModule: _safeModuleLabel(widget.general),
          idRegister: widget.general["id"].toString(),
          repeaterSlug: campo['slug']?.toString(),
          updateJsonRepeater: (jsonRepeater) {
            safeSetState(() {
              jsonRepeaterToSend = jsonRepeater;
            });
          }),
      'firma': (context, campo, index) => DefaultFirmaWidget(
            text: campo['data'],
            isEdit: canEdit,
            controller: firmaControllers[index]!,
            rolSign: const [],
          ),
      'firmaext': (context, campo, index) {
          print(' [DEBUG WIDGET] Renderizando DefaultFirmaExt para index $index');
          print(' [DEBUG WIDGET] campo completo: $campo');
          print(' [DEBUG WIDGET] campo[slug]: ${campo['slug']}');
          print(' [DEBUG WIDGET] campo[data]: ${campo['data']}');
          print(' [DEBUG WIDGET] campo[type]: ${campo['type']}');
          return DefaultFirmaExt(
              controller: signatureControllers[index]!,
              isEdit: canEdit,
              text: campo['data'] ?? '',
              height: 150,
              width: MediaQuery.sizeOf(context).width * 1.0,
              onSignatureChanged: (base64Signature) {
                print(' [DEBUG] Firma externa dibujada para index $index');
              },
            );
        },
      'formato': (context, campo, index) => DefaultFormatoWidget(
            text: campo['data'],
          ),
      'external_value': (context, campo, index) => ExternalValueField(
            field: campo,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
              _updateJsonData(slug, value);
            },
          ),
      'mercadopago': (context, campo, index) => MercadoPagoField(
            field: campo,
            jsonData: jsonConfigToSend["json_data"] ?? {},
            handleDynamicFieldChanges: (slug, value, idx, mainSlug) {
              _updateJsonData(slug, value);
            },
            moduleName: getJsonField(
              widget.general,
              r'''$.modulo_info.name''',
            ).toString().toString(),
            recordId: widget.general is Map ? widget.general['id'] : null,
            recordType: getJsonField(
              widget.general,
              r'''$.modulo_info.type''',
            ).toString().toString(),
            onlyView: !canEdit,
          ),
    };

    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        floatingActionButton: Visibility(
          visible: true ||
              functions.hasPermission(
                  FFAppState().permissions.toList(),
                  'query_-_editar',
                  getJsonField(
                    widget.general,
                    r'''$.modulo_info.name''',
                  ).toString().toString()),
          child: FloatingActionButton(
            onPressed: () async {
              if (!canEdit) {
                setState(() {
                  canEdit = !canEdit;
                });
                setState(() {
                  FFAppState().clearTextoControladores();
                });
              } else {
                await updateJsonConfigToSend();

                String bodyJson = jsonEncode(jsonConfigToSend);

                ApiCallResponse? postResult = await EditRegister.call(
                    tenant: FFAppState().organizacion,
                    moduleName: getJsonField(
                      widget.general,
                      r'''$.modulo_info.name''',
                    ).toString().toString(),
                    moduleType: getJsonField(
                      widget.general,
                      r'''$.modulo_info.type''',
                    ).toString().toString(),
                    token: FFAppState().token,
                    body: bodyJson,
                    id: widget.general['id']);

                if ((postResult.succeeded)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '¡Registro editado exitosamente!',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).white,
                        ),
                      ),
                      duration: const Duration(milliseconds: 4000),
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                    ),
                  );
                  Navigator.popAndPushNamed(context, 'singlePage');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Algo salió mal al editar el registro',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).white,
                        ),
                      ),
                      duration: const Duration(milliseconds: 4000),
                      backgroundColor: FlutterFlowTheme.of(context).tertiary,
                    ),
                  );
                }
                setState(() {
                  canEdit = !canEdit;
                });
              }
            },
            backgroundColor: FlutterFlowTheme.of(context).primary,
            elevation: 8.0,
            child: Icon(
              canEdit ? Icons.check : Icons.edit_outlined,
              color: FlutterFlowTheme.of(context).white,
              size: 24.0,
            ),
          ),
        ),
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
                  'Detalle de',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                      ),
                ),
                Text(
                  valueOrDefault<String>(
                    getJsonField(
                      widget.general,
                      r'''$.modulo_info.label''',
                    ).toString(),
                    'No data',
                  ),
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
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: Image.asset(
                  'assets/images/fondoQuery.png',
                ).image,
              ),
            ),
            child: Stack(children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SearcherTextField(
                      width: 0.85,
                      hintText: 'Busca un campo',
                      controller: _controller,
                      onChanged: (text) {
                        _filterFields(text);
                      },
                    ),

                    //Container(
                    //  width: MediaQuery.sizeOf(context).width * 1.0,
                    //  height: 200,
                    //  decoration: BoxDecoration(
                    //    color: FlutterFlowTheme.of(context).primaryBackground,
                    //    borderRadius: BorderRadius.circular(0.0),
                    //  ),
                    //  alignment: const AlignmentDirectional(0.0, 0.0),
                    //  child: RelationalWidget(
                    //      text: 'aa',
                    //      controller: TextEditingController(),
                    //      isEdit: true)
                    //),
                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 50.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(0.0),
                      ),
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Consecutivo: ',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                            TextSpan(
                              text: functions.parseText(valueOrDefault<String>(
                                getJsonField(
                                  widget.general,
                                  r'''$.consecutivo''',
                                ).toString(),
                                'No data',
                              )),
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    isLoading == true
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  FlutterFlowTheme.of(context).primary),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: camposFiltrados.length,
                              itemBuilder: (context, index) {
                                final campo = camposFiltrados[index];
                                final typeField = campo["type"];
                                final widgetBuilder = fieldWidgets[typeField];

                                if (campo.isNotEmpty) {
                                  final slug = campo['slug']?.toString() ?? '';
                                  switch (typeField) {
                                    case 'text':
                                      {
                                        final wasNew = !textControllersNotifierTextField.containsKey(index);
                                        textControllersNotifierTextField[index] ??= TextControllerNotifier(campo['data']?.toString() ?? '');
                                        if (wasNew) {
                                          textControllersNotifierTextField[index]!.addListener(() {
                                            _updateJsonData(slug, textControllersNotifierTextField[index]!.value);
                                          });
                                        }
                                      }
                                      break;
                                    case 'textarea':
                                      {
                                        final wasNew = !textControllersNotifierTextArea.containsKey(index);
                                        textControllersNotifierTextArea[index] ??= TextAreaControllerNotifier(campo['data']?.toString() ?? '');
                                        if (wasNew) {
                                          textControllersNotifierTextArea[index]!.addListener(() {
                                            _updateJsonData(slug, textControllersNotifierTextArea[index]!.value);
                                          });
                                        }
                                      }
                                      break;
                                    case 'calendar':
                                      {
                                        final wasNew = !textControllersCalendar.containsKey(index);
                                        textControllersCalendar[index] ??= TextEditingController(text: campo['data']?.toString() ?? '');
                                        if (wasNew) {
                                          textControllersCalendar[index]!.addListener(() {
                                            final text = textControllersCalendar[index]!.text;
                                            _updateJsonData(slug, (text != 'Sin fecha') ? dateTimeFormat('yyyy-MM-dd', DateTime.parse(text)) : '');
                                          });
                                        }
                                      }
                                      break;
                                    case 'datetime':
                                      {
                                        final wasNew = !textControllersDatetime.containsKey(index);
                                        textControllersDatetime[index] ??= TextEditingController(text: campo['data']?.toString() ?? '');
                                        if (wasNew) {
                                          textControllersDatetime[index]!.addListener(() {
                                            final text = textControllersDatetime[index]!.text;
                                            _updateJsonData(slug, (text != 'Sin fecha') ? dateTimeFormat('yyyy-MM-ddThh:mm', DateTime.parse(text)) : '');
                                          });
                                        }
                                      }
                                      // intentional fallthrough
                                    case 'number':
                                      {
                                        final wasNew = !textControllersNumber.containsKey(index);
                                        textControllersNumber[index] ??= TextEditingController(text: campo['data']?.toString() ?? '');
                                        if (wasNew) {
                                          textControllersNumber[index]!.addListener(() {
                                            _updateJsonData(slug, textControllersNumber[index]!.text);
                                          });
                                        }
                                      }
                                      break;
                                    case 'checkbox':
                                      {
                                        final wasNew = !checkboxControllers.containsKey(index);
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
                                          checkboxControllers[index] ??= FormFieldController<Map<String, bool>>(checkboxData);
                                        } else {
                                          checkboxControllers[index] ??= FormFieldController<Map<String, bool>>({});
                                        }
                                        if (wasNew) {
                                          checkboxControllers[index]!.addListener(() {
                                            _updateJsonData(slug, checkboxControllers[index]!.value);
                                          });
                                        }
                                      }
                                      break;
                                    case 'dropdown':
                                      {
                                        final wasNew = !dropdownControllers.containsKey(index);
                                        dropdownControllers[index] ??= FormFieldController<String>(campo['data']);
                                        if (wasNew) {
                                          dropdownControllers[index]!.addListener(() {
                                            _updateJsonData(slug, dropdownControllers[index]!.value);
                                          });
                                        }
                                      }
                                      break;
                                    case 'dropdown_advance':
                                      {
                                        final wasNew = !dropdownControllers.containsKey(index);
                                        dropdownControllers[index] ??= FormFieldController<String>(campo['data']);
                                        if (wasNew) {
                                          dropdownControllers[index]!.addListener(() {
                                            _updateJsonData(slug, dropdownControllers[index]!.value);
                                          });
                                        }
                                      }
                                      break;
                                    case 'radio':
                                      {
                                        final wasNew = !radioButtonControllers.containsKey(index);
                                        radioButtonControllers[index] ??= FormFieldController<String>(campo['data']);
                                        if (wasNew) {
                                          radioButtonControllers[index]!.addListener(() {
                                            _updateJsonData(slug, radioButtonControllers[index]!.value);
                                          });
                                        }
                                      }
                                      break;
                                    case 'image':
                                      fileControllers[index] ??= FFUploadedFile();
                                      break;
                                    case 'file':
                                      fileControllers[index] ??= FFUploadedFile(bytes: Uint8List.fromList([]));
                                      break;
                                    case 'status':
                                      {
                                        final wasNew = !dropdownControllers.containsKey(index);
                                        dropdownControllers[index] ??= FormFieldController<String>(campo['data']?.toString());
                                        if (wasNew) {
                                          dropdownControllers[index]!.addListener(() {
                                            _updateJsonData(slug, dropdownControllers[index]!.value);
                                          });
                                        }
                                      }
                                      break;
                                    case 'relational':
                                      {
                                        final wasNew = !relationalControllers.containsKey(index);
                                        final rConfig = RelationalFieldConfig.fromRawConfig(Map<String, dynamic>.from(campo));
                                        relationalControllers[index] ??= RelationalController(
                                          textController: TextEditingController(text: campo['data']?.toString() ?? ''),
                                          relationalLabel: campo['label'],
                                          relationalValue: 1,
                                          relationalAvatar: '',
                                          relationalFullName: '',
                                          type: rConfig.relationType,
                                          module: rConfig.relatedModuleId,
                                          moduleName: rConfig.relatedModuleName,
                                          fieldConfig: rConfig,
                                          relationsFormula: campo['relations_formula'],
                                        );
                                        if (wasNew) {
                                          relationalControllers[index]!.textController.addListener(() {
                                            _updateJsonData(slug, relationalControllers[index]!.textController.text);
                                          });
                                        }
                                      }
                                      break;
                                    case 'calculator':
                                      {
                                        final wasNew = !textControllersCalculator.containsKey(index);
                                        textControllersCalculator[index] ??= TextEditingController(text: campo['data']?.toString() ?? '');
                                        if (wasNew) {
                                          textControllersCalculator[index]!.addListener(() {
                                            _updateJsonData(slug, textControllersCalculator[index]!.text);
                                          });
                                        }
                                      }
                                      break;
                                    case 'repeater':
                                      while (_repeaterKeys.length <= index) {
                                        _repeaterKeys.add(GlobalKey<DefaultRepeaterWidgetState>());
                                      }
                                      break;
                                    case 'firma':
                                      // Parsear datos de firma existente
                                      print('🔍 [DEBUG] Inicializando firma controller para index $index, campo: ${campo['slug']}');
                                      print('🔍 [DEBUG] campo[data]: ${campo['data']}');
                                      Map<String, dynamic> firmaData = {
                                        'firmado': false,
                                        'firma': '',
                                        'name': '',
                                        'datetime': '',
                                      };
                                      if (campo['data'] != null && campo['data'].toString().isNotEmpty) {
                                        try {
                                          final parsed = jsonDecode(campo['data']);
                                          print('🔍 [DEBUG] firma parsed: $parsed');
                                          if (parsed is Map) {
                                            firmaData = {
                                              'firmado': true,
                                              'firma': parsed['url'] ?? '',
                                              'name': parsed['name'] ?? '',
                                              'datetime': parsed['datetime'] ?? '',
                                            };
                                          } else if (parsed is String && parsed.isNotEmpty) {
                                            firmaData = {
                                              'firmado': true,
                                              'firma': parsed,
                                              'name': FFAppState().fullName,
                                              'datetime': '',
                                            };
                                          }
                                        } catch (e) {
                                          // Si falla el parse, intentar usar como string directo
                                          print('🔍 [DEBUG] firma parse error: $e');
                                          if (campo['data'].toString().isNotEmpty) {
                                            firmaData = {
                                              'firmado': true,
                                              'firma': campo['data'],
                                              'name': FFAppState().fullName,
                                              'datetime': '',
                                            };
                                          }
                                        }
                                      }
                                      firmaControllers[index] ??= firmaData;
                                      print('🔍 [DEBUG] firmaControllers[$index]: ${firmaControllers[index]}');
                                      break;
                                    case 'firmaext':
                                      print('🔍 [DEBUG] Inicializando firmaext controller para index $index, campo: ${campo['slug']}');
                                      print('🔍 [DEBUG] campo[data] para firmaext: ${campo['data']}');
                                      signatureControllers[index] ??=
                                          SignatureController(
                                        penStrokeWidth: 3,
                                        penColor: Colors.black,
                                        exportPenColor: Colors.black,
                                        exportBackgroundColor: Colors.white,
                                      );
                                      break;
                                    default:
                                      break;
                                  }
                                  if (widgetBuilder != null) {
                                    return Column(
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
                                                10.0, 10.0, 20.0, 20.0),
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
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                widgetBuilder(
                                                    context, campo, index),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 10,
                                          //color: FlutterFlowTheme.of(context).secondaryBackground
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox();
                                } else if (campo.isEmpty) {
                                  return const Text(
                                      'No se encontraron coincidencias');
                                }
                                return const Text(
                                    'No se encontraron coincidencias');
                              },
                            ),
                          ),

                    if (false)
                      ElevatedButton(
                        onPressed: () {
                          // Accede al método updateJsonRepeater a través del GlobalKey

                          _repeaterKey.currentState?.updateJsonRepeater();
                        },
                        child: Text('Actualizar JSON'),
                      ),

                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 50.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(0.0),
                      ),
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Fecha publicación: ',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                            TextSpan(
                              text: functions.parseText(valueOrDefault<String>(
                                getJsonField(
                                  widget.general,
                                  r'''$.published_date''',
                                ).toString(),
                                'No data',
                              )),
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 50.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(0.0),
                      ),
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Última actualización: ',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                            TextSpan(
                              text: functions.parseText(valueOrDefault<String>(
                                getJsonField(
                                  widget.general,
                                  r'''$.last_updated''',
                                ).toString(),
                                'No data',
                              )),
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Outfit',
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        height: 70.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          borderRadius: BorderRadius.circular(0.0),
                        ),
                        alignment: const AlignmentDirectional(0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60.0,
                              height: 60.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).accent1,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2.0,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: InkWell(
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
                                          image: CachedNetworkImage(
                                            fadeInDuration: const Duration(
                                                milliseconds: 500),
                                            fadeOutDuration: const Duration(
                                                milliseconds: 500),
                                            imageUrl:
                                                'https://${FFAppState().organizacion}.itsquery.com${getJsonField(
                                              widget.general,
                                              r'''$.profile_info.avatar''',
                                            ).toString()}',
                                            //'${valueOrDefault<String>(FFAppState().organizacion, 'api',)}.itsquery.com/${FFAppState().avatar}',
                                            fit: BoxFit.contain,
                                          ),
                                          allowRotation: false,
                                          tag:
                                              'https://${FFAppState().organizacion}.itsquery.com${getJsonField(
                                            widget.general,
                                            r'''$.profile_info.avatar''',
                                          ).toString()}detail_widget',
                                          //'${valueOrDefault<String>(FFAppState().organizacion, 'api',)}.itsquery.com/${FFAppState().avatar}',
                                          useHeroAnimation: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Hero(
                                    tag:
                                        'https://${FFAppState().organizacion}.itsquery.com${getJsonField(
                                      widget.general,
                                      r'''$.profile_info.avatar''',
                                    ).toString()}detail_widget2',
                                    //'${valueOrDefault<String>(FFAppState().organizacion, 'api',)}.itsquery.com/${FFAppState().avatar}',
                                    transitionOnUserGestures: true,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        'https://${FFAppState().organizacion}.itsquery.com${getJsonField(
                                          widget.general,
                                          r'''$.profile_info.avatar''',
                                        ).toString()}',
                                        //'${valueOrDefault<String>(FFAppState().organizacion, 'api',)}.itsquery.com/${FFAppState().avatar}',
                                        width: 44.0,
                                        height: 44.0,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/images/app_launcher_icon.png',
                                            width: 300.0,
                                            height: 200.0,
                                            fit: BoxFit.contain,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              getJsonField(
                                widget.general,
                                r'''$.profile_info.full_name''',
                              ).toString(),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                          ].divide(SizedBox(width: 10)),
                        )),

                    Container(
                      height: 30,
                      //color: FlutterFlowTheme.of(context).secondaryBackground
                    ),

                    if (true)
                      TapRegion(
                          onTapInside: (e) async {
                            await updateJsonConfigToSend();
                          },
                          child: Container(
                            height: 45,
                            width: 45,
                            color: Colors.black,
                          )),
                  ]
                      .divide(const SizedBox(height: 10.0))
                      .addToStart(const SizedBox(height: 30.0)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
