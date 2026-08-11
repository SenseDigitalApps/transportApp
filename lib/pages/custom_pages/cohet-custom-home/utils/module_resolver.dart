import '../types/cohet_module.dart';

/// Resuelve los módulos configurados contra la lista completa devuelta por el API.
///
/// Compara `name` del API (insensible a mayúsculas) con el `slug` configurado.
/// Si un módulo configurado no se encuentra en la respuesta, se omite del mapa.
Map<String, CohetModule> resolveModules(
  List<dynamic> apiModules,
  List<CohetModule> config,
) {
  final resolved = <String, CohetModule>{};

  for (final configModule in config) {
    for (final apiModule in apiModules) {
      if (apiModule is! Map) continue;

      final apiName = apiModule['name']?.toString().toLowerCase() ?? '';
      if (apiName == configModule.slug.toLowerCase()) {
        resolved[configModule.slug] = configModule.copyWithResolvedData(
          Map<String, dynamic>.from(apiModule),
        );
        break;
      }
    }
  }

  return resolved;
}
