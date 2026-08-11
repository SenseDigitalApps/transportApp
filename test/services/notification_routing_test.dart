import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transport_app/custom_code/PushNotificationService.dart';
import 'package:transport_app/services/realtime_notification_service.dart';

void main() {
  test('FCM usa la ruta dinamica del chat', () {
    expect(
      PushNotificationService.routeFromData({
        'route': '/chatMode?threadId=27',
      }),
      '/chatMode?threadId=27',
    );
  });

  test('FCM rechaza rutas externas', () {
    expect(
      PushNotificationService.routeFromData({
        'route': 'https://example.com',
      }),
      PushNotificationService.fixedRoute,
    );
  });

  test('FCM traduce la ruta web del agente al hilo móvil correcto', () {
    expect(
      PushNotificationService.routeFromData({
        'type': 'openclaw_message',
        'thread_id': '72',
        'route': '/apps/agents?agentId=8&threadId=72',
      }),
      '/chatMode?threadId=72',
    );
  });

  test('timeout del agente también abre directamente el hilo', () {
    final event = PushNotificationEvent.fromMessage(
      RemoteMessage(
        data: {
          'type': 'openclaw_timeout',
          'thread_id': '73',
          'route': '/apps/agents?agentId=8&threadId=73',
        },
      ),
    );

    expect(event.isChatMessage, isTrue);
    expect(event.route, '/chatMode?threadId=73');
    expect(event.threadId, 73);
  });

  test('FCM identifica el mensaje del chat y conserva notification_id', () {
    final event = PushNotificationEvent.fromMessage(
      RemoteMessage(
        data: {
          'type': 'openclaw_message',
          'thread_id': '27',
          'notification_id': 'openclaw:27:turn-1',
          'route': '/chatMode?threadId=27',
          'title': 'undefined',
        },
      ),
    );

    expect(event.isChatMessage, isTrue);
    expect(event.threadId, 27);
    expect(event.notificationId, 'openclaw:27:turn-1');
    expect(event.title, 'Tu agente respondió');
  });

  test('evento realtime conserva navegacion y estado leido', () {
    final event = RealtimeNotificationEvent.fromJson({
      'notification_id': 15,
      'message': 'El agente respondio',
      'link': '/chatMode?threadId=27',
      'is_read': true,
      'persisted': false,
      'instance_data': {
        'type': 'openclaw_message',
        'title': 'Agente respondio',
        'body': 'Listo',
        'thread_id': 27,
      },
    });

    expect(event.notificationId, '15');
    expect(event.route, '/chatMode?threadId=27');
    expect(event.isChatMessage, isTrue);
    expect(event.threadId, 27);
    expect(event.title, 'Agente respondio');
    expect(event.body, 'Listo');
    expect(event.isRead, isTrue);
    expect(event.persisted, isFalse);
  });

  test('notificacion realtime antigua abre el centro de notificaciones', () {
    final event = RealtimeNotificationEvent.fromJson({
      'notification_id': 16,
      'message': 'Registro actualizado',
      'link': '/apps/proyectos#45',
    });

    expect(event.route, '/notificationsScreen');
    expect(event.isChatMessage, isFalse);
  });

  test('evento de chat reemplaza textos undefined por mensajes seguros', () {
    final event = RealtimeNotificationEvent.fromJson({
      'notification_id': 'openclaw:27:turn-1',
      'message': 'Respuesta disponible',
      'link': '/chatMode?threadId=27',
      'instance_data': {
        'type': 'openclaw_message',
        'title': 'undefined',
        'body': 'undefined',
        'thread_id': '27',
      },
    });

    expect(event.title, 'Tu agente respondió');
    expect(event.body, 'Respuesta disponible');
    expect(event.notificationId, 'openclaw:27:turn-1');
  });
}
