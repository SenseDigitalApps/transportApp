import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'default_dropdown_model.dart';
export 'default_dropdown_model.dart';

class DefaultDropdownWidget extends StatefulWidget {
  DefaultDropdownWidget({
    super.key,
    required this.text,
    required this.options,
    required this.isEdit,
    required this.controller,
  });

  final String? text;
  final List<String> options;
  final bool isEdit;
  FormFieldController<String> controller;

  @override
  State<DefaultDropdownWidget> createState() => _DefaultDropdownWidgetState();
}

class _DefaultDropdownWidgetState extends State<DefaultDropdownWidget> {
  late DefaultDropdownModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultDropdownModel());

    // Si viene null, inicializa con null (sin selección)
    widget.controller.value = widget.controller.value;
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedValue = widget.controller.value;
    final hasSelected = selectedValue != null && selectedValue.isNotEmpty;
    final valueExistsInOptions = hasSelected &&
        widget.options.any((opt) => opt.trim() == selectedValue.trim());
    final dropdownValue = valueExistsInOptions ? selectedValue : null;

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: dropdownValue,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          hint: Text(
            widget.text ?? '',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  letterSpacing: 0.0,
                  color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.5),
                ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: FlutterFlowTheme.of(context).secondaryText,
            size: 24.0,
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Outfit',
                fontSize: 13,
                letterSpacing: 0.0,
                decoration: TextDecoration.none,
              ),
          dropdownColor: FlutterFlowTheme.of(context).secondaryBackground,
          elevation: 8,
          items: widget.options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt),
            );
          }).toList(),
          onChanged: !widget.isEdit
              ? null
              : (val) {
                  setState(() {
                    widget.controller.value = val;
                    _model.dropDownValue = val;
                  });
                },
        ),
      ),
    );
  }
}
