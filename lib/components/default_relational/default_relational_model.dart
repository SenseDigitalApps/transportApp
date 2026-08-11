import '/backend/api_requests/api_calls.dart';
import 'default_relational_widget.dart' show RelationalWidget;
import '/flutter_flow/flutter_flow_model.dart';
import 'package:flutter/material.dart';

class RelationalModel extends FlutterFlowModel<RelationalWidget> {
  FocusNode? textFieldVehiculoFocusNode;
  TextEditingController? textFieldVehiculoTextController;
  String? Function(BuildContext, String?)? textFieldVehiculoTextControllerValidator;
  bool loadingState = false;
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  ApiCallResponse? getInfoRelational;

  SelectedItem? selectedItem;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldVehiculoFocusNode?.dispose();
    textFieldVehiculoTextController?.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}

class SelectedItem {
  final int value;
  final String label;
  final String? avatar;
  final String? fullName;
  final String? nameModule;
  final String type;
  final int module;

  const SelectedItem({
    required this.value,
    required this.label,
    this.avatar,
    this.fullName,
    this.nameModule,
    required this.type,
    required this.module,
  });
}
