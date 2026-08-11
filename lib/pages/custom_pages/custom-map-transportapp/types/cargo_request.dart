import '/flutter_flow/lat_lng.dart';

/// Modelo puro de solicitud de carga.
/// Sin dependencias de Flutter ni FlutterFlow.

class CargoRequest {
  // Campos existentes
  final String codigo;
  final String tipoViaje;
  final String formaPago;
  final String cliente;
  final String carroceria;
  final String destinatario;
  final String ciudadOrigen;
  final String ciudadDestino;
  final double peso;
  final DateTime horaCargue;
  final LatLng origenCoords;
  final LatLng destinoCoords;
  final double precio;

  // Nuevos campos del JSON real
  final String? servicio;
  final String estado;
  final String? claseVehiculo;
  final String remitente;
  final String? zonaOrigen;
  final String? zonaDestino;
  final String producto;
  final String noVehiculos;
  final String cantidad;
  final double? valorMercancia;
  final String? personaAutoriza;
  final String observacion;
  final DateTime fechaCargue;
  final String empaque;
  final String? tipoRemesasRndc;
  final String usuario;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;
  final List<String> imagenes;

  const CargoRequest({
    required this.codigo,
    required this.tipoViaje,
    required this.formaPago,
    required this.cliente,
    required this.carroceria,
    required this.destinatario,
    required this.ciudadOrigen,
    required this.ciudadDestino,
    required this.peso,
    required this.horaCargue,
    required this.origenCoords,
    required this.destinoCoords,
    required this.precio,
    this.servicio,
    this.estado = 'SIN ESTADO',
    this.claseVehiculo,
    required this.remitente,
    this.zonaOrigen,
    this.zonaDestino,
    required this.producto,
    this.noVehiculos = '1',
    this.cantidad = '1',
    this.valorMercancia,
    this.personaAutoriza,
    this.observacion = '',
    required this.fechaCargue,
    this.empaque = '',
    this.tipoRemesasRndc,
    this.usuario = '',
    required this.fechaCreacion,
    required this.fechaModificacion,
    this.imagenes = const [],
  });

  /// Indica si es viaje nacional vs urbano.
  bool get isNacional => tipoViaje.toLowerCase() == 'nacional';

  /// Indica si el precio supera un umbral (util para badges).
  bool get isHighValue => precio > 800000;

  /// Factory desde JSON de la API real.
  factory CargoRequest.fromJson(Map<String, dynamic> json) {
    return CargoRequest(
      codigo: json['codigo']?.toString() ?? '',
      tipoViaje: json['tipo_viaje']?.toString() ?? '',
      formaPago: json['forma_pago']?.toString() ?? 'No definido',
      cliente: json['cliente']?.toString().trim() ?? '',
      carroceria: json['carroceria']?.toString() ?? '',
      destinatario: json['destinatario']?.toString().trim() ?? '',
      ciudadOrigen: json['ciudad_origen']?.toString() ?? '',
      ciudadDestino: json['ciudad_destino']?.toString() ?? '',
      peso: double.tryParse(json['peso']?.toString() ?? '0') ?? 0,
      horaCargue: _parseHoraCargue(
        json['fecha_cargue']?.toString(),
        json['hora_cargue']?.toString(),
      ),
      origenCoords: const LatLng(4.7110, -74.0721),
      destinoCoords: const LatLng(4.7110, -74.0721),
      precio: 0,
      servicio: json['servicio']?.toString(),
      estado: json['estado']?.toString() ?? 'SIN ESTADO',
      claseVehiculo: json['clase_vehiculo']?.toString(),
      remitente: json['remitente']?.toString().trim() ?? '',
      zonaOrigen: json['zona_origen']?.toString().trim(),
      zonaDestino: json['zona_destino']?.toString().trim(),
      producto: json['producto']?.toString() ?? '',
      noVehiculos: json['no_vehiculos']?.toString() ?? '1',
      cantidad: json['cantidad']?.toString() ?? '1',
      valorMercancia: double.tryParse(json['valor_mercancia']?.toString() ?? ''),
      personaAutoriza: json['persona_autoriza']?.toString().trim(),
      observacion: json['observacion']?.toString() ?? '',
      fechaCargue: DateTime.tryParse(json['fecha_cargue']?.toString() ?? '') ?? DateTime.now(),
      empaque: json['empaque']?.toString() ?? '',
      tipoRemesasRndc: json['tipo_remesas_rndc']?.toString(),
      usuario: json['usuario']?.toString() ?? '',
      fechaCreacion: DateTime.tryParse(json['fecha_creacion']?.toString() ?? '') ?? DateTime.now(),
      fechaModificacion: DateTime.tryParse(json['fecha_modificacion']?.toString() ?? '') ?? DateTime.now(),
      imagenes: List<String>.from(json['imagenes'] ?? []),
    );
  }

  static DateTime _parseHoraCargue(String? fecha, String? hora) {
    if (fecha == null) return DateTime.now();
    final datePart = DateTime.tryParse(fecha) ?? DateTime.now();
    if (hora == null) return datePart;
    final timeParts = hora.split(':');
    if (timeParts.length >= 2) {
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      return DateTime(datePart.year, datePart.month, datePart.day, hour, minute);
    }
    return datePart;
  }
}

final List<CargoRequest> mockCargoRequests = [
  CargoRequest(
    codigo: 'ABC12345678901',
    tipoViaje: 'Nacional',
    formaPago: 'Efectivo',
    cliente: 'Transportes XYZ S.A.S.',
    carroceria: 'Sencillo',
    destinatario: 'Juan Perez',
    ciudadOrigen: 'Bogota',
    ciudadDestino: 'Medellin',
    peso: 2.5,
    horaCargue: DateTime(2026, 4, 27, 14, 30),
    origenCoords: const LatLng(4.7110, -74.0721),
    destinoCoords: const LatLng(6.2476, -75.5658),
    precio: 450000,
    servicio: 'CARGA NO USAR',
    estado: 'DESPACHADA',
    claseVehiculo: 'TURBO',
    remitente: 'Transportes XYZ S.A.S.',
    zonaOrigen: 'SUR',
    zonaDestino: 'NORTE',
    producto: 'PRODUCTOS VARIOS',
    noVehiculos: '1',
    cantidad: '1',
    observacion: 'CUPO VH EN PERFECTO ESTADO',
    fechaCargue: DateTime(2026, 4, 27),
    empaque: 'VARIOS',
    usuario: 'DTALERO',
    fechaCreacion: DateTime(2026, 4, 26),
    fechaModificacion: DateTime(2026, 4, 26),
    imagenes: const [],
  ),
  CargoRequest(
    codigo: 'ABC12345678902',
    tipoViaje: 'Urbano',
    formaPago: 'Credito',
    cliente: 'Distribuciones ABC',
    carroceria: 'Doble',
    destinatario: 'Maria Lopez',
    ciudadOrigen: 'Bogota',
    ciudadDestino: 'Cali',
    peso: 5.0,
    horaCargue: DateTime(2026, 4, 27, 16, 0),
    origenCoords: const LatLng(4.7110, -74.0721),
    destinoCoords: const LatLng(3.4372, -76.5225),
    precio: 850000,
    servicio: 'CARGA URBANA',
    estado: 'PENDIENTE',
    claseVehiculo: 'SENCILLO',
    remitente: 'Distribuciones ABC',
    zonaOrigen: 'CENTRO',
    producto: 'PAQUETERIA',
    noVehiculos: '2',
    cantidad: '5',
    observacion: 'ENTREGA EN HORARIO DIURNO',
    fechaCargue: DateTime(2026, 4, 27),
    empaque: 'CAJAS',
    usuario: 'JRAMIREZ',
    fechaCreacion: DateTime(2026, 4, 25),
    fechaModificacion: DateTime(2026, 4, 26),
    imagenes: const [],
  ),
  CargoRequest(
    codigo: 'ABC12345678903',
    tipoViaje: 'Nacional',
    formaPago: 'Contraentrega',
    cliente: 'Logistica Rapida',
    carroceria: 'Tolva',
    destinatario: 'Carlos Ruiz',
    ciudadOrigen: 'Bogota',
    ciudadDestino: 'Barranquilla',
    peso: 8.0,
    horaCargue: DateTime(2026, 4, 27, 8, 0),
    origenCoords: const LatLng(4.7110, -74.0721),
    destinoCoords: const LatLng(10.9685, -74.7813),
    precio: 1200000,
    servicio: 'CARGA PESADA',
    estado: 'CANCELADA',
    claseVehiculo: 'TRACTOMULA',
    remitente: 'Logistica Rapida',
    zonaOrigen: 'NORTE',
    zonaDestino: 'CENTRO',
    producto: 'MATERIALES DE CONSTRUCCION',
    noVehiculos: '1',
    cantidad: '10',
    observacion: 'REQUIERE MANIOBRA',
    fechaCargue: DateTime(2026, 4, 27),
    empaque: 'BULTOS',
    usuario: 'MLOPEZ',
    fechaCreacion: DateTime(2026, 4, 24),
    fechaModificacion: DateTime(2026, 4, 25),
    imagenes: const [],
  ),
];
