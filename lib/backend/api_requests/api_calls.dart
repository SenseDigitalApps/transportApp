import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:transport_app/backend/api_requests/api_interceptor.dart';
import 'interceptor.dart';
import 'api_base_url.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class RegisterUserCall {
  static Future<ApiCallResponse> call(
      {String? tenant = '',
      String? username = '',
      String? password = '',
      String? email = '',
      List<String?> groups = const [],
      String? fullName = '',
      dynamic jsonData = ''}) async {
    final ffApiRequestBody = '''
{
  "username": "$username",
  "password": "$password",
  "password2": "$password",
  "email": "$email",
  "groups": $groups,
  "full_name": "$fullName",
  "json_data": $jsonData
}''';
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'loginTenant',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'public/register/',
          ),
          callType: ApiCallType.POST,
          headers: {
            'X-Request-Source': 'app',
          },
          params: {},
          body: ffApiRequestBody,
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static String? username(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.username''',
      ));

  static String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.email''',
      ));

  static String? avatar(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.avatar''',
      ));

  static String? jsonData(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.json_data''',
      ));
}

class PublicRegistrationOptions {
  static Future<ApiCallResponse> call({
    String? tenant = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'Modulos',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'public/registration-settings/',
          ),
          headers: {},
          callType: ApiCallType.GET,
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<String>? idAllowedRole(dynamic response) => (getJsonField(
        response,
        r'''$.allowed_roles[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  static List<String>? nameAllowedRole(dynamic response) => (getJsonField(
        response,
        r'''$.allowed_roles[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  static List? AllowedRoles(dynamic response) => getJsonField(
        response,
        r'''$.allowed_roles''',
        true,
      ) as List?;

  static bool? enabled(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.enabled''',
      ));
}

class LoginTenantCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? username = '',
    String? password = '',
  }) async {
    final ffApiRequestBody = '''
{
  "username": "$username",
  "password": "$password"
}''';
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'loginTenant',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'token/',
          ),
          callType: ApiCallType.POST,
          headers: {
            'X-Request-Source': 'app',
          },
          params: {},
          body: ffApiRequestBody,
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static String? token(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.access''',
      ));

  static String? refresh(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.refresh''',
      ));
}

class ModulosCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'Modulos',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/modulos/?items_per_page=100&page=1',
          ),
          headers: {'Authorization': 'Bearer $token'},
          callType: ApiCallType.GET,
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<int>? idModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? nameModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? labelModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].label''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? iconModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].icon''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? moduleType(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].type''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? descriptionModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? type(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].type''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class CheckAdditionalInfoUserCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'checkAdditionalInfoUser',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/modulos/check-additional-info-user/',
          ),
          headers: {'Authorization': 'Bearer $token'},
          callType: ApiCallType.GET,
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class AdditionalInfoAlert {
  final int moduleId;
  final String moduleName;
  final String moduleLabel;
  final int? recordId;
  final bool hasRecord;
  final double completenessPercent;
  final int totalFields;
  final int completedFields;
  final List<String> missingFields;
  final String redirectPath;

  AdditionalInfoAlert({
    required this.moduleId,
    required this.moduleName,
    required this.moduleLabel,
    this.recordId,
    required this.hasRecord,
    required this.completenessPercent,
    required this.totalFields,
    required this.completedFields,
    required this.missingFields,
    required this.redirectPath,
  });

  factory AdditionalInfoAlert.fromJson(Map<String, dynamic> json) {
    return AdditionalInfoAlert(
      moduleId: json['module_id'] as int,
      moduleName: json['module_name'] as String,
      moduleLabel: json['module_label'] as String,
      recordId: json['record_id'] as int?,
      hasRecord: json['has_record'] as bool,
      completenessPercent: (json['completeness_percent'] as num).toDouble(),
      totalFields: json['total_fields'] as int,
      completedFields: json['completed_fields'] as int,
      missingFields: (json['missing_fields'] as List<dynamic>).cast<String>(),
      redirectPath: json['redirect_path'] as String? ?? '',
    );
  }
}

class CategorizedModulesCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getCategorizedModulesCall',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/modulos-category/?&items_per_page=100',
          ),
          headers: {'Authorization': 'Bearer $token'},
          callType: ApiCallType.GET,
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<int>? idModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? nameModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? labelModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].label''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? iconModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].icon''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? moduleType(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].type''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? descriptionModulo(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? type(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].type''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class ComunicacionesCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'Comunicaciones',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v1/comunicaciones/',
          ),
          callType: ApiCallType.GET,
          headers: {},
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<int>? id(dynamic response) => (getJsonField(
        response,
        r'''$[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? name(dynamic response) => (getJsonField(
        response,
        r'''$[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? comunication(dynamic response) => (getJsonField(
        response,
        r'''$[:].comunication''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? imageUrl(dynamic response) => getJsonField(
        response,
        r'''$[:].imageUrl''',
        true,
      ) as List?;
  static List? localImageUrl(dynamic response) => getJsonField(
        response,
        r'''$[:].image''',
        true,
      ) as List?;
}

class TenantsCall {
  static Future<ApiCallResponse> call() async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'tenants',
          apiUrl: 'https://itsquery.com/api/v2/tenants/',
          callType: ApiCallType.GET,
          headers: {},
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<int>? id(dynamic response) => (getJsonField(
        response,
        r'''$[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? tenantSchema(dynamic response) => (getJsonField(
        response,
        r'''$[:].schema_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? tenantName(dynamic response) => (getJsonField(
        response,
        r'''$[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? paidUntil(dynamic response) => (getJsonField(
        response,
        r'''$[:].paid_until''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<bool>? onTrial(dynamic response) => (getJsonField(
        response,
        r'''$[:].on_trial''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<bool>(x))
          .withoutNulls
          .toList();
  static List<String>? createdOn(dynamic response) => (getJsonField(
        response,
        r'''$[:].created_on''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class TestSheetsCall {
  static Future<ApiCallResponse> call({
    String? filter = '',
    String? valueFiltered = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'testSheets',
      apiUrl:
          'https://api.sheety.co/8f66a6232cf52f5f7478cdb51d4569c9/produccion2024/asignaciónYEntrega?filter$filter=$valueFiltered',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: true,
      decodeUtf8: true,
      cache: false,
      alwaysAllowBody: false,
    );
  }

  static List<String>? linea(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].línea''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? pais(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].país''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? idCliente(dynamic response) => getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].idCliente''',
        true,
      ) as List?;
  static List<String>? familiaProd(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].familiaDeProducto''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? producto(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].tipo''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? label(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].proyecto''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? saldo(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].saldo''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? fechaVenta(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].venta''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? equipo(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].responsable''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? fase(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].fase''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? fechaEntrega(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].entregaFinal''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? dealId(dynamic response) => getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].dealId''',
        true,
      ) as List?;
  static List<String>? comercial(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].comercial''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? estado(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].estadoProductoEnCartera''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? general(dynamic response) => getJsonField(
        response,
        r'''$.asignaciónYEntrega''',
        true,
      ) as List?;
  static List<int>? precio(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].precio''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? nombreCliente(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].cliente''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? anticipo(dynamic response) => (getJsonField(
        response,
        r'''$.asignaciónYEntrega[:].anticipo''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
}

class UserDataCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    String? tenant = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'userData',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'test/',
          ),
          callType: ApiCallType.POST,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static int? idUser(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.id''',
      ));
  static String? userName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.username''',
      ));
  static String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.email''',
      ));
  static String? fullName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.full_name''',
      ));
  static String? avatar(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.avatar''',
      ));
  static String? role(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.role''',
      ));
  static String? firma(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.firma''',
      ));
  static List<String>? permissions(dynamic response) => (getJsonField(
        response,
        r'''$.data.permissions''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetModules {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
  }) async {
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: 'v2/modulos/?items_per_page=100&page=1',
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getModules',
          apiUrl: apiUrl,
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
  static List? jsonData(dynamic response) => getJsonField(
        response,
        r'''$.data[:].json_data''',
        true,
      ) as List?;
}

class GetDataModulesCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? module = '',
    String? moduleType = '',
    String? token = '',
    int? page,
    int? limit,
    String? jsonKey = '',
    String? jsonValue = '',
    String? jsonCondition = '',
    String? searchMode = '',
  }) async {
    final moduleTable = (moduleType == 'registers') ? 'register' : 'master';
    final queryParams = [
      if (jsonKey != null && jsonKey.isNotEmpty) 'json_key=$jsonKey',
      if (jsonValue != null && jsonValue.isNotEmpty) 'json_value=$jsonValue',
      if (jsonCondition != null && jsonCondition.isNotEmpty)
        'json_condition=$jsonCondition',
      if (searchMode != null && searchMode.isNotEmpty)
        'search_mode=$searchMode',
      'page=$page',
      'items_per_page=$limit',
      'filter_module=$module'
    ].join('&');

    final apiPath = 'v2/$moduleTable/?$queryParams';
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: apiPath,
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getDataModules',
          apiUrl: apiUrl,
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<int>? id(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? moduleName(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? icon(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.icon''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? description(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? jsonData(dynamic response) => getJsonField(
        response,
        r'''$.data[:].json_data''',
        true,
      ) as List?;
  static List<String>? fullName(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].profile_info.full_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? avatar(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].profile_info.avatar''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static int? lastPage(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.payload.pagination.last_page''',
      ));
  static int? actualPage(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.payload.pagination.page''',
      ));
  static List<String>? publishedDate(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].published_date''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? lastUpdated(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].last_updated''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? title(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].title''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
  static dynamic pagination(dynamic response) => getJsonField(
        response,
        r'''$.payload.pagination''',
        true,
      );
  static int? total(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.payload.pagination.total''',
      ));
}

class GetDataMastersCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? id = '',
    String? token = '',
  }) async {
    final apiPath = 'v2/master/$id/';
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: apiPath,
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getDataModules',
          apiUrl: apiUrl,
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<int>? id(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? moduleName(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? icon(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.icon''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? description(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? jsonData(dynamic response) => getJsonField(
        response,
        r'''$.data[:].json_data''',
        true,
      ) as List?;
  static List<String>? fullName(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].profile_info.full_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? avatar(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].profile_info.avatar''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static int? lastPage(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.payload.pagination.last_page''',
      ));
  static int? actualPage(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.payload.pagination.page''',
      ));
  static List<String>? publishedDate(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].published_date''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? lastUpdated(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].last_updated''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? title(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].title''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class GetDataRegistersCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? id = '',
    String? token = '',
  }) async {
    final apiPath = 'v2/register/$id/';
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: apiPath,
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getDataModules',
          apiUrl: apiUrl,
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<int>? id(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? moduleName(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? icon(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.icon''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? description(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].modulo_info.description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? jsonData(dynamic response) => getJsonField(
        response,
        r'''$.data[:].json_data''',
        true,
      ) as List?;
  static List<String>? fullName(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].profile_info.full_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? avatar(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].profile_info.avatar''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static int? lastPage(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.payload.pagination.last_page''',
      ));
  static int? actualPage(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.payload.pagination.page''',
      ));
  static List<String>? publishedDate(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].published_date''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? lastUpdated(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].last_updated''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? title(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].title''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
}

class PostNewRegister {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? moduleName = '',
    String? moduleType = '',
    String? token = '',
    String? body = '',
  }) async {
    final ffApiRequestBody = body;
    final moduleTable = (moduleType == 'registers') ? 'register' : 'master';

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'postNewRegister',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/$moduleTable/',
          ),
          callType: ApiCallType.POST,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          body: ffApiRequestBody,
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class EditRegister {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? moduleName = '',
    String? moduleType = '',
    String? token = '',
    String? body = '',
    int? id,
  }) async {
    final ffApiRequestBody = body;
    final moduleTable = (moduleType == 'registers') ? 'register' : 'master';

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'editRegister',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/$moduleTable/$id/',
          ),
          callType: ApiCallType.PUT,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          body: ffApiRequestBody,
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class GetCustomFieldsPerModuleCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? moduleName = '',
    String? token = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getCustomFieldsPerModule',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath:
                'v2/custom-fields?filter_module=$moduleName&items_per_page=250&page=1',
          ),
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List<int>? moduleId(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].module''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? label(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].label''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? fieldType(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].field_type''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<int>? id(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? slug(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].slug''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetInfoModuleForRelationalCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? search = '',
    String? filterModule = '',
    String? token = '',
    String? typeRelation = '',
    String? v2Manager = '',
    String? json_key = '',
    String? json_value = '',
    String? json_condition = '',
    String? advanced_filter = '',
    String? normal_filter = '',
    String? role_filter = '',
  }) async {
    final queryParams = [
      'search=$search',
      if (filterModule != null && filterModule.isNotEmpty)
        'filter_module=$filterModule',
      if (json_key != null && json_key.isNotEmpty) 'json_key=$json_key',
      if (json_value != null && json_value.isNotEmpty) 'json_value=$json_value',
      if (json_condition != null && json_condition.isNotEmpty)
        'json_condition=$json_condition',
      if (advanced_filter != null && advanced_filter.isNotEmpty)
        'advanced_filter=$advanced_filter',
      if (normal_filter != null && normal_filter.isNotEmpty)
        'normal_filter=$normal_filter',
      if (role_filter != null && role_filter.isNotEmpty)
        'role_filter=$role_filter',
    ].join('&');

    final isUsers = typeRelation == 'users';
    final prefix = isUsers ? '' : 'v2';

    final apiPath = prefix.isEmpty
        ? '$typeRelation/?page=1&items_per_page=100&$queryParams'
        : '$prefix/$typeRelation/?page=1&items_per_page=100&$queryParams';
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getInfoModuleForRelational',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: apiPath,
          ),
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List? data(dynamic response) => getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?;
  static int? consecutivo(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data[:].consecutivo''',
      ));
  static String? titulo(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data[:].title''',
      ));
}

class SendMailCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? body = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'Send Mail',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/email-administrator/',
          ),
          callType: ApiCallType.POST,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          body: body,
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static int? total(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.total''',
      ));
}

class PostCalculatorRelationalSumCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? moduleName = '',
    String? relationalSlug = '',
    String? registerId = '',
    String? comparatedKey = '',
    String? token = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'Post Calculator Relational Sum',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath:
                'v2/sum-register-values/$moduleName/$relationalSlug/$registerId/$comparatedKey/',
          ),
          callType: ApiCallType.POST,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static int? total(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.total''',
      ));
}

class GetOptionsPanelCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getOptionsPanel',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/options/?items_per_page=50&page=1',
          ),
          callType: ApiCallType.GET,
          headers: {},
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List? metaValue(dynamic response) => getJsonField(
        response,
        r'''$.results[:].meta_value''',
        true,
      ) as List?;
  static List<String>? metaKey(dynamic response) => (getJsonField(
        response,
        r'''$.results[:].meta_key''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetGroupedFieldsCall {
  static Future<ApiCallResponse> call({
    String? tenant = 'apicertificadora',
    String? moduleId = '',
    String? token = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getGroupedFields',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/modulos/$moduleId/custom_fields/',
          ),
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List? metaValue(dynamic response) => getJsonField(
        response,
        r'''$.results[:].meta_value''',
        true,
      ) as List?;
  static List<String>? metaKey(dynamic response) => (getJsonField(
        response,
        r'''$.results[:].meta_key''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetNotificationsCount {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
  }) async {
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: 'v3/notifications/unread_count/',
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getNotificationsCount',
          apiUrl: apiUrl,
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class GetNotifications {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
  }) async {
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: 'v3/notifications/?items_per_page=100&page=1',
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getNotifications',
          apiUrl: apiUrl,
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class PatchNotifications {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? id = '',
  }) async {
    final apiPath = 'v3/notifications/${id}/';
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: apiPath,
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'patchNotifications',
          apiUrl: apiUrl,
          callType: ApiCallType.PATCH,
          headers: {
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({"is_read": true}),
          bodyType: BodyType.JSON,
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class GetTasks {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    int itemsPerPage = 50,
    int page = 1,
    String? status,
    String? originModule,
  }) async {
    final baseUrl = 'https://$tenant.itsquery.com/api/v1/tasks/tasks/';
    final query = <String, String>{
      'items_per_page': itemsPerPage.toString(),
      'page': page.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (originModule != null && originModule.isNotEmpty)
        'origin_module': originModule,
    };

    final apiUrl =
        Uri.parse(baseUrl).replace(queryParameters: query).toString();

    return FFApiInterceptor.makeApiCall(
      ApiCallOptions(
        callName: 'getTasks',
        apiUrl: apiUrl,
        callType: ApiCallType.GET,
        headers: {'Authorization': 'Bearer $token'},
        params: {},
        returnBody: true,
        encodeBodyUtf8: true,
        decodeUtf8: true,
        cache: false,
        alwaysAllowBody: false,
      ),
      interceptors,
    );
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class PostTaskSetStatus {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    required String id,
    required String status,
    String? comment,
  }) async {
    final apiPath = 'v1/tasks/tasks/$id/set-status/';
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: apiPath,
    );

    return FFApiInterceptor.makeApiCall(
      ApiCallOptions(
        callName: 'postTaskSetStatus',
        apiUrl: apiUrl,
        callType: ApiCallType.POST,
        headers: {'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'status': status,
          if (comment != null) 'comment': comment,
        }),
        bodyType: BodyType.JSON,
        params: {},
        returnBody: true,
        encodeBodyUtf8: true,
        decodeUtf8: true,
        cache: false,
        alwaysAllowBody: false,
      ),
      interceptors,
    );
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class PatchUser {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? pushToken = '',
    String? deviceId,
    String? platform,
    bool active = true,
  }) async {
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: 'profile/push-token/',
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'patchNotifications',
          apiUrl: apiUrl,
          callType: ApiCallType.PATCH,
          headers: {
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "push_token": pushToken,
            if (deviceId != null && deviceId.isNotEmpty) "device_id": deviceId,
            if (platform != null && platform.isNotEmpty) "platform": platform,
            "active": active,
          }),
          bodyType: BodyType.JSON,
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class UpdateUserProfile {
  static Future<ApiCallResponse> call(
      {String? tenant = '',
      String? token = '',
      String? id = '',
      String? fullName = '',
      String? username = '',
      String? email = '',
      String? avatar = '',
      String? roleId = '',
      String? firma = ''}) async {
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: 'update-user/$id/',
    );
    final body = '''
{
    "id": $id,
    "username": $username,
    "email": $email,
    "groups": [
        $roleId
    ],
    "full_name": $fullName,
    "avatar": $avatar,
    "firma": $firma,
    "json_data": {}
}
''';

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'updateUserProfile',
          apiUrl: apiUrl,
          callType: ApiCallType.PUT,
          headers: {
            'Authorization': 'Bearer $token',
          },
          body: body,
          bodyType: BodyType.JSON,
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class GenerateDocument {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? body = '',
  }) async {
    final ffApiRequestBody = body;

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'postGenerateDocument',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/downloadContract',
          ),
          callType: ApiCallType.POST,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: const {},
          body: ffApiRequestBody,
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List? url(dynamic response) => getJsonField(
        response,
        r'''$.data[:].file_url''',
        true,
      ) as List?;
}

