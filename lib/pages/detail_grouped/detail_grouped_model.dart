import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'detail_grouped_widget.dart' show DetailGroupedWidget;
import 'package:flutter/material.dart';

class DetailGroupedModel extends FlutterFlowModel<DetailGroupedWidget> {
  final unfocusNode = FocusNode();
  ApiCallResponse? moduleConfig;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}