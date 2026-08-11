import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Botón glass premium empresarial.
/// Sin glows de neón, solo colores sólidos del theme con blur.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isPrimary = true,
    this.isFullWidth = true,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isPrimary;
  final bool isFullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);

    return Animate(
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 700)),
        SlideEffect(
          begin: Offset(0, 0.08),
          end: Offset.zero,
          duration: Duration(milliseconds: 700),
        ),
      ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: GestureDetector(
            onTap: isLoading ? null : onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isFullWidth ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: isFullWidth ? 0 : 28,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: isPrimary
                    ? theme.primary.withValues(alpha: 0.88)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.50)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPrimary
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.45)),
                  width: 0.8,
                ),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: isPrimary || isDark ? Colors.white : theme.primaryText, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: TextStyle(
                            color: isPrimary || isDark ? Colors.white : theme.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
