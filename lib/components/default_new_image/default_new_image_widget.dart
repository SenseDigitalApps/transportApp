import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:page_transition/page_transition.dart';
import 'default_new_image_model.dart';
export 'default_new_image_model.dart';

class DefaultNewImageWidget extends StatefulWidget {
  DefaultNewImageWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controller,
    required this.onFileSelected,
    this.watermarkUser,
    this.watermarkModule,
  });

  final String? text;
  final bool? isEdit;
  FFUploadedFile controller;
  final Function(FFUploadedFile) onFileSelected;
  final String? watermarkUser;
  final String? watermarkModule;

  @override
  State<DefaultNewImageWidget> createState() => DefaultNewImageWidgetState();
}

class DefaultNewImageWidgetState extends State<DefaultNewImageWidget> {
  late DefaultNewImageModel _model;
  late FFUploadedFile _localController;
  bool uploadedImage = false;

  void updateUploadedImage(bool value, FFUploadedFile selectedFile) {
    setState(() {
      _localController = selectedFile;
      widget.controller = _localController;
      uploadedImage = value;
      widget.onFileSelected(selectedFile);
    });
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultNewImageModel());
    _localController = widget.controller;

    if (_localController.bytes != null && _localController.bytes!.isNotEmpty) {
      uploadedImage = true;
    }
  }

  @override
  void didUpdateWidget(DefaultNewImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _localController = widget.controller;
      if (_localController.bytes != null &&
          _localController.bytes!.isNotEmpty) {
        uploadedImage = true;
      }
    }
  }

  Future<MediaSource> _pickImageSource() async => MediaSource.camera;

  Future<String?> _getCurrentCoordinatesLabel() async {
    if (kIsWeb) return null;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );

      return 'Lat ${position.latitude.toStringAsFixed(6)}, '
          'Lon ${position.longitude.toStringAsFixed(6)}';
    } catch (_) {
      return null;
    }
  }

  int _measureTextWidth(String text, img.BitmapFont font) {
    var width = 0;
    for (final codeUnit in text.codeUnits) {
      width += font.characterXAdvance(String.fromCharCode(codeUnit));
    }
    return width;
  }

  img.Image _applyWatermarkToImage(img.Image source, String watermarkText) {
    final image = img.Image.from(source);
    final font = img.arial14;
    final lines = watermarkText.split('\n');

    var maxTextWidth = 0;
    for (final line in lines) {
      final lineWidth = _measureTextWidth(line, font);
      if (lineWidth > maxTextWidth) {
        maxTextWidth = lineWidth;
      }
    }

    final lineHeight = (font.lineHeight > 0 ? font.lineHeight : 14) + 4;
    final margin = (image.width * 0.02).round().clamp(6, 18).toInt();
    const internalPadding = 8;

    final boxWidth = maxTextWidth + (internalPadding * 2);
    final boxHeight = (lines.length * lineHeight) + (internalPadding * 2);

    final x1 =
        (image.width - boxWidth - margin).clamp(0, image.width - 1).toInt();
    final y1 =
        (image.height - boxHeight - margin).clamp(0, image.height - 1).toInt();
    final x2 = (x1 + boxWidth).clamp(0, image.width - 1).toInt();
    final y2 = (y1 + boxHeight).clamp(0, image.height - 1).toInt();

    img.fillRect(
      image,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
      color: img.ColorRgba8(0, 0, 0, 150),
    );

    for (var i = 0; i < lines.length; i++) {
      img.drawString(
        image,
        lines[i],
        font: font,
        x: x1 + internalPadding,
        y: y1 + internalPadding + (i * lineHeight),
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    return image;
  }

  Future<FFUploadedFile> _buildProcessedUploadedFile({
    required SelectedFile media,
    required bool addWatermark,
  }) async {
    final decoded = img.decodeImage(media.bytes);

    if (decoded == null) {
      return FFUploadedFile(
        name: media.storagePath.split('/').last,
        bytes: media.bytes,
        height: media.dimensions?.height,
        width: media.dimensions?.width,
        blurHash: media.blurHash,
      );
    }

    var processedImage = img.bakeOrientation(decoded);

    if (addWatermark) {
      final nowText = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final userText = (widget.watermarkUser != null &&
              widget.watermarkUser!.trim().isNotEmpty)
          ? widget.watermarkUser!.trim()
          : (FFAppState().fullName.trim().isNotEmpty
              ? FFAppState().fullName.trim()
              : 'Usuario no disponible');
      final moduleText = (widget.watermarkModule != null &&
              widget.watermarkModule!.trim().isNotEmpty)
          ? widget.watermarkModule!.trim()
          : 'Módulo no disponible';
      final coordinatesLabel = await _getCurrentCoordinatesLabel();
      final watermarkText = coordinatesLabel == null
          ? '$nowText\nUsuario: $userText\nMódulo: $moduleText\nGPS: no disponible'
          : '$nowText\nUsuario: $userText\nMódulo: $moduleText\n$coordinatesLabel';
      processedImage = _applyWatermarkToImage(processedImage, watermarkText);
    }

    final encodedBytes = Uint8List.fromList(
      img.encodeJpg(processedImage, quality: 90),
    );

    final originalName = media.storagePath.split('/').last;
    final normalizedName =
        originalName.replaceAll(RegExp(r'\.[^./\\]+$'), '.jpg');

    return FFUploadedFile(
      name: normalizedName,
      bytes: encodedBytes,
      height: processedImage.height.toDouble(),
      width: processedImage.width.toDouble(),
      blurHash: media.blurHash,
    );
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
          SizedBox(height: 12),
          Text(
            'Imagen no disponible',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isEdit!)
              FFButtonWidget(
                onPressed: () async {
                  if (_model.isDataUploading)
                    return; // Evita múltiples cargas simultáneas

                  setState(() {
                    _model.isDataUploading = true;
                  });

                  final mediaSource = await _pickImageSource();

                  final selectedMedia = await selectMedia(
                    maxWidth: 800.00,
                    maxHeight: 800.00,
                    imageQuality: 80,
                    mediaSource: mediaSource,
                    isVideo: false,
                  );

                  if (selectedMedia == null || selectedMedia.isEmpty) {
                    setState(() => _model.isDataUploading = false);
                    return;
                  }

                  final isValid = selectedMedia.every(
                    (m) => validateFileFormat(m.storagePath, context),
                  );

                  if (!isValid) {
                    setState(() => _model.isDataUploading = false);
                    return;
                  }

                  final addWatermark = mediaSource == MediaSource.camera;
                  final selectedUploadedFiles = await Future.wait(
                    selectedMedia.map(
                      (m) => _buildProcessedUploadedFile(
                        media: m,
                        addWatermark: addWatermark,
                      ),
                    ),
                  );

                  if (selectedUploadedFiles.length != selectedMedia.length) {
                    setState(() => _model.isDataUploading = false);
                    return;
                  }

                  if (!mounted) return;
                  setState(() {
                    _model.isDataUploading = false;
                    _localController = selectedUploadedFiles.first;
                    widget.controller = _localController;
                    widget.onFileSelected(selectedUploadedFiles.first);
                    uploadedImage = true;
                  });
                },
                text: _model.isDataUploading ? 'Subiendo...' : 'Subir imagen',
                icon: _model.isDataUploading
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Icon(Icons.upload, size: 15),
                options: FFButtonOptions(
                  height: 40,
                  padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                  iconPadding: EdgeInsets.zero,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                  elevation: 0,
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            Align(
              alignment: AlignmentDirectional(0, 0),
              child: Container(
                width: 250,
                height: 250,
                alignment: AlignmentDirectional(0, 0),
                child: Container(
                  width: 220,
                  height: 220,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isEdit! &&
                          (_localController.name != null) &&
                          uploadedImage)
                        RepaintBoundary(
                          child: InkWell(
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
                                    image: Image.memory(
                                      _localController.bytes ??
                                          Uint8List.fromList([]),
                                      fit: BoxFit.contain,
                                    ),
                                    allowRotation: false,
                                    tag:
                                        buildMediaUrl(widget.text!) + 'default_new_image',
                                    useHeroAnimation: true,
                                  ),
                                ),
                              );
                            },
                            child: RepaintBoundary(
                              // ⬅️ Optimizamos el Hero
                              child: Hero(
                                tag:
                                    buildMediaUrl(widget.text!) + 'default_new_image2',
                                transitionOnUserGestures: true,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _localController.bytes ??
                                        Uint8List.fromList([]),
                                    width: 220,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.isEdit! &&
                          (widget.text!.isNotEmpty) &&
                          !uploadedImage)
                        RepaintBoundary(
                          child: InkWell(
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
                                      buildMediaUrl(widget.text!),
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildErrorWidget(context);
                                      },
                                    ),
                                    allowRotation: false,
                                    tag:
                                        buildMediaUrl(widget.text!) + 'default_new_image3',
                                    useHeroAnimation: true,
                                  ),
                                ),
                              );
                            },
                            child: RepaintBoundary(
                              // ⬅️ Optimizamos el Hero
                              child: Hero(
                                tag:
                                    buildMediaUrl(widget.text!) + 'default_new_image4',
                                transitionOnUserGestures: true,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    buildMediaUrl(widget.text!),
                                    width: 220,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildErrorWidget(context);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!widget.isEdit! &&
                          (widget.text!.isNotEmpty) &&
                          !uploadedImage)
                        RepaintBoundary(
                          child: InkWell(
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
                                      buildMediaUrl(widget.text!),
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildErrorWidget(context);
                                      },
                                    ),
                                    allowRotation: false,
                                    tag:
                                        buildMediaUrl(widget.text!) + 'default_new_image5',
                                    useHeroAnimation: true,
                                  ),
                                ),
                              );
                            },
                            child: RepaintBoundary(
                              // ⬅️ Optimizamos el Hero
                              child: Hero(
                                tag:
                                    buildMediaUrl(widget.text!) + 'default_new_image6',
                                transitionOnUserGestures: true,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    buildMediaUrl(widget.text!),
                                    width: 220,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildErrorWidget(context);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!widget.isEdit! && (widget.text!.isEmpty))
                        Align(
                          alignment: AlignmentDirectional(0, 0),
                          child: Text(
                            'Sin Imagen',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ].divide(SizedBox(height: 30)),
        ),
      ),
    );
  }
}
