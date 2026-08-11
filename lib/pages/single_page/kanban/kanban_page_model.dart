import 'dart:convert';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'kanban_page_widget.dart' show KanbanPageWidget;
import 'widgets/kanban_column.dart';
import 'widgets/kanban_column_colors.dart';

class KanbanPageModel extends FlutterFlowModel<KanbanPageWidget> {
  List<KanbanColumnData> columns = [];
  bool isLoading = true;
  String? error;
  String statusFieldSlug = '';
  Map<String, Color> columnColors = {};
  dynamic moduleConfig;
  List<int> timeIntervals = [5, 10, 15]; // Default intervals in hours

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  Future<void> initializeKanban(
    dynamic moduleConfigParam,
    String moduleName,
    String? moduleType, {
    dynamic filters,
  }) async {
    isLoading = true;
    error = null;
    moduleConfig = moduleConfigParam;

    try {
      final fields = getJsonField(moduleConfig, r'''$.data''', true) as List? ?? [];

      dynamic statusField;
      for (var field in fields) {
        final fieldType = getJsonField(field, r'''$.field_type''')?.toString().toLowerCase() ?? '';
        final slug = getJsonField(field, r'''$.slug''')?.toString() ?? '';
        if (fieldType == 'status') {
          statusField = field;
          break;
        }
      }

      if (statusField == null) {
        error = 'No se encontró un campo de estado para el kanban';
        isLoading = false;
        return;
      }

      statusFieldSlug = getJsonField(statusField, r'''$.slug''')?.toString() ?? '';
      final optionsRaw = getJsonField(statusField, r'''$.options''')?.toString() ?? '';
      columnColors = parseStatusOptions(optionsRaw);

      // Parse time intervals from status field config
      final statusFieldJson = statusField is Map ? statusField : {};
      for (final value in statusFieldJson.values) {
        if (value is String) {
          final match = RegExp(r'intervalo\((\d+),(\d+),(\d+)\)').firstMatch(value);
          if (match != null) {
            timeIntervals = [
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            ];
            break;
          }
        }
      }

      // Create empty columns first
      columns = columnColors.keys.map((name) {
        return KanbanColumnData(
          id: name,
          name: name,
          color: columnColors[name] ?? const Color(0xFF6C757D),
        );
      }).toList();

      // Load first page of each column in parallel
      final futures = columns.map((column) => _loadColumnPage(
        column: column,
        page: 1,
        moduleName: moduleName,
        moduleType: moduleType,
        filters: filters,
      ));

      await Future.wait(futures);

      isLoading = false;
    } catch (e) {
      error = 'Error: $e';
      isLoading = false;
    }
  }

  Map<String, String> _buildColumnFilters(dynamic globalFilters, String statusLabel) {
    final existingKey = globalFilters != null ? getJsonField(globalFilters, r'''$.json_key''').toString() : '';
    final existingValue = globalFilters != null ? getJsonField(globalFilters, r'''$.json_value''').toString() : '';
    final existingCondition = globalFilters != null ? getJsonField(globalFilters, r'''$.json_condition''').toString() : '';

    if (existingKey.isEmpty) {
      return {
        'jsonKey': statusFieldSlug,
        'jsonValue': statusLabel,
        'jsonCondition': 'igual',
      };
    }

    return {
      'jsonKey': '${existingKey}^${statusFieldSlug}',
      'jsonValue': '${existingValue}^${statusLabel}',
      'jsonCondition': '${existingCondition}^igual',
    };
  }

  Future<void> _loadColumnPage({
    required KanbanColumnData column,
    required int page,
    required String moduleName,
    required String? moduleType,
    dynamic filters,
  }) async {
    final columnFilters = _buildColumnFilters(filters, column.name);

    final response = await GetDataModulesCall.call(
      tenant: FFAppState().organizacion,
      module: moduleName,
      token: FFAppState().token,
      moduleType: moduleType,
      limit: 20,
      page: page,
      jsonKey: columnFilters['jsonKey'] ?? '',
      jsonValue: columnFilters['jsonValue'] ?? '',
      jsonCondition: columnFilters['jsonCondition'] ?? '',
    );

    if (!response.succeeded) return;

    final registers = getJsonField(response.jsonBody, r'''$.data''', true) as List? ?? [];
    final pagination = response.jsonBody['payload']?['pagination'];
    final total = pagination?['total'] ?? registers.length;

    if (page == 1) {
      column.cards = registers;
    } else {
      column.cards.addAll(registers);
    }
    column.currentPage = page;
    column.total = total;
    column.hasMore = column.cards.length < total;
  }

  Future<void> loadMoreForColumn({
    required String columnId,
    required String moduleName,
    required String? moduleType,
    dynamic filters,
  }) async {
    final column = columns.firstWhere(
      (c) => c.id == columnId,
      orElse: () => throw Exception('Column not found: $columnId'),
    );

    if (column.isLoadingMore || !column.hasMore) return;

    column.isLoadingMore = true;

    await _loadColumnPage(
      column: column,
      page: column.currentPage + 1,
      moduleName: moduleName,
      moduleType: moduleType,
      filters: filters,
    );

    column.isLoadingMore = false;
  }

  Future<String?> moveCard({
    required dynamic card,
    required String sourceColumnId,
    required String targetColumnId,
    required String moduleName,
    required String? moduleType,
  }) async {
    final sourceColumn = columns.firstWhere(
      (c) => c.id == sourceColumnId,
      orElse: () => throw Exception('Source column not found: $sourceColumnId'),
    );
    final targetColumn = columns.firstWhere(
      (c) => c.id == targetColumnId,
      orElse: () => throw Exception('Target column not found: $targetColumnId'),
    );

    // Optimistic UI: move card locally
    sourceColumn.cards.remove(card);
    targetColumn.cards.add(card);
    sourceColumn.total = (sourceColumn.total > 0 ? sourceColumn.total - 1 : 0);
    targetColumn.total = targetColumn.total + 1;

    try {
      final cardId = getJsonField(card, r'''$.id''');
      final existingJsonData = getJsonField(card, r'''$.json_data''') ?? {};
      final jsonData = Map<String, dynamic>.from(
        existingJsonData is Map ? existingJsonData : {},
      );
      jsonData[statusFieldSlug] = targetColumn.name;

      final body = jsonEncode({'json_data': jsonData});

      final response = await EditRegister.call(
        tenant: FFAppState().organizacion,
        moduleName: moduleName,
        moduleType: moduleType,
        token: FFAppState().token,
        body: body,
        id: cardId is int ? cardId : int.tryParse(cardId.toString()),
      );

      if (!response.succeeded) {
        // Revert optimistic UI
        targetColumn.cards.remove(card);
        sourceColumn.cards.add(card);
        sourceColumn.total = sourceColumn.total + 1;
        targetColumn.total = (targetColumn.total > 0 ? targetColumn.total - 1 : 0);
        return 'Error al actualizar el estado del registro';
      }

      // Update card's local json_data to reflect the change
      if (card is Map) {
        card['json_data'] = jsonData;
      }

      return null;
    } catch (e) {
      // Revert optimistic UI
      targetColumn.cards.remove(card);
      sourceColumn.cards.add(card);
      sourceColumn.total = sourceColumn.total + 1;
      targetColumn.total = (targetColumn.total > 0 ? targetColumn.total - 1 : 0);
      return 'Error: $e';
    }
  }
}
