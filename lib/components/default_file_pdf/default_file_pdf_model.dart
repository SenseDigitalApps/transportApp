import '/flutter_flow/flutter_flow_util.dart';
import 'default_file_pdf_widget.dart' show DefaultFilePdfWidget;
import 'package:flutter/material.dart';

class DefaultFilePdfModel extends FlutterFlowModel<DefaultFilePdfWidget> {
  ///  State fields for stateful widgets in this component.

  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile = FFUploadedFile(bytes: Uint8List.fromList([]));

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
