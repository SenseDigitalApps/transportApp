import 'package:flutter/material.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../cohet_custom_home_model.dart';

class CohetDrawer extends StatelessWidget {
  final CohetCustomHomeModel model;
  final VoidCallback updateCallback;

  const CohetDrawer({
    super.key,
    required this.model,
    required this.updateCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: WebViewAware(
        child: wrapWithModel(
          model: model.sideNavModel,
          updateCallback: updateCallback,
          child: const SideNavWidget(),
        ),
      ),
    );
  }
}
