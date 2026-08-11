import 'package:flutter/cupertino.dart';

import '../../flutter_flow/form_field_controller.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import '/flutter_flow/custom_functions.dart' as functions;


class BooleanControllerNotifier extends ValueNotifier<bool> {
  BooleanControllerNotifier(super.value);

  void updateValue(bool newValue) {
    value = newValue;
    notifyListeners();
  }
}

class DefaultBooleanWidget extends StatefulWidget {
  DefaultBooleanWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controllerNotifier,
  });

  final String? text;
  final bool isEdit;
  final BooleanControllerNotifier controllerNotifier;

  @override
  State<DefaultBooleanWidget> createState() => _DefaultBooleanWidgetState();
}

class _DefaultBooleanWidgetState extends State<DefaultBooleanWidget> {
  bool light = true;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
  }

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controllerNotifier,
      builder: (context, value, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: value
                    ? FlutterFlowTheme.of(context).primary.withValues(alpha: 0.15)
                    : FlutterFlowTheme.of(context).secondaryText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value ? 'Activado' : 'Desactivado',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Lexend Deca',
                  color: value
                      ? FlutterFlowTheme.of(context).primary
                      : FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CupertinoSwitch(
              activeColor: FlutterFlowTheme.of(context).primary,
              trackColor: Colors.grey.shade400,
              thumbColor: CupertinoColors.white,
              value: value,
              onChanged: widget.isEdit
                  ? (val) {
                widget.controllerNotifier.updateValue(val);
              }
                  : null,
            ),
          ],
        );
      },
    );
  }
}
