

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../backend/api_requests/api_base_url.dart';
import '../../flutter_flow/custom_functions.dart';
import '../../flutter_flow/flutter_flow_expanded_image_view.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';

class DefaultFirmaWidget extends StatefulWidget {
  const DefaultFirmaWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controller,
    required this.rolSign,
    this.onChanged,
  });

  final String? text;
  final bool isEdit;
  final Map<String, dynamic> controller;
  final List<dynamic> rolSign;
  final VoidCallback? onChanged;

  @override
  State<DefaultFirmaWidget> createState() => _DefaultFirmaWidgetState();
}

class _DefaultFirmaWidgetState extends State<DefaultFirmaWidget> {

  late bool isSigned = false;

  @override
  void initState() {
    super.initState();

    if (widget.controller['firma'] != null && widget.controller['firma'].isNotEmpty) {
      isSigned = true;
    }
  }

  bool _canUserSign() {
    final String currentRole = FFAppState().role.trim().toLowerCase();
    final List<dynamic> rolSign = widget.rolSign;
    final List allRoles = FFAppState().roleGroups;

    final allowedRoleNames = allRoles
        .where((role) {
          if (role is! Map) return false;
          final roleId = role['id'];
          return rolSign.any((signId) => 
            signId.toString().trim() == roleId.toString().trim()
          );
        })
        .map((role) => role['name'].toString().trim().toLowerCase())
        .toList();

    return allowedRoleNames.any((name) => currentRole.contains(name) || name.contains(currentRole));
  }

  String _buildFirmaImageUrl() {
    final firmaValue = widget.controller['firma']?.toString() ?? '';
    if (firmaValue.isEmpty) return '';
    
    final extractedUrl = extractFirmaUrlFromJson(firmaValue);
    final normalizedUrl = normalizeFirmaUrl(extractedUrl);
    
    return ApiBaseUrl.build(
      tenant: FFAppState().organizacion,
      path: normalizedUrl,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 [DEBUG DefaultFirma] widget.text: "${widget.text}"');
    print('🔍 [DEBUG DefaultFirma] widget.controller: ${widget.controller}');
    print('🔍 [DEBUG DefaultFirma] isSigned: $isSigned');
    
    final firmaImageUrl = _buildFirmaImageUrl();
    
    return isSigned
          ? Stack(
            children: [
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  await Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.fade,
                      child: FlutterFlowExpandedImageView(
                        image: Image.network(
                          firmaImageUrl,
                          fit: BoxFit.contain,
                        ),
                        allowRotation: false,
                        tag: '${firmaImageUrl}default_firma',
                        useHeroAnimation: true,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: '${firmaImageUrl}default_firma2',
                  transitionOnUserGestures: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      firmaImageUrl,
                      width: double.infinity,
                      height: 200.0,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              if (FFAppState().firma == widget.controller['firma'] && widget.isEdit)
              Positioned(
                top: 10,
                right: 10,

                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.transparent,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_forever,
                      color: FlutterFlowTheme.of(context).error,
                    ),
                    onPressed: () async {
                      safeSetState(() {
                        widget.controller['firmado'] = false;
                        widget.controller['firma'] = '';
                        isSigned = false;
                      });
                      widget.onChanged?.call();
                    },
                  ),
                ),
              ),

              if (widget.controller['name'] != null && widget.controller['name'].isNotEmpty
                  && widget.controller['datetime'] != null && widget.controller['datetime'].toString().isNotEmpty)
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.controller['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat("d 'de' MMMM 'de' y, h:mm a", 'es_ES')
                            .format(DateTime.parse(widget.controller['datetime']).toLocal()),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ]
          )
          : AbsorbPointer(
            absorbing: !widget.isEdit,
            child: FFButtonWidget(
                    onPressed: !_canUserSign() ? null : () async {
                      widget.controller['firmado'] = true;
                      widget.controller['firma'] = FFAppState().firma;
                      widget.controller['name'] = FFAppState().fullName;
                      widget.controller['datetime'] = DateTime.now().toUtc().toIso8601String();

                        setState(() {
                          isSigned = true;
                        });
                        widget.onChanged?.call();
                    },
                    text: _canUserSign() ?'Firmar solicitud' : 'No puede firmar esta solicitud',
                    options: FFButtonOptions(
            width: MediaQuery.sizeOf(context).width * 1,
            height: 44.0,
            padding:
            const EdgeInsetsDirectional.fromSTEB(
                0.0, 0.0, 0.0, 0.0),
            iconPadding:
            const EdgeInsetsDirectional.fromSTEB(
                0.0, 0.0, 0.0, 0.0),
            color: Colors.transparent,
            textStyle:
            FlutterFlowTheme.of(context)
                .titleSmall
                .override(
              fontFamily: 'Readex Pro',
              color:
              FlutterFlowTheme.of(
                  context)
                  .white,
              letterSpacing: 0.0,
            ),
            elevation: 0.0,
            borderSide: const BorderSide(
              color: Colors.transparent,
              width: 1.0,
            ),
            borderRadius:
            BorderRadius.circular(12.0),
                    ),
                  ),
          ) ;


  }
}
