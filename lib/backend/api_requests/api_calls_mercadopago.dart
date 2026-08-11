import 'dart:convert';
import 'interceptor.dart';
import 'api_manager.dart';
import 'api_base_url.dart';
import '/flutter_flow/flutter_flow_util.dart';

export 'api_manager.dart' show ApiCallResponse;

class MercadoPagoCreatePreferenceCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? moduleName = '',
    int? recordId,
    String? recordType = 'register',
    String? fieldSlug = '',
    String? backUrlSuccess = '',
  }) async {
    final bodyJson = jsonEncode({
      'module_name': moduleName ?? '',
      'record_id': recordId,
      'record_type': recordType ?? 'register',
      'field_slug': fieldSlug ?? '',
      'back_url_success': backUrlSuccess ?? '',
    });
    return FFApiInterceptor.makeApiCall(
      ApiCallOptions(
        callName: 'mercadoPagoCreatePreference',
        apiUrl: ApiBaseUrl.forTenantCall(
          tenant: tenant ?? '',
          apiPath: 'v2/mercadopago/create-preference/',
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
      interceptors,
    );
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static String? preferenceId(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.preference_id'''));
  static String? initPoint(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.init_point'''));
  static String? sandboxInitPoint(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.sandbox_init_point'''));
  static double? amount(dynamic response) =>
      castToType<double>(getJsonField(response, r'''$.amount'''));
  static String? currencyId(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.currency_id'''));
}

class MercadoPagoCreateSubscriptionPlanCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? moduleName = '',
    int? recordId,
    String? recordType = 'register',
    String? fieldSlug = '',
    int? planIndex,
  }) async {
    final bodyJson = jsonEncode({
      'module_name': moduleName ?? '',
      'record_id': recordId,
      'record_type': recordType ?? 'register',
      'field_slug': fieldSlug ?? '',
      'plan_index': planIndex ?? 0,
    });
    return FFApiInterceptor.makeApiCall(
      ApiCallOptions(
        callName: 'mercadoPagoCreateSubscriptionPlan',
        apiUrl: ApiBaseUrl.forTenantCall(
          tenant: tenant ?? '',
          apiPath: 'v2/mercadopago/create-subscription-plan/',
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
      interceptors,
    );
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static String? planId(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.plan_id'''));
  static String? initPoint(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.init_point'''));
  static String? reason(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.reason'''));
  static double? amount(dynamic response) =>
      castToType<double>(getJsonField(response, r'''$.amount'''));
  static String? frequency(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.frequency'''));
  static String? frequencyType(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.frequency_type'''));
  static String? currencyId(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.currency_id'''));
}

class MercadoPagoCreateSubscriptionCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? moduleName = '',
    int? recordId,
    String? recordType = 'register',
    String? fieldSlug = '',
    String? payerEmail = '',
    String? cardTokenId = '',
  }) async {
    final bodyMap = <String, dynamic>{
      'module_name': moduleName ?? '',
      'record_id': recordId,
      'record_type': recordType ?? 'register',
      'field_slug': fieldSlug ?? '',
      'payer_email': payerEmail ?? '',
    };
    if (cardTokenId != null && cardTokenId.isNotEmpty) {
      bodyMap['card_token_id'] = cardTokenId;
    }
    final bodyJson = jsonEncode(bodyMap);
    return FFApiInterceptor.makeApiCall(
      ApiCallOptions(
        callName: 'mercadoPagoCreateSubscription',
        apiUrl: ApiBaseUrl.forTenantCall(
          tenant: tenant ?? '',
          apiPath: 'v2/mercadopago/create-subscription/',
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
      interceptors,
    );
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static String? subscriptionId(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.subscription_id'''));
  static String? initPoint(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.init_point'''));
  static String? status(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.status'''));
  static String? reason(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.reason'''));
  static double? amount(dynamic response) =>
      castToType<double>(getJsonField(response, r'''$.amount'''));
}

class MercadoPagoPaymentStatusCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? moduleName = '',
    int? recordId,
    String? recordType = 'register',
    String? fieldSlug = '',
  }) async {
    return FFApiInterceptor.makeApiCall(
      ApiCallOptions(
        callName: 'mercadoPagoPaymentStatus',
        apiUrl: ApiBaseUrl.forTenantCall(
          tenant: tenant ?? '',
          apiPath:
              'v2/mercadopago/payment-status/?module_name=${Uri.encodeComponent(moduleName ?? '')}&record_id=${recordId ?? ''}&field_slug=${Uri.encodeComponent(fieldSlug ?? '')}&record_type=${Uri.encodeComponent(recordType ?? 'register')}',
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
      interceptors,
    );
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static String? status(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.status'''));
  static String? preferenceId(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.preference_id'''));
  static double? amount(dynamic response) =>
      castToType<double>(getJsonField(response, r'''$.amount'''));
  static String? paymentId(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.payment_id'''));
  static String? paidAt(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.paid_at'''));
}

class MercadoPagoSyncPaymentCall {
  static Future<ApiCallResponse> call({
    String? tenant = '',
    String? token = '',
    String? paymentId = '',
  }) async {
    final bodyJson = jsonEncode({
      'payment_id': paymentId ?? '',
    });
    return FFApiInterceptor.makeApiCall(
      ApiCallOptions(
        callName: 'mercadoPagoSyncPayment',
        apiUrl: ApiBaseUrl.forTenantCall(
          tenant: tenant ?? '',
          apiPath: 'v2/mercadopago/sync-payment/',
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
      interceptors,
    );
  }

  static final interceptors = [
    ExpiredSessionInterceptor(),
  ];

  static String? status(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.status'''));
  static bool? statusChanged(dynamic response) =>
      castToType<bool>(getJsonField(response, r'''$.status_changed'''));
  static bool? synced(dynamic response) =>
      castToType<bool>(getJsonField(response, r'''$.synced'''));
}
