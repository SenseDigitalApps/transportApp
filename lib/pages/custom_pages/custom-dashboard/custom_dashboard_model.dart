import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'custom_dashboard_widget.dart' show CustomDashboardWidget;
import 'package:flutter/material.dart';

class CustomDashboardModel extends FlutterFlowModel<CustomDashboardWidget> {
  /// State fields for the custom dashboard.

  // Model for SideNav component
  late SideNavModel sideNavModel;

  // Kanban state
  List<dynamic> kanbanColumns = [];
  Map<String, Color> kanbanColorCache = {};

  // Recent projects state
  List<dynamic> recentProjects = [];

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
  }
}
