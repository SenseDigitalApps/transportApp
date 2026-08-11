import '/flutter_flow/lat_lng.dart';

/// Configuracion de ubicacion inicial del mapa.
/// Centraliza los valores hardcodeados de coordenadas.

class MapConfig {
  /// Ubicacion inicial por defecto (Bogota).
  static const LatLng defaultOrigin = LatLng(4.7110, -74.0721);

  /// Nivel de zoom inicial.
  static const double defaultZoom = 12.0;

  /// Padding al dibujar bounds de ruta (en pixeles).
  static const double routeBoundsPadding = 80.0;

  /// Zoom minimo y maximo.
  static const double minZoom = 5.0;
  static const double maxZoom = 18.0;

  /// Posicion inicial del bottom sheet (fraccion de pantalla).
  static const double initialSheetChildSize = 0.52;
  static const double minSheetChildSize = 0.22;
  static const double maxSheetChildSize = 0.88;
}
