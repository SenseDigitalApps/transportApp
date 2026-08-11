import '/flutter_flow/flutter_flow_util.dart';
import 'web_view_support_widget.dart' show WebViewSupportWidget;
import 'package:flutter/material.dart';

class WebViewSupportModel extends FlutterFlowModel<WebViewSupportWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}
