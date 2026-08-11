/// Formateador de moneda COP.
/// Funcion pura — sin estado, sin side effects.
String formatCurrencyCOP(double value) {
  final formatted = value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return '\$$formatted';
}
