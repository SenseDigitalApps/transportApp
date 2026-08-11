import 'dart:convert';
import 'dart:typed_data';

/// Contratos del centro de mensajes de Query.
///
/// Mantienen compatibilidad con el hilo interno de Query IA y reflejan los
/// contratos actuales de `/api/bots/`, `/api/v4/chat-threads/` y el gateway
/// WebSocket de agentes externos.
enum ChatThreadKind { queryBot, openclaw }

enum AgentThreadType { general, topic, privateChannel, standalone }

AgentThreadType agentThreadTypeFromString(String? value) {
  return switch (value) {
    'general' => AgentThreadType.general,
    'topic' => AgentThreadType.topic,
    'private' => AgentThreadType.privateChannel,
    _ => AgentThreadType.standalone,
  };
}

/// Repara texto UTF-8 que algún cliente haya interpretado como Latin-1.
/// Los textos correctos se devuelven sin cambios.
String normalizeChatText(Object? value) {
  final text = value?.toString() ?? '';
  if (!RegExp(r'[ÃÂâð�]').hasMatch(text)) return text;
  try {
    final repaired = utf8.decode(latin1.encode(text));
    final originalMarkers = RegExp(r'[ÃÂâð�]').allMatches(text).length;
    final repairedMarkers = RegExp(r'[ÃÂâð�]').allMatches(repaired).length;
    return repairedMarkers < originalMarkers ? repaired : text;
  } catch (_) {
    return text;
  }
}

ChatThreadKind chatThreadKindFromString(String? value) {
  return value == 'query_bot'
      ? ChatThreadKind.queryBot
      : ChatThreadKind.openclaw;
}

String chatThreadKindToString(ChatThreadKind kind) {
  return kind == ChatThreadKind.queryBot ? 'query_bot' : 'openclaw';
}

enum BotConnectionStatus { pending, delivered, configured }

BotConnectionStatus botConnectionStatusFromString(String? value) {
  switch (value) {
    case 'configured':
      return BotConnectionStatus.configured;
    case 'delivered':
      return BotConnectionStatus.delivered;
    case 'pending':
    default:
      return BotConnectionStatus.pending;
  }
}

class BotConnection {
  final int id;
  final String displayName;
  final String? avatar;
  final int? threadId;
  final int? generalThreadId;
  final int? privateThreadId;
  final BotConnectionStatus status;
  final bool hasBeenConfigured;
  final bool canManage;
  final bool canDelete;
  final int userCount;
  final int groupCount;
  final bool isShared;

  const BotConnection({
    required this.id,
    required this.displayName,
    this.avatar,
    this.threadId,
    this.generalThreadId,
    this.privateThreadId,
    required this.status,
    this.hasBeenConfigured = false,
    this.canManage = false,
    this.canDelete = false,
    this.userCount = 0,
    this.groupCount = 0,
    this.isShared = false,
  });

  bool get isConfigured =>
      hasBeenConfigured || status == BotConnectionStatus.configured;

  BotConnection copyWith({
    String? avatar,
    BotConnectionStatus? status,
    bool? hasBeenConfigured,
  }) {
    return BotConnection(
      id: id,
      displayName: displayName,
      avatar: avatar ?? this.avatar,
      threadId: threadId,
      generalThreadId: generalThreadId,
      privateThreadId: privateThreadId,
      status: status ?? this.status,
      hasBeenConfigured: hasBeenConfigured ?? this.hasBeenConfigured,
      canManage: canManage,
      canDelete: canDelete,
      userCount: userCount,
      groupCount: groupCount,
      isShared: isShared,
    );
  }

  factory BotConnection.fromJson(Map<String, dynamic> json) {
    final access =
        (json['access_summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    return BotConnection(
      id: _asInt(json['id']) ?? 0,
      displayName: normalizeChatText(json['display_name'] ?? 'Agente'),
      avatar: json['avatar']?.toString(),
      threadId: _asInt(json['thread_id']),
      generalThreadId: _asInt(json['general_thread_id'] ?? json['thread_id']),
      privateThreadId: _asInt(json['private_thread_id']),
      status: botConnectionStatusFromString(json['status']?.toString()),
      hasBeenConfigured: json['has_been_configured'] == true,
      canManage: json['can_manage'] == true,
      canDelete: json['can_delete'] == true,
      userCount: _asInt(access['user_count']) ?? 0,
      groupCount: _asInt(access['group_count']) ?? 0,
      isShared: access['is_shared'] == true,
    );
  }
}

class BotBundle {
  final String setupMessage;
  final String connectionUrl;
  final String warning;
  final BotConnectionStatus status;

