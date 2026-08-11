import 'package:flutter/material.dart';

/// Registro de custom home pages.
/// Equivalente al import.meta.glob de Vite pero manual.
/// Cada custom page se registra aqui con su nombre (el mismo valor de custom_page en el modulo).
class HomeWidgetRegistry {
  static final Map<String, WidgetBuilder> _registry = {};

  static void register(String name, WidgetBuilder builder) {
    _registry[name] = builder;
  }

  static WidgetBuilder? getBuilder(String? name) {
    if (name == null) return null;
    return _registry[name];
  }

  static bool hasPage(String? name) {
    if (name == null) return false;
    return _registry.containsKey(name);
  }
}
