import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/solicitud_trabajo.dart';
import '../utils/currency_formatter.dart';
import '../utils/time_formatter.dart';
import '../utils/solicitud_historial_status.dart';
import '../utils/status_colors.dart';
import 'cargo_request_info_chip.dart';

class HistorialCard extends StatelessWidget {
  const HistorialCard({
    super.key,
    required this.solicitud,
    required this.isSelected,
    required this.onTap,
    this.onCardTap,
    this.statusColors,
  });

  final SolicitudTrabajo solicitud;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onCardTap;
  final Map<String, StatusColor>? statusColors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: isSelected ? const EdgeInsets.all(20) : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withValues(alpha: isDark ? 0.15 : 0.1)
              : (isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: isDark ? 0.25 : 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark, theme),
            const SizedBox(height: 14),
            _buildRouteRow(context, isDark, theme),
            const SizedBox(height: 10),
            _buildChips(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, FlutterFlowTheme theme) {
    return Row(
      children: [
        _buildTruckIcon(theme, isDark),
        const SizedBox(width: 14),
        Expanded(child: _buildTitleAndSubtitle(theme, isDark)),
        _buildStatusBadge(),
        const SizedBox(width: 8),
        if (onCardTap != null) ...[
          GestureDetector(
            onTap: onCardTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.info_outline,
                color: theme.secondaryText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        _buildSelectionIndicator(theme),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final historialStatus = HistorialStatusConfig.get(solicitud.estado);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: historialStatus.bgColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: historialStatus.bgColor.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            solicitud.estado,
            style: TextStyle(
              color: historialStatus.textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTruckIcon(FlutterFlowTheme theme, bool isDark) {
    return Container(
      padding: isSelected ? const EdgeInsets.all(12) : const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primary.withValues(alpha: 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.local_shipping,
        color: isSelected
            ? theme.primary
            : (isDark ? Colors.white : theme.primaryText),
        size: isSelected ? 28 : 24,
      ),
    );
  }

  Widget _buildTitleAndSubtitle(FlutterFlowTheme theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '#${solicitud.consecutive} — ${solicitud.title}',
          style: TextStyle(
            color: isDark ? Colors.white : theme.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: isSelected ? 17 : 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          solicitud.tipoCarga,
          style: TextStyle(
            color: theme.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionIndicator(FlutterFlowTheme theme) {
    return Icon(
      isSelected ? Icons.check_circle : Icons.circle_outlined,
      color: isSelected
          ? theme.primary
          : theme.secondaryText.withValues(alpha: 0.35),
      size: isSelected ? 28 : 24,
    );
  }

  Widget _buildRouteRow(BuildContext context, bool isDark, FlutterFlowTheme theme) {
    return Row(
      children: [
        Icon(Icons.location_on, color: theme.success, size: 18),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            solicitud.ciudadOrigenRef.label,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : theme.primaryText.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward,
            color: theme.secondaryText.withValues(alpha: 0.4),
            size: 16,
          ),
        ),
        Expanded(
          child: Text(
            solicitud.ciudadDestinoRef.label,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : theme.primaryText.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChips(BuildContext context, FlutterFlowTheme theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        CargoRequestInfoChip(
          icon: Icons.calendar_today,
          label: formatDate(solicitud.fechaSolicitud),
          isSelected: isSelected,
        ),
        CargoRequestInfoChip(
          icon: Icons.attach_money,
          label: formatCurrencyCOP(solicitud.valorEstimado),
          isSelected: isSelected,
        ),
        if (solicitud.observaciones.isNotEmpty)
          CargoRequestInfoChip(
            icon: Icons.notes,
            label: solicitud.observaciones,
            isSelected: isSelected,
          ),
      ],
    );
  }
}
