import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Diálogo glassmorphism premium para preguntar si guardar credenciales.
///
/// Se usa después de un login exitoso para ofrecer al usuario la opción
/// de guardar sus credenciales y habilitar el login biométrico.
/// Soporta light y dark mode usando [FlutterFlowTheme].
class GlassSaveCredentialsDialog extends StatelessWidget {
  const GlassSaveCredentialsDialog({super.key});

  /// Muestra el diálogo y retorna `true` si el usuario acepta, `false` si no.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const GlassSaveCredentialsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);

    return PopScope(
      canPop: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: Colors.transparent,
            child: Animate(
              effects: [
                FadeEffect(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                ),
                ScaleEffect(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1, 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                ),
              ],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A2E).withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.60),
                        width: 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono biométrico
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            size: 32,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Título
                        Text(
                          '¿Guardar credenciales?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : theme.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Outfit',
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Descripción
                        Text(
                          'Guarda tus credenciales para iniciar sesión '
                          'automáticamente con tu huella digital o Face ID.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.65)
                                : theme.secondaryText,
                            fontSize: 14,
                            fontFamily: 'Outfit',
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Botones
                        Row(
                          children: [
                            // Botón No
                            Expanded(
                              child: _GlassDialogButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                label: 'No',
                                isPrimary: false,
                                isDark: isDark,
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Botón Sí, guardar
                            Expanded(
                              child: _GlassDialogButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                label: 'Sí, guardar',
                                isPrimary: true,
                                isDark: isDark,
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ─── Botón interno del diálogo ───────────────────────────────────────────

/// Botón con estilo glass para usar dentro de [GlassSaveCredentialsDialog].
class _GlassDialogButton extends StatelessWidget {
  const _GlassDialogButton({
    required this.onPressed,
    required this.label,
    required this.isPrimary,
    required this.isDark,
    required this.theme,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isPrimary;
  final bool isDark;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isPrimary
                  ? theme.primary.withValues(alpha: 0.88)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.55)),
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
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isPrimary || isDark ? Colors.white : theme.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
