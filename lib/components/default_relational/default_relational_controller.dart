import 'package:flutter/material.dart';
import 'relational_field_config.dart';

class RelationalController {
  TextEditingController textController;
  String relationalLabel;
  int relationalValue;
  String? relationalAvatar;
  String? relationalFullName;
  String? moduleName;
  String? type;
  int? module;
  String? relationsFormula;
  // NUEVO: referencia a la config del campo
  RelationalFieldConfig? fieldConfig;

  RelationalController({
    required this.textController,
    required this.relationalLabel,
    required this.relationalValue,
    this.relationalAvatar,
    this.relationalFullName,
    this.moduleName,
    this.type,
    this.module,
    this.relationsFormula,
    this.fieldConfig,
  });

  // NUEVO: helper para crear desde datos guardados + config
  factory RelationalController.fromSavedData({
    required Map<String, dynamic>? savedData,
    required RelationalFieldConfig config,
  }) {
    final label = savedData?['label']?.toString() ?? '';
    final value =
        int.tryParse(savedData?['value']?.toString() ?? '') ?? 0;
    final type = savedData?['type']?.toString() ?? config.storageType;
    final moduleId =
        int.tryParse(savedData?['module']?.toString() ?? '') ??
            config.relatedModuleId;
    final moduleName =
        savedData?['module_name']?.toString() ?? config.relatedModuleName;

    return RelationalController(
      textController: TextEditingController(text: label),
      relationalLabel: label,
      relationalValue: value,
      relationalAvatar: savedData?['avatar']?.toString(),
      relationalFullName: savedData?['full_name']?.toString(),
      moduleName: moduleName.isNotEmpty ? moduleName : config.relatedModuleName,
      type: type.isNotEmpty ? type : config.relationType,
      module: moduleId,
      fieldConfig: config,
    );
  }
}
