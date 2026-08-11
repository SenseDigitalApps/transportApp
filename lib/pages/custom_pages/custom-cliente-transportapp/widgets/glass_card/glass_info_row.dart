import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Fila label: valor para usar dentro de GlassSection.
class GlassInfoRow extends StatelessWidget {
  const GlassInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.isHighlighted = false,
    this.isBold = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool isHighlighted;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono opcional
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: hasValue
                  ? (isHighlighted ? theme.primary : theme.secondaryText)
                  : theme.secondaryText.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
          ],
          // Label
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: hasValue
                    ? theme.secondaryText
                    : theme.secondaryText.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ),
          // Valor
          Expanded(
            child: Text(
              hasValue ? value : '—',
              style: TextStyle(
                color: isDark ? Colors.white : theme.primaryText,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
