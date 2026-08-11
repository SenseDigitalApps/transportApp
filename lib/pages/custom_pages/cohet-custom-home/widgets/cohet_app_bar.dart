import 'package:flutter/material.dart';
import '/components/app_notification_bell/app_notification_bell_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/cohet_home_config.dart';

class CohetAppBar extends StatelessWidget {
  const CohetAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AppBar(
      backgroundColor: theme.secondaryBackground,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: theme.primary,
            size: 28,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            CohetHomeConfig.pageSubtitle,
            style: theme.bodyMedium,
          ),
          Text(
            CohetHomeConfig.pageTitle,
            style: theme.titleMedium.override(
              fontFamily: 'Outfit',
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: true,
      elevation: 0.0,
      actions: const [
        AppNotificationBell(),
      ],
    );
  }
}
