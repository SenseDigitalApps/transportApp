import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:transport_app/components/default_repeater/default_repeater_widget.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';

class AcordeonSimpleWidget extends StatefulWidget {
  const AcordeonSimpleWidget({
    super.key,
    required this.repeater,
    required this.title,
    required this.options,
    required this.updateJsonRepeater,
  });
  final dynamic repeater;
  final String title;
  final dynamic options;
  final Function(List<Map<String, dynamic>>) updateJsonRepeater;

  @override
  AcordeonSimpleWidgetState createState() => AcordeonSimpleWidgetState();
  // DefaultRepeaterWidgetState createState() => DefaultRepeaterWidgetState();
}

class AcordeonSimpleWidgetState extends State<AcordeonSimpleWidget> {
  String? dataRepeater;
  bool isActive = false;
  late List<dynamic> listToSend = [];

  final GlobalKey<DefaultRepeaterWidgetState> _repeaterKey =
      GlobalKey<DefaultRepeaterWidgetState>();

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
  }

  @override
  void initState() {
    super.initState();
    dataRepeater = jsonEncode(widget.repeater);
  }

  @override
  void didUpdateWidget(covariant AcordeonSimpleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (jsonEncode(oldWidget.repeater) != jsonEncode(widget.repeater)) {
      setState(() {
        dataRepeater = jsonEncode(widget.repeater);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  getRepeater() {
    listToSend = _repeaterKey.currentState?.updateJsonRepeater() ?? [];

    return listToSend;
  }

  Widget build(BuildContext context) {
    return Stack(
      children: [
        //if (isActive)
        Offstage(
          offstage: !isActive,
          child: Align(
            alignment: AlignmentDirectional(0, -1),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  // boxShadow: [
                  //   BoxShadow(
                  //     blurRadius: 10,
                  //     color: Color(0x33000000),
                  //     offset: Offset(0, 2),
                  //   )
                  // ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    if (false)
                      TapRegion(
                        onTapInside: (e) {
                          widget.updateJsonRepeater(
                              _repeaterKey.currentState!.updateJsonRepeater());
                        },
                        child: Container(
                          height: 45,
                          width: 45,
                          color: Colors.black,
                        ),
                      ), // Space for the title container
                    DefaultRepeaterWidget(
                      key: _repeaterKey,
                      data: dataRepeater,
                      isEdit: true,
                      options: widget.options,
                      watermarkUser: FFAppState().fullName,
                      watermarkModule: widget.title,
                      updateJsonRepeater: (jsonRepeater) {
                        listToSend = jsonRepeater;
                        widget.updateJsonRepeater(jsonRepeater);
                      },
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional(0, -1),
          child: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              isActive = !isActive;
              setState(() {});
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.08,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Color(0x33000000),
                    offset: Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.title,
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          letterSpacing: 0.0,
                          color: FlutterFlowTheme.of(context).white,
                        ),
                  ),
                  Positioned(
                    right:
                        16.0, // Asegura que el ícono no esté pegado al borde derecho
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: FlutterFlowTheme.of(context).white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
