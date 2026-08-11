import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

class RelationalSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEdit;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onViewDetail;
  final bool showSuffixes;
  final bool showEye;

  const RelationalSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isEdit,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.onViewDetail,
    required this.showSuffixes,
    required this.showEye,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      constraints: const BoxConstraints(minHeight: 45, maxHeight: 65),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        readOnly: !isEdit,
        onChanged: onChanged,
        autofocus: false,
        obscureText: false,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0,
              ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0x00000000), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).error,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).error,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: FlutterFlowTheme.of(context).secondaryBackground,
          suffixIcon: showSuffixes
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showEye)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.remove_red_eye_outlined,
                          size: 20,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                        onPressed: onViewDetail,
                      ),
                    const SizedBox(width: 4),
                    if (isEdit)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                        onPressed: onClear,
                      ),
                  ],
                )
              : null,
        ),
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Outfit',
              fontSize: 11,
              letterSpacing: 0,
            ),
        maxLines: 1,
        minLines: 1,
      ),
    );
  }
}
