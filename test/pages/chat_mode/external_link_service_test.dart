import 'package:flutter_test/flutter_test.dart';
import 'package:transport_app/pages/chat_mode/services/external_link_service.dart';

void main() {
  group('ExternalLinkService.browserUri', () {
    test('acepta enlaces web seguros', () {
      expect(
        ExternalLinkService.browserUri('https://itsquery.com/demo')?.toString(),
        'https://itsquery.com/demo',
      );
    });

    test('normaliza enlaces que comienzan por www', () {
      expect(
        ExternalLinkService.browserUri('www.itsquery.com')?.toString(),
        'https://www.itsquery.com',
      );
    });

    test('rechaza esquemas que no deben abrirse en el navegador', () {
      expect(ExternalLinkService.browserUri('javascript:alert(1)'), isNull);
      expect(ExternalLinkService.browserUri('/ruta/interna'), isNull);
    });
  });
}
