import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:transport_app/app_state.dart';
import 'package:transport_app/backend/api_requests/api_base_url.dart';

import '../models/chat_models.dart';

/// Cliente REST del centro de mensajes.
///
/// Los agentes se administran con `/api/bots/`; el historial y los adjuntos
/// viven en `/api/v4/chat-threads/`. El contenido conversacional de agentes
/// externos se persiste por REST; el WebSocket se reserva para eventos.
class ChatApiService {
  String get _tenant => FFAppState().organizacion;
  String get _token => FFAppState().token;

  Map<String, String> get _jsonHeaders => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'X-Request-Source': 'app',
      };

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
        'X-Request-Source': 'app',
      };

  Uri _v4Uri(String path) => Uri.parse(
        ApiBaseUrl.build(tenant: _tenant, path: '/api/v4/$path'),
      );

  Uri _botsUri([String path = '']) => Uri.parse(
        ApiBaseUrl.build(tenant: _tenant, path: '/api/bots/$path'),
      );

  String resolveMediaUrl(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return '';
    final uri = Uri.tryParse(raw);
    if (uri?.hasScheme == true) return raw;
    final path = raw.startsWith('/') ? raw : '/$raw';
    return ApiBaseUrl.build(tenant: _tenant, path: path);
  }

  // --- Query IA ----------------------------------------------------------

  Future<ChatThread> fetchMainThread() async {
    final response = await http.get(
      _v4Uri('chat-threads/main/'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'fetchMainThread');
    return ChatThread.fromJson(_decodeMap(response));
  }

  Future<String> sendToQueryBot(String message) async {
    final response = await http.post(
      _v4Uri('start-gpt-chat/'),
      headers: _jsonHeaders,
      body: jsonEncode({'message': message}),
    );
    _ensureOk(response, 'sendToQueryBot');
    final data = _decodeMap(response);
    return (data['bot_response'] ?? data['response'] ?? '').toString();
  }

  Future<void> logThreadMessage(
    int threadId, {
    required ChatRole role,
    required String content,
    String? clientMsgId,
    Map<String, dynamic> metadata = const {},
  }) async {
    final response = await http.post(
      _v4Uri('chat-threads/$threadId/messages/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'role': role.name,
        'content': content,
        'client_msg_id': clientMsgId ?? '',
        'metadata': metadata,
      }),
    );
    _ensureOk(response, 'logThreadMessage');
  }

  // --- Agentes -----------------------------------------------------------

  Future<List<BotConnection>> fetchBots() async {
    final response = await http.get(_botsUri(), headers: _jsonHeaders);
    _ensureOk(response, 'fetchBots');
    final results = _decodeMap(response)['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map((item) => BotConnection.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<BotConnection> createBot({
    required String displayName,
    Uint8List? avatarBytes,
    String? avatarName,
    String? avatarMimeType,
  }) async {
    final request = http.MultipartRequest('POST', _botsUri())
      ..headers.addAll(_authHeaders)
      ..fields['display_name'] = displayName;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'avatar',
        avatarBytes,
        filename: avatarName ?? 'avatar.jpg',
        contentType: _mediaType(avatarMimeType, 'image/jpeg'),
      ));
    }
    final response = await http.Response.fromStream(await request.send());
    _ensureOk(response, 'createBot');
    return BotConnection.fromJson(_decodeMap(response));
  }

  Future<void> deleteBot(int botId) async {
    final response = await http.delete(
      _botsUri('$botId/'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'deleteBot');
  }

  Future<BotBundle> fetchBotBundle(int botId) async {
    final response = await http.get(
      _botsUri('$botId/bundle/'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'fetchBotBundle');
    return BotBundle.fromJson(_decodeMap(response));
  }

  Future<AgentAccessCatalog> fetchAgentAccessOptions() async {
    final response = await http.get(
      _botsUri('access-options/'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'fetchAgentAccessOptions');
    return AgentAccessCatalog.fromJson(_decodeMap(response));
  }

  Future<AgentAccessSelection> fetchAgentAccess(int botId) async {
    final response = await http.get(
      _botsUri('$botId/access/'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'fetchAgentAccess');
    return AgentAccessSelection.fromJson(_decodeMap(response));
  }

  Future<AgentAccessSelection> updateAgentAccess(
    int botId, {
    required List<int> userIds,
    required List<int> groupIds,
  }) async {
    final response = await http.patch(
      _botsUri('$botId/access/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'user_ids': userIds,
        'group_ids': groupIds,
      }),
    );
    _ensureOk(response, 'updateAgentAccess');
    return AgentAccessSelection.fromJson(_decodeMap(response));
  }

  Future<List<ChatThread>> fetchAgentThreads(BotConnection bot) async {
    final response = await http.get(
      _botsUri('${bot.id}/threads/'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'fetchAgentThreads');
    final results = _decodeMap(response)['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map(
          (item) => ChatThread.fromJson(
            item.cast<String, dynamic>(),
            bot: bot,
          ),
        )
        .toList();
  }

  Future<ChatThread> createAgentTopic(
    BotConnection bot, {
    required String name,
    List<int>? userIds,
    List<int>? groupIds,
  }) async {
    final response = await http.post(
      _botsUri('${bot.id}/threads/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        if (userIds != null) 'user_ids': userIds,
        if (groupIds != null) 'group_ids': groupIds,
      }),
    );
    _ensureOk(response, 'createAgentTopic');
    return ChatThread.fromJson(_decodeMap(response), bot: bot);
  }

  Future<ChatThread> updateAgentTopic(
    ChatThread thread, {
    String? name,
    List<int>? userIds,
    List<int>? groupIds,
  }) async {
    final bot = thread.bot;
    if (bot == null || thread.id == null) {
      throw const ChatApiException(
        'updateAgentTopic',
        400,
        '{"error":"invalid_thread"}',
      );
    }
    final response = await http.patch(
      _botsUri('${bot.id}/threads/${thread.id}/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        if (name != null) 'name': name,
        if (userIds != null) 'user_ids': userIds,
        if (groupIds != null) 'group_ids': groupIds,
      }),
    );
    _ensureOk(response, 'updateAgentTopic');
    return ChatThread.fromJson(_decodeMap(response), bot: bot);
  }

  Future<void> archiveAgentTopic(ChatThread thread) async {
    final bot = thread.bot;
    if (bot == null || thread.id == null) return;
    final response = await http.delete(
      _botsUri('${bot.id}/threads/${thread.id}/'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'archiveAgentTopic');
  }

  Future<bool> setThreadMuted(ChatThread thread, bool isMuted) async {
    final bot = thread.bot;
    if (bot == null || thread.id == null) return thread.isMuted;
    final response = await http.patch(
      _botsUri('${bot.id}/threads/${thread.id}/mute/'),
      headers: _jsonHeaders,
      body: jsonEncode({'is_muted': isMuted}),
    );
    _ensureOk(response, 'setThreadMuted');
    return _decodeMap(response)['is_muted'] == true;
  }

  Future<void> markThreadRead(ChatThread thread) async {
    final bot = thread.bot;
    if (bot == null || thread.id == null) return;
    final response = await http.post(
      _botsUri('${bot.id}/threads/${thread.id}/read/'),
      headers: _jsonHeaders,
      body: '{}',
    );
    _ensureOk(response, 'markThreadRead');
  }

  /// Borra un mensaje propio que aun no tuvo respuesta del agente.
  ///
  /// Descartarlo solo en el cliente era mentira: la fila seguia persistida y el
  /// mensaje reaparecia al recargar el hilo.
  Future<void> deleteThreadMessage(int threadId, int messageId) async {
    final response = await http.delete(
      _v4Uri('chat-threads/$threadId/messages/$messageId/'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'deleteThreadMessage');
  }

  /// Recorta el historial visible del canal. No borra: los mensajes anteriores
  /// se conservan y el agente mantiene su contexto.
  Future<void> resetThreadHistory(ChatThread thread) async {
    final bot = thread.bot;
    if (bot == null || thread.id == null) return;
    final response = await http.post(
      _botsUri('${bot.id}/threads/${thread.id}/reset-history/'),
      headers: _jsonHeaders,
      body: '{}',
    );
    _ensureOk(response, 'resetThreadHistory');
  }

  /// Aplica o descarta un cambio propuesto por un agente. Lo resuelve la
  /// persona con su propia sesion, nunca el agente con su credencial.
  Future<void> resolveAgentAction(String actionId, {required bool confirm}) async {
    final decision = confirm ? 'confirm' : 'cancel';
    final response = await http.post(
      _v4Uri('openclaw-agent/actions/$actionId/$decision/'),
      headers: _jsonHeaders,
      body: '{}',
    );
    _ensureOk(response, 'resolveAgentAction');
  }

  /// Resuelve varias propuestas con una sola decision.
  ///
  /// El backend responde 207 cuando proceso el lote entero pero algo fallo, asi
  /// que el detalle por accion es la unica fuente fiable: no basta con que la
  /// peticion no lance. Devuelve los ids que si quedaron resueltos y cuantos
  /// fallaron, para poder decirlo sin inventar.
  Future<({List<String> resolved, int failed, bool conflicted})>
      resolveAgentActionsBatch(
    List<String> actionIds, {
    required bool confirm,
  }) async {
    if (actionIds.isEmpty) {
      return (resolved: <String>[], failed: 0, conflicted: false);
    }
    final response = await http.post(
      _v4Uri('openclaw-agent/actions/resolve-batch/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'action_ids': actionIds,
        'decision': confirm ? 'confirm' : 'cancel',
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 207) {
      _ensureOk(response, 'resolveAgentActionsBatch');
    }
    final body = _decodeMap(response);
    final results = (body['results'] as List?) ?? const [];
    final resolved = <String>[];
    var conflicted = false;
    for (final raw in results.whereType<Map>()) {
      final item = raw.cast<String, dynamic>();
      final actionId = item['action_id'];
      if (item['ok'] == true && actionId is String) {
        resolved.add(actionId);
      } else if (item['error'] == 'record_changed') {
        conflicted = true;
      }
    }
    final failed = (body['failed'] as num?)?.toInt() ?? 0;
    return (resolved: resolved, failed: failed, conflicted: conflicted);
  }

  Future<bool> setSupportMode(ChatThread thread, bool active) async {
    final bot = thread.bot;
    if (bot == null || thread.id == null) return false;
    final uri = _botsUri('${bot.id}/threads/${thread.id}/support/');
    final response = active
        ? await http.post(uri, headers: _jsonHeaders, body: '{}')
        : await http.delete(uri, headers: _jsonHeaders);
    _ensureOk(response, 'setSupportMode');
    return _decodeMap(response)['active'] == true;
  }

  // --- Historial y adjuntos ---------------------------------------------

  Future<List<ChatMessage>> fetchThreadMessages(
    int threadId, {
    int limit = 100,
  }) async {
    final response = await http.get(
      _v4Uri('chat-threads/$threadId/messages/?limit=$limit'),
      headers: _jsonHeaders,
    );
    _ensureOk(response, 'fetchThreadMessages');
    final results = _decodeMap(response)['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map((item) => ChatMessage.fromThreadJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<ChatMessage> sendOpenClawMessage(
    int threadId, {
    required String content,
    required String clientMsgId,
    List<ChatAttachment> attachments = const [],
    bool retry = false,
  }) async {
    final response = await http
        .post(
          _v4Uri('chat-threads/$threadId/messages/send/'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'role': ChatRole.user.name,
            'content': content,
            'client_msg_id': clientMsgId,
            'metadata': {
              'attachments': attachments.map((item) => item.toJson()).toList(),
            },
            if (retry) 'retry': true,
          }),
        )
        .timeout(const Duration(seconds: 20));
    _ensureOk(response, 'sendOpenClawMessage');
    return ChatMessage.fromThreadJson(_decodeMap(response));
  }

  Future<ChatAttachment> uploadAttachment({
    required int threadId,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    required ChatAttachmentKind kind,
  }) async {
    if (bytes.length > 25 * 1024 * 1024) {
      throw const ChatApiException(
        'uploadAttachment',
        413,
        'El archivo supera el límite de 25 MB.',
      );
    }
    final request = http.MultipartRequest(
      'POST',
      _v4Uri('chat-threads/$threadId/attachments/'),
    )
      ..headers.addAll(_authHeaders)
      ..fields['kind'] = chatAttachmentKindToString(kind)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _mediaType(mimeType, 'application/octet-stream'),
      ));
    final streamed = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamed);
    _ensureOk(response, 'uploadAttachment');
    return ChatAttachment.fromJson(_decodeMap(response));
  }

  MediaType _mediaType(String? value, String fallback) {
    try {
      return MediaType.parse(
        value == null || value.trim().isEmpty ? fallback : value,
      );
    } catch (_) {
      return MediaType.parse(fallback);
    }
  }

  String _decodeBody(http.Response response) {
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = jsonDecode(_decodeBody(response));
    return decoded is Map ? decoded.cast<String, dynamic>() : const {};
  }

  void _ensureOk(http.Response response, String operation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatApiException(
        operation,
        response.statusCode,
        _decodeBody(response),
      );
    }
  }
}

class ChatApiException implements Exception {
  final String operation;
  final int statusCode;
  final String body;

  const ChatApiException(this.operation, this.statusCode, this.body);

  String get userMessage {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'] ?? decoded['detail'];
        if (error != null) return error.toString();
      }
    } catch (_) {}
    return 'No fue posible completar la operación.';
  }

  @override
  String toString() => 'ChatApiException($operation): $statusCode $body';
}
