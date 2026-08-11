import '../backend/api_requests/api_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'splash_screen_widget.dart' show SplashScreenWidget;
import 'package:flutter/material.dart';

class SplashScreenModel extends FlutterFlowModel<SplashScreenWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for RadioButton widget.
  FormFieldController<String>? radioButtonValueController;
  // State field(s) for TextFieldEmpresa widget.
  FocusNode? textFieldEmpresaFocusNode;
  TextEditingController? textFieldEmpresaTextController;
  String? Function(BuildContext, String?)?
      textFieldEmpresaTextControllerValidator;
  ApiCallResponse? optionsPanel;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldEmpresaFocusNode?.dispose();
    textFieldEmpresaTextController?.dispose();
  }

  /// Additional helper methods.
  String? get radioButtonValue => radioButtonValueController?.value;
}
