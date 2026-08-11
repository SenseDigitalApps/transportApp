import 'package:flutter/material.dart';
import 'status_colors.dart';

/// Mapeo de estados para el historial de solicitudes.
/// pendiente|warning, aprobado|success, rechazado|danger, en transito|primary, entregado|success
class HistorialStatusConfig {
  final String estado;
  final StatusColor color;

  const HistorialStatusConfig({
    required this.estado,
    required this.color,
  });

  static const Map<String, HistorialStatusConfig> _configs = {
    'PENDIENTE': HistorialStatusConfig(
      estado: 'PENDIENTE',
      color: StatusColor(bgColor: Color(0xFFFFA500), textColor: Colors.white),
    ),
    'APROBADO': HistorialStatusConfig(
      estado: 'APROBADO',
      color: StatusColor(bgColor: Color(0xFF4CAF50), textColor: Colors.white),
    ),
    'RECHAZADO': HistorialStatusConfig(
      estado: 'RECHAZADO',
      color: StatusColor(bgColor: Color(0xFFF44336), textColor: Colors.white),
    ),
    'EN TRANSITO': HistorialStatusConfig(
      estado: 'EN TRANSITO',
      color: StatusColor(bgColor: Color(0xFF2196F3), textColor: Colors.white),
    ),
    'ENTREGADO': HistorialStatusConfig(
      estado: 'ENTREGADO',
      color: StatusColor(bgColor: Color(0xFF4CAF50), textColor: Colors.white),
    ),
    'CON NOVEDAD': HistorialStatusConfig(
      estado: 'CON NOVEDAD',
      color: StatusColor(bgColor: Color(0xFFFF9800), textColor: Colors.white),
    ),
  };

  static StatusColor get(String estado) {
    return _configs[estado.toUpperCase()]?.color ??
        const StatusColor(
          bgColor: Color(0xFF888888),
          textColor: Colors.white,
        );
  }
}
