import 'package:flutter_test/flutter_test.dart';
import 'package:transport_app/backend/api_requests/api_base_url.dart';

void main() {
  group('ApiBaseUrl.buildWebSocket', () {
    test('cambia el host API del tenant por el servicio socket', () {
      final uri = ApiBaseUrl.buildWebSocket(
        tenant: 'apius',
        path: '/ws/openclaw/42/',
        queryParameters: const {'token': 'jwt'},
      );

      expect(uri.scheme, 'wss');
      expect(uri.host, 'socketus.itsquery.com');
      expect(uri.path, '/ws/openclaw/42/');
      expect(uri.queryParameters['token'], 'jwt');
    });

    test('evita duplicar prefijos de servicio', () {
      final uri = ApiBaseUrl.buildWebSocket(
        tenant: 'socketus.itsquery.com',
        path: 'ws/openclaw/7/',
      );

      expect(uri.toString(), 'wss://socketus.itsquery.com/ws/openclaw/7/');
    });
  });

  group('ApiBaseUrl.buildWebOrigin', () {
    test('usa el host web del tenant y no el host de API o sockets', () {
      expect(
        ApiBaseUrl.buildWebOrigin(tenant: 'apius'),
        'https://us.itsquery.com',
      );
      expect(
        ApiBaseUrl.buildWebOrigin(tenant: 'socketus.itsquery.com'),
        'https://us.itsquery.com',
      );
    });
  });
}