  const BotBundle({
    required this.setupMessage,
    required this.connectionUrl,
    required this.warning,
    required this.status,
  });

  factory BotBundle.fromJson(Map<String, dynamic> json) => BotBundle(
        setupMessage: normalizeChatText(json['setup_message']),
        connectionUrl: (json['connection_url'] ?? '').toString(),
        warning: normalizeChatText(json['warning']),
        status: botConnectionStatusFromString(json['status']?.toString()),
      );
}

class AgentAccessOption {
  final int id;
  final String name;
  final String detail;

  const AgentAccessOption({
    required this.id,
    required this.name,
    this.detail = '',
  });

  factory AgentAccessOption.fromJson(Map<String, dynamic> json) =>
      AgentAccessOption(
        id: _asInt(json['id']) ?? 0,
        name: normalizeChatText(json['name'] ?? ''),
        detail: normalizeChatText(json['email'] ?? json['description'] ?? ''),
      );
}

class AgentAccessSelection {
  final List<int> userIds;
  final List<int> groupIds;

  const AgentAccessSelection({
    this.userIds = const [],
    this.groupIds = const [],
  });

  factory AgentAccessSelection.fromJson(Map<String, dynamic> json) =>
      AgentAccessSelection(
        userIds: _asIntList(json['user_ids']),
        groupIds: _asIntList(json['group_ids']),
      );
}

class AgentAccessCatalog {
  final List<AgentAccessOption> users;
  final List<AgentAccessOption> groups;

  const AgentAccessCatalog({
    this.users = const [],
    this.groups = const [],
  });

  factory AgentAccessCatalog.fromJson(Map<String, dynamic> json) =>
      AgentAccessCatalog(
        users: _accessOptions(json['users']),
        groups: _accessOptions(json['groups']),
      );
}

class ChatThread {
  final int? id;
  final String name;
  final ChatThreadKind kind;
  final int? conversationId;
  final Map<String, dynamic> config;
  final bool isPinned;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final BotConnection? bot;
  final int? agentId;
  final AgentThreadType threadType;
  final ChatAuthor? owner;
  final bool isMuted;
  final bool canMute;

  /// El canal solo notifica si se activa a mano. Aplica a los administradores
  /// en canales compartidos: para ellos la accion no es silenciar sino seguir.
  final bool notificationsOptIn;

  /// Estado efectivo que resuelve el backend respetando [notificationsOptIn].
  /// No siempre equivale a `!isMuted`: un admin sin seguir el canal tiene
  /// `isMuted == false` y aun asi no recibe nada.
  final bool notificationsEnabled;
  final bool canManage;
  final bool canWrite;

  /// Reiniciar el historial visible: administrador que ademas puede escribir.
  final bool canResetHistory;
  final bool supportActive;
  final int unreadCount;
  final List<int> allowedUserIds;
  final List<int> allowedGroupIds;

  const ChatThread({
    required this.id,
    required this.name,
    required this.kind,
    this.conversationId,
    this.config = const {},
    this.isPinned = false,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.bot,
    this.agentId,
    this.threadType = AgentThreadType.standalone,
    this.owner,
    this.isMuted = false,
    this.canMute = false,
    this.notificationsOptIn = false,
    this.notificationsEnabled = true,
    this.canManage = false,
    this.canWrite = true,
    this.canResetHistory = false,
    this.supportActive = false,
    this.unreadCount = 0,
    this.allowedUserIds = const [],
    this.allowedGroupIds = const [],
  });

  bool get isMainThread => kind == ChatThreadKind.queryBot;
  bool get isExternalAgent => bot != null;

