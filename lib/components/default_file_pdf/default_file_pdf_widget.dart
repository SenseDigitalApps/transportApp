import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'package:flutter/material.dart';
import 'default_file_pdf_model.dart';
export 'default_file_pdf_model.dart';

class DefaultFilePdfWidget extends StatefulWidget {
  DefaultFilePdfWidget({
    super.key,
    required this.pdfUrl,
    required this.isEdit,
    required this.controller,
    required this.onFileSelected
  });

  final String? pdfUrl;
  final bool isEdit;
  FFUploadedFile controller;
  final Function(FFUploadedFile) onFileSelected;

  @override
  State<DefaultFilePdfWidget> createState() => _DefaultFilePdfWidgetState();
}

class _DefaultFilePdfWidgetState extends State<DefaultFilePdfWidget> {
  late DefaultFilePdfModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultFilePdfModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEdit) {
      if (widget.pdfUrl != '' && widget.pdfUrl != ' ' && widget.pdfUrl != null) {
        return InkWell(
          onTap: () async {
            context.pushNamed('pdfviewer', queryParameters: {
              'pdfUrl': widget.pdfUrl,
            });
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: FlutterFlowTheme.of(context).primary,
              size: 40,
            ),
          ),
        );
      } else {
        return Text(
          'Sin PDF adjunto',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Outfit',
            fontSize: 16,
            letterSpacing: 0,
            fontWeight: FontWeight.w500,
            color: FlutterFlowTheme.of(context).primary,
          ),
        );
      }
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FFButtonWidget(
            onPressed: () async {
              final selectedFiles = await selectFiles(
                allowedExtensions: ['pdf'],
                multiFile: false,
              );
              if (selectedFiles != null) {
                setState(() => _model.isDataUploading = true);
                var selectedUploadedFiles = <FFUploadedFile>[];

                try {
                  selectedUploadedFiles = selectedFiles
                      .map((m) => FFUploadedFile(
                    name: m.storagePath.split('/').last,
                    bytes: m.bytes,
                  ))
                      .toList();
                } finally {
                  _model.isDataUploading = false;
                }
                if (selectedUploadedFiles.length == selectedFiles.length) {
                  setState(() {
                    widget.controller = selectedUploadedFiles.first;
                  });
                  if (selectedUploadedFiles.length == selectedFiles.length) {
                    widget.onFileSelected(selectedUploadedFiles.first);
                  }
                } else {
                  setState(() {});
                  return;
                }
              }
            },
            text: 'Subir PDF',
            icon: const Icon(
              Icons.document_scanner_outlined,
              size: 15,
            ),
            options: FFButtonOptions(
              height: 40,
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
              iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
              color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: 'Outfit',
                color: FlutterFlowTheme.of(context).primary,
                letterSpacing: 0,
              ),
              elevation: 0,
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            valueOrDefault<String>(
              (widget.controller.bytes?.isEmpty ?? true)
                  ? 'Adjunta un archivo.'
                  : widget.controller.name,
              'Adjunta un archivo.',
            ),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Outfit',
              letterSpacing: 0,
            ),
          ),
        ],
      );
    }
  }
}
