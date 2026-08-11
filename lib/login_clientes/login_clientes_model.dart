import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'login_clientes_widget.dart' show LoginClientesWidget;
import 'package:flutter/material.dart';

class LoginClientesModel extends FlutterFlowModel<LoginClientesWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  // State field(s) for clientId widget.
  FocusNode? clientIdFocusNode;
  TextEditingController? clientIdTextController;
  String? Function(BuildContext, String?)? clientIdTextControllerValidator;
  // Stores action output result for [Backend Call - API (testSheets)] action in homeClient widget.
  ApiCallResponse? clientSheetsObject;
  // Stores action output result for [Backend Call - API (testSheets)] action in Text widget.
  ApiCallResponse? clientSheetsObjectCopy;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
    tabBarController?.dispose();
    clientIdFocusNode?.dispose();
    clientIdTextController?.dispose();
  }
}