  bool get isPrivateChannel => threadType == AgentThreadType.privateChannel;
  String get displayName {
    final ownerName = owner?.name.trim() ?? '';
    if (isPrivateChannel && canManage && ownerName.isNotEmpty) {
      return '$name · $ownerName';
    }
    return name;
  }

  bool get isSharedChannel =>
      threadType == AgentThreadType.general ||
      threadType == AgentThreadType.topic;

  ChatThread copyWith({
    BotConnection? bot,
    bool? isMuted,
    bool? notificationsEnabled,
    bool? canWrite,
    bool? supportActive,
    int? unreadCount,
  }) {
    return ChatThread(
      id: id,
      name: name,
      kind: kind,
      conversationId: conversationId,
      config: config,
      isPinned: isPinned,
      lastMessageAt: lastMessageAt,
      lastMessagePreview: lastMessagePreview,
      bot: bot ?? this.bot,
      agentId: agentId,
      threadType: threadType,
      owner: owner,
      isMuted: isMuted ?? this.isMuted,
      canMute: canMute,
      notificationsOptIn: notificationsOptIn,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      canManage: canManage,
      canWrite: canWrite ?? this.canWrite,
      canResetHistory: canResetHistory,
      supportActive: supportActive ?? this.supportActive,
      unreadCount: unreadCount ?? this.unreadCount,
      allowedUserIds: allowedUserIds,
      allowedGroupIds: allowedGroupIds,
    );
  }

  factory ChatThread.fromJson(
    Map<String, dynamic> json, {
    BotConnection? bot,
  }) {
    final lastMessage = json['last_message'];
    final rawOwner = json['owner'];
    return ChatThread(
      id: _asInt(json['id']),
      name: normalizeChatText(json['name'] ?? 'Hilo'),
      kind: chatThreadKindFromString(json['kind']?.toString()),
      conversationId: _asInt(json['conversation']),
      config: (json['config'] as Map?)?.cast<String, dynamic>() ?? const {},
      isPinned: json['is_pinned'] == true,
      lastMessageAt: _parseDate(json['last_message_at']),
      lastMessagePreview:
          lastMessage is Map ? normalizeChatText(lastMessage['content']) : null,
      bot: bot,
      agentId: _asInt(json['agent_id']),
      threadType: agentThreadTypeFromString(json['thread_type']?.toString()),
      owner: rawOwner is Map
          ? ChatAuthor.fromJson(rawOwner.cast<String, dynamic>())
          : null,
      isMuted: json['is_muted'] == true,
      canMute: json['can_mute'] == true,
      notificationsOptIn: json['notifications_opt_in'] == true,
      // Backends viejos no mandan el estado resuelto: ahi vale la regla clasica.
      notificationsEnabled: json.containsKey('notifications_enabled')
          ? json['notifications_enabled'] == true
          : json['is_muted'] != true,
      canManage: json['can_manage'] == true,
      canWrite: json['can_write'] != false,
      canResetHistory: json['can_reset_history'] == true,
      supportActive: json['support_active'] == true,
      unreadCount: _asInt(json['unread_count']) ?? 0,
      allowedUserIds: _asIntList(json['allowed_user_ids']),
      allowedGroupIds: _asIntList(json['allowed_group_ids']),
    );
  }

  factory ChatThread.fromBot(BotConnection bot) => ChatThread(
        id: bot.privateThreadId ?? bot.generalThreadId ?? bot.threadId,
        name: bot.displayName,
        kind: ChatThreadKind.openclaw,
        config: {'bot_connection_id': bot.id},
        bot: bot,
        agentId: bot.id,
        threadType: bot.privateThreadId != null
            ? AgentThreadType.privateChannel
            : AgentThreadType.general,
        canManage: bot.canManage,
      );
}

class ChatAuthor {
  final int? id;
  final String name;
  final String? avatar;
  final String type;

  const ChatAuthor({
    this.id,
    required this.name,
    this.avatar,
    required this.type,
  });

  bool get isSupport => type == 'support';

