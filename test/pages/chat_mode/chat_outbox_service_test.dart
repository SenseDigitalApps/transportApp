import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:transport_app/pages/chat_mode/models/chat_models.dart';
import 'package:transport_app/pages/chat_mode/services/chat_api_service.dart';
import 'package:transport_app/pages/chat_mode/services/chat_outbox_service.dart';
import 'package:sembast/sembast_memory.dart';

class _FakeChatApiService extends ChatApiService {
  bool failNextSend = false;
  int uploadCalls = 0;
  int sendCalls = 0;
  final List<String> sentClientIds = [];

  @override
  Future<ChatAttachment> uploadAttachment({
    required int threadId,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    required ChatAttachmentKind kind,
  }) async {
    uploadCalls++;
    return ChatAttachment(
      id: 99,
      kind: kind,
      name: filename,
      mimeType: mimeType,
      size: bytes.length,
      url: 'https://example.test/$filename',
    );
  }

  @override
  Future<ChatMessage> sendOpenClawMessage(
    int threadId, {
    required String content,
    required String clientMsgId,
    List<ChatAttachment> attachments = const [],
    bool retry = false,
  }) async {
    sendCalls++;
    sentClientIds.add(clientMsgId);
    if (failNextSend) {
      failNextSend = false;
      throw StateError('offline');
    }
    return ChatMessage(
      id: 501,
      clientMsgId: clientMsgId,
      role: ChatRole.user,
      content: content,
      metadata: {
        'attachments': attachments.map((item) => item.toJson()).toList(),
      },
      timestamp: DateTime.now(),
    );
  }
}

void main() {
  late Database database;
  late ChatOutboxStore store;

  setUp(() async {
    database = await databaseFactoryMemory.openDatabase(
      'outbox-${DateTime.now().microsecondsSinceEpoch}',
    );
    store = ChatOutboxStore(openDatabase: () async => database);
  });

  tearDown(() => database.close());

  test('persists pending messages and local attachment bytes', () async {
    final pending = PendingChatMessage(
      tenant: 'tenant-a',
      userId: '7',
      clientMsgId: 'local-1',
      threadId: 42,
      content: 'Mensaje offline',
      attachments: [
        ChatAttachment.local(
          kind: ChatAttachmentKind.image,
          name: 'photo.jpg',
          mimeType: 'image/jpeg',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ],
      createdAt: DateTime.utc(2026, 7, 20),
    );

    await store.put(pending);
    final restored = await store.get('tenant-a', '7', 'local-1');

    expect(restored, isNotNull);
    expect(restored!.content, 'Mensaje offline');
    expect(restored.attachments.single.localBytes, [1, 2, 3, 4]);
  });

  test('retries the same id without uploading an accepted attachment twice',
      () async {
    final api = _FakeChatApiService()..failNextSend = true;
    final service = ChatOutboxService(
      api: api,
      store: store,
      tenantProvider: () => 'tenant-a',
      userIdProvider: () => '7',
    );
    final retryScheduled = service.events.firstWhere(
      (event) => event.pending.attemptCount == 1,
    );

    final pending = await service.enqueue(
      threadId: 42,
      content: 'Enviar cuando vuelva',
      attachments: [
        ChatAttachment.local(
          kind: ChatAttachmentKind.file,
          name: 'document.pdf',
          mimeType: 'application/pdf',
          bytes: Uint8List.fromList([5, 6, 7]),
        ),
      ],
    );
    await retryScheduled.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final completed = service.events.firstWhere((event) => event.completed);
    await service.flush(force: true);
    final result = await completed.timeout(const Duration(seconds: 2));

    expect(result.pending.clientMsgId, pending.clientMsgId);
    expect(api.sentClientIds, [pending.clientMsgId, pending.clientMsgId]);
    expect(api.uploadCalls, 1);
    expect(api.sendCalls, 2);
    expect(await store.list('tenant-a', '7'), isEmpty);
    await service.dispose();
  });
}
