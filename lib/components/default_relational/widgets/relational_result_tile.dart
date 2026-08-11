import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class RelationalResultTile extends StatelessWidget {
  final dynamic item;
  final String typeRelation;
  final VoidCallback onTap;

  const RelationalResultTile({
    required this.item,
    required this.typeRelation,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    if (typeRelation == 'user') {
      final id = getJsonField(item, r'''$.id''')?.toString() ?? '';
      final fullName = getJsonField(item, r'''$.full_name''')?.toString() ?? '';
      text = '$id - $fullName';
    } else {
      final consecutivo = getJsonField(item, r'''$.consecutivo''')?.toString() ?? '';
      final title = getJsonField(item, r'''$.title''')?.toString() ?? '';
      text = '$consecutivo - $title';
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: FlutterFlowTheme.of(context).alternate.withOpacity(0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              text,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          Divider(
            thickness: 0.5,
            height: 1,
            color: FlutterFlowTheme.of(context).secondaryText.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
