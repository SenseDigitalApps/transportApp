import '/flutter_flow/flutter_flow_radio_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'default_text_radio_button_model.dart';
export 'default_text_radio_button_model.dart';

class DefaultTextRadioButtonWidget extends StatefulWidget {
  DefaultTextRadioButtonWidget({
    super.key,
    required this.text,
    required this.options,
    required this.isEdit,
    required this.controller,
    this.onChanged,

  });

  final String? text;
  final dynamic options;
  final bool isEdit;
  late FormFieldController<String> controller;
  final Function(String)? onChanged;

  @override
  State<DefaultTextRadioButtonWidget> createState() =>
      _DefaultTextRadioButtonWidgetState();
}

class _DefaultTextRadioButtonWidgetState
    extends State<DefaultTextRadioButtonWidget> {
  late DefaultTextRadioButtonModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultTextRadioButtonModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = widget.controller.value;

    return AbsorbPointer(
      absorbing: !widget.isEdit,
      child: widget.isEdit
          ? Wrap(
        alignment: WrapAlignment.start,
        spacing: 8.0,
        runSpacing: 8.0,
        children: widget.options.map<Widget>((option) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: option,
                groupValue: widget.controller.value,
                onChanged: (val) {
                  if (widget.onChanged != null) {
                    widget.onChanged!(val!);
                  }
                  setState(() {
                    widget.controller.value = val??"";
                  });
                },
              ),
              Text(
                option,
                style: FlutterFlowTheme.of(context).labelMedium.override(
                  fontFamily: 'Roboto',
                  letterSpacing: 0.0,
                ),
              ),
            ],
          );
        }).toList(),
      )
          : selectedOption != null
          ? Text(
        selectedOption!,
        style: FlutterFlowTheme.of(context).labelMedium.override(
          fontFamily: 'Roboto',
          letterSpacing: 0.0,
        ),
      )
          : Container(),
    );
  }
}
