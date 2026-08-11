import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:transport_app/flutter_flow/flutter_flow_theme.dart';

class LoaderImage extends StatefulWidget {
  final String backgroundUrl;
  final String loadingText;

  const LoaderImage({
    super.key,
    this.backgroundUrl = '',
    required this.loadingText,
  });
  @override
  State<LoaderImage> createState() => _LoaderImageState();
}

class _LoaderImageState extends State<LoaderImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundUrl = widget.backgroundUrl.trim().isEmpty
        ? 'https://us.itsquery.com/mediafiles/auth/bg9-dark.jpg'
        : widget.backgroundUrl.trim();
    final loaderColor = FlutterFlowTheme.of(context).white;

    return Stack(
      fit: StackFit.expand,
      children: [
        // El fondo acompaña la identidad visual configurada para el tenant.
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: effectiveBackgroundUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: const Color(0xFF0D1117),
            ),
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFF0D1117),
            ),
          ),
        ),

        // Overlay para conservar el contraste del logo con cualquier fondo.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.48),
                  Colors.black.withValues(alpha: 0.62),
                ],
              ),
            ),
          ),
        ),

        // Contenido principal
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Espacio arriba
            const SizedBox(height: 10),

            // Logo centrado
            Center(
              child: ScaleTransition(
                scale: _animation,
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  height: MediaQuery.sizeOf(context).height * 0.8,
                  padding: const EdgeInsetsDirectional.all(70),
                  child: Image.asset(
                    'assets/images/query_loader_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Loader al fondo
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loaderColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
