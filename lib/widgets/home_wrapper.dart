import 'package:flutter/material.dart';
import 'package:transport_app/config/home_widget_registry.dart';
import 'package:transport_app/pages/home/home_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Equivalente al HomeWrapper de query-core.
/// Si existe un customHomePage registrado, lo renderiza. Sino, HomeWidget normal.
class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final customPageName = FFAppState().customHomePage;

    if (customPageName.isNotEmpty) {
      final builder = HomeWidgetRegistry.getBuilder(customPageName);
      if (builder != null) {
        return builder(context);
      }
    }

    return const HomeWidget();
  }
}
