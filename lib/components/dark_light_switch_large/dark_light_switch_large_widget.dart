import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class DarkLightSwitchLargeWidget extends StatelessWidget {
  const DarkLightSwitchLargeWidget({super.key});

  void _changeTheme(BuildContext context, ThemeMode mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAlreadySelected = mode == ThemeMode.dark ? isDark : !isDark;

    if (isAlreadySelected) return;

    // Evita que Enter, usado en un formulario o WebView, reutilice el foco
    // del selector de tema y active una opción accidentalmente.
    FocusManager.instance.primaryFocus?.unfocus();
    setDarkModeSetting(context, mode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ExcludeFocus(
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
          ),
        ),
        child: Stack(
          children: [
            // Indicador deslizante
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),

            // Botones
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    excludeFromSemantics: true,
                    onTap: () => _changeTheme(context, ThemeMode.light),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_sunny_rounded,
                            size: 14,
                            color: isDark
                                ? FlutterFlowTheme.of(context).secondaryText
                                : Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Claro',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Outfit',
                                      color: isDark
                                          ? FlutterFlowTheme.of(context)
                                              .secondaryText
                                          : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                      letterSpacing: 0,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    excludeFromSemantics: true,
                    onTap: () => _changeTheme(context, ThemeMode.dark),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.nightlight_round,
                            size: 14,
                            color: isDark
                                ? Colors.white
                                : FlutterFlowTheme.of(context).secondaryText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Oscuro',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Outfit',
                                      color: isDark
                                          ? Colors.white
                                          : FlutterFlowTheme.of(context)
                                              .secondaryText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                      letterSpacing: 0,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
