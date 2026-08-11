import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/cohet_module.dart';

class ModuleTile extends StatelessWidget {
  final CohetModule module;
  final double size;
  final VoidCallback? onTap;

  const ModuleTile({
    super.key,
    required this.module,
    required this.size,
    this.onTap,
  });

  static const Map<String, IconData> _iconMap = {
    'assignment': Icons.assignment_outlined,
    'people': Icons.people_outline,
    'engineering': Icons.engineering_outlined,
    'receipt_long': Icons.receipt_long_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.primary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.18),
                    theme.secondary.withValues(alpha: 0.22),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                _iconMap[module.iconKey] ?? Icons.folder_outlined,
                color: theme.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                module.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.titleMedium.override(
                  fontFamily: 'Outfit',
                  color: theme.primaryText,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
