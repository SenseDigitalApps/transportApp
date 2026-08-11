import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

/// Reusable app bar actions widget with notifications and tasks bells.
/// Used across Home, CustomDashboard, and other screens.
class AppNotificationBell extends StatelessWidget {
  const AppNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Notifications bell
        GestureDetector(
          onTap: () {
            context.pushNamed('notificationsScreen');
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 10.0, 5.0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 30.0,
                ),
                if (FFAppState().unreadNotifications > 0)
                  Positioned(
                    right: -4.0,
                    top: -2.0,
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18.0,
                        minHeight: 18.0,
                      ),
                      child: Text(
                        FFAppState().unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Tasks bell
        GestureDetector(
          onTap: () {
            context.pushNamed('taskScreen');
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 10.0, 5.0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 30.0,
                ),
                if (FFAppState().pendingTasks > 0)
                  Positioned(
                    right: -4.0,
                    top: -2.0,
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18.0,
                        minHeight: 18.0,
                      ),
                      child: Text(
                        FFAppState().pendingTasks.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
