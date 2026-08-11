import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/solicitud_trabajo.dart';
import '../utils/currency_formatter.dart';
import '../utils/time_formatter.dart';
import '../utils/status_colors.dart';
import 'cargo_request_info_chip.dart';

class ActivaCard extends StatelessWidget {
  const ActivaCard({
    super.key,
    required this.solicitud,
    this.isSelected = false,
    this.onTap,
    this.onEntregar,
    this.onNovedad,
    this.onCardTap,
    this.statusColors,
  });

  final SolicitudTrabajo solicitud;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEntregar;
  final VoidCallback? onNovedad;
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: isDark ? 0.25 : 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con # consecutivo, tipo, badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_shipping, color: theme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${solicitud.consecutive} — ${solicitud.title}',
                        style: TextStyle(
                          color: isDark ? Colors.white : theme.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
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
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 16),

            // Ruta expandida
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  solicitud.ciudadOrigenRef.label,
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.85) : theme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: theme.secondaryText, size: 16),
                ),
                Icon(Icons.location_on, color: Colors.red.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  solicitud.ciudadDestinoRef.label,
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.85) : theme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                CargoRequestInfoChip(
                  icon: Icons.calendar_today,
                  label: formatDate(solicitud.fechaSolicitud),
                  isSelected: true,
                ),
                CargoRequestInfoChip(
                  icon: Icons.attach_money,
                  label: formatCurrencyCOP(solicitud.valorEstimado),
                  isSelected: true,
                ),
                CargoRequestInfoChip(
                  icon: Icons.business,
                  label: solicitud.clienteRef.label,
                  isSelected: true,
                ),
              ],
            ),

            // Observaciones si existen
            if (solicitud.observaciones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 14, color: theme.secondaryText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      solicitud.observaciones,
                      style: TextStyle(
                        color: theme.secondaryText,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEntregar,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text(
                      'Entregado',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNovedad,
                    icon: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: const Text(
                      'Novedad',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildStatusBadge() {
    // Badge "EN TRANSITO" estilizado
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.5)),
          ),
          child: const Text(
            'EN TRANSITO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
