import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'default_dropdown_option_value_model.dart';
import '/flutter_flow/custom_functions.dart' as functions;

class DefaultDropdownOptionsWidget extends StatefulWidget {
  final bool isEdit;
  final List<Map<String, String>> options; // Aquí ahora recibimos solo los labels
  late FormFieldController<String> controller;
  final String text;
  final Function(String?) onTypeChanged;

  DefaultDropdownOptionsWidget({
    super.key,
    required this.isEdit,
    required this.options,
    required this.controller,
    required this.text,
    required this.onTypeChanged,
  });

  @override
  _DefaultDropdownOptionsWidgetState createState() => _DefaultDropdownOptionsWidgetState();
}

class _DefaultDropdownOptionsWidgetState extends State<DefaultDropdownOptionsWidget> {
  late DefaultDropdownModel _model;
  String? selectedLabel;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultDropdownModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }
  String? selectedType;

  @override
  Widget build(BuildContext context) {


    final List<String> labels = widget.options
        .map((option) => option['label'])
        .where((label) => label != null)
        .cast<String>()
        .map((label) => label)
        .toList();




    return FlutterFlowDropDown<String>(
      controller: widget.controller,
      options: labels,
      onChanged: (val) {
        setState(() {
          selectedLabel = val;
          widget.controller.value = widget.options.firstWhere((option) => option['label'] == val)['slug'] ;
        });
        setState(() {

          selectedType = widget.options.firstWhere((option) => option['label'] == val)['type'];

          widget.onTypeChanged(selectedType);
        });
      },
      width: 300.0,
      height: 56.0,
      textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
        fontFamily: 'Outfit',
        letterSpacing: 0.0,
      ),
      hintText: widget.text,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: FlutterFlowTheme.of(context).secondaryText,
        size: 24.0,
      ),
      fillColor: Colors.transparent,
      elevation: 0.0,
      borderColor: Colors.transparent,
      borderWidth: 0.0,
      borderRadius: 8.0,
      margin: EdgeInsets.zero,
      hidesUnderline: true,
      isOverButton: true,
      isSearchable: false,
      isMultiSelect: false,
      disabled: !widget.isEdit ? true : false,
    );
  }
}