class GetFilteredDocumentTemplates {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    int? moduleId,
    int? recordId,
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getFilteredDocumentTemplates',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/modulos/$moduleId/document-templates/$recordId/',
          ),
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          bodyType: BodyType.NONE,
          returnBody: true,
          encodeBodyUtf8: false,
          decodeUtf8: false,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static List? templates(dynamic response) => getJsonField(
        response,
        r'''$.templates''',
        true,
      ) as List?;

  static int total(dynamic response) => getJsonField(
        response,
        r'''$.total''',
      ) as int;
}

class ChangePassword {
  static Future<ApiCallResponse> call({
    String? id = '',
    String? password = '',
    String? token = '',
  }) async {
    final ffApiRequestBody = '''
{
  "password": "$password",
  "password2": "$password"
}''';
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'changePassword',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: FFAppState().organizacion,
            apiPath: 'reset-password/$id/',
          ),
          callType: ApiCallType.PUT,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          body: ffApiRequestBody,
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: false,
          decodeUtf8: false,
          cache: false,
          isStreamingApi: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class GetRoleGroups {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
  }) async {
    final apiUrl = ApiBaseUrl.forTenantCall(
      tenant: tenant ?? '',
      apiPath: 'groups/?&items_per_page=100',
    );

    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'getRoleGroups',
          apiUrl: apiUrl,
          callType: ApiCallType.GET,
          headers: {
            'Authorization': 'Bearer $token',
          },
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

class HomeConfigResponse {
  final String? customPage;
  final String? moduleName;
  final bool replaceHome;
  final bool appOnly;

  HomeConfigResponse({
    this.customPage,
    this.moduleName,
    this.replaceHome = false,
    this.appOnly = false,
  });

  factory HomeConfigResponse.fromJson(Map<String, dynamic> json) {
    return HomeConfigResponse(
      customPage: json['custom_page'] as String?,
      moduleName: json['module_name'] as String?,
      replaceHome: json['replace_home'] as bool? ?? false,
      appOnly: json['app_only'] as bool? ?? false,
    );
  }
}

class HomeConfigCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'homeConfig',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/modulos/home-config/',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Platform': 'app',
          },
          callType: ApiCallType.GET,
          params: {},
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}

