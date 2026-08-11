import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../app_state.dart';
import '../../backend/api_requests/api_base_url.dart';
import '../../flutter_flow/custom_functions.dart';
import '../../flutter_flow/flutter_flow_expanded_image_view.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';

class DefaultFirmaExt extends StatefulWidget{
  const DefaultFirmaExt({
    Key? key,
    required this.controller,
    required this.isEdit,
    required this.text,
    required this.height,
    required this.width,
    this.onSignatureChanged,
  }) : super(key: key);

  final String text;
  final bool isEdit;
  final SignatureController controller;
  final double? height;
  final double? width;
  final Function(String base64Signature)? onSignatureChanged;

  @override
  State<DefaultFirmaExt> createState() => _DefaultFirmaExtState();
}
class _DefaultFirmaExtState extends State<DefaultFirmaExt> {
  late bool editSign = false;
  String? _drawnSignatureBase64;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _buildFirmaImageUrl() {
    final textValue = widget.text;
    if (textValue.isEmpty) return '';
    
    final extractedUrl = extractFirmaUrlFromJson(textValue);
    final normalizedUrl = normalizeFirmaUrl(extractedUrl);
    
    return ApiBaseUrl.build(
      tenant: FFAppState().organizacion,
      path: normalizedUrl,
    );
  }

  Widget _buildSignaturePreview() {
    final firmaImageUrl = _buildFirmaImageUrl();
    
    if (_drawnSignatureBase64 != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.memory(
            base64Decode(_drawnSignatureBase64!.split(',').last),
            width: double.infinity,
            height: 200.0,
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    
    if (firmaImageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            firmaImageUrl,
            width: double.infinity,
            height: 200.0,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 200.0,
                color: FlutterFlowTheme.of(context).secondaryBackground,
                child: Center(
                  child: Text(
                    'Sin firma',
                    style: TextStyle(
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Container(
        width: double.infinity,
        height: 200.0,
        color: FlutterFlowTheme.of(context).secondaryBackground,
        child: Center(
          child: Text(
            'Sin firma',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(' [DEBUG DefaultFirmaExt] widget.text: "${widget.text}"');
    print('🔍 [DEBUG DefaultFirmaExt] widget.isEdit: ${widget.isEdit}');
    print('🔍 [DEBUG DefaultFirmaExt] editSign: $editSign');
    print('🔍 [DEBUG DefaultFirmaExt] _drawnSignatureBase64: ${_drawnSignatureBase64 != null ? "exists" : "null"}');
    
    return Stack(
      children: [

        if (editSign)
        Container(
            width: MediaQuery.sizeOf(context).width * 1.0,
            height: 200.0,
            child: ClipRect(
              child: Signature(
                controller: widget.controller,
                backgroundColor: Colors.transparent,
                height: widget.height ?? 200,
                width: widget.width,
              ),
            )
        ),

        if (!editSign)
        InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: _drawnSignatureBase64 != null || _buildFirmaImageUrl().isNotEmpty ? () async {
            if (_drawnSignatureBase64 != null) {
              await Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.fade,
                  child: FlutterFlowExpandedImageView(
                    image: Image.memory(
                      base64Decode(_drawnSignatureBase64!.split(',').last),
                      fit: BoxFit.contain,
                    ),
                    allowRotation: false,
                    tag: 'drawn_signature_preview',
                    useHeroAnimation: true,
                  ),
                ),
              );
            } else {
              final firmaImageUrl = _buildFirmaImageUrl();
              await Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.fade,
                  child: FlutterFlowExpandedImageView(
                    image: Image.network(
                      firmaImageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/error_image.jpg',
                          width: double.infinity,
                          height: 200.0,
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                    allowRotation: false,
                    tag: '${firmaImageUrl}default_firma_text',
                    useHeroAnimation: true,
                  ),
                ),
              );
            }
          } : null,
          child: Hero(
            tag: _drawnSignatureBase64 != null ? 'drawn_signature_preview2' : '${_buildFirmaImageUrl()}default_firma_text2',
            transitionOnUserGestures: true,
            child: _buildSignaturePreview(),
          ),
        ),

        if (!editSign && widget.isEdit)
          Positioned(
            right: 10.0,
            top: 10.0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.transparent,
              ),
              child: IconButton(
                icon: Icon(
                    Icons.edit_outlined,
                  color: FlutterFlowTheme.of(context).primary,
                ),
                onPressed: () async {
                  safeSetState(() {
                    editSign = true;
                  });
                },
              ),
            ),
          ),

        if (editSign)
          Positioned(
            right: 10.0,
            top: 10.0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.transparent,
              ),
              child: IconButton(
                icon: Icon(
                    Icons.cancel,
                    color: Colors.red
                ),
                onPressed: () async {
                  safeSetState(() {
                    editSign = false;
                  });
                },
              ),
            ),
          ),



        if (editSign)
        Positioned(
          right: 50.0,
          top: 10.0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: Icon(
                  Icons.delete_outlined,
                  color: Colors.red
              ),
              onPressed: () async {
                widget.controller.clear();
              },
            ),
          ),
        ),

        if (editSign)
        Positioned(
          right: 90.0,
          top: 10.0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: Icon(
                  Icons.check,
                  color: Colors.white
              ),
              onPressed: () async {
                if (widget.controller.isNotEmpty) {
                  final image = await widget.controller.toImage();
                  if (image != null) {
                      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                    if (byteData != null) {
                      final bytes = byteData.buffer.asUint8List();
                      final base64String = base64Encode(bytes);
                      final fullBase64 = 'data:image/png;base64,$base64String';
                      widget.onSignatureChanged?.call(fullBase64);
                      safeSetState(() {
                        _drawnSignatureBase64 = fullBase64;
                      });
                    }
                  }
                }
                safeSetState(() {
                  editSign = false;
                });
              },
            ),
          ),
        ),

      ],
    );
  }
  }
