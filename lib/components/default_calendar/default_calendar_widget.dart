import 'package:transport_app/components/default_text_field/default_text_field_widget.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'default_calendar_model.dart';
export 'default_calendar_model.dart';

class DefaultCalendarWidget extends StatefulWidget {
  const DefaultCalendarWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controllerNotifier,
  });

  final String? text;
  final bool isEdit;
  final TextControllerNotifier? controllerNotifier;

  @override
  State<DefaultCalendarWidget> createState() => _DefaultCalendarWidgetState();
}

class _DefaultCalendarWidgetState extends State<DefaultCalendarWidget> {
  late DefaultCalendarModel _model;
  late TextEditingController _textController;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultCalendarModel());

    _textController =
        TextEditingController(text: widget.controllerNotifier?.value);

    if (_textController.text.isEmpty &&
        widget.text != null &&
        widget.text!.isNotEmpty) {
      _textController.text = widget.text!;
    }

    _textController.addListener(() {
      widget.controllerNotifier?.updateText(_textController.text);
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayText = 'Sin fecha';
    final dateStr = widget.controllerNotifier?.value ?? '';
    if (dateStr.isNotEmpty) {
      try {
        DateTime parsedDate;
        if (dateStr.contains('/')) {
          final parts = dateStr.split('/');
          parsedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          parsedDate = DateTime.parse(dateStr);
        }
        displayText = dateTimeFormat('yyyy-MM-dd', parsedDate);
      } catch (e) {
        displayText = dateStr;
      }
    }

    return ValueListenableBuilder<String>(
      valueListenable: widget.controllerNotifier ?? TextControllerNotifier(''),
      builder: (context, value, child) {
        return FFButtonWidget(
          onPressed: !widget.isEdit
              ? null
              : () async {
                  await DatePicker.showDatePicker(
                    context,
                    showTitleActions: true,
                    onConfirm: (date) {
                      safeSetState(() {
                        _model.datePicked = date;
                        widget.controllerNotifier?.value =
                            date.toString();
                      });
                    },
                    currentTime: getCurrentTimestamp,
                    minTime: DateTime(1900),
                  );
                },
          text: displayText,
          icon: const Icon(Icons.calendar_today, size: 18),
          options: FFButtonOptions(
            width: double.infinity,
            height: 45.0,
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
            iconPadding:
                const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
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
            disabledColor: FlutterFlowTheme.of(context).accent2,
          ),
        );
      },
    );
  }
}
