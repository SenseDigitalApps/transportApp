import 'package:flutter/material.dart';

export '../components/default_relational/default_relational_controller.dart';

class GeoReferenceController {
  TextEditingController latLng;
  TextEditingController address;

  GeoReferenceController({
    required this.latLng,
    required this.address,
  });

  factory GeoReferenceController.fromString(String? input) {
    if (input == null || input.isEmpty) {
      return GeoReferenceController(
        latLng: TextEditingController(),
        address: TextEditingController(),
      );
    }

    final parts = input.split('|');

    if (parts.length != 2) {
      throw FormatException('Invalid geo reference format');
    }

    return GeoReferenceController(
      latLng: TextEditingController(text: parts[0]),
      address: TextEditingController(text: parts[1]),
    );
  }
}