import 'package:flutter/foundation.dart';

/// Mantiene el json_data vivo del formulario.
/// Similar a Formik's values.json_data en web.
/// Los campos que necesitan reaccionar a cambios cross-field
/// se suscriben via addListener().
class FormDataNotifier extends ChangeNotifier {
  Map<String, dynamic> _data = {};

  /// Snapshot actual del json_data
  Map<String, dynamic> get data => Map.unmodifiable(_data);

  /// Obtener un valor específico
  dynamic get(String slug) => _data[slug];

  /// Actualizar un campo individual
  void set(String slug, dynamic value) {
    _data[slug] = value;
    notifyListeners();
  }

  /// Actualizar múltiples campos a la vez (usado por herencia batch)
  void setAll(Map<String, dynamic> updates) {
    _data.addAll(updates);
    notifyListeners();
  }

  /// Reemplazar todo el json_data (útil al cargar registro existente)
  void replaceAll(Map<String, dynamic> newData) {
    _data = Map<String, dynamic>.from(newData);
    notifyListeners();
  }

  /// Para debug
  @override
  String toString() => 'FormDataNotifier(${_data.length} keys)';
}
