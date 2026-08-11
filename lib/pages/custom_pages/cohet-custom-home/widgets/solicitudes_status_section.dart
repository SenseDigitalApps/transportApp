import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/cohet_home_config.dart';
import '../types/solicitud_status.dart';

/// Sección que muestra el conteo de solicitudes agrupadas por estado.
///
/// Recibe un mapa `apiValue → count`. Los estados se definen en
/// [SolicitudStatus.values]; si un estado no tiene entrada en el mapa
/// se muestra con count 0.
class SolicitudesStatusSection extends StatelessWidget {
  final Map<String, int> counts;
  final bool isLoading;

  const SolicitudesStatusSection({
    super.key,
    required this.counts,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _StatusGrid(counts: counts),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                theme.accent1.withValues(alpha: 0.20),
                theme.accent2.withValues(alpha: 0.24),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.accent1.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            Icons.assignment_outlined,
            color: theme.accent1,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CohetHomeConfig.solicitudesSectionTitle,
                style: theme.titleLarge.override(
                  fontFamily: 'Roboto',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.0,
                ),
              ),
              Text(
                CohetHomeConfig.solicitudesSectionSubtitle,
                style: theme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Grid ────────────────────────────────────────────────────────────────────

class _StatusGrid extends StatelessWidget {
  final Map<String, int> counts;

  const _StatusGrid({required this.counts});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: SolicitudStatus.values.map((status) {
            final count = counts[status.apiValue] ?? 0;
            return _StatusTile(
              status: status,
              count: count,
              width: tileWidth,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Tile ────────────────────────────────────────────────────────────────────

class _StatusTile extends StatelessWidget {
  final SolicitudStatus status;
  final int count;
  final double width;

  const _StatusTile({
    required this.status,
    required this.count,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bgColor = status.color.withValues(alpha: 0.10);
    final borderColor = status.color.withValues(alpha: 0.30);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(status.icon, color: status.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: theme.headlineSmall.override(
                    fontFamily: 'Roboto',
                    color: status.color,
                    fontSize: 22.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.label,
                  style: theme.bodySmall.override(
                    fontFamily: 'Roboto',
                    color: theme.secondaryText,
                    fontSize: 12.0,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
