import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Carta principal glass para el formulario de login.
/// Estilo premium: blur suave, bordes blancos muy sutiles, sin glows de color.
class GlassAuthCard extends StatelessWidget {
  const GlassAuthCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(28),
    this.borderRadius = 24,
    this.blur = 20,
    this.darkSurface = false,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double borderRadius;
  final double blur;
  final bool darkSurface;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Animate(
      effects: const [
        FadeEffect(
            duration: Duration(milliseconds: 800), curve: Curves.easeOut),
        SlideEffect(
          begin: Offset(0, 0.12),
          end: Offset.zero,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOut,
        ),
      ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: darkSurface
                  ? Colors.black.withValues(alpha: 0.38)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: darkSurface
                    ? Colors.white.withValues(alpha: 0.18)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.55),
                width: 0.8,
              ),
            ),
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
