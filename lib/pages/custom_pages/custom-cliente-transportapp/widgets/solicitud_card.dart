import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/solicitud_trabajo.dart';
import '../utils/status_colors.dart';
import '../utils/time_formatter.dart';
import 'glass_card/glass_card.dart';

class SolicitudCard extends StatelessWidget {
  final SolicitudTrabajo request;
  final VoidCallback? onTap;
  final bool compact;

  const SolicitudCard({
    Key? key,
    required this.request,
    this.onTap,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final statusColor = fallbackStatusColors[request.estado.toUpperCase()] ??
        const StatusColor(bgColor: Color(0xFF888888), textColor: Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt, color: theme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.title,
                        style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.bgColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        request.estado,
                        style: theme.bodySmall.copyWith(color: statusColor.textColor),
                      ),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(context, Icons.calendar_today, formatDate(request.fechaSolicitud)),
                  _buildInfoRow(context, Icons.attach_money, formatCurrency(request.valorEstimado)),
                  if (request.ciudadOrigenRef.label.isNotEmpty && request.ciudadDestinoRef.label.isNotEmpty)
                    _buildInfoRow(
                      context,
                      Icons.route,
                      '${request.ciudadOrigenRef.label} → ${request.ciudadDestinoRef.label}',
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.secondaryText),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return formatter.format(value);
  }
}