  factory ChatAuthor.fromJson(Map<String, dynamic> json) => ChatAuthor(
        id: _asInt(json['id']),
        name: normalizeChatText(json['name'] ?? ''),
        avatar: json['avatar']?.toString(),
        type: (json['type'] ?? 'member').toString(),
      );
}

enum ChatRole { user, assistant, system }

ChatRole chatRoleFromString(String? value) {
  switch (value) {
    case 'assistant':
    case 'bot':
      return ChatRole.assistant;
    case 'system':
      return ChatRole.system;
    case 'user':
    default:
      return ChatRole.user;
  }
}

enum ChatAttachmentKind { image, file, audio }

ChatAttachmentKind chatAttachmentKindFromString(String? value) {
  switch (value) {
    case 'image':
      return ChatAttachmentKind.image;
    case 'audio':
      return ChatAttachmentKind.audio;
    case 'file':
    default:
      return ChatAttachmentKind.file;
  }
}

String chatAttachmentKindToString(ChatAttachmentKind kind) => kind.name;

class ChatAttachment {
  final int id;
  final ChatAttachmentKind kind;
  final String name;
  final String mimeType;
  final int size;
  final String url;
  final Uint8List? localBytes;

  const ChatAttachment({
    required this.id,
    required this.kind,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.url,
    this.localBytes,
  });

  factory ChatAttachment.local({
    required ChatAttachmentKind kind,
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) =>
      ChatAttachment(
        id: 0,
        kind: kind,
        name: name,
        mimeType: mimeType,
        size: bytes.length,
        url: '',
        localBytes: bytes,
      );

  bool get isUploaded => url.isNotEmpty;
  bool get isLocal => localBytes != null && localBytes!.isNotEmpty;

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        id: _asInt(json['id']) ?? 0,
        kind: chatAttachmentKindFromString(json['kind']?.toString()),
        name: normalizeChatText(json['name'] ?? 'archivo'),
        mimeType: (json['mime_type'] ?? '').toString(),
        size: _asInt(json['size']) ?? 0,
        url: (json['url'] ?? '').toString(),
        localBytes: _asBytes(json['_local_bytes']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'mime_type': mimeType,
        'size': size,
        'url': url,
      };

  Map<String, dynamic> toLocalJson() => {
        ...toJson(),
        if (localBytes != null) '_local_bytes': localBytes,
      };
}

class ChatMessage {
  final int? id;
  final String? eventId;
  final String? clientMsgId;
  final ChatRole role;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final ChatMessageStatus status;
  final String? deliveryStatus;
  final DateTime? lastAgentActivityAt;
  final Map<String, dynamic> agentActivity;
  final ChatAuthor? author;

  const ChatMessage({
    this.id,
    this.eventId,
    this.clientMsgId,
    required this.role,
    required this.content,
    this.metadata = const {},
    required this.timestamp,
    this.status = ChatMessageStatus.sent,
    this.deliveryStatus,
    this.lastAgentActivityAt,
    this.agentActivity = const {},
    this.author,
  });

  bool get isMine => role == ChatRole.user;

