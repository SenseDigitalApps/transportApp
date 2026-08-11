import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../flutter_flow/flutter_flow_expanded_image_view.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';

class DefaultImageViewWidget extends StatefulWidget {
  const DefaultImageViewWidget({
    super.key,
    this.image
  });

  final String? image;

  @override
  State<DefaultImageViewWidget> createState() => DefaultImageViewWidgetState();
}

class DefaultImageViewWidgetState extends State<DefaultImageViewWidget> {


  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
  }


  Widget _buildImageView() {

      return Image.network(
      'https://${FFAppState().organizacion}.itsquery.com${widget.image}',
      width: 220,
      height: 220,
      fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/app_launcher_icon.png',
          width: 220,
          height: 220,
          fit: BoxFit.contain,
        );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const AlignmentDirectional(0, 0),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () async {
              if (widget.image != null) {
                await Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: FlutterFlowExpandedImageView(
                      image: _buildImageView(),
                      allowRotation: false,
                      tag: 'local_image_view',
                      useHeroAnimation: true,
                    ),
                  ),
                );
              }
            },
            child: Hero(
              tag:'local_image_view',
              transitionOnUserGestures: true,
              child: _buildImageView(),
            ),
          ),
        ),
      ),
    );
  }
}