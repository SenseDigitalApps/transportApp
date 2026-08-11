import 'dart:ui';
import 'package:flutter/material.dart';

/// Carta glassmórfica reutilizable.
/// Equivale a lo que antes era _GlassmorphicSheet pero como widget standalone.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.borderRadius = 20,
    this.opacity = 0.5,
    this.borderOpacity = 0.15,
  });

  final Widget child;
  final double blur;
  final double borderRadius;
  final double opacity;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: opacity)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: borderOpacity)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
