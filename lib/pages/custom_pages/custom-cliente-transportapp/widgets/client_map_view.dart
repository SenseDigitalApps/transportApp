import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_google_map.dart';

class ClientMapView extends StatefulWidget {
  const ClientMapView({Key? key}) : super(key: key);

  @override
  State<ClientMapView> createState() => _ClientMapViewState();
}

class _ClientMapViewState extends State<ClientMapView> {
  final _mapController = Completer<GoogleMapController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FlutterFlowGoogleMap(
      controller: _mapController,
      initialLocation: const LatLng(4.6773562, -74.164434),
      initialZoom: 10,
      allowInteraction: false,
      style: isDark ? GoogleMapStyle.dark : GoogleMapStyle.silver,
      showZoomControls: false,
      showLocation: false,
      showCompass: false,
      showTraffic: false,
    );
  }
}
