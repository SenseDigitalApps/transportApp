import '/flutter_flow/flutter_flow_util.dart';
import 'default_file_image_widget.dart' show DefaultFileImageWidget;
import 'package:flutter/material.dart';

class DefaultFileImageModel extends FlutterFlowModel<DefaultFileImageWidget> {
  ///  State fields for stateful widgets in this component.

  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile = FFUploadedFile(bytes: Uint8List.fromList([]));

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
