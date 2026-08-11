import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'login_equipo_widget.dart' show LoginEquipoWidget;
import 'package:flutter/material.dart';

class LoginEquipoModel extends FlutterFlowModel<LoginEquipoWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;

  // State field(s) for emailAddress_Login widget.
  FocusNode? emailAddressLoginFocusNode;
  TextEditingController? emailAddressLoginTextController;
  String? Function(BuildContext, String?)?
      emailAddressLoginTextControllerValidator;
  // State field(s) for password_Login widget.
  FocusNode? passwordLoginFocusNode;
  TextEditingController? passwordLoginTextController;
  late bool passwordLoginVisibility;
  String? Function(BuildContext, String?)? passwordLoginTextControllerValidator;
  // Stores action output result for [Backend Call - API (loginTenant)] action in Button-Login widget.
  ApiCallResponse? loginResult;
  // Stores action output result for [Backend Call - API (userData)] action in Button-Login widget.
  ApiCallResponse? userDataOut;
  // Stores action output result for [Backend Call - API (loginTenant)] action in Text widget.
  ApiCallResponse? loginResultCopy;
  // Stores action output result for [Backend Call - API (userData)] action in Text widget.
  ApiCallResponse? userDataOutCopy;

  @override
  void initState(BuildContext context) {
    passwordLoginVisibility = false;
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    tabBarController?.dispose();
    emailAddressLoginFocusNode?.dispose();
    emailAddressLoginTextController?.dispose();

    passwordLoginFocusNode?.dispose();
    passwordLoginTextController?.dispose();
  }
}
