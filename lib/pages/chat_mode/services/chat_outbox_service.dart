import 'dart:async';
import 'dart:typed_data';

import 'package:transport_app/app_state.dart';
import 'package:sembast/blob.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_models.dart';
import 'chat_api_service.dart';
import 'chat_outbox_database.dart';

enum ChatOutboxStatus { queued, sending, failed }

class PendingChatMessage {
  final String tenant;
  final String userId;
  final String clientMsgId;
  final int threadId;
  final String content;
  final List<ChatAttachment> attachments;
  final DateTime createdAt;
  final ChatOutboxStatus status;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final bool retryExisting;

  const PendingChatMessage({
    required this.tenant,
    required this.userId,
    required this.clientMsgId,
    required this.threadId,
    required this.content,
    required this.attachments,
    required this.createdAt,
    this.status = ChatOutboxStatus.queued,
    this.attemptCount = 0,
    this.nextAttemptAt,
    this.lastError,
    this.retryExisting = false,
  });

  String get storageKey => '$tenant|$userId|$clientMsgId';

  ChatMessage get optimisticMessage => ChatMessage(
        clientMsgId: clientMsgId,
        role: ChatRole.user,
        content: content,
        metadata: {
          'attachments': attachments.map((item) => item.toLocalJson()).toList(),
        },
        timestamp: createdAt,
        status: switch (status) {
          ChatOutboxStatus.queued => ChatMessageStatus.queued,
          ChatOutboxStatus.sending => ChatMessageStatus.sending,
          ChatOutboxStatus.failed => ChatMessageStatus.failed,
        },
      );

  PendingChatMessage copyWith({
    List<ChatAttachment>? attachments,
    ChatOutboxStatus? status,
    int? attemptCount,
    DateTime? nextAttemptAt,
    bool clearNextAttempt = false,
    String? lastError,
    bool clearError = false,
  }) =>
      PendingChatMessage(
        tenant: tenant,
        userId: userId,
        clientMsgId: clientMsgId,
        threadId: threadId,
        content: content,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        nextAttemptAt:
            clearNextAttempt ? null : (nextAttemptAt ?? this.nextAttemptAt),
        lastError: clearError ? null : (lastError ?? this.lastError),
        retryExisting: retryExisting,
      );

  Map<String, Object?> toRecord() => {
        'tenant': tenant,
        'user_id': userId,
        'client_msg_id': clientMsgId,
        'thread_id': threadId,
        'content': content,
        'attachments': attachments.map(_attachmentToRecord).toList(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'status': status.name,
        'attempt_count': attemptCount,
        'next_attempt_at': nextAttemptAt?.toUtc().toIso8601String(),
        'last_error': lastError,
        'retry_existing': retryExisting,
      };

  factory PendingChatMessage.fromRecord(Map<String, Object?> record) {
    final rawAttachments = record['attachments'];
    return PendingChatMessage(
      tenant: record['tenant']?.toString() ?? '',
      userId: record['user_id']?.toString() ?? '',
      clientMsgId: record['client_msg_id']?.toString() ?? '',
      threadId: int.tryParse(record['thread_id']?.toString() ?? '') ?? 0,
      content: record['content']?.toString() ?? '',
      attachments: rawAttachments is List
          ? rawAttachments
              .whereType<Map>()
              .map(
                  (item) => _attachmentFromRecord(item.cast<String, Object?>()))
              .toList()
          : const [],
      createdAt: DateTime.tryParse(record['created_at']?.toString() ?? '') ??
          DateTime.now(),
      status: ChatOutboxStatus.values.firstWhere(
        (item) => item.name == record['status']?.toString(),
        orElse: () => ChatOutboxStatus.queued,
      ),
      attemptCount:
          int.tryParse(record['attempt_count']?.toString() ?? '') ?? 0,
      nextAttemptAt:
          DateTime.tryParse(record['next_attempt_at']?.toString() ?? ''),
      lastError: record['last_error']?.toString(),
      retryExisting: record['retry_existing'] == true,
    );
  }

  static Map<String, Object?> _attachmentToRecord(ChatAttachment attachment) =>
      {
        ...attachment.toJson(),
        if (attachment.localBytes != null)
          'local_bytes': Blob(attachment.localBytes!),
      };

  static ChatAttachment _attachmentFromRecord(Map<String, Object?> record) {
    final value = record['local_bytes'];
    final bytes = value is Blob
        ? value.bytes
        : value is Uint8List
            ? value
            : null;
    return ChatAttachment(
      id: int.tryParse(record['id']?.toString() ?? '') ?? 0,
      kind: chatAttachmentKindFromString(record['kind']?.toString()),
      name: record['name']?.toString() ?? 'archivo',
      mimeType: record['mime_type']?.toString() ?? '',
      size:
          int.tryParse(record['size']?.toString() ?? '') ?? bytes?.length ?? 0,
      url: record['url']?.toString() ?? '',
      localBytes: bytes,
    );
  }
}

class ChatOutboxEvent {
  final PendingChatMessage pending;
  final ChatMessage? serverMessage;
  final bool completed;

