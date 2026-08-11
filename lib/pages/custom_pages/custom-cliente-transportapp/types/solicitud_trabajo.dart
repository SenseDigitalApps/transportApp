import 'dart:convert';

import '/flutter_flow/lat_lng.dart';

/// Representa un campo de referencia (ref_*) en json_data.
class RefField {
  final String type;
  final String label;
  final int? value;
  final int? module;
  final String? moduleName;
  final String? avatar;
  final String? fullName;

  const RefField({
    required this.type,
    required this.label,
    this.value,
    this.module,
    this.moduleName,
    this.avatar,
    this.fullName,
  });

  factory RefField.fromJson(Map<String, dynamic> json) => RefField(
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: json['value'] as int?,
        module: json['module'] as int?,
        moduleName: json['module_name'] as String?,
        avatar: json['avatar'] as String?,
        fullName: json['full_name'] as String?,
      );

  bool get hasValue => value != null && value! > 0;
}

/// Modelo puro de Solicitud de Trabajo.
/// Parsea el JSON real del endpoint de solicitud_de_trabajo.
class SolicitudTrabajo {
  final int id;
  final int consecutive;
  final String title;
  final DateTime? publishedDate;
  final DateTime? lastUpdated;

  // Campos de json_data
  final DateTime fechaSolicitud;
  final String estado;
  final String tipoCarga;
  final double valorEstimado;
  final String observaciones;
  final RefField remitenteRef;
  final RefField destinatarioRef;
  final RefField ciudadOrigenRef;
  final RefField ciudadDestinoRef;
  final RefField clienteRef;
  final RefField vehiculoRef;
  final RefField conductorRef;
  final RefField usuarioRef;

  // Coordenadas resueltas (pueden ser null)
  final LatLng? origenCoords;
  final LatLng? destinoCoords;

  const SolicitudTrabajo({
    required this.id,
    required this.consecutive,
    required this.title,
    this.publishedDate,
    this.lastUpdated,
    required this.fechaSolicitud,
    required this.estado,
    required this.tipoCarga,
    required this.valorEstimado,
    required this.observaciones,
    required this.remitenteRef,
    required this.destinatarioRef,
    required this.ciudadOrigenRef,
    required this.ciudadDestinoRef,
    required this.clienteRef,
    required this.vehiculoRef,
    required this.conductorRef,
    required this.usuarioRef,
    this.origenCoords,
    this.destinoCoords,
  });

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return {};
  }

  factory SolicitudTrabajo.fromJson(
    Map<String, dynamic> json, {
    Map<String, LatLng>? ciudadCoords,
  }) {
    final data = _asMap(json['json_data']);

    final origenRef = RefField.fromJson(_asMap(data['ref_ciudad_de_origen_solicitud']));
    final destinoRef = RefField.fromJson(_asMap(data['ref_ciudad_de_destino_solicitud']));

    return SolicitudTrabajo(
      id: json['id'] as int? ?? 0,
      consecutive: json['consecutivo'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      publishedDate: _parseDateTime(json['published_date'] as String?),
      lastUpdated: _parseDateTime(json['last_updated'] as String?),
      fechaSolicitud: DateTime.tryParse(data['fecha_de_solicitud'] as String? ?? '') ?? DateTime.now(),
      estado: (data['estado_de_la_solicitud'] as String? ?? 'pendiente').toUpperCase(),
      tipoCarga: data['tipo_de_carga_solicitud'] as String? ?? '',
      valorEstimado: double.tryParse(data['valor_estimado_solicitud']?.toString() ?? '0') ?? 0,
      observaciones: data['observaciones_de_la_solicitud'] as String? ?? '',
      remitenteRef: RefField.fromJson(_asMap(data['ref_remitente_solicitud'])),
      destinatarioRef: RefField.fromJson(_asMap(data['ref_destinatario_solicitud'])),
      ciudadOrigenRef: origenRef,
      ciudadDestinoRef: destinoRef,
      clienteRef: RefField.fromJson(_asMap(data['ref_cliente_relacionado_solicitud'])),
      vehiculoRef: RefField.fromJson(_asMap(data['ref_vehiculo_relacionado_solicitud'])),
      conductorRef: RefField.fromJson(_asMap(data['ref_conductor_relacionado_solicitud'])),
      usuarioRef: RefField.fromJson(_asMap(data['ref_usuario_encargado_de_la_solicitud'])),
      origenCoords: ciudadCoords != null ? _resolveCoords(origenRef.label, ciudadCoords) : null,
      destinoCoords: ciudadCoords != null ? _resolveCoords(destinoRef.label, ciudadCoords) : null,
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    // Intenta formato ISO primero
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    // Fallback para formatos tipo "20 Feb 2026, 05:42 PM"
    try {
      final parts = value.split(',');
      if (parts.length == 2) {
        final datePart = parts[0].trim();
        final timePart = parts[1].trim();
        final months = {
          'ene': 1, 'feb': 2, 'mar': 3, 'abr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'ago': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dic': 12,
          'jan': 1, 'fev': 2, 'avr': 4,
        };
        final dateTokens = datePart.toLowerCase().split(' ');
        if (dateTokens.length == 3) {
          final day = int.parse(dateTokens[0]);
          final month = months[dateTokens[1].substring(0, 3)] ?? 1;
          final year = int.parse(dateTokens[2]);
          final timeTokens = timePart.split(':');
          var hour = int.parse(timeTokens[0]);
          final minute = int.parse(timeTokens[1].split(' ')[0]);
          final ampm = timePart.toLowerCase().contains('pm') ? 'pm' : 'am';
          if (ampm == 'pm' && hour != 12) hour += 12;
          if (ampm == 'am' && hour == 12) hour = 0;
          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (_) {}
    return null;
  }

  static LatLng? _resolveCoords(String label, Map<String, LatLng> map) {
    final normalized = label.toLowerCase().replaceAll(RegExp(r'^\d+\s*-\s*'), '').trim();
    return map[normalized];
  }

  bool get isNacional => tipoCarga.toLowerCase() != 'urbano';

  bool get isHighValue => valorEstimado > 800000;
}
