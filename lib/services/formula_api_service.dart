import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app_state.dart';

class FormulaApiService {
  static String get _baseUrl {
    final org = FFAppState().organizacion;
    return 'https://$org.itsquery.com/api/v2/';
  }

  static Map<String, String> get _headers {
    final token = FFAppState().token;
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// POST /api/v2/fetch-complex-formula/
  /// Evalúa fórmulas con sumExternal, countExternal, operaciones entre ellas
  static Future<double> fetchComplexFormula({
    required String formula,
    required String registerId,
    required String slug,
    required Map<String, dynamic> jsonData,
  }) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}fetch-complex-formula/'),
      headers: _headers,
      body: jsonEncode({
        'formula': formula,
        'register_id': registerId,
        'slug': slug,
        'json_data': jsonData,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['total'] as num?)?.toDouble() ?? 0.0;
    }
    throw Exception(
        'fetchComplexFormula error ${response.statusCode}: ${response.body}');
  }

  /// POST /api/v2/fetch-filter-formula/
  /// Evalúa filter() y filterRepeaterInheritField()
  static Future<Map<String, dynamic>> fetchFilterFormula({
    required String formula,
    required String registerId,
    required String targetSlug,
    required Map<String, dynamic> jsonData,
    String? currentUser,
  }) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}fetch-filter-formula/'),
      headers: _headers,
      body: jsonEncode({
        'formula': formula,
        'register_id': registerId,
        'target_slug': targetSlug,
        'json_data': jsonData,
        'current_user': currentUser ?? FFAppState().fullName,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
        'fetchFilterFormula error ${response.statusCode}: ${response.body}');
  }

  /// GET /api/v2/fetch-formula/{formula}/{params}/{reg_id}/{slug}/
  /// Suma con filtros (sumExternal base)
  static Future<double> fetchFormula({
    required String moduleName,
    required String fieldSlug,
    required String registerId,
    required String customFieldSlug,
    String filters = '',
  }) async {
    final encodedFormula = Uri.encodeComponent('sumExternal($moduleName,$fieldSlug${filters.isNotEmpty ? ';[$filters]' : ''})');
    final encodedParams = Uri.encodeComponent(filters);
    final response = await http.get(
      Uri.parse('${_baseUrl}fetch-formula/$encodedFormula/$encodedParams/$registerId/$customFieldSlug/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['total'] as num?)?.toDouble() ?? 0.0;
    }
    throw Exception('fetchFormula error ${response.statusCode}: ${response.body}');
  }

  /// GET /api/v2/backend-formula/{registerId}/{slug}/
  /// Evalúa toda la fórmula en el backend (lee CustomField automáticamente)
  static Future<double> fetchBackendFormula({
    required String registerId,
    required String slug,
  }) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}backend-formula/$registerId/$slug/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['total'] as num?)?.toDouble() ?? 0.0;
    }
    throw Exception(
        'fetchBackendFormula error ${response.statusCode}: ${response.body}');
  }

  /// GET /api/v2/register/{id}/ o /api/v2/masters/{id}/
  /// Obtiene un registro relacionado (para ref_campo:subcampo)
  static Future<Map<String, dynamic>> getRegisterById({
    required int id,
    required String tableName,
  }) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}$tableName$id/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
        'getRegisterById error $response.statusCode: ${response.body}');
  }
}