Future<HomeConfigResponse> fetchHomeConfig(String tenant, String token) async {
  try {
    final response = await HomeConfigCall.call(
      tenant: tenant,
      token: token,
    );

    if (response.succeeded && response.jsonBody != null) {
      return HomeConfigResponse.fromJson(
          response.jsonBody as Map<String, dynamic>);
    }

    return HomeConfigResponse();
  } catch (e) {
    print('HomeConfig fetch error: $e');
    return HomeConfigResponse();
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {}
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {}
    return isList ? '[]' : '{}';
  }
}
// config group https://apicertificadora.itsquery.com/api/v2/modulos/53/custom_fields/

class FetchExternalFieldOptionsCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    int? customFieldId,
    Map<String, dynamic>? params,
    String? token,
  }) async {
    final bodyJson = jsonEncode({'params': params ?? {}});
    return FFApiInterceptor.makeApiCall(
        ApiCallOptions(
          callName: 'fetchExternalFieldOptions',
          apiUrl: ApiBaseUrl.forTenantCall(
            tenant: tenant ?? '',
            apiPath: 'v2/custom-fields/$customFieldId/fetch-options/',
          ),
          callType: ApiCallType.POST,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          params: {},
          body: bodyJson,
          bodyType: BodyType.JSON,
          returnBody: true,
          encodeBodyUtf8: true,
          decodeUtf8: true,
          cache: false,
          alwaysAllowBody: false,
        ),
        interceptors);
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];
}
