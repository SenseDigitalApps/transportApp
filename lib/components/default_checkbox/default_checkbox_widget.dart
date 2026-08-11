import '/flutter_flow/flutter_flow_checkbox_group.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'default_checkbox_model.dart';
export 'default_checkbox_model.dart';

class DefaultCheckboxWidget extends StatefulWidget {
  DefaultCheckboxWidget({
    super.key,
    required this.text,
    required this.options,
    required this.isEdit,
    required this.controller,
  });

  final String? text;
  final dynamic options;
  final bool isEdit;
  late FormFieldController<Map<String, bool>> controller;

  @override
  State<DefaultCheckboxWidget> createState() => _DefaultCheckboxWidgetState();
}

class _DefaultCheckboxWidgetState extends State<DefaultCheckboxWidget> {
  late DefaultCheckboxModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultCheckboxModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOptions = widget.controller.value;

    return AbsorbPointer(
      absorbing: !widget.isEdit,
      child: widget.isEdit
          ? Column(
        children: widget.options.map<Widget>((option) {
          return Row(
            children: [
              Checkbox(
                  activeColor: FlutterFlowTheme.of(context).primary,
                  shape: const RoundedRectangleBorder(),
                  value: selectedOptions?[option] ?? false,
                  onChanged: (val) {
                    setState(() {
                      widget.controller.value = {
                        ...?selectedOptions,
                        option: val ?? false,
                      };
                      _model.checkboxGroupValues =
                          widget.controller.value?.entries
                              .where((entry) => entry.value)
                              .map((entry) => entry.key)
                              .toList();
                    });
                  },
                ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  option,
                  softWrap: true,
                ),
              ),
            ],
          );
        }).toList(),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: selectedOptions!.entries
            .where((entry) => entry.value)
            .map<Widget>(
              (entry) => Text(
            entry.key,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Outfit',
              letterSpacing: 0.0,
            ),
          ),
        )
            .toList(),
      ),
    );
  }

}

