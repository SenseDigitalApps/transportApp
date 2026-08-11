import 'dart:convert';
import 'package:flutter/material.dart';

import '../../backend/api_requests/api_calls.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';

class DefaultFormatoWidget extends StatefulWidget {
  const DefaultFormatoWidget({
    super.key,
    required this.text,
  });

  final String? text;

  @override
  State<DefaultFormatoWidget> createState() => DefaultFormatoWidgetState();
}

class DefaultFormatoWidgetState extends State<DefaultFormatoWidget> {
  ApiCallResponse? modules;
  String? selectedLabel;
  int? selectedId;
  List<Map<String, dynamic>>? modulesList;
  List<dynamic>? formatosList = [];
  String? hintText;
  String? valueText;

  // 👇 Nuevo/clave: control de modo icono vs desplegado
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    getModules();

    // 👇 Solo calculamos el hint, pero SIEMPRE arrancamos con el ícono (_isExpanded = false)
    if (widget.text != null && widget.text!.isNotEmpty) {
      try {
        final textDecoded = jsonDecode(widget.text!);
        if (textDecoded is Map) {
          hintText = textDecoded['label']?.toString();
        } else {
          hintText = textDecoded?.toString();
        }
      } catch (_) {
        // text is not valid JSON (e.g. a Dart Map toString() or plain text)
        hintText = widget.text;
      }
    } else {
      hintText = "Crear un nuevo formato";
    }

    _isExpanded = false; // ← siempre inicia en modo ícono
  }

  void getModules() async {
    modules = await GetModules.call(
      tenant: FFAppState().organizacion,
      token: FFAppState().token,
    );

    if (mounted) {
      setState(() {
        modulesList = (modules?.jsonBody['data'] as List)
            .where((e) => e is Map<String, dynamic> && e['type'] == 'masters')
            .cast<Map<String, dynamic>>()
            .toList();
      });

      valueText = hintText?.toLowerCase();
      hintText = await modulesList?.firstWhere(
            (module) =>
        module['label'].toLowerCase() == hintText?.toLowerCase(),
        orElse: () => {},
      )['description'];
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String getValueForm() {
    var originalId;
    if (widget.text != null && widget.text!.isNotEmpty) {
      final textDecoded = jsonDecode(widget.text!);
      originalId = textDecoded['value'];
    }
    var idForm = selectedId ?? originalId;
    var selectedForm = {
      "value": "${selectedId ?? idForm}",
      "label": "${selectedLabel?.toLowerCase() ?? valueText?.toLowerCase()}"
    };
    return jsonEncode(selectedForm);
  }

  @override
  Widget build(BuildContext context) {
    // 👇 Mientras no esté expandido, mostramos SOLO el icono
    if (!_isExpanded) {
      return InkWell(
        onTap: () {
          setState(() {
            _isExpanded = true; // al hacer clic mostramos el dropdown
          });
        },
        child: Container(
          width: 32,
          height: 32,
          child: Icon(
            Icons.description_outlined, // ícono de formato/documento
            size: 18,
            color: FlutterFlowTheme.of(context).primary,
          ),
        ),
      );
    }

    // 👇 Una vez expandido, se muestra tu componente original
    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      height: 60.0,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          itemHeight: 60,
          hint: Text(
            selectedLabel ?? hintText ?? "Crear un nuevo formato",
            style: TextStyle(
              color: selectedLabel == null
                  ? FlutterFlowTheme.of(context).primary
                  : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          value: selectedLabel,
          onChanged: (String? newValue) async {
            setState(() {
              selectedLabel = newValue;
              selectedId = modulesList
                  ?.firstWhere((module) => module['label'] == newValue)['id'];
            });
          },
          items: modulesList?.map<DropdownMenuItem<String>>((module) {
            return DropdownMenuItem<String>(
              alignment: Alignment.centerLeft,
              value: module['label'],
              key: module['value'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    module['description'],
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          style: const TextStyle(color: Colors.white),
          dropdownColor: Colors.transparent,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_outlined,
            color: FlutterFlowTheme.of(context).primary,
            size: 15,
          ),
        ),
      ),
    );
  }
}