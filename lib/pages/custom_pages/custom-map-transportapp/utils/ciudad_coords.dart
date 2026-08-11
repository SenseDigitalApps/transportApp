import '/flutter_flow/lat_lng.dart';

/// Mapa hardcodeado temporal de ciudades de Colombia a coordenadas.
/// Reemplazar cuando el backend incluya lat/lng reales.
const Map<String, LatLng> ciudadCoordsMap = {
  'bogota': LatLng(4.7110, -74.0721),
  'medellin': LatLng(6.2476, -75.5658),
  'cali': LatLng(3.4372, -76.5225),
  'barranquilla': LatLng(10.9685, -74.7813),
  'cartagena': LatLng(10.3910, -75.4794),
  'bucaramanga': LatLng(7.1255, -73.1198),
  'chia': LatLng(4.8612, -74.0580),
  'funza': LatLng(4.7059, -74.2301),
  'cauca': LatLng(2.4400, -76.9800),
  'ibague': LatLng(4.4389, -75.2322),
  'pereira': LatLng(4.8087, -75.6906),
  'manizales': LatLng(5.0620, -75.5021),
  'armenia': LatLng(4.5360, -75.6727),
  'pasto': LatLng(1.2059, -77.2858),
  'neiva': LatLng(2.9345, -75.2809),
  'monteria': LatLng(8.7493, -75.8785),
  'santa marta': LatLng(11.2404, -74.2110),
  'villavicencio': LatLng(4.1275, -73.3639),
  'valledupar': LatLng(10.4742, -73.2436),
  'popayan': LatLng(2.4382, -76.6132),
};

/// Resuelve coordenadas a partir del label de ciudad (ej: "1 - Bogota").
/// Retorna null si no se encuentra.
LatLng? getCoordsForCiudad(String label) {
  final normalized = label.toLowerCase().replaceAll(RegExp(r'^\d+\s*-\s*'), '').trim();
  return ciudadCoordsMap[normalized];
}
