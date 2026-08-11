import 'package:flutter/material.dart';

/// Representa un estado de solicitud con su configuración visual.
///
/// El [apiValue] se usa como `json_value` en la query al backend.
/// Para agregar/quitar estados, solo modificar [SolicitudStatus.values].
class SolicitudStatus {
  final String label;
  final String apiValue;
  final Color color;
  final IconData icon;

  const SolicitudStatus({
    required this.label,
    required this.apiValue,
    required this.color,
    required this.icon,
  });

  /// Catálogo de estados activos. Modificar aquí para agregar/quitar.
  static const List<SolicitudStatus> values = [
    SolicitudStatus(
      label: 'Pendientes',
      apiValue: 'PENDIENTE',
      color: Color(0xFFFFA500),
      icon: Icons.schedule_outlined,
    ),
    SolicitudStatus(
      label: 'Listas',
      apiValue: 'LISTA',
      color: Color(0xFF66BB6A),
      icon: Icons.check_circle_outline,
    ),
    SolicitudStatus(
      label: 'Tramitadas',
      apiValue: 'TRAMITADA',
      color: Color(0xFF42A5F5),
      icon: Icons.description_outlined,
    ),
    SolicitudStatus(
      label: 'Canceladas',
      apiValue: 'CANCELADA',
      color: Color(0xFFF44336),
      icon: Icons.cancel_outlined,
    ),
  ];
}
