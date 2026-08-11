import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CargoSheetFooter extends StatelessWidget {
  const CargoSheetFooter({
    super.key,
    required this.formaPago,
    this.onPaymentTap,
    this.onProfileTap,
  });

  final String formaPago;
  final VoidCallback? onPaymentTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          _PaymentMethodButton(
            formaPago: formaPago,
            theme: theme,
            isDark: isDark,
            onTap: onPaymentTap,
          ),
          const Spacer(),
          _ProfileButton(theme: theme, onTap: onProfileTap),
        ],
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  const _PaymentMethodButton({
    required this.formaPago,
    required this.theme,
    required this.isDark,
    this.onTap,
  });

  final String formaPago;
  final FlutterFlowTheme theme;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined, color: theme.secondaryText, size: 18),
            const SizedBox(width: 8),
            Text(
              formaPago,
              style: TextStyle(
                color: isDark ? Colors.white : theme.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.theme, this.onTap});

  final FlutterFlowTheme theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.primary,
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 22),
      ),
    );
  }
}