  const ChatOutboxEvent({
    required this.pending,
    this.serverMessage,
    this.completed = false,
  });
}

class ChatOutboxStore {
  ChatOutboxStore({Future<Database> Function()? openDatabase})
      : _openDatabase = openDatabase ?? openChatOutboxDatabase;

  final Future<Database> Function() _openDatabase;
  final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('pending_chat_messages');
  Database? _database;

  Future<Database> get _db async => _database ??= await _openDatabase();

  Future<void> put(PendingChatMessage message) async {
    await _store.record(message.storageKey).put(await _db, message.toRecord());
  }

  Future<void> delete(PendingChatMessage message) async {
    await _store.record(message.storageKey).delete(await _db);
  }

  Future<PendingChatMessage?> get(
    String tenant,
    String userId,
    String clientMsgId,
  ) async {
    final value =
        await _store.record('$tenant|$userId|$clientMsgId').get(await _db);
    return value == null ? null : PendingChatMessage.fromRecord(value);
  }

  Future<List<PendingChatMessage>> list(String tenant, String userId) async {
    final records = await _store.find(
      await _db,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('tenant', tenant),
          Filter.equals('user_id', userId),
        ]),
        sortOrders: [SortOrder('created_at')],
      ),
    );
    return records
        .map((record) => PendingChatMessage.fromRecord(record.value))
        .toList();
  }
}

class ChatOutboxService {
  static final ChatOutboxService instance = ChatOutboxService();

  ChatOutboxService({
    ChatApiService? api,
    ChatOutboxStore? store,
    String Function()? tenantProvider,
    String Function()? userIdProvider,
  })  : _api = api ?? ChatApiService(),
        _store = store ?? ChatOutboxStore(),
        _tenantProvider = tenantProvider ?? (() => FFAppState().organizacion),
        _userIdProvider = userIdProvider ?? (() => FFAppState().id);

  final ChatApiService _api;
  final ChatOutboxStore _store;
  final String Function() _tenantProvider;
  final String Function() _userIdProvider;
  final StreamController<ChatOutboxEvent> _events =
      StreamController<ChatOutboxEvent>.broadcast();
  final StreamController<bool> _availability =
      StreamController<bool>.broadcast();
  final Uuid _uuid = const Uuid();
  Timer? _timer;
  bool _flushing = false;
  bool _disposed = false;

  Stream<ChatOutboxEvent> get events => _events.stream;
  Stream<bool> get availability => _availability.stream;

  String get _tenant => _tenantProvider();
  String get _userId => _userIdProvider();

