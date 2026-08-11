import 'package:flutter/material.dart';

class StatusColor {
  final Color bgColor;
  final Color textColor;

  const StatusColor({required this.bgColor, required this.textColor});
}

const Map<String, StatusColor> fallbackStatusColors = {
  'PENDIENTE': StatusColor(bgColor: Color(0xFFFFA500), textColor: Colors.white),
  'DESPACHADA': StatusColor(bgColor: Color(0xFF4CAF50), textColor: Colors.white),
  'CANCELADA': StatusColor(bgColor: Color(0xFFF44336), textColor: Colors.white),
  'EN_PROCESO': StatusColor(bgColor: Color(0xFF2196F3), textColor: Colors.white),
};

Color _parseHex(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Parsea el campo `default_status` desde la respuesta de
/// GetCustomFieldsPerModuleCall para el módulo solicitud_de_trabajo.
Map<String, StatusColor> parseDefaultStatus(dynamic jsonBody) {
  try {
    final fields = jsonBody['data'] as List? ?? [];
    for (final field in fields) {
      if (field['slug'] == 'estado_de_la_solicitud') {
        final options = field['options'] as List? ?? [];
        return {
          for (final opt in options)
            (opt['value'] as String).toUpperCase():
              StatusColor(
                bgColor: _parseHex(opt['bgColor'] as String? ?? '#888888'),
                textColor: _parseHex(opt['textColor'] as String? ?? '#ffffff'),
              ),
        };
      }
    }
  } catch (_) {}
  return Map<String, StatusColor>.from(fallbackStatusColors);
}

/// Obtiene el color de estado para una solicitud.
StatusColor getStatusColor(String estado, Map<String, StatusColor> statusColors) {
  return statusColors[estado.toUpperCase()] ??
      const StatusColor(bgColor: Color(0xFF888888), textColor: Colors.white);
}
