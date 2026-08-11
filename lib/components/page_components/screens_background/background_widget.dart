import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:transport_app/app_state.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class DynamicBackground extends StatelessWidget {
  final Color bottomLeftColor;
  final Color topRightColor;

  const DynamicBackground({
    Key? key,
    required this.bottomLeftColor,
    required this.topRightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl:  (FFAppState().fondoLink == '')? 'https://itsquery.com/mediafiles/auth/bg9-dark.jpg': FFAppState().fondoLink,
            fit: BoxFit.cover,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade300,
            ),
          ),
        ),

        // 2) Capa blanca semitransparente sobre la imagen
        Positioned.fill(
          child: Container(
            color: FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.95),
          ),
        ),

        // Positioned(
        //   bottom: screenHeight * 0.2,
        //   left: -screenWidth * 0.3,
        //   child: Transform.rotate(
        //     angle: -0.785, // About 17 degrees counterclockwise
        //     child: Container(
        //       width: screenWidth * 0.5,
        //       height: screenHeight * 0.25,
        //       decoration: BoxDecoration(
        //         color: topRightColor,
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //     ),
        //   ),
        // ),
        // Positioned(
        //   bottom: screenHeight * 0.05,
        //   left: -screenWidth * 0.3,
        //   child: Transform.rotate(
        //     angle: -0.785, // About 17 degrees counterclockwise
        //     child: Container(
        //       width: screenWidth * 0.5,
        //       height: screenHeight * 0.25,
        //       decoration: BoxDecoration(
        //         color: bottomLeftColor,
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //     ),
        //   ),
        // ),
        //
        // // Top right shape
        // Positioned(
        //   top: screenHeight * 0.05,
        //   right: -screenWidth * 0.3,
        //   child: Transform.rotate(
        //     angle: -0.785, // About 17 degrees counterclockwise
        //     child: Container(
        //       width: screenWidth * 0.5,
        //       height: screenHeight * 0.25,
        //       decoration: BoxDecoration(
        //         color: topRightColor,
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //     ),
        //   ),
        // ),
        //
        // Positioned(
        //   top: screenHeight * 0.2,
        //   right: -screenWidth * 0.3,
        //   child: Transform.rotate(
        //     angle: -0.785, // About 17 degrees counterclockwise
        //     child: Container(
        //       width: screenWidth * 0.5,
        //       height: screenHeight * 0.25,
        //       decoration: BoxDecoration(
        //         color: bottomLeftColor,
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //     ),
        //   ),
        // ),

      ],
    );
  }
}
