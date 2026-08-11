/// Modelo inmutable que representa un módulo accesible desde la home de Cohet.
class CohetModule {
  final String name;
  final String slug;
  final String iconKey;
  final String type;
  final Map<String, dynamic> rawData;

  const CohetModule({
    required this.name,
    required this.slug,
    required this.iconKey,
    this.type = 'registers',
    this.rawData = const {},
  });

  /// Crea una copia con datos resueltos desde la respuesta del API.
  ///
  /// Mantiene el [name] legible de la configuración; el nombre técnico/slug
  /// del API se conserva en [rawData] para navegación.
  CohetModule copyWithResolvedData(Map<String, dynamic> data) {
    return CohetModule(
      name: name,
      slug: slug,
      iconKey: data['icon']?.toString() ?? iconKey,
      type: data['type']?.toString() ?? type,
      rawData: data,
    );
  }
}
