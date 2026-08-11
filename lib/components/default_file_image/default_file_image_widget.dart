import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'package:flutter/material.dart';
import 'default_file_image_model.dart';
export 'default_file_image_model.dart';

class DefaultFileImageWidget extends StatefulWidget {
   DefaultFileImageWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controller,
  });

  final String? text;
  final bool isEdit;
  FFUploadedFile controller;

  @override
  State<DefaultFileImageWidget> createState() => _DefaultFileImageWidgetState();
}

class _DefaultFileImageWidgetState extends State<DefaultFileImageWidget> {
  late DefaultFileImageModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultFileImageModel());

  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isEdit)
          FFButtonWidget(
            onPressed: () async {
              final selectedMedia = await selectMediaWithSourceBottomSheet(
                context: context,
                maxWidth: 1000.00,
                maxHeight: 1000.00,
                imageQuality: 75,
                allowPhoto: true,
              );
              if (selectedMedia != null &&
                  selectedMedia.every(
                          (m) => validateFileFormat(m.storagePath, context))) {
                setState(() => _model.isDataUploading = true);
                var selectedUploadedFiles = <FFUploadedFile>[];

                try {
                  selectedUploadedFiles = selectedMedia
                      .map((m) => FFUploadedFile(
                    name: m.storagePath.split('/').last,
                    bytes: m.bytes,
                    height: m.dimensions?.height,
                    width: m.dimensions?.width,
                    blurHash: m.blurHash,
                  ))
                      .toList();
                } finally {
                  _model.isDataUploading = false;
                }
                if (selectedUploadedFiles.length == selectedMedia.length) {
                  setState(() {
                    widget.controller = selectedUploadedFiles.first;
                  });
                } else {
                  setState(() {});
                  return;
                }
              }
            },
            text: 'Subir imágenes',
            icon: const Icon(
              Icons.upload,
              size: 24.0,
            ),
            options: FFButtonOptions(
              height: 40.0,
              padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
              iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
              color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: 'Outfit',
                color: FlutterFlowTheme.of(context).primary,
                letterSpacing: 0.0,
              ),
              elevation: 0,
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          width: 250.0,
          height: 250.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: Container(
            width: 230.0,
            height: 230.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground.withValues(alpha: 0.3),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: widget.isEdit
                    ? Image.memory(widget.controller.bytes ?? Uint8List.fromList([]),).image
                    : NetworkImage('https://${FFAppState().organizacion}.itsquery.com${widget.text}'),
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }
}
