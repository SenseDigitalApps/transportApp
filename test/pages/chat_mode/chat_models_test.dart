import 'package:flutter_test/flutter_test.dart';
import 'package:transport_app/pages/chat_mode/models/chat_models.dart';

void main() {
  group('BotConnection', () {
    test('lee el contrato actual de /api/bots/', () {
      final bot = BotConnection.fromJson({
        'id': 7,
        'display_name': 'Agente comercial',
        'avatar': '/media/agent.png',
        'thread_id': 42,
        'general_thread_id': 42,
        'private_thread_id': 43,
        'status': 'configured',
        'has_been_configured': true,
        'can_manage': true,
        'can_delete': false,
        'access_summary': {
          'user_count': 3,
          'group_count': 2,
          'is_shared': true,
        },
      });

      expect(bot.id, 7);
      expect(bot.threadId, 42);
      expect(bot.generalThreadId, 42);
      expect(bot.privateThreadId, 43);
      expect(bot.isConfigured, isTrue);
      expect(bot.hasBeenConfigured, isTrue);
      expect(bot.canManage, isTrue);
      expect(bot.canDelete, isFalse);
      expect(bot.userCount, 3);
      expect(bot.groupCount, 2);
      expect(bot.isShared, isTrue);
    });

    test('interpreta canales, permisos y contador sin mezclar al agente', () {
      const bot = BotConnection(
        id: 7,
        displayName: 'Agente comercial',
        status: BotConnectionStatus.configured,
      );
      final thread = ChatThread.fromJson({
        'id': 91,
        'agent_id': 7,
        'name': 'Mi canal privado',
        'kind': 'openclaw',
        'thread_type': 'private',
        'owner': {
          'id': 12,
          'name': 'Julia',
          'type': 'member',
        },
        'can_mute': false,
        'can_manage': true,
        'can_write': false,
        'support_active': false,
        'unread_count': 4,
        'allowed_user_ids': [12],
        'allowed_group_ids': [],
      }, bot: bot);

      expect(thread.bot?.id, 7);
      expect(thread.agentId, 7);
      expect(thread.isPrivateChannel, isTrue);
      expect(thread.canMute, isFalse);
      expect(thread.canWrite, isFalse);
      expect(thread.unreadCount, 4);
      expect(thread.owner?.name, 'Julia');
      expect(thread.displayName, 'Mi canal privado · Julia');
      expect(thread.allowedUserIds, [12]);
    });

    test('mantiene disponible un agente configurado aunque esté offline', () {
      final bot = BotConnection.fromJson({
        'id': 15,
        'display_name': 'Agente offline',
        'status': 'delivered',
        'has_been_configured': true,
      });

      expect(bot.status, BotConnectionStatus.delivered);
      expect(bot.isConfigured, isTrue);
    });

    test('se convierte en hilo del agente sin perder la identidad', () {
      const bot = BotConnection(
        id: 9,
        displayName: 'Agente de soporte',
        threadId: 81,
        status: BotConnectionStatus.delivered,
      );

      final thread = ChatThread.fromBot(bot);

      expect(thread.id, 81);
      expect(thread.kind, ChatThreadKind.openclaw);
      expect(thread.bot?.id, 9);
      expect(thread.name, 'Agente de soporte');
    });
  });

  group('ChatMessage attachments', () {
    test('preserva el autor real y su intervención como soporte', () {
      final message = ChatMessage.fromThreadJson({
        'id': 1,
        'role': 'user',
        'content': 'Estoy revisando el caso.',
        'timestamp': '2026-07-23T12:00:00Z',
        'author': {
          'id': 99,
          'name': 'Admin Query',
          'type': 'support',
        },
      });

      expect(message.author?.id, 99);
      expect(message.author?.name, 'Admin Query');
      expect(message.author?.isSupport, isTrue);
    });

    test('restaura estados de entrega persistidos por el backend', () {
      final queued = ChatMessage.fromThreadJson({
        'role': 'user',
        'content': 'hola',
        'client_msg_id': 'turn-queued',
        'delivery_status': 'queued',
        'timestamp': '2026-07-22T12:00:00Z',
      });
      final failed = ChatMessage.fromThreadJson({
        'role': 'user',
        'content': 'hola',
        'client_msg_id': 'turn-failed',
        'delivery_status': 'failed',
        'timestamp': '2026-07-22T12:00:00Z',
      });

      expect(queued.status, ChatMessageStatus.queued);
      expect(queued.deliveryStatus, 'queued');
      expect(isPendingAgentDelivery('processing'), isTrue);
      expect(failed.status, ChatMessageStatus.failed);
      expect(isPendingAgentDelivery('completed'), isFalse);
    });

    test('interpreta imagen, archivo y audio desde metadata', () {
      final message = ChatMessage.fromThreadJson({
        'id': 1,
        'role': 'assistant',
        'content': '**Listo**',
        'timestamp': '2026-07-18T12:00:00Z',
        'metadata': {
          'attachments': [
            {
              'id': 10,
              'kind': 'image',
              'name': 'foto.png',
              'mime_type': 'image/png',
              'size': 120,
              'url': 'https://example.com/foto.png',
            },
            {
              'id': 11,
              'kind': 'file',
              'name': 'reporte.pdf',
              'mime_type': 'application/pdf',
              'size': 2048,
              'url': 'https://example.com/reporte.pdf',
            },
            {
              'id': 12,
              'kind': 'audio',
              'name': 'voz.m4a',
              'mime_type': 'audio/mp4',
              'size': 4096,
              'url': 'https://example.com/voz.m4a',
            },
          ],
        },
      });

      expect(message.attachments, hasLength(3));
      expect(message.attachments[0].kind, ChatAttachmentKind.image);
      expect(message.attachments[1].kind, ChatAttachmentKind.file);
      expect(message.attachments[2].kind, ChatAttachmentKind.audio);
      expect(message.content, '**Listo**');
    });

    test('serializa el adjunto con el contrato del WebSocket', () {
      const attachment = ChatAttachment(
        id: 15,
        kind: ChatAttachmentKind.audio,
        name: 'voz.m4a',
        mimeType: 'audio/mp4',
        size: 8000,
        url: 'https://example.com/voz.m4a',
      );

      expect(attachment.toJson(), {
        'id': 15,
        'kind': 'audio',
        'name': 'voz.m4a',
        'mime_type': 'audio/mp4',
        'size': 8000,
        'url': 'https://example.com/voz.m4a',
      });
    });

    test('repara texto UTF-8 interpretado como Latin-1', () {
      final message = ChatMessage.fromThreadJson({
        'role': 'assistant',
        'content': 'AquÃ­ estoy. Â¿QuÃ© necesitas?',
        'timestamp': '2026-07-18T12:00:00Z',
      });

      expect(message.content, 'Aquí estoy. ¿Qué necesitas?');
      expect(normalizeChatText('Información correcta'), 'Información correcta');
    });
  });

  group('Actividad del agente', () {
    test('clasifica mensajes, audios y archivos para el indicador correcto',
        () {
      const audio = ChatAttachment(
        id: 1,
        kind: ChatAttachmentKind.audio,
        name: 'nota.m4a',
        mimeType: 'audio/mp4',
        size: 24,
        url: 'https://example.com/nota.m4a',
      );
      const file = ChatAttachment(
        id: 2,
        kind: ChatAttachmentKind.file,
        name: 'datos.csv',
        mimeType: 'text/csv',
        size: 42,
        url: 'https://example.com/datos.csv',
      );

      expect(
        classifyAgentPendingInput('hola', const [audio]),
        AgentPendingInputKind.message,
      );
      expect(
        classifyAgentPendingInput('', const [audio]),
        AgentPendingInputKind.audioOnly,
      );
      expect(
        classifyAgentPendingInput('', const [file]),
        AgentPendingInputKind.attachmentOnly,
      );
    });

    test('normaliza la actividad operacional recibida por WebSocket', () {
      final activity = AgentActivity.fromEvent(
        type: 'tool.progress',
        content: '',
        data: const {
          'label': 'Consultando inventario',
          'detail': 'Revisando existencias',
          'stage': 'consulta',
          'tool_name': 'inventario',
          'progress': 140,
        },
        receivedAt: DateTime.utc(2026, 7, 18),
      );

      expect(activity.label, 'Consultando inventario');
      expect(activity.detail, 'Revisando existencias');
      expect(activity.stage, 'consulta');
      expect(activity.toolName, 'inventario');
      expect(activity.progress, 100);
    });

    test('actualiza el mismo paso y conserva solo las seis actividades nuevas',
        () {
      final turn = AgentPendingTurn(
        clientMsgId: 'turn-1',
        startedAt: DateTime.utc(2026, 7, 18),
        inputKind: AgentPendingInputKind.message,
      );
      turn.recordActivity(AgentActivity.fromEvent(
        type: 'progress',
        content: '',
        data: const {'label': 'Paso repetido', 'progress': 20},
      ));
      turn.recordActivity(AgentActivity.fromEvent(
        type: 'progress',
        content: '',
        data: const {'label': 'Paso repetido', 'progress': 80},
      ));

      expect(turn.activities, hasLength(1));
      expect(turn.activities.single.progress, 80);

      for (var index = 0; index < 7; index++) {
        turn.recordActivity(AgentActivity.fromEvent(
          type: 'activity',
          content: '',
          data: {'label': 'Paso $index'},
        ));
      }

      expect(turn.activities, hasLength(6));
      expect(turn.activities.first.label, 'Paso 1');
      expect(turn.activities.last.label, 'Paso 6');
    });

    test('mantiene la referencia de la última actividad sin timeout local', () {
      final startedAt = DateTime.utc(2026, 7, 18, 12);
      final turn = AgentPendingTurn(
        clientMsgId: 'turn-long-running',
        startedAt: startedAt,
        inputKind: AgentPendingInputKind.audioOnly,
      );

      final activityAt = startedAt.add(const Duration(minutes: 8));
      turn.recordActivity(AgentActivity.fromEvent(
        type: 'activity',
        content: '',
        data: const {'label': 'Preparando la respuesta'},
        receivedAt: activityAt,
      ));

      expect(turn.lastActivityAt, activityAt);
      expect(turn.label, 'Preparando la respuesta');
    });
  });
}
