import '/components/page_components/webview/webview_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'web_view_viewer_widget.dart' show WebViewViewerWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WebViewViewerModel extends FlutterFlowModel<WebViewViewerWidget> {
  ///  Local state fields for this page.

  String filterSet = 'Ser';

  ///  State fields for stateful widgets in this page.

  // Model for webview component.
  late WebviewModel webviewModel;

  @override
  void initState(BuildContext context) {
    webviewModel = createModel(context, () => WebviewModel());
  }

  @override
  void dispose() {
    webviewModel.dispose();
  }
}
