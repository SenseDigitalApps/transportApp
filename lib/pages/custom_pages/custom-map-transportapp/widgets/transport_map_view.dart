import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '../types/map_config.dart';

class TransportMapView extends StatelessWidget {
  const TransportMapView({
    super.key,
    required this.controller,
    required this.initialLocation,
    required this.markers,
    required this.polylines,
    this.style,
    this.initialZoom = MapConfig.defaultZoom,
  });

  final Completer<GoogleMapController> controller;
  final LatLng initialLocation;
  final List<FlutterFlowMarker> markers;
  final Set<Polyline> polylines;
  final GoogleMapStyle? style;
  final double initialZoom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FlutterFlowGoogleMap(
      controller: controller,
      initialLocation: initialLocation,
      markers: markers,
      polylines: polylines,
      style: style ?? (isDark ? GoogleMapStyle.dark : GoogleMapStyle.silver),
      markerColor: GoogleMarkerColor.azure,
      initialZoom: initialZoom,
      allowInteraction: true,
      allowZoom: true,
      showZoomControls: false,
      showLocation: true,
      showCompass: false,
      showMapToolbar: false,
      showTraffic: false,
    );
  }
}
