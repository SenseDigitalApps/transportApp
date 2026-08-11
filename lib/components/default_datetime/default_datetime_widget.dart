import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'default_datetime_model.dart';
export 'default_datetime_model.dart';

class DefaultDateTimeWidget extends StatefulWidget {
  const DefaultDateTimeWidget({
    super.key,
    required this.controller,
    required this.text,
    bool? isEdit,
  }) : this.isEdit = isEdit ?? false;

  final bool isEdit;
  final String? text;
  final TextEditingController? controller;

  @override
  State<DefaultDateTimeWidget> createState() => _DefaultDateTimeWidgetState();
}

class _DefaultDateTimeWidgetState extends State<DefaultDateTimeWidget> {
  late DefaultDateTimeModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultDateTimeModel());
    if (widget.controller!.text.isEmpty) {
      if (widget.text != null && widget.text != '') {
        widget.controller!.text = widget.text!;
      }
    }
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FFButtonWidget(
      onPressed: !widget!.isEdit
          ? null
          : () async {
              await DatePicker.showDateTimePicker(
                context,
                showTitleActions: true,
                onConfirm: (date) {
                  safeSetState(() {
                    _model.datePicked = date;
                    widget.controller.text = date.toString();
                  });
                },
                currentTime: getCurrentTimestamp,
                minTime: getCurrentTimestamp,
              );
            },
      text: widget.controller.text == ''
          ? 'Sin fecha'
          : dateTimeFormat(
              'yyyy-MM-dd hh:mm a', DateTime.parse(widget.controller.text)),
      icon: const Icon(Icons.access_time, size: 18),
      options: FFButtonOptions(
        width: double.infinity,
        height: 45.0,
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
        color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
              fontFamily: 'Outfit',
              color: FlutterFlowTheme.of(context).primary,
              letterSpacing: 0.0,
            ),
        elevation: 0,
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
        disabledColor: FlutterFlowTheme.of(context).alternate,
      ),
    );
  }
}
