import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiBaseUrl {
  ApiBaseUrl._();

  static String get _localBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static const String _productionDomain = 'itsquery.com';

  static const List<String> _localKeywords = [
    'local',
    'apilocal',
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  ];

  static bool _isLocalTenant(String tenant) {
    final normalized = tenant.trim().toLowerCase();
    return _localKeywords.any((keyword) => normalized.contains(keyword));
  }

  static String _tenantLabel(String tenant) {
    var label = tenant.trim().toLowerCase();
    label = label
        .replaceFirst(RegExp(r'^https?://'), '')
        .split('/')
        .first
        .split('.')
        .first;
    if (label.startsWith('socket')) {
      return label.substring('socket'.length);
    }
    if (label.startsWith('api')) {
      return label.substring('api'.length);
    }
    return label;
  }

  static String build({
    required String tenant,
    required String path,
  }) {
    if (_isLocalTenant(tenant)) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return '$_localBaseUrl$cleanPath';
    }

    if (tenant.trim().isEmpty) {
      return 'https://$_productionDomain$path';
    }

    return 'https://$tenant.$_productionDomain$path';
  }

  /// Construye la URL del gateway WebSocket correspondiente al tenant.
  ///
  /// La API y los sockets viven en servicios distintos en producción:
  /// `apius.itsquery.com` y `socketus.itsquery.com`, respectivamente.
  static Uri buildWebSocket({
    required String tenant,
    required String path,
    Map<String, String> queryParameters = const {},
  }) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    if (_isLocalTenant(tenant)) {
      final localUri = Uri.parse(_localBaseUrl);
      return localUri.replace(
        scheme: localUri.scheme == 'https' ? 'wss' : 'ws',
        path: cleanPath,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
    }

    final tenantLabel = _tenantLabel(tenant);
    final socketHost = tenantLabel.isEmpty
        ? 'socket.$_productionDomain'
        : 'socket$tenantLabel.$_productionDomain';
    return Uri(
      scheme: 'wss',
      host: socketHost,
      path: cleanPath,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  /// Origin web autorizado por el gateway para el tenant actual.
  ///
  /// Los navegadores lo envían automáticamente. Los clientes nativos deben
  /// incluirlo expresamente durante el handshake WebSocket.
  static String buildWebOrigin({required String tenant}) {
    if (_isLocalTenant(tenant)) return _localBaseUrl;
    final tenantLabel = _tenantLabel(tenant);
    return tenantLabel.isEmpty
        ? 'https://$_productionDomain'
        : 'https://$tenantLabel.$_productionDomain';
  }

  static String forTenantCall({
    required String tenant,
    required String apiPath,
  }) {
    return build(
      tenant: tenant,
      path: '/api/$apiPath',
    );
  }
}
