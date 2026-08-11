import 'package:flutter/material.dart';

Color parseStatusColor(String colorName) {
  switch (colorName.toLowerCase()) {
    case 'primary':
      return const Color(0xFF007BFF);
    case 'secondary':
      return const Color(0xFF6C757D);
    case 'success':
      return const Color(0xFF28A745);
    case 'danger':
      return const Color(0xFFDC3545);
    case 'warning':
      return const Color(0xFFFFC107);
    case 'info':
      return const Color(0xFF17A2B8);
    case 'light':
      return const Color(0xFFF8F9FA);
    case 'dark':
      return const Color(0xFF343A40);
    default:
      return const Color(0xFF6C757D);
  }
}

Map<String, Color> parseStatusOptions(String options) {
  final result = <String, Color>{};
  if (options.isEmpty) return result;

  final parts = options.split(',');
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;

    final subParts = trimmed.split('|');
    final label = subParts[0].trim();
    final colorName = subParts.length > 1 ? subParts[1].trim() : 'secondary';
    result[label] = parseStatusColor(colorName);
  }

  return result;
}
