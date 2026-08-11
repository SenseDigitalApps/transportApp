import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transport_app/widgets/chat_message_notification_overlay.dart';

void main() {
  testWidgets('la notificacion del chat muestra una vista previa accionable',
      (WidgetTester tester) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageNotificationOverlay(
            title: 'Agente de ventas respondió',
            body: 'La consulta ya está lista.',
            onOpen: () => opened = true,
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('MENSAJE DE TU AGENTE'), findsOneWidget);
    expect(find.text('Agente de ventas respondió'), findsOneWidget);
    expect(find.text('La consulta ya está lista.'), findsOneWidget);

    await tester.tap(find.text('Abrir conversación'));
    expect(opened, isTrue);
  });
}
