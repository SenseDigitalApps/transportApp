import 'package:flutter/material.dart';

/// Fondo sutil y elegante para la pantalla de login.
/// Usa un degradado oscuro muy tenue que no compite con el contenido.
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? Colors.black : Colors.white).withValues(alpha: 0.0),
            (isDark ? Colors.black : Colors.white).withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }
}
