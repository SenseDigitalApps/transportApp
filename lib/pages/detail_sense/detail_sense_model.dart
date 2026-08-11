import '/flutter_flow/flutter_flow_util.dart';
import 'detail_sense_widget.dart' show DetailSenseWidget;
import 'package:flutter/material.dart';

class DetailSenseModel extends FlutterFlowModel<DetailSenseWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}
