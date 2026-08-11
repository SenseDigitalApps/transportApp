import '/flutter_flow/flutter_flow_util.dart';
import 'default_text_area_widget.dart' show DefaultTextAreaWidget;
import 'package:flutter/material.dart';

class DefaultTextAreaModel extends FlutterFlowModel<DefaultTextAreaWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
