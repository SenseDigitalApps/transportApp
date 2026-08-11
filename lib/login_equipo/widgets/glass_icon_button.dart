import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Botón circular glass premium empresarial.
/// Limpio, sin glows de color.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 900)),
        ScaleEffect(
          begin: Offset(0.85, 0.85),
          end: Offset(1, 1),
          duration: Duration(milliseconds: 900),
        ),
      ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.50),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.45),
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.7),
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
