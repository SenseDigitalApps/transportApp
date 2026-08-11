import 'package:flutter/material.dart';
import '/components/app_notification_bell/app_notification_bell_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class TransportAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TransportAppBar({
    super.key,
    required this.scaffoldKey,
    this.title = 'TransportApp',
    this.showNotificationBell = true,
    this.onCreateConductorTap,
    this.onCreateVehiculoTap,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final bool showNotificationBell;
  final VoidCallback? onCreateConductorTap;
  final VoidCallback? onCreateVehiculoTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: theme.primary),
      automaticallyImplyLeading: true,
      leading: IconButton(
        icon: Icon(Icons.menu, color: theme.primary),
        onPressed: () => scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        title,
        style: theme.titleMedium.override(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white : theme.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.0,
        ),
      ),
      actions: [
        // TODO: Temporalmente ocultado - botón de crear conductor
        // if (onCreateConductorTap != null)
        //   Padding(
        //     padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
        //     child: IconButton(
        //       icon: Icon(Icons.person, color: theme.primary),
        //       onPressed: onCreateConductorTap,
        //       tooltip: 'Nuevo conductor',
        //     ),
        //   ),
        if (onCreateVehiculoTap != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
            child: IconButton(
              icon: Icon(Icons.directions_car_outlined, color: theme.primary),
              onPressed: onCreateVehiculoTap,
              tooltip: 'Nuevo vehículo',
            ),
          ),
        if (showNotificationBell)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
            child: AppNotificationBell(),
          ),
      ],
      centerTitle: true,
    );
  }
}
