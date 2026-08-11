import 'cohet_module.dart';

/// Configuración estática de la home personalizada para Cohet.
class CohetHomeConfig {
  static const String pageTitle = 'Home';
  static const String pageSubtitle = 'Pantalla';
  static const String modulesSectionTitle = 'Modulos';
  static const String modulesSectionSubtitle =
      'Accesos disponibles para este usuario';

  static const String solicitudesSectionTitle = 'Solicitudes';
  static const String solicitudesSectionSubtitle =
      'Resumen por estado';

  static const List<CohetModule> modules = [
    CohetModule(
      name: 'Solicitudes',
      slug: 'solicitudes',
      iconKey: 'assignment',
    ),
    CohetModule(
      name: 'Clientes',
      slug: 'clientes',
      iconKey: 'people',
    ),
    CohetModule(
      name: 'Equipos',
      slug: 'inventario_equipos',
      iconKey: 'engineering',
    ),
    CohetModule(
      name: 'Cotizaciones',
      slug: 'cotizacion',
      iconKey: 'receipt_long',
    ),
  ];
}
