import 'package:transport_app/controllers/field_controllers.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_google_map.dart';

class DefaultGeoreferenceWidget extends StatefulWidget {
  DefaultGeoreferenceWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.geoReferenceController,
  });

  final String? text;
  final bool isEdit;
  final GeoReferenceController geoReferenceController;

  @override
  State<DefaultGeoreferenceWidget> createState() =>
      _DefaultGeoReferenceWidgetState();
}

class _DefaultGeoReferenceWidgetState
    extends State<DefaultGeoreferenceWidget> {
  LatLng? _selectedLatLng;
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  bool _syncingFromMap = false;
  bool _syncingFromFields = false;

  @override
  void initState() {
    super.initState();
    _initializeFromController();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _initializeFromController() {
    final value = widget.geoReferenceController.latLng.text;

    if (value.isNotEmpty) {
      final parts = value.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);

        if (lat != null && lng != null) {
          _selectedLatLng = LatLng(lat, lng);
          _latController.text = lat.toString();
          _lngController.text = lng.toString();
        }
      }
    }
  }

  void _updateMapFromFields() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null) {
      final newLatLng = LatLng(lat, lng);

      if (!_syncingFromMap) {
        _syncingFromFields = true;
        setState(() {
          _selectedLatLng = newLatLng;
        });
        widget.geoReferenceController.latLng.text = '$lat,$lng';

        _mapController.future.then((controller) {
          controller.animateCamera(
              CameraUpdate.newLatLng(newLatLng.toGoogleMaps()));
        });
        _syncingFromFields = false;
      }
    }
  }

  void _onLocationSelected(LatLng latLng) {
    if (_syncingFromFields) return;

    _syncingFromMap = true;
    setState(() {
      _selectedLatLng = latLng;
    });

    widget.geoReferenceController.latLng.text =
        '${latLng.latitude},${latLng.longitude}';

    _latController.text = latLng.latitude.toString();
    _lngController.text = latLng.longitude.toString();
    _syncingFromMap = false;
  }

  @override
  Widget build(BuildContext context) {
    final addressText = widget.geoReferenceController.address.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: widget.isEdit
                  ? TextFormField(
                      controller: _latController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                      ),
                      style: TextStyle(fontSize: 14),
                      onChanged: (_) => _updateMapFromFields(),
                    )
                  : (widget.geoReferenceController.latLng.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Lat: ${widget.geoReferenceController.latLng.text}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  FlutterFlowTheme.of(context).secondaryText,
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
            ),
            Expanded(
              child: widget.isEdit
                  ? TextFormField(
                      controller: _lngController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                      ),
                      style: TextStyle(fontSize: 14),
                      onChanged: (_) => _updateMapFromFields(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        widget.isEdit
            ? TextFormField(
                controller: widget.geoReferenceController.address,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                ),
                style: TextStyle(fontSize: 14),
              )
            : (addressText.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      addressText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 250,
            width: double.infinity,
            child: FlutterFlowGoogleMap(
              controller: _mapController,
              initialLocation:
                  _selectedLatLng ?? const LatLng(4.6773562, -74.164434),
              initialZoom: 14,
              allowInteraction: widget.isEdit,
              markers: [
                if (_selectedLatLng != null)
                  FlutterFlowMarker(
                    _selectedLatLng!.serialize(),
                    _selectedLatLng!,
                  ),
              ],
              onCameraIdle: (latLng) {
                if (!widget.isEdit) return;
                _onLocationSelected(latLng);
              },
              markerColor: GoogleMarkerColor.azure,
              mapType: MapType.normal,
              style: GoogleMapStyle.night,
              allowZoom: true,
              showZoomControls: true,
              showLocation: true,
              showCompass: true,
              showMapToolbar: false,
              showTraffic: false,
              centerMapOnMarkerTap: true,
            ),
          ),
        ),
      ],
    );
  }
}
