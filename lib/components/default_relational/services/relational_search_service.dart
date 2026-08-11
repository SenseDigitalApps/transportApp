import 'package:flutter/material.dart';
import '../../../backend/api_requests/api_calls.dart';
import '../relational_formula_parser.dart';

class RelationalSearchService {
  static Future<ApiCallResponse> search({
    required String query,
    required String typeRelation,
    required String? nameModule,
    required String tenant,
    required String token,
    String? relationsFormula,
    Map<String, dynamic>? jsonData,
    String? mainSlug,
    int? index,
    // Legacy simple formula params (fallback)
    String slugFormula = '',
    String valueFormula = '',
    String typeFormula = '',
  }) async {
    final urlParam = _urlParam(typeRelation);
    final filterModule = typeRelation != 'user' ? (nameModule ?? '') : '';

    // Parse advanced formula
    String? advancedFilter;
    String? normalFilter;
    String? roleFilter;
    if (relationsFormula != null && relationsFormula.isNotEmpty) {
      final parsed = parseRelationsFormula(
        relationsFormula,
        jsonData ?? {},
        mainSlug: mainSlug,
        index: index,
      );
      advancedFilter = parsed.advancedFilter;
      normalFilter = parsed.normalFilter;
      roleFilter = parsed.roleFilter;

      // Dynamic slug value can be merged into normal_filter if present
      if (parsed.dynamicSlugValue != null && parsed.dynamicSlugValue!.isNotEmpty) {
        if (normalFilter != null && normalFilter!.isNotEmpty) {
          normalFilter = '$normalFilter,${parsed.dynamicSlugValue}';
        } else {
          normalFilter = parsed.dynamicSlugValue;
        }
      }
    }

    // Fallback to legacy simple formula if no advanced filters were produced
    if ((advancedFilter == null || advancedFilter.isEmpty) &&
        (normalFilter == null || normalFilter.isEmpty) &&
        (roleFilter == null || roleFilter.isEmpty)) {
      // Keep legacy behavior
    }

    return await GetInfoModuleForRelationalCall.call(
      search: query,
      typeRelation: urlParam,
      filterModule: filterModule,
      tenant: tenant,
      token: token,
      json_key: slugFormula,
      json_value: valueFormula,
      json_condition: typeFormula,
      advanced_filter: advancedFilter,
      normal_filter: normalFilter,
      role_filter: roleFilter,
    );
  }

  static Future<ApiCallResponse> fetchDetail({
    required String type,
    required String id,
    required String tenant,
    required String token,
  }) async {
    if (type == 'register' || type == 'module') {
      return await GetDataRegistersCall.call(
        tenant: tenant,
        id: id,
        token: token,
      );
    } else if (type == 'master') {
      return await GetDataMastersCall.call(
        tenant: tenant,
        id: id,
        token: token,
      );
    } else {
      throw Exception('Tipo de detalle no soportado: $type');
    }
  }

  static String _urlParam(String type) {
    switch (type) {
      case 'user':
        return 'users';
      case 'module':
      case 'register':
        return 'register';
      case 'master':
        return 'master';
      default:
        return 'master';
    }
  }
}