  Future<List<PendingChatMessage>> initialize() async {
    final pending = await _store.list(_tenant, _userId);
    _timer ??= Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(flush()),
    );
    unawaited(flush());
    return pending;
  }

  Future<PendingChatMessage> enqueue({
    required int threadId,
    required String content,
    required List<ChatAttachment> attachments,
    String? clientMsgId,
    bool retryExisting = false,
  }) async {
    final message = PendingChatMessage(
      tenant: _tenant,
      userId: _userId,
      clientMsgId: clientMsgId ?? _uuid.v4(),
      threadId: threadId,
      content: content,
      attachments: attachments,
      createdAt: DateTime.now(),
      nextAttemptAt: DateTime.now(),
      retryExisting: retryExisting,
    );
    await _store.put(message);
    _emit(message);
    unawaited(flush());
    return message;
  }

  Future<bool> retry(String clientMsgId) async {
    final pending = await _store.get(_tenant, _userId, clientMsgId);
    if (pending == null) return false;
    final retried = pending.copyWith(
      status: ChatOutboxStatus.queued,
      attemptCount: 0,
      nextAttemptAt: DateTime.now(),
      clearError: true,
    );
    await _store.put(retried);
    _emit(retried);
    await flush();
    return true;
  }

  /// Descarta definitivamente un mensaje del outbox para que no reviva en el
  /// próximo `initialize()` ni lo reintente el flush periódico.
  Future<void> discard(String clientMsgId) async {
    final pending = await _store.get(_tenant, _userId, clientMsgId);
    if (pending == null) return;
    await _store.delete(pending);
  }

  Future<void> flush({bool force = false}) async {
    if (_flushing || _disposed || _tenant.isEmpty || _userId.isEmpty) return;
    _flushing = true;
    try {
      final now = DateTime.now();
      final pending = await _store.list(_tenant, _userId);
      for (final message in pending) {
        if (!force &&
            message.status != ChatOutboxStatus.failed &&
            message.nextAttemptAt?.isAfter(now) == true) {
          continue;
        }
        if (message.status == ChatOutboxStatus.failed) continue;
        await _send(message);
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _send(PendingChatMessage original) async {
    var pending = original.copyWith(
      status: ChatOutboxStatus.sending,
      clearError: true,
    );
    await _store.put(pending);
    _emit(pending);
    try {
      final uploaded = List<ChatAttachment>.from(pending.attachments);
      for (var index = 0; index < uploaded.length; index++) {
        final attachment = uploaded[index];
        if (attachment.isUploaded) {
          continue;
        }
        final bytes = attachment.localBytes;
        if (bytes == null || bytes.isEmpty) {
          throw const ChatOutboxException(
              'El adjunto local ya no está disponible.');
        }
        uploaded[index] = await _api.uploadAttachment(
          threadId: pending.threadId,
          bytes: bytes,
          filename: attachment.name,
          mimeType: attachment.mimeType,
          kind: attachment.kind,
        );
        pending = pending.copyWith(attachments: List.of(uploaded));
        await _store.put(pending);
      }
      pending = pending.copyWith(attachments: uploaded);
      final serverMessage = await _api.sendOpenClawMessage(
        pending.threadId,
        content: pending.content,
        clientMsgId: pending.clientMsgId,
        attachments: uploaded,
        retry: pending.retryExisting,
      );
      await _store.delete(pending);
      if (!_disposed) {
        _availability.add(true);
        _events.add(ChatOutboxEvent(
          pending: pending,
          serverMessage: serverMessage,
          completed: true,
        ));
      }
    } catch (error) {
      final attempt = pending.attemptCount + 1;
      final terminal = error is ChatOutboxException ||
          (error is ChatApiException &&
              error.statusCode >= 400 &&
              error.statusCode < 500 &&
              error.statusCode != 408 &&
              error.statusCode != 429);
      final failed = pending.copyWith(
        status: terminal ? ChatOutboxStatus.failed : ChatOutboxStatus.queued,
        attemptCount: attempt,
        nextAttemptAt:
            terminal ? null : DateTime.now().add(_retryDelay(attempt)),
        clearNextAttempt: terminal,
        lastError: _friendlyError(error),
      );
      await _store.put(failed);
      if (!_disposed) _availability.add(false);
      _emit(failed);
    }
  }

  Duration _retryDelay(int attempt) {
    const seconds = [2, 5, 10, 20, 40, 60];
    return Duration(
        seconds: seconds[(attempt - 1).clamp(0, seconds.length - 1)]);
  }

  String _friendlyError(Object error) {
    if (error is ChatOutboxException) return error.message;
    if (error is ChatApiException) return error.userMessage;
    return 'Sin conexión. Se reintentará automáticamente.';
  }

  void _emit(PendingChatMessage pending) {
    if (!_disposed) _events.add(ChatOutboxEvent(pending: pending));
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    await _events.close();
    await _availability.close();
  }
}

class ChatOutboxException implements Exception {
  final String message;

  const ChatOutboxException(this.message);
}
