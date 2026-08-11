import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:octo_image/octo_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Header con logo glass circular. Premium, limpio, sin glows.
class GlassLogoHeader extends StatelessWidget {
  const GlassLogoHeader({
    super.key,
    this.logoUrl = '',
    this.size = 96,
    this.imageScale = 1.0,
    this.contentPaddingFactor = 0.0,
    this.darkSurface = false,
    this.blurHash = 'L9I5f1wf00~q-Vk;aKoL00we0000',
    this.imageProvider,
  });

  final String logoUrl;
  final double size;
  final double imageScale;
  final double contentPaddingFactor;
  final bool darkSurface;
  final String blurHash;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageWidget = imageProvider != null
        ? Image(
            image: imageProvider!,
            width: size,
            height: size,
            fit: BoxFit.contain,
          )
        : logoUrl.trim().isEmpty
            ? _AiLogoFallback(size: size)
            : OctoImage(
                placeholderBuilder: (_) => SizedBox.expand(
                  child: Image(
                    image: BlurHashImage(blurHash),
                    fit: BoxFit.cover,
                  ),
                ),
                image: NetworkImage(logoUrl),
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _AiLogoFallback(size: size),
              );

    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 800)),
        ScaleEffect(
          begin: Offset(0.85, 0.85),
          end: Offset(1, 1),
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
        ),
      ],
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: darkSurface
                    ? Colors.black.withValues(alpha: 0.30)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: darkSurface
                      ? Colors.white.withValues(alpha: 0.20)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.50),
                  width: 0.8,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: EdgeInsets.all(size * contentPaddingFactor),
                  child: Transform.scale(
                    scale: imageScale,
                    child: imageWidget,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiLogoFallback extends StatelessWidget {
  const _AiLogoFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Container(
        width: size * 0.58,
        height: size * 0.58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primary.withValues(alpha: 0.20),
              theme.secondary.withValues(alpha: 0.10),
            ],
          ),
          border: Border.all(
            color: theme.primary.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.primary, theme.secondary],
          ).createShader(bounds),
          child: Icon(
            Icons.psychology_alt_rounded,
            color: Colors.white,
            size: size * 0.34,
          ),
        ),
      ),
    );
  }
}
