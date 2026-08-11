import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/solicitud_trabajo.dart';
import '../types/map_config.dart';
import 'cargo_request_card.dart';
import 'cargo_sheet_footer.dart';

class CargoBottomSheet extends StatelessWidget {
  const CargoBottomSheet({
    super.key,
    required this.controller,
    required this.solicitudes,
    required this.selectedSolicitud,
    required this.onSolicitudSelected,
    this.title = 'Elige una solicitud',
    this.onCardTap,
  });

  final DraggableScrollableController controller;
  final List<SolicitudTrabajo> solicitudes;
  final SolicitudTrabajo? selectedSolicitud;
  final void Function(SolicitudTrabajo) onSolicitudSelected;
  final String title;
  final void Function(SolicitudTrabajo)? onCardTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: MapConfig.initialSheetChildSize,
      minChildSize: MapConfig.minSheetChildSize,
      maxChildSize: MapConfig.maxSheetChildSize,
      builder: (context, scrollController) {
        return _GlassmorphicSheet(
          isDark: isDark,
          child: Column(
            children: [
              _SheetHandle(isDark: isDark),
              _SheetTitle(title: title, isDark: isDark),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    final s = solicitudes[index];
                    return CargoRequestCard(
                      solicitud: s,
                      isSelected: selectedSolicitud?.id == s.id,
                      onTap: () => onSolicitudSelected(s),
                      onCardTap: onCardTap != null ? () => onCardTap!(s) : null,
                    );
                  },
                ),
              ),
              CargoSheetFooter(
                formaPago: 'Por definir',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassmorphicSheet extends StatelessWidget {
  const _GlassmorphicSheet({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 10),
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: theme.titleMedium.override(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white : theme.primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
    );
  }
}