  List<ChatAttachment> get attachments {
    final raw = metadata['attachments'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ChatAttachment.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  ChatMessage copyWith({
    int? id,
    String? eventId,
    ChatMessageStatus? status,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    String? deliveryStatus,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      clientMsgId: clientMsgId,
      role: role,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      lastAgentActivityAt: lastAgentActivityAt,
      agentActivity: agentActivity,
      author: author,
    );
  }

  factory ChatMessage.fromThreadJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _asInt(json['id']),
      clientMsgId: json['client_msg_id']?.toString(),
      role: chatRoleFromString(json['role']?.toString()),
      content: normalizeChatText(json['content']),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      timestamp: _parseDate(json['timestamp']) ?? DateTime.now(),
      status: chatMessageStatusFromDelivery(json['delivery_status']),
      deliveryStatus: json['delivery_status']?.toString(),
      lastAgentActivityAt: _parseDate(json['last_agent_activity_at']),
      agentActivity:
          (json['agent_activity'] as Map?)?.cast<String, dynamic>() ?? const {},
      author: json['author'] is Map
          ? ChatAuthor.fromJson(
              (json['author'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

enum ChatMessageStatus { queued, sending, sent, failed }

ChatMessageStatus chatMessageStatusFromDelivery(dynamic value) {
  return switch (value?.toString()) {
    'queued' => ChatMessageStatus.queued,
    'failed' => ChatMessageStatus.failed,
    _ => ChatMessageStatus.sent,
  };
}

bool isPendingAgentDelivery(dynamic value) {
  return const {'queued', 'dispatched', 'processing'}
      .contains(value?.toString());
}

enum AgentPendingInputKind { message, audioOnly, attachmentOnly }

AgentPendingInputKind classifyAgentPendingInput(
  String content,
  List<ChatAttachment> attachments,
) {
  if (content.trim().isNotEmpty) return AgentPendingInputKind.message;
  return attachments.any((item) => item.kind == ChatAttachmentKind.audio)
      ? AgentPendingInputKind.audioOnly
      : AgentPendingInputKind.attachmentOnly;
}

class AgentActivity {
  final String label;
  final String? detail;
  final String? stage;
  final String? toolName;
  final double? progress;
  final DateTime receivedAt;

  const AgentActivity({
    required this.label,
    this.detail,
    this.stage,
    this.toolName,
    this.progress,
    required this.receivedAt,
  });

  factory AgentActivity.fromEvent({
    required String type,
    required String content,
    required Map<String, dynamic> data,
    DateTime? receivedAt,
  }) {
    final state = data['state']?.toString().trim().toLowerCase();
    final explicitLabel = _activityText(data['label']);
    final contentLabel = _activityText(content);
    final tool = _activityText(data['tool_name'] ?? data['tool'], 64);
    final terminalState = {'done', 'complete', 'stop'}.contains(state);
    final label = terminalState
        ? 'Preparando la respuesta'
        : explicitLabel ??
            contentLabel ??
            ((type == 'typing' || type == 'message.delta')
                ? 'Preparando la respuesta'
                : type.startsWith('tool')
                    ? (tool == null
                        ? 'Consultando herramientas'
                        : 'Usando $tool')
                    : 'Trabajando en tu solicitud');
    final rawProgress = double.tryParse(data['progress']?.toString() ?? '');
    return AgentActivity(
      label: label,
      detail: _activityText(
        data['detail'] ?? data['summary'] ?? data['message'],
      ),
      stage: _activityText(data['stage'], 48),
      toolName: tool,
      progress: rawProgress?.clamp(0, 100).toDouble(),
      receivedAt: receivedAt ?? DateTime.now(),
    );
  }

  bool describesSameStep(AgentActivity other) {
    return label == other.label &&
        detail == other.detail &&
        stage == other.stage &&
        toolName == other.toolName;
  }
}

class AgentPendingTurn {
  final String clientMsgId;
  final DateTime startedAt;
  final AgentPendingInputKind inputKind;
  String? label;
  DateTime? lastActivityAt;
  final List<AgentActivity> activities;

  AgentPendingTurn({
    required this.clientMsgId,
    required this.startedAt,
    required this.inputKind,
    this.label,
    this.lastActivityAt,
    List<AgentActivity>? activities,
  }) : activities = activities ?? [];

  void recordActivity(AgentActivity activity) {
    label = activity.label;
    lastActivityAt = activity.receivedAt;
    if (activities.isNotEmpty && activities.last.describesSameStep(activity)) {
      activities[activities.length - 1] = activity;
      return;
    }
    activities.add(activity);
    if (activities.length > 6) activities.removeAt(0);
  }
}

String? _activityText(dynamic value, [int maxLength = 180]) {
  if (value is! String) return null;
  final text = normalizeChatText(value).trim();
  if (text.isEmpty) return null;
  return text.length <= maxLength ? text : text.substring(0, maxLength);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

List<int> _asIntList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_asInt).whereType<int>().toList(growable: false);
}

List<AgentAccessOption> _accessOptions(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => AgentAccessOption.fromJson(item.cast<String, dynamic>()),
      )
      .where((item) => item.id > 0)
      .toList(growable: false);
}

Uint8List? _asBytes(dynamic value) {
  if (value is Uint8List) return value;
  if (value is List<int>) return Uint8List.fromList(value);
  if (value is List) {
    return Uint8List.fromList(
        value.whereType<num>().map((item) => item.toInt()).toList());
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
