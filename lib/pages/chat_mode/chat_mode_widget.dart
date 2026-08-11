import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mime_type/mime_type.dart';
import 'package:transport_app/app_state.dart';
import 'package:transport_app/components/dark_light_switch_large/dark_light_switch_large_widget.dart';
import 'package:transport_app/flutter_flow/flutter_flow_theme.dart';
import 'package:transport_app/services/realtime_notification_service.dart';

import 'models/chat_models.dart';
import 'services/chat_api_service.dart';
import 'services/chat_outbox_service.dart';
import 'services/openclaw_socket.dart';
import 'widgets/chat_widgets.dart';

class ChatModeWidget extends StatefulWidget {
  const ChatModeWidget({super.key, this.initialThreadId});

  final int? initialThreadId;

  @override
  State<ChatModeWidget> createState() => _ChatModeWidgetState();
}

class _ChatModeWidgetState extends State<ChatModeWidget>
    with WidgetsBindingObserver {
  static const int _messagePageSize = 50;
  static const double _loadOlderThreshold = 160;
  static const double _showScrollButtonThreshold = 360;
  static const Duration _reconcileInterval = Duration(seconds: 12);
  static const Duration _botRefreshFast = Duration(seconds: 5);
  static const Duration _botRefreshIdle = Duration(seconds: 30);

  final _api = ChatApiService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _socket = OpenClawSocket();
  final _outbox = ChatOutboxService.instance;

  StreamSubscription<OpenClawEvent>? _socketSubscription;
  StreamSubscription<OpenClawConnectionState>? _socketStateSubscription;
  StreamSubscription<ChatOutboxEvent>? _outboxSubscription;
  StreamSubscription<bool>? _availabilitySubscription;
  StreamSubscription<RealtimeNotificationEvent>? _notificationSubscription;
  Timer? _botRefreshTimer;
  Timer? _activityTimer;

  ChatThread? _mainThread;
  List<BotConnection> _bots = [];
  List<ChatThread> _agentThreads = [];
  List<ChatThread> _threads = [];
  ChatThread? _selected;
  int? _expandedAgentId;
  final Map<int, List<ChatMessage>> _messages = {};
  final Map<int, int> _loadedMessageLimits = {};
  final Map<int, bool> _hasOlderMessages = {};
  final List<AgentPendingTurn> _pendingTurns = [];

  /// Propuestas del agente ya resueltas, para cerrar la tarjeta sin esperar a
  /// que vuelva el aviso del servidor.
  final Set<String> _resolvedActionIds = {};

  /// Hay un lote de propuestas resolviéndose ahora mismo.
  bool _resolvingBatch = false;

  BotBundle? _bundle;
  int? _bundleBotId;
  bool _loadingBundle = false;
  bool _loadingThreads = true;
  bool _loadingMessages = false;
  bool _loadingOlderMessages = false;
  bool _openingThread = false;
  bool _showScrollToBottom = false;
  bool _queryBotTyping = false;
  OpenClawConnectionState _socketState = OpenClawConnectionState.disconnected;
  bool? _agentOnline;
  bool _deliveryAvailable = true;
  final Map<String, int> _outboxPendingThreads = {};
  String? _error;
  DateTime _activityNow = DateTime.now();
  DateTime? _lastReconcileAt;
  bool _reconciling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleChatScroll);
    _socketSubscription = _socket.events.listen(_onSocketEvent);
    _socketStateSubscription = _socket.states.listen((state) {
      final reconnected = state == OpenClawConnectionState.connected &&
          _socketState != OpenClawConnectionState.connected;
      if (mounted) setState(() => _socketState = state);
      if (reconnected) {
        unawaited(_outbox.flush(force: true));
        unawaited(_reconcileThread(force: true));
      }
    });
    _outboxSubscription = _outbox.events.listen(_onOutboxEvent);
    _availabilitySubscription = _outbox.availability.listen((available) {
      if (mounted) setState(() => _deliveryAvailable = available);
    });
    _notificationSubscription = RealtimeNotificationService.instance.events
        .listen(_onRealtimeNotification);
    _activityTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickActivity());
    _scheduleBotRefresh();
    unawaited(_restoreOutbox());
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _botRefreshTimer?.cancel();
    _activityTimer?.cancel();
    _socketSubscription?.cancel();
    _socketStateSubscription?.cancel();
    _outboxSubscription?.cancel();
    _availabilitySubscription?.cancel();
    _notificationSubscription?.cancel();
    RealtimeNotificationService.instance.clearActiveThread(_selected?.id);
    _socket.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // En movil el socket del hilo muere en segundo plano (doze, cambio de red) y
  // los eventos del agente no se reenvian: al volver reconciliamos el historial
  // para no quedarnos con el indicador girando sobre una respuesta ya recibida.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    unawaited(_reconcileThread(force: true));
  }

  @override
  void didUpdateWidget(covariant ChatModeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialThreadId == oldWidget.initialThreadId ||
        widget.initialThreadId == _selected?.id) {
      return;
    }
    final requested = widget.initialThreadId;
    if (requested == null) return;
    for (final thread in _threads) {
      if (thread.id == requested) {
        unawaited(_selectThread(thread));
        break;
      }
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingThreads = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        _api.fetchMainThread(),
        _api.fetchBots(),
      ]);
      if (!mounted) return;
      _mainThread = values[0] as ChatThread;
      _bots = _resolveBots(values[1] as List<BotConnection>);
      _agentThreads = await _fetchAgentThreads(_bots);
      if (!mounted) return;
      _rebuildThreads();
      setState(() => _loadingThreads = false);
      ChatThread? initial;
      final requestedThreadId = widget.initialThreadId;
      if (requestedThreadId != null) {
        for (final thread in _threads) {
          if (thread.id == requestedThreadId) {
            initial = thread;
            break;
          }
        }
      }
      initial ??= _defaultAgentThread() ?? _mainThread!;
      await _selectThread(initial);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingThreads = false;
        _error = 'No se pudo cargar el centro de mensajes.';
      });
    }
  }

  List<BotConnection> _resolveBots(List<BotConnection> bots) {
    return bots
        .map((bot) => bot.copyWith(avatar: _api.resolveMediaUrl(bot.avatar)))
        .toList();
  }

  Future<List<ChatThread>> _fetchAgentThreads(
    List<BotConnection> bots,
  ) async {
    final groups = await Future.wait(
      bots.map((bot) async {
        try {
          return await _api.fetchAgentThreads(bot);
        } on ChatApiException catch (error) {
          // Si el permiso cambió entre la carga del agente y la de sus canales,
          // no reconstruimos un hilo legado que el servidor ya dejó de exponer.
          if (error.statusCode == 403 || error.statusCode == 404) {
            return const <ChatThread>[];
          }
          rethrow;
        }
      }),
    );
    return groups.expand((threads) => threads).toList();
  }

  ChatThread? _defaultAgentThread([int? botId]) {
    final candidates = _agentThreads
        .where((thread) => botId == null || thread.bot?.id == botId)
        .toList();
    if (candidates.isEmpty) return null;
    return candidates.firstWhere(
      (thread) => thread.isPrivateChannel,
      orElse: () => candidates.first,
    );
  }

  void _rebuildThreads() {
    final main = _mainThread;
    _threads = [
      if (main != null) main,
      ..._agentThreads,
    ];
  }

  /// Cadencia del sondeo de agentes, decidida en cada vuelta.
  ///
  /// Sondear rapido solo aporta mientras se empareja: ahi no hay socket que
  /// avise. Con presencia en vivo el canal ya informa de lo que cambia y el
  /// sondeo se queda vigilando el catalogo (canales nuevos, permisos), que no
  /// justifica una peticion por agente cada cinco segundos en un movil.
  Duration get _botRefreshInterval {
    final bot = _selected?.bot;
    if (bot == null) return _botRefreshIdle;
    if (!bot.isConfigured) return _botRefreshFast;
    return _agentOnline == null ? _botRefreshFast : _botRefreshIdle;
  }

  /// Reprograma el sondeo con la cadencia que toque ahora.
  ///
  /// El `finally` no es adorno: encadenar temporizadores de un disparo deja el
  /// sondeo muerto si una vuelta falla, cosa que un `Timer.periodic` no podia
  /// hacer.
  void _scheduleBotRefresh() {
    _botRefreshTimer?.cancel();
    _botRefreshTimer = Timer(_botRefreshInterval, () async {
      try {
        await _refreshBots(silent: true);
      } finally {
        if (mounted) _scheduleBotRefresh();
      }
    });
  }

  Future<void> _refreshBots({bool silent = false}) async {
    // Emparejamiento conocido antes de esta vuelta, por agente. Mirar el hilo
    // activo no sirve: entre las dos peticiones puede aparecer (arranque en
    // frio) o cambiar, y entonces el «no estaba configurado» que se leyo era
    // de otro agente —o de ninguno— y disparaba una preparacion de mas.
    final wasConfiguredById = {
      for (final bot in _bots) bot.id: bot.isConfigured,
    };
    try {
      final bots = _resolveBots(await _api.fetchBots());
      if (!mounted) return;
      final selectedBotId = _selected?.bot?.id;
      final selectedThreadId = _selected?.id;
      final agentThreads = await _fetchAgentThreads(bots);
      if (!mounted) return;
      ChatThread? permittedFallback;
      setState(() {
        _bots = bots;
        _agentThreads = agentThreads;
        _rebuildThreads();
        if (selectedThreadId != null) {
          final matching =
              _threads.where((thread) => thread.id == selectedThreadId);
          if (matching.isEmpty) {
            permittedFallback =
                _defaultAgentThread(selectedBotId) ?? _mainThread;
          } else {
            _selected = matching.first;
          }
        }
        if (_selected?.bot?.isConfigured == false) _agentOnline = false;
      });

      if (permittedFallback != null) {
        // Cambiar mediante el flujo normal cierra el socket anterior y actualiza
        // la supresión de push del hilo activo.
        await _selectThread(permittedFallback!);
        return;
      }

      final selected = _selected;
      final selectedBot = selected?.bot;
      if (selected == null || selectedBot == null) return;
      final threadId = selected.id;
      // Solo hay que preparar la conversacion cuando este agente acaba de
      // emparejarse y todavia no tiene canal. Con el canal vivo no se toca:
      // el sondeo vigila el catalogo, no la conexion.
      final becameConfigured = selectedBot.isConfigured &&
          wasConfiguredById[selectedBot.id] == false;
      if (becameConfigured &&
          (threadId == null || !_socket.isLiveFor(threadId))) {
        await _prepareAgentConversation(selected);
      } else if (!selectedBot.isConfigured && selectedBot.canManage) {
        await _loadBundle(selectedBot, silent: true);
      }
    } catch (_) {
      if (!silent) _showSnack('No se pudieron actualizar los agentes.');
    }
  }

  List<ChatMessage> get _currentMessages {
    final id = _selected?.id;
    return id == null ? const [] : (_messages[id] ?? const []);
  }

  Future<void> _restoreOutbox() async {
    try {
      final pending = await _outbox.initialize();
      if (!mounted) return;
      setState(() {
        for (final item in pending) {
          _outboxPendingThreads[item.clientMsgId] = item.threadId;
          _appendMessage(item.threadId, item.optimisticMessage);
        }
      });
    } catch (_) {
      // Si el almacenamiento local no abre, el compositor conservara el texto
      // porque enqueue propagara el error y no limpiara el borrador.
    }
  }

  void _onOutboxEvent(ChatOutboxEvent event) {
    if (!mounted) return;
    final pending = event.pending;
    setState(() {
      if (event.completed) {
        _outboxPendingThreads.remove(pending.clientMsgId);
        final server = event.serverMessage;
        if (server != null) {
          _replaceOrAppendMessage(pending.threadId, server);
        } else {
          _updateOptimistic(
            pending.threadId,
            pending.clientMsgId,
            status: ChatMessageStatus.sent,
          );
        }
      } else {
        _outboxPendingThreads[pending.clientMsgId] = pending.threadId;
        _replaceOrAppendMessage(pending.threadId, pending.optimisticMessage);
        if (pending.status == ChatOutboxStatus.failed) {
          _removePendingTurn(pending.clientMsgId);
        }
      }
    });
  }

  void _replaceOrAppendMessage(int threadId, ChatMessage message) {
    final list = List<ChatMessage>.from(_messages[threadId] ?? const []);
    final index =
        list.indexWhere((item) => _sameMessageIdentity(item, message));
    if (index >= 0) {
      list[index] = message;
    } else {
      list.add(message);
      list.sort((first, second) => first.timestamp.compareTo(second.timestamp));
    }
    _messages[threadId] = list;
  }

  Future<void> _selectThread(ChatThread thread) async {
    // Solo el cambio de hilo invalida la presencia: la del hilo anterior no
    // dice nada del nuevo. Reabrir el que ya estaba abierto no la invalida, y
    // borrarla ahi dejaba el indicador esperando un anuncio que no llegaria
    // porque el canal —al seguir vivo— no vuelve a conectarse.
    final changedThread = _selected?.id != thread.id;
    _pendingTurns.clear();
    setState(() {
      _selected = thread;
      _expandedAgentId = thread.bot?.id;
      if (changedThread) _agentOnline = null;
      _queryBotTyping = false;
      _bundle = null;
      _bundleBotId = null;
      _loadingMessages = false;
      _loadingOlderMessages = false;
      _openingThread = thread.id != null;
      _showScrollToBottom = false;
    });
    RealtimeNotificationService.instance.setActiveThread(thread.id);
    // La cadencia depende del agente que se este mirando: abrir uno sin
    // emparejar tiene que volver al sondeo rapido sin esperar al tic lento.
    _scheduleBotRefresh();

    if (thread.isMainThread) {
      _socket.disconnect();
      _socketState = OpenClawConnectionState.disconnected;
      await _loadMessages(thread);
      return;
    }

    final bot = thread.bot;
    if (bot == null) return;
    if (bot.isConfigured) {
      await _prepareAgentConversation(thread);
    } else {
      _socket.disconnect();
      setState(() => _openingThread = false);
      if (bot.canManage) await _loadBundle(bot);
    }
  }

  // Idempotente a proposito: puede llamarse sobre una conversacion ya abierta
  // (al confirmarse el emparejamiento, por ejemplo) sin tocar lo que ya se sabe
  // del agente. Si el canal sigue vivo, el socket repite la ultima presencia.
  Future<void> _prepareAgentConversation(ChatThread thread) async {
    if (thread.id == null) return;
    _socket.connect(thread.id!);
    if (!_messages.containsKey(thread.id)) {
      await _loadMessages(thread);
    } else {
      await _loadMessages(thread, silent: true);
    }
  }

  Future<void> _loadMessages(
    ChatThread thread, {
    bool silent = false,
    bool preserveScroll = false,
  }) async {
    if (thread.id == null) return;
    if (!silent) setState(() => _loadingMessages = true);
    final wasNearBottom = preserveScroll ? _isNearBottom() : false;
    try {
      final messages = await _api.fetchThreadMessages(
        thread.id!,
        limit: _messagePageSize,
      );
      if (!mounted || _selected?.id != thread.id) return;
      setState(() {
        final liveMessages = _messages[thread.id!] ?? const <ChatMessage>[];
        final merged = List<ChatMessage>.from(messages);
        for (final liveMessage in liveMessages) {
          final duplicate = merged.any(
            (item) => _sameMessageIdentity(item, liveMessage),
          );
          if (!duplicate) merged.add(liveMessage);
        }
        merged.sort(
            (first, second) => first.timestamp.compareTo(second.timestamp));
        _messages[thread.id!] = merged;
        if (!thread.isMainThread) {
          _syncPendingTurnsFromHistory(merged);
          _syncResolvedActionsFromHistory(merged);
        }
        _loadedMessageLimits[thread.id!] = _messagePageSize;
        _hasOlderMessages[thread.id!] = messages.length >= _messagePageSize;
        if (!silent) _loadingMessages = false;
      });
      // Una reconciliación en segundo plano no marca leído: el usuario puede no
      // estar mirando el hilo y perdería el contador de no leídos.
      if (!thread.isMainThread &&
          (!preserveScroll ||
              RealtimeNotificationService.instance
                  .isViewingThread(thread.id))) {
        unawaited(_markSelectedThreadRead(thread));
      }
      // Una reconciliación en segundo plano no debe robarle el scroll a quien
      // está leyendo mensajes anteriores; solo seguimos la conversación si ya
      // estaba al final.
      if (preserveScroll) {
        if (wasNearBottom) _scrollToBottomSoon();
      } else {
        unawaited(_jumpToBottomAfterOpen(thread.id!));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.putIfAbsent(thread.id!, () => []);
        if (!silent) _loadingMessages = false;
        _openingThread = false;
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    final threadId = _selected?.id;
    if (threadId == null ||
        _loadingMessages ||
        _loadingOlderMessages ||
        _openingThread ||
        _hasOlderMessages[threadId] == false) {
      return;
    }

    final currentLimit = _loadedMessageLimits[threadId] ?? _messagePageSize;
    final nextLimit = currentLimit + _messagePageSize;
    final previousPixels =
        _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
    final previousMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    setState(() => _loadingOlderMessages = true);
    try {
      final fetched = await _api.fetchThreadMessages(
        threadId,
        limit: nextLimit,
      );
      if (!mounted || _selected?.id != threadId) return;

      final current = _messages[threadId] ?? const <ChatMessage>[];
      final merged = List<ChatMessage>.from(fetched);
      for (final message in current) {
        if (!merged.any((item) => _sameMessageIdentity(item, message))) {
          merged.add(message);
        }
      }
      merged
          .sort((first, second) => first.timestamp.compareTo(second.timestamp));
      final addedCount = merged.length - current.length;

      setState(() {
        _messages[threadId] = merged;
        _syncResolvedActionsFromHistory(merged);
        _loadedMessageLimits[threadId] = nextLimit;
        _hasOlderMessages[threadId] =
            fetched.length >= nextLimit && addedCount > 0;
        if (addedCount == 0) _loadingOlderMessages = false;
      });

      if (addedCount > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              _selected?.id != threadId ||
              !_scrollController.hasClients) {
            if (mounted && _selected?.id == threadId) {
              setState(() => _loadingOlderMessages = false);
            }
            return;
          }
          final addedExtent =
              _scrollController.position.maxScrollExtent - previousMaxExtent;
          _scrollController.jumpTo(
            (previousPixels + addedExtent).clamp(
              _scrollController.position.minScrollExtent,
              _scrollController.position.maxScrollExtent,
            ),
          );
          setState(() => _loadingOlderMessages = false);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingOlderMessages = false);
        _showSnack('No se pudieron cargar mensajes anteriores.');
      }
    }
  }

  Future<void> _loadBundle(BotConnection bot, {bool silent = false}) async {
    if (_loadingBundle) return;
    setState(() => _loadingBundle = true);
    try {
      final bundle = await _api.fetchBotBundle(bot.id);
      if (!mounted || _selected?.bot?.id != bot.id) return;
      setState(() {
        _bundle = bundle;
        _bundleBotId = bot.id;
      });
    } catch (_) {
      if (!silent) _showSnack('No se pudo preparar el mensaje de conexión.');
    } finally {
      if (mounted) setState(() => _loadingBundle = false);
    }
  }

  void _appendMessage(int threadId, ChatMessage message) {
    final list = List<ChatMessage>.from(_messages[threadId] ?? const []);
    final duplicate = list.any((item) => _sameMessageIdentity(item, message));
    if (!duplicate) list.add(message);
    _messages[threadId] = list;
  }

  bool _sameMessageIdentity(ChatMessage first, ChatMessage second) {
    final firstPersisted = _persistedMessageId(first);
    if (firstPersisted != null &&
        firstPersisted == _persistedMessageId(second)) {
      return true;
    }
    if (first.eventId?.isNotEmpty == true && first.eventId == second.eventId) {
      return true;
    }
    return first.clientMsgId?.isNotEmpty == true &&
        first.clientMsgId == second.clientMsgId &&
        first.role == second.role;
  }

  /// La propuesta y su resolucion son dos mensajes distintos, y la tarjeta
  /// guarda el estado que tenia al proponerse. Sin releer el historial, una
  /// propuesta ya aplicada volvia a ofrecer sus botones al reabrir el canal y
  /// pulsarlos solo servia para chocar contra el servidor.
  void _syncResolvedActionsFromHistory(List<ChatMessage> messages) {
    for (final message in messages) {
      if (message.metadata['event'] != 'agent.action.resolved') continue;
      final action = message.metadata['action'];
      if (action is! Map) continue;
      final actionId = action['action_id'];
      if (actionId is String && actionId.isNotEmpty) {
        _resolvedActionIds.add(actionId);
      }
    }
  }

  /// Id de la fila guardada, venga como venga.
  ///
  /// El mismo mensaje llega con dos formas: el historial trae `id` y el socket
  /// trae `eventId` (`chat-message:<id>`) con el id dentro de los metadatos.
  /// Sin traducir una a la otra, un evento de sistema —la tarjeta que propone
  /// un cambio— se pintaba dos veces en cuanto se recargaba el historial.
  int? _persistedMessageId(ChatMessage message) {
    if (message.id != null) return message.id;
    final fromMetadata = message.metadata['message_id'];
    if (fromMetadata is int) return fromMetadata;
    if (fromMetadata is String) {
      final parsed = int.tryParse(fromMetadata);
      if (parsed != null) return parsed;
    }
    final eventId = message.eventId ?? '';
    if (eventId.startsWith('chat-message:')) {
      // El reenvio manual anade el intento: `chat-message:<id>:<intento>`.
      return int.tryParse(eventId.split(':')[1]);
    }
    return null;
  }

  String? _activitySnapshotLabel(Map<String, dynamic> snapshot) {
    final current = snapshot['current'];
    if (current is! Map) return null;
    final label = current['label']?.toString().trim();
    return label == null || label.isEmpty ? null : label;
  }

  List<AgentActivity> _activitiesFromSnapshot(
    Map<String, dynamic> snapshot,
  ) {
    final raw = snapshot['activities'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = item.cast<String, dynamic>();
      return AgentActivity.fromEvent(
        type: data['type']?.toString() ?? 'activity',
        content: '',
        data: data,
        receivedAt: DateTime.tryParse(data['received_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  void _syncPendingTurnsFromHistory(List<ChatMessage> messages) {
    final historicalUserIds = messages
        .where((message) =>
            message.role == ChatRole.user &&
            message.clientMsgId?.isNotEmpty == true)
        .map((message) => message.clientMsgId!)
        .toSet();
    final terminalIds = messages
        .where((message) =>
            message.role == ChatRole.assistant &&
            message.clientMsgId?.isNotEmpty == true)
        .map((message) => message.clientMsgId!)
        .toSet();
    final pendingMessages = messages.where((message) {
      final clientMsgId = message.clientMsgId;
      if (message.role != ChatRole.user || clientMsgId?.isNotEmpty != true) {
        return false;
      }
      if (terminalIds.contains(clientMsgId)) return false;
      // Un mensaje que el servidor todavía no confirmó (copia optimista o en el
      // outbox) no puede juzgarse por delivery_status: el turno sigue abierto
      // aunque el historial descargado aún no lo incluya.
      if (_outboxPendingThreads.containsKey(clientMsgId)) return true;
      if (message.status == ChatMessageStatus.queued ||
          message.status == ChatMessageStatus.sending) {
        return true;
      }
      return isPendingAgentDelivery(message.deliveryStatus);
    }).toList();
    final pendingIds =
        pendingMessages.map((message) => message.clientMsgId!).toSet();

    _pendingTurns.removeWhere((turn) =>
        historicalUserIds.contains(turn.clientMsgId) &&
        !pendingIds.contains(turn.clientMsgId));
    for (final message in pendingMessages) {
      final clientMsgId = message.clientMsgId!;
      final existingIndex = _pendingTurns.indexWhere(
        (turn) => turn.clientMsgId == clientMsgId,
      );
      if (existingIndex >= 0) {
        final existing = _pendingTurns[existingIndex];
        existing.label =
            _activitySnapshotLabel(message.agentActivity) ?? existing.label;
        final snapshotActivities =
            _activitiesFromSnapshot(message.agentActivity);
        if (snapshotActivities.isNotEmpty) {
          existing.activities
            ..clear()
            ..addAll(snapshotActivities);
        }
        existing.lastActivityAt =
            message.lastAgentActivityAt ?? existing.lastActivityAt;
        continue;
      }
      _pendingTurns.add(AgentPendingTurn(
        clientMsgId: clientMsgId,
        startedAt: message.timestamp,
        inputKind: classifyAgentPendingInput(
          message.content,
          message.attachments,
        ),
        label: _activitySnapshotLabel(message.agentActivity),
        lastActivityAt: message.lastAgentActivityAt,
        activities: _activitiesFromSnapshot(message.agentActivity),
      ));
    }
  }

  void _updateOptimistic(
    int threadId,
    String clientMsgId, {
    required ChatMessageStatus status,
  }) {
    final list = _messages[threadId];
    if (list == null) return;
    final index = list.indexWhere((item) => item.clientMsgId == clientMsgId);
    if (index >= 0) list[index] = list[index].copyWith(status: status);
  }

  Future<void> _sendMessage(
    String text,
    List<ChatAttachment> attachments,
  ) async {
    final thread = _selected;
    if (thread?.id == null ||
        !thread!.canWrite ||
        (text.isEmpty && attachments.isEmpty)) {
      return;
    }
    final threadId = thread.id!;

    if (!thread.isMainThread) {
      final pending = await _outbox.enqueue(
        threadId: threadId,
        content: text,
        attachments: attachments,
      );
      setState(() {
        _outboxPendingThreads[pending.clientMsgId] = pending.threadId;
        _replaceOrAppendMessage(threadId, pending.optimisticMessage);
        if (!_pendingTurns
            .any((turn) => turn.clientMsgId == pending.clientMsgId)) {
          _pendingTurns.add(AgentPendingTurn(
            clientMsgId: pending.clientMsgId,
            startedAt: pending.createdAt,
            inputKind: classifyAgentPendingInput(text, attachments),
          ));
        }
        _activityNow = DateTime.now();
      });
      _scrollToBottomSoon();
      return;
    }

    final clientMsgId =
        'query-${DateTime.now().microsecondsSinceEpoch.toString()}';
    setState(() {
      _appendMessage(
        threadId,
        ChatMessage(
          clientMsgId: clientMsgId,
          role: ChatRole.user,
          content: text,
          timestamp: DateTime.now(),
          status: ChatMessageStatus.sending,
        ),
      );
    });
    _scrollToBottomSoon();

    setState(() => _queryBotTyping = true);
    unawaited(_api.logThreadMessage(
      threadId,
      role: ChatRole.user,
      content: text,
      clientMsgId: clientMsgId,
    ));
    try {
      final reply = await _api.sendToQueryBot(text);
      if (!mounted) return;
      final shouldFollowReply = _isNearBottom();
      setState(() {
        _updateOptimistic(
          threadId,
          clientMsgId,
          status: ChatMessageStatus.sent,
        );
        _appendMessage(
          threadId,
          ChatMessage(
            role: ChatRole.assistant,
            content: reply.isEmpty ? '(sin respuesta)' : reply,
            timestamp: DateTime.now(),
          ),
        );
        _queryBotTyping = false;
      });
      unawaited(_api.logThreadMessage(
        threadId,
        role: ChatRole.assistant,
        content: reply,
      ));
      if (shouldFollowReply) _scrollToBottomSoon();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _updateOptimistic(
          threadId,
          clientMsgId,
          status: ChatMessageStatus.failed,
        );
        _queryBotTyping = false;
      });
      _showSnack('No se pudo enviar el mensaje.');
    }
  }

  Future<ChatAttachment> _uploadAttachment(
    Uint8List bytes,
    String filename,
    String mimeType,
    ChatAttachmentKind kind,
  ) async {
    if (bytes.length > 25 * 1024 * 1024) {
      throw const ChatOutboxException('El archivo supera el límite de 25 MB.');
    }
    return ChatAttachment.local(
      bytes: bytes,
      name: filename,
      mimeType: mimeType,
      kind: kind,
    );
  }

  void _onSocketEvent(OpenClawEvent event) {
    final threadId = _selected?.id;
    if (threadId == null || _selected?.isMainThread == true) return;

    if (event.type == 'session.status') {
      setState(() => _agentOnline = event.data['connected'] == true);
      return;
    }

    // El servidor avisa que el agente estaba desconectado al enviar: el mensaje
    // quedo en cola y se entregara al reconectarse. Reflejamos el estado para
    // que el indicador lo muestre y el usuario no espere en silencio.
    if (event.type == 'agent.offline') {
      setState(() {
        _agentOnline = false;
        if (event.clientMsgId.isNotEmpty) {
          _updateOptimistic(
            threadId,
            event.clientMsgId,
            status: ChatMessageStatus.queued,
          );
        }
      });
      return;
    }

    const activityTypes = {
      'activity',
      'progress',
      'typing',
      'tool_call',
      'tool.start',
      'tool.progress',
      'message.delta',
    };
    if (activityTypes.contains(event.type)) {
      if (event.clientMsgId.isEmpty) return;
      final activity = AgentActivity.fromEvent(
        type: event.type,
        content: event.content,
        data: event.data,
      );
      setState(() {
        _updateOptimistic(
          threadId,
          event.clientMsgId,
          status: ChatMessageStatus.sent,
        );
        final index = _pendingTurns.indexWhere(
          (turn) => turn.clientMsgId == event.clientMsgId,
        );
        if (index >= 0) {
          final turn = _pendingTurns[index];
          if (event.data['heartbeat'] == true) {
            turn.label = activity.label;
            turn.lastActivityAt = activity.receivedAt;
          } else {
            turn.recordActivity(activity);
          }
        }
      });
      return;
    }

    if (event.type == 'ack') {
      setState(() => _updateOptimistic(
            threadId,
            event.clientMsgId,
            status: ChatMessageStatus.sent,
          ));
      return;
    }

    if ((event.type == 'message' || event.type == 'message.user') &&
        event.role == 'user' &&
        event.clientMsgId.isNotEmpty) {
      final timestamp =
          DateTime.tryParse(event.data['timestamp']?.toString() ?? '');
      final messageId =
          int.tryParse(event.data['message_id']?.toString() ?? '');
      final deliveryStatus = event.data['delivery_status']?.toString();
      setState(() {
        _replaceOrAppendMessage(
          threadId,
          ChatMessage(
            id: messageId,
            eventId: event.eventId,
            clientMsgId: event.clientMsgId,
            role: ChatRole.user,
            content: event.content,
            metadata: event.data,
            timestamp: timestamp ?? DateTime.now(),
            status: chatMessageStatusFromDelivery(deliveryStatus),
            deliveryStatus: deliveryStatus,
            lastAgentActivityAt: DateTime.tryParse(
              event.data['last_agent_activity_at']?.toString() ?? '',
            ),
            agentActivity: (event.data['agent_activity'] as Map?)
                    ?.cast<String, dynamic>() ??
                const {},
            author: event.data['sender'] is Map
                ? ChatAuthor.fromJson(
                    (event.data['sender'] as Map).cast<String, dynamic>(),
                  )
                : null,
          ),
        );
      });
      _scrollToBottomSoon();
      return;
    }

    if ((event.type == 'message' || event.type == 'message.assistant') &&
        event.role == 'assistant') {
      if (event.clientMsgId.isEmpty) {
        _showSnack(
          'El agente respondió sin identificador. El turno seguirá protegido.',
        );
        return;
      }
      final timestamp =
          DateTime.tryParse(event.data['timestamp']?.toString() ?? '');
      final shouldFollowReply = _isNearBottom();
      setState(() {
        _removePendingTurn(event.clientMsgId);
        _updateOptimistic(
          threadId,
          event.clientMsgId,
          status: ChatMessageStatus.sent,
        );
        _appendMessage(
          threadId,
          ChatMessage(
            eventId: event.eventId,
            clientMsgId: event.clientMsgId,
            role: ChatRole.assistant,
            content: event.content,
            metadata: event.data,
            timestamp: timestamp ?? DateTime.now(),
            author: event.data['sender'] is Map
                ? ChatAuthor.fromJson(
                    (event.data['sender'] as Map).cast<String, dynamic>(),
                  )
                : null,
          ),
        );
      });
      unawaited(_markSelectedThreadRead(_selected!));
      if (shouldFollowReply) _scrollToBottomSoon();
      return;
    }

    if (event.type == 'message.system') {
      final timestamp =
          DateTime.tryParse(event.data['timestamp']?.toString() ?? '');
      final marker = ChatMessage(
        eventId: event.eventId,
        role: ChatRole.system,
        content: event.content,
        metadata: event.data,
        timestamp: timestamp ?? DateTime.now(),
        author: event.data['sender'] is Map
            ? ChatAuthor.fromJson(
                (event.data['sender'] as Map).cast<String, dynamic>(),
              )
            : null,
      );
      setState(() {
        // El indice null-aware `?[` no se puede usar dentro de la rama de un
        // ternario: el parser lee el `?` como otro ternario y `['action_id']`
        // como lista. Se resuelve sacando el acceso del ternario.
        final action = event.data['action'];
        final resolved =
            event.data['event'] == 'agent.action.resolved' && action is Map
                ? action['action_id']
                : null;
        if (resolved is String) _resolvedActionIds.add(resolved);
        if (event.data['event'] == 'history.reset') {
          // El servidor ya recorto el historial: el aviso pasa a ser el primer
          // mensaje del canal, tambien para quien lo tenia abierto.
          _messages[threadId] = [marker];
          // Los turnos en vuelo son los del hilo abierto: si es el que acaban
          // de reiniciar, dejan de tener un mensaje al que pertenecer.
          if (_selected?.id == threadId) _pendingTurns.clear();
        } else {
          _appendMessage(threadId, marker);
        }
      });
      unawaited(_markSelectedThreadRead(_selected!));
      _scrollToBottomSoon();
      return;
    }

    if (event.type == 'error') {
      if (event.clientMsgId.isNotEmpty) {
        setState(() {
          _removePendingTurn(event.clientMsgId);
          _updateOptimistic(
            threadId,
            event.clientMsgId,
            status: ChatMessageStatus.failed,
          );
          _appendMessage(
            threadId,
            ChatMessage(
              eventId: 'error:${event.clientMsgId}',
              role: ChatRole.system,
              content: event.content.isEmpty
                  ? 'El agente no pudo completar la solicitud.'
                  : event.content,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
      // Los errores de reconexion sin turno se reflejan en el banner del chat;
      // no se generan SnackBars repetitivos mientras cambia la conectividad.
    }
  }

  void _removePendingTurn(String clientMsgId) {
    if (clientMsgId.isEmpty) return;
    _pendingTurns.removeWhere((turn) => turn.clientMsgId == clientMsgId);
  }

  /// El aviso de respuesta viaja por el socket global de notificaciones, que
  /// tiene heartbeat y reconexion propios. Si el socket del hilo perdio el
  /// evento del agente, este aviso cierra el turno y refresca el historial: sin
  /// esto el usuario ve la notificacion (y luego el mensaje) con el indicador de
  /// "el agente esta trabajando" todavia girando.
  void _onRealtimeNotification(RealtimeNotificationEvent event) {
    if (!mounted || !event.isChatMessage) return;
    final thread = _selected;
    if (thread?.id == null || thread!.isMainThread) return;
    if (event.threadId != null && event.threadId != thread.id) return;
    final clientMsgId = event.instanceData['client_msg_id']?.toString() ?? '';
    if (clientMsgId.isNotEmpty &&
        _pendingTurns.any((turn) => turn.clientMsgId == clientMsgId)) {
      setState(() => _removePendingTurn(clientMsgId));
    }
    unawaited(_reconcileThread(force: true));
  }

  /// Relee el historial del hilo activo para cerrar turnos cuya respuesta ya
  /// esta guardada en el servidor. Los eventos del agente son fire-and-forget:
  /// si el socket estaba caido cuando llego la respuesta, nadie mas cierra el
  /// turno hasta que el historial vuelva a sincronizarse.
  Future<void> _reconcileThread({bool force = false}) async {
    final thread = _selected;
    if (!mounted || thread?.id == null || thread!.isMainThread) return;
    if (!force && _pendingTurns.isEmpty) return;
    if (_reconciling) return;
    final now = DateTime.now();
    if (!force &&
        _lastReconcileAt != null &&
        now.difference(_lastReconcileAt!) < _reconcileInterval) {
      return;
    }
    _reconciling = true;
    _lastReconcileAt = now;
    try {
      await _loadMessages(thread, silent: true, preserveScroll: true);
    } finally {
      _reconciling = false;
    }
  }

  Future<void> _retryMessage(ChatMessage message) async {
    final clientMsgId = message.clientMsgId;
    if (clientMsgId == null || clientMsgId.isEmpty) return;
    if (await _outbox.retry(clientMsgId)) return;
    final threadId = _selected?.id;
    if (threadId == null) return;
    final pending = await _outbox.enqueue(
      threadId: threadId,
      content: message.content,
      attachments: message.attachments,
      clientMsgId: clientMsgId,
      retryExisting: true,
    );
    if (!mounted) return;
    setState(() {
      _outboxPendingThreads[pending.clientMsgId] = pending.threadId;
      if (!_pendingTurns.any((turn) => turn.clientMsgId == clientMsgId)) {
        _pendingTurns.add(AgentPendingTurn(
          clientMsgId: clientMsgId,
          startedAt: DateTime.now(),
          inputKind: classifyAgentPendingInput(
            message.content,
            message.attachments,
          ),
        ));
      }
    });
  }

  // El mensaje fallido nunca se persistió en el servidor, así que borrarlo es
  // quitarlo del outbox durable y del estado local del hilo.
  Future<void> _deleteMessage(ChatMessage message) async {
    final threadId = _selected?.id;
    if (threadId == null) return;
    final clientMsgId = message.clientMsgId;
    // Un envio que el usuario vio fallar puede haberse persistido igualmente
    // (llego el POST y se perdio la respuesta). Si tiene id de servidor hay que
    // borrar la fila, o el mensaje vuelve al recargar el hilo.
    final messageId = message.id;
    if (messageId != null) {
      try {
        await _api.deleteThreadMessage(threadId, messageId);
      } catch (error) {
        if (!mounted) return;
        _showSnack(error is ChatApiException
            ? error.userMessage
            : 'No se pudo descartar el mensaje.');
        return;
      }
    }
    if (clientMsgId != null && clientMsgId.isNotEmpty) {
      await _outbox.discard(clientMsgId);
    }
    if (!mounted) return;
    setState(() {
      final list = List<ChatMessage>.from(_messages[threadId] ?? const []);
      list.removeWhere((item) => _sameMessageIdentity(item, message));
      _messages[threadId] = list;
      if (clientMsgId != null && clientMsgId.isNotEmpty) {
        _outboxPendingThreads.remove(clientMsgId);
        _removePendingTurn(clientMsgId);
      }
    });
  }

  void _tickActivity() {
    if (!mounted || _pendingTurns.isEmpty) return;
    // Red de seguridad mientras haya un turno abierto: si el evento terminal se
    // perdió en el camino, el historial cierra el indicador apenas la respuesta
    // ya esté persistida en el servidor.
    unawaited(_reconcileThread());
    final now = DateTime.now();
    setState(() => _activityNow = now);
  }

  void _handleChatScroll() {
    if (!mounted || !_scrollController.hasClients || _openingThread) return;
    final position = _scrollController.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    final shouldShow = distanceFromBottom > _showScrollButtonThreshold;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
    if (position.pixels <= _loadOlderThreshold) {
      unawaited(_loadOlderMessages());
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <=
        _showScrollButtonThreshold;
  }

  void _scrollToBottomSoon({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _jumpToBottomAfterOpen(int threadId) async {
    const settlingDelays = [
      Duration.zero,
      Duration(milliseconds: 50),
      Duration(milliseconds: 140),
      Duration(milliseconds: 280),
    ];
    for (final delay in settlingDelays) {
      if (delay != Duration.zero) await Future<void>.delayed(delay);
      if (!mounted || _selected?.id != threadId) return;
      await WidgetsBinding.instance.endOfFrame;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    }
    if (!mounted || _selected?.id != threadId) return;
    setState(() {
      _openingThread = false;
      _showScrollToBottom = false;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _markSelectedThreadRead(ChatThread thread) async {
    if (thread.isMainThread || thread.id == null) return;
    try {
      await _api.markThreadRead(thread);
      if (!mounted) return;
      setState(() {
        _agentThreads = _agentThreads
            .map((item) =>
                item.id == thread.id ? item.copyWith(unreadCount: 0) : item)
            .toList();
        _rebuildThreads();
        _selected = _threads.firstWhere(
          (item) => item.id == thread.id,
          orElse: () => thread.copyWith(unreadCount: 0),
        );
      });
    } catch (_) {
      // Leer el historial no debe fallar por un contador no actualizado.
    }
  }

  /// Para un admin en canal compartido la accion es seguir, no silenciar.
  String _notificationMenuLabel(ChatThread? thread) {
    final enabled = thread?.notificationsEnabled ?? true;
    if (thread?.notificationsOptIn == true) {
      return enabled ? 'Dejar de seguir el canal' : 'Seguir este canal';
    }
    return enabled ? 'Silenciar canal' : 'Activar notificaciones';
  }

  Future<void> _toggleMute() async {
    final thread = _selected;
    if (thread == null || !thread.canMute) return;
    try {
      // Mandar el estado actual invierte el efectivo en los dos sentidos: para
      // quien silencia y para el admin que sigue el canal.
      final isMuted =
          await _api.setThreadMuted(thread, thread.notificationsEnabled);
      if (!mounted) return;
      setState(() {
        _agentThreads = _agentThreads
            .map((item) => item.id == thread.id
                ? item.copyWith(
                    isMuted: isMuted,
                    notificationsEnabled: !isMuted,
                  )
                : item)
            .toList();
        _rebuildThreads();
        _selected = _threads.firstWhere((item) => item.id == thread.id);
      });
      if (thread.notificationsOptIn) {
        _showSnack(isMuted
            ? 'Dejaste de seguir el canal.'
            : 'Ahora sigues este canal.');
      } else {
        _showSnack(isMuted
            ? 'Notificaciones del canal silenciadas.'
            : 'Notificaciones del canal activadas.');
      }
    } catch (error) {
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudo cambiar la notificación.');
    }
  }

  Future<void> _toggleSupport() async {
    final thread = _selected;
    if (thread == null || !thread.canManage) return;
    try {
      await _api.setSupportMode(thread, !thread.supportActive);
      final refreshed = await _api.fetchAgentThreads(thread.bot!);
      if (!mounted) return;
      setState(() {
        _agentThreads = [
          ..._agentThreads.where((item) => item.bot?.id != thread.bot?.id),
          ...refreshed,
        ];
        _rebuildThreads();
        _selected = _threads.firstWhere((item) => item.id == thread.id);
      });
    } catch (error) {
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudo cambiar el modo soporte.');
    }
  }

  /// Aplica o descarta lo que el agente propuso. Lo resuelve la persona con su
  /// propia sesion: el agente no puede cerrar su propia propuesta.
  Future<void> _resolveAgentAction(String actionId, bool confirm) async {
    if (_resolvedActionIds.contains(actionId)) return;
    setState(() => _resolvedActionIds.add(actionId));
    try {
      await _api.resolveAgentAction(actionId, confirm: confirm);
    } catch (error) {
      if (!mounted) return;
      // Si no se aplico, la tarjeta debe volver a estar disponible.
      setState(() => _resolvedActionIds.remove(actionId));
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudo resolver la propuesta del agente.');
    }
  }

  /// Propuestas visibles que esta persona todavía puede aplicar.
  ///
  /// Se derivan de los mensajes que ya están en pantalla, no de una consulta
  /// aparte: así la barra y las tarjetas nunca se contradicen, y lo que aún no
  /// cargó del historial tampoco entra en un "confirmar todas" que nadie vio.
  List<Map<String, dynamic>> get _pendingActions {
    final seen = <String>{};
    final pending = <Map<String, dynamic>>[];
    for (final message in _currentMessages) {
      final action = proposedActionFromMetadata(message.metadata);
      if (action == null) continue;
      final actionId = action['action_id'];
      if (actionId is! String || actionId.isEmpty) continue;
      if (action['status'] != 'pending') continue;
      if (_resolvedActionIds.contains(actionId) || !seen.add(actionId)) continue;
      if (!canApplyProposedAction(action, FFAppState().permissions)) continue;
      pending.add(action);
    }
    return pending;
  }

  /// Cierra de una vez todas las propuestas a la vista.
  ///
  /// Revisar diez tarjetas y pulsar diez botones no hace la aprobación más
  /// segura, solo más tediosa. Las que fallen vuelven a quedar disponibles con
  /// su motivo, en vez de desaparecer como si se hubieran aplicado.
  Future<void> _resolveAllPendingActions(bool confirm) async {
    final ids = _pendingActions
        .map((action) => action['action_id'] as String)
        .toList();
    if (ids.isEmpty || _resolvingBatch) return;
    setState(() {
      _resolvingBatch = true;
      _resolvedActionIds.addAll(ids);
    });
    try {
      final outcome =
          await _api.resolveAgentActionsBatch(ids, confirm: confirm);
      if (!mounted) return;
      final failedIds = ids.where((id) => !outcome.resolved.contains(id));
      setState(() {
        _resolvingBatch = false;
        _resolvedActionIds.removeAll(failedIds);
      });
      if (outcome.failed > 0) {
        _showSnack(
          outcome.conflicted
              ? 'Se aplicaron ${outcome.resolved.length} de ${ids.length}. '
                  'El resto cambió desde que se propuso; revísalas una por una.'
              : 'Se aplicaron ${outcome.resolved.length} de ${ids.length}.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _resolvingBatch = false;
        _resolvedActionIds.removeAll(ids);
      });
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudieron resolver las propuestas.');
    }
  }

  Future<void> _confirmResetHistory() async {
    final thread = _selected;
    if (thread == null || !thread.canResetHistory) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Reiniciar el historial?'),
        content: const Text(
          'El canal quedará en blanco para todos sus miembros. No se borra '
          'nada: los mensajes anteriores se conservan y el agente mantiene su '
          'contexto, así que puede seguir respondiendo sobre lo que ya '
          'hablaron.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sí, reiniciar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      // El evento de reinicio vuelve por el socket y limpia la vista; aqui solo
      // se dispara la accion.
      await _api.resetThreadHistory(thread);
    } catch (error) {
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudo reiniciar el historial.');
    }
  }

  Future<void> _createTopic(BotConnection bot) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _CreateTopicDialog(botName: bot.displayName),
    );
    if (name == null || name.isEmpty) return;
    try {
      final thread = await _api.createAgentTopic(bot, name: name);
      if (!mounted) return;
      setState(() {
        _agentThreads = [..._agentThreads, thread];
        _rebuildThreads();
      });
      await _selectThread(thread);
    } catch (error) {
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudo crear el canal.');
    }
  }

  Future<void> _editTopicAccess() async {
    final thread = _selected;
    if (thread == null ||
        thread.threadType != AgentThreadType.topic ||
        !thread.canManage) {
      return;
    }
    try {
      final values = await Future.wait([
        _api.fetchAgentAccessOptions(),
        _api.fetchAgentAccess(thread.bot!.id),
      ]);
      if (!mounted) return;
      final catalog = values[0] as AgentAccessCatalog;
      final agentAccess = values[1] as AgentAccessSelection;
      final permittedUsers = catalog.users
          .where((item) => agentAccess.userIds.contains(item.id))
          .toList();
      final permittedGroups = catalog.groups
          .where((item) => agentAccess.groupIds.contains(item.id))
          .toList();
      final userIds = thread.allowedUserIds.toSet();
      final groupIds = thread.allowedGroupIds.toSet();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Acceso · ${thread.name}'),
            content: SizedBox(
              width: 440,
              height: 430,
              child: ListView(
                children: [
                  const Text(
                    'Solo aparecen personas y grupos que ya tienen acceso al agente.',
                  ),
                  const SizedBox(height: 12),
                  if (permittedUsers.isNotEmpty)
                    const Text(
                      'Personas',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  for (final user in permittedUsers)
                    CheckboxListTile(
                      value: userIds.contains(user.id),
                      title: Text(user.name),
                      subtitle: user.detail.isEmpty ? null : Text(user.detail),
                      onChanged: (checked) => setDialogState(() {
                        checked == true
                            ? userIds.add(user.id)
                            : userIds.remove(user.id);
                      }),
                    ),
                  if (permittedGroups.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Grupos',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  for (final group in permittedGroups)
                    CheckboxListTile(
                      value: groupIds.contains(group.id),
                      title: Text(group.name),
                      subtitle:
                          group.detail.isEmpty ? null : Text(group.detail),
                      onChanged: (checked) => setDialogState(() {
                        checked == true
                            ? groupIds.add(group.id)
                            : groupIds.remove(group.id);
                      }),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      );
      if (save != true) return;
      final updated = await _api.updateAgentTopic(
        thread,
        userIds: userIds.toList(),
        groupIds: groupIds.toList(),
      );
      if (!mounted) return;
      setState(() {
        _agentThreads = _agentThreads
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
        _rebuildThreads();
        _selected = updated;
      });
    } catch (error) {
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudieron actualizar los permisos del canal.');
    }
  }

  Future<void> _editAgentAccess() async {
    final bot = _selected?.bot;
    if (bot == null || !bot.canManage) return;
    try {
      final values = await Future.wait([
        _api.fetchAgentAccessOptions(),
        _api.fetchAgentAccess(bot.id),
      ]);
      if (!mounted) return;
      final catalog = values[0] as AgentAccessCatalog;
      final current = values[1] as AgentAccessSelection;
      final userIds = current.userIds.toSet();
      final groupIds = current.groupIds.toSet();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Compartir · ${bot.displayName}'),
            content: SizedBox(
              width: 440,
              height: 460,
              child: ListView(
                children: [
                  const Text(
                    'Cada persona autorizada recibe un canal privado. General y los canales temáticos conservan su historial compartido.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Personas',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  for (final user in catalog.users)
                    CheckboxListTile(
                      value: userIds.contains(user.id),
                      title: Text(user.name),
                      subtitle: user.detail.isEmpty ? null : Text(user.detail),
                      onChanged: (checked) => setDialogState(() {
                        checked == true
                            ? userIds.add(user.id)
                            : userIds.remove(user.id);
                      }),
                    ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Grupos',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (final group in catalog.groups)
                    CheckboxListTile(
                      value: groupIds.contains(group.id),
                      title: Text(group.name),
                      subtitle:
                          group.detail.isEmpty ? null : Text(group.detail),
                      onChanged: (checked) => setDialogState(() {
                        checked == true
                            ? groupIds.add(group.id)
                            : groupIds.remove(group.id);
                      }),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      );
      if (save != true) return;
      await _api.updateAgentAccess(
        bot.id,
        userIds: userIds.toList(),
        groupIds: groupIds.toList(),
      );
      await _refreshBots();
    } catch (error) {
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudo actualizar el acceso al agente.');
    }
  }

  Future<void> _archiveSelectedTopic() async {
    final thread = _selected;
    if (thread == null ||
        thread.threadType != AgentThreadType.topic ||
        !thread.canManage) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar canal'),
        content: Text(
          '¿Archivar “${thread.name}”? El historial se conserva, pero dejará de estar disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.archiveAgentTopic(thread);
      if (!mounted) return;
      final botId = thread.bot?.id;
      setState(() {
        _agentThreads =
            _agentThreads.where((item) => item.id != thread.id).toList();
        _rebuildThreads();
      });
      await _selectThread(_defaultAgentThread(botId) ?? _mainThread!);
    } catch (error) {
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudo archivar el canal.');
    }
  }

  void _exitChatMode() {
    FFAppState().chatMode = '';
    final state = FFAppState();
    final target = state.simpleApp == 'true' &&
            state.simpleAppRole.isNotEmpty &&
            state.role == state.simpleAppRole
        ? 'homeSimpleApp'
        : 'home';
    context.goNamed(target);
  }

  Future<void> _createBot() async {
    final input = await showDialog<_CreateBotInput>(
      context: context,
      builder: (_) => const _CreateBotDialog(),
    );
    if (input == null) return;
    try {
      final bot = await _api.createBot(
        displayName: input.name,
        avatarBytes: input.avatarBytes,
        avatarName: input.avatarName,
        avatarMimeType: input.avatarMimeType,
      );
      if (!mounted) return;
      final resolved = bot.copyWith(avatar: _api.resolveMediaUrl(bot.avatar));
      setState(() {
        _bots = [..._bots, resolved];
      });
      final agentThreads = await _api.fetchAgentThreads(resolved);
      if (!mounted) return;
      setState(() {
        _agentThreads = [..._agentThreads, ...agentThreads];
        _rebuildThreads();
      });
      await _selectThread(
        agentThreads.firstWhere(
          (thread) => thread.isPrivateChannel,
          orElse: () => agentThreads.first,
        ),
      );
    } catch (error) {
      _showSnack(error is ChatApiException
          ? error.userMessage
          : 'No se pudo crear el agente.');
    }
  }

  Future<void> _deleteSelectedBot() async {
    final bot = _selected?.bot;
    if (bot == null || !bot.canDelete) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar agente'),
        content: Text('¿Eliminar el agente “${bot.displayName}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteBot(bot.id);
      if (!mounted) return;
      setState(() {
        _bots = _bots.where((item) => item.id != bot.id).toList();
        _agentThreads =
            _agentThreads.where((item) => item.bot?.id != bot.id).toList();
        _rebuildThreads();
      });
      // Con agentes restantes hay que caer en uno de ellos: Query IA ya no
      // esta en la lista y dejaria abierto un chat que el panel no muestra.
      final next = _defaultAgentThread() ?? _mainThread;
      if (next != null) await _selectThread(next);
    } catch (_) {
      _showSnack('No se pudo eliminar el agente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: theme.primaryBackground,
          drawer: isWide ? null : Drawer(child: _buildThreadPanel(theme)),
          appBar: _buildAppBar(theme, isWide),
          body: isWide
              ? Row(
                  children: [
                    SizedBox(width: 320, child: _buildThreadPanel(theme)),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildConversation(theme)),
                  ],
                )
              : _buildConversation(theme),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(FlutterFlowTheme theme, bool isWide) {
    final isAgent = _selected?.bot != null;
    final agentStatusColor = _agentStatusColor(theme);
    return AppBar(
      backgroundColor: theme.primaryBackground,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              theme.primaryBackground,
              Color.alphaBlend(
                theme.primary.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.045
                      : 0.10,
                ),
                theme.primaryBackground,
              ),
            ],
          ),
        ),
      ),
      iconTheme: IconThemeData(color: theme.primary),
      elevation: 1,
      leading: isWide
          ? null
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selected?.displayName ?? 'Chats',
            style: theme.titleMedium.override(
              fontFamily: 'Outfit',
              letterSpacing: 0,
            ),
          ),
          if (isAgent)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: agentStatusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: agentStatusColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _agentStatusLabel(),
                  style: theme.bodySmall.override(
                    fontFamily: 'Outfit',
                    color: agentStatusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        if (isAgent &&
            (_selected?.bot?.canManage == true || _selected?.canMute == true))
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _deleteSelectedBot();
              if (value == 'setup' && _selected?.bot != null) {
                _loadBundle(_selected!.bot!);
              }
              if (value == 'topic' && _selected?.bot != null) {
                _createTopic(_selected!.bot!);
              }
              if (value == 'mute') _toggleMute();
              if (value == 'support') _toggleSupport();
              if (value == 'reset_history') _confirmResetHistory();
              if (value == 'access') _editTopicAccess();
              if (value == 'agent_access') _editAgentAccess();
              if (value == 'archive') _archiveSelectedTopic();
            },
            itemBuilder: (_) => [
              if (_selected?.canMute == true)
                PopupMenuItem(
                  value: 'mute',
                  child: Text(_notificationMenuLabel(_selected)),
                ),
              if (_selected?.canManage == true)
                PopupMenuItem(
                  value: 'support',
                  child: Text(_selected?.supportActive == true
                      ? 'Salir de soporte'
                      : 'Entrar como soporte'),
                ),
              if (_selected?.canResetHistory == true)
                const PopupMenuItem(
                  value: 'reset_history',
                  child: Text('Reiniciar historial'),
                ),
              if (_selected?.canManage == true &&
                  _selected?.threadType == AgentThreadType.topic)
                const PopupMenuItem(
                  value: 'access',
                  child: Text('Permisos del canal'),
                ),
              if (_selected?.canManage == true &&
                  _selected?.threadType == AgentThreadType.topic)
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archivar canal'),
                ),
              if (_selected?.canManage == true)
                const PopupMenuItem(
                  value: 'topic',
                  child: Text('Crear canal temático'),
                ),
              if (_selected?.bot?.canManage == true)
                const PopupMenuItem(
                  value: 'agent_access',
                  child: Text('Compartir agente'),
                ),
              if (_selected?.bot?.canManage == true)
                const PopupMenuItem(
                  value: 'setup',
                  child: Text('Ver conexión'),
                ),
              if (_selected?.bot?.canDelete == true)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar agente'),
                ),
            ],
          ),
        IconButton(
          tooltip: 'Volver al modo app',
          icon: const Icon(Icons.grid_view_rounded),
          onPressed: _exitChatMode,
        ),
      ],
    );
  }

  /// Presencia efectiva del agente, la que decide comportamiento.
  ///
  /// `_agentOnline` es la verdad en vivo, pero viaja en un evento que puede
  /// perderse. Hasta que llegue, el `status` que trajo la lista aproxima bien
  /// —el servidor lo mantiene en «configurado» mientras el agente sigue
  /// conectado— y evita apagar media pantalla por un anuncio ausente. El
  /// `null` se reserva para el indicador, que si debe admitir que aun no sabe.
  bool get _agentEffectivelyOnline =>
      _agentOnline ??
      (_selected?.bot?.status == BotConnectionStatus.configured);

  String _agentStatusLabel() {
    if (_selected?.bot?.isConfigured != true) return 'Agente sin conectar';
    if (_socketState == OpenClawConnectionState.connecting) {
      return 'Conectando canal…';
    }
    if (_socketState != OpenClawConnectionState.connected) {
      return 'Reconectando canal…';
    }
    if (_agentOnline == false) return 'El agente está desconectado';
    if (_agentOnline == null) return 'Verificando el agente…';
    return 'El agente está activo';
  }

  Color _agentStatusColor(FlutterFlowTheme theme) {
    if (_selected?.bot?.isConfigured != true || _agentOnline == false) {
      return theme.error;
    }
    if (_socketState == OpenClawConnectionState.connected &&
        _agentOnline == true) {
      return const Color(0xFF2FA66D);
    }
    return const Color(0xFFE0A32A);
  }

  Widget _buildThreadPanel(FlutterFlowTheme theme) {
    return Container(
      color: theme.primaryBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Chats',
                  style: theme.titleLarge.override(
                    fontFamily: 'Outfit',
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Crear agente',
                  icon: Icon(Icons.add_circle_outline, color: theme.primary),
                  onPressed: _createBot,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loadingThreads
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(theme)
                    : ListView(
                        children: [
                          for (final bot in _bots)
                            AgentThreadGroupTile(
                              key: ValueKey('agent-group-${bot.id}'),
                              bot: bot,
                              threads: _agentThreads
                                  .where((thread) => thread.bot?.id == bot.id)
                                  .toList(),
                              expanded: _expandedAgentId == bot.id,
                              selected: _selected?.bot?.id == bot.id,
                              selectedThreadId: _selected?.id,
                              onToggle: () => _toggleAgentChannels(bot),
                              onSelectThread: _openThreadFromPanel,
                              onCreateTopic: _agentThreads.any(
                                (thread) =>
                                    thread.bot?.id == bot.id &&
                                    thread.canManage,
                              )
                                  ? () => _createTopic(bot)
                                  : null,
                              onLongPress: bot.canDelete
                                  ? () {
                                      final thread =
                                          _defaultAgentThread(bot.id);
                                      if (thread == null) return;
                                      _selectThread(thread);
                                      _deleteSelectedBot();
                                    }
                                  : null,
                            ),
                          // Query IA es el chat de respaldo, para quien todavia
                          // no tiene nada propio. Con agentes creados sobra en
                          // la lista: solo compite con ellos por la atencion.
                          if (_bots.isEmpty)
                            if (_mainThread case final mainThread?)
                              ThreadTile(
                                thread: mainThread,
                                selected: _selected?.id == mainThread.id &&
                                    _selected?.bot == null,
                                onTap: () => _openThreadFromPanel(mainThread),
                              ),
                        ],
                      ),
          ),
          _buildChatMenuFooter(theme),
        ],
      ),
    );
  }

  void _toggleAgentChannels(BotConnection bot) {
    final willExpand = _expandedAgentId != bot.id;
    setState(() => _expandedAgentId = willExpand ? bot.id : null);
    if (willExpand && _selected?.bot?.id != bot.id) {
      final thread = _defaultAgentThread(bot.id);
      if (thread != null) unawaited(_selectThread(thread));
    }
  }

  void _openThreadFromPanel(ChatThread thread) {
    unawaited(_selectThread(thread));
    if (!isWideScreen(context) && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Widget _buildChatMenuFooter(FlutterFlowTheme theme) {
    const logoutColor = Color(0xFFE53935);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          border: Border(top: BorderSide(color: theme.alternate)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 7),
              child: Text(
                'Apariencia',
                style: theme.bodySmall.override(
                  fontFamily: 'Outfit',
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: const DarkLightSwitchLargeWidget(),
            ),
            const SizedBox(height: 8),
            Material(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _logout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: logoutColor, size: 21),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            color: logoutColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0x66E53935),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    _socket.disconnect();
    FFAppState().update(() {
      FFAppState().clienteEquipo = '';
      FFAppState().token = '';
      FFAppState().refreshToken = '';
      FFAppState().loginUser = '';
      FFAppState().loginPassword = '';
      FFAppState().id = '';
      FFAppState().clientId = '';
      FFAppState().permissions.clear();
      FFAppState().modulesPermissions.clear();
      FFAppState().recientes.clear();
      FFAppState().role = '';
      FFAppState().textoControlador.clear();
      FFAppState().fullName = '';
      FFAppState().username = '';
      FFAppState().email = '';
      FFAppState().avatar = '';
      FFAppState().shortname = '';
    });
    if (mounted) context.pushReplacementNamed('LoginEquipo');
  }

  bool isWideScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 800;

  /// Cierra el teclado al tocar la conversacion.
  ///
  /// Solo hace algo si hay teclado abierto: sin esa condicion, en un monitor
  /// —donde no estorba nada— tocar la conversacion para leer le quitaria el
  /// foco al compositor a mitad de una frase.
  void _dismissKeyboard() {
    if (MediaQuery.viewInsetsOf(context).bottom <= 0) return;
    FocusScope.of(context).unfocus();
  }

  Widget _buildError(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.error, size: 40),
            const SizedBox(height: 12),
            Text(_error ?? 'Error', textAlign: TextAlign.center),
            TextButton(onPressed: _bootstrap, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation(FlutterFlowTheme theme) {
    final thread = _selected;
    if (thread == null) {
      return const ChatConversationSurface(
        child: Center(child: Text('Selecciona un chat')),
      );
    }
    final bot = thread.bot;
    if (bot != null && !bot.isConfigured) {
      return ChatConversationSurface(child: _buildSetup(theme, bot));
    }

    final messages = _currentMessages;
    final activeTurn = _pendingTurns.isEmpty ? null : _pendingTurns.last;
    final elapsed = activeTurn == null
        ? Duration.zero
        : _activityNow.difference(activeTurn.startedAt);
    return ChatConversationSurface(
      child: Column(
        children: [
          Expanded(
            // Con el teclado abierto la conversacion se queda en un par de
            // mensajes. Tocarla la devuelve entera, que es el gesto que ya
            // hace todo el mundo para volver a leer.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissKeyboard,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _loadingMessages
                        ? const Center(child: CircularProgressIndicator())
                        : messages.isEmpty &&
                                !_queryBotTyping &&
                                activeTurn == null
                            ? _buildEmptyConversation(theme)
                            : ListView.builder(
                                controller: _scrollController,
                                // Desplazarse hacia atras ya es leer: el
                                // teclado se aparta sin cerrarlo aparte.
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                itemCount: messages.length +
                                    ((_queryBotTyping || activeTurn != null)
                                        ? 1
                                        : 0),
                                itemBuilder: (context, index) {
                                  if (index < messages.length) {
                                    return MessageBubble(
                                      message: messages[index],
                                      currentUserId:
                                          int.tryParse(FFAppState().id),
                                      resolvedActionIds: _resolvedActionIds,
                                      onResolveAction: _resolveAgentAction,
                                      // Reenvio manual disponible tanto para
                                      // mensajes fallidos como para los que
                                      // quedaron en cola (p. ej. agente offline),
                                      // por si el reintento automatico no basta.
                                      onRetry: !thread.isMainThread &&
                                              (messages[index].status ==
                                                      ChatMessageStatus.failed ||
                                                  messages[index].status ==
                                                      ChatMessageStatus.queued)
                                          ? () => unawaited(
                                                _retryMessage(messages[index]),
                                              )
                                          : null,
                                      // Solo los mensajes fallidos (terminales)
                                      // se pueden descartar; los "queued" siguen
                                      // reintentando solos.
                                      onDelete: !thread.isMainThread &&
                                              messages[index].status ==
                                                  ChatMessageStatus.failed
                                          ? () => unawaited(
                                                _deleteMessage(messages[index]),
                                              )
                                          : null,
                                    );
                                  }
                                  if (_queryBotTyping) {
                                    return const TypingIndicator();
                                  }
                                  return AgentActivityIndicator(
                                    label: _pendingLabel(activeTurn!, elapsed),
                                    detail: _pendingDetail(elapsed),
                                    elapsed: elapsed,
                                    activities:
                                        List.unmodifiable(activeTurn.activities),
                                    gatewayConnected: _socketState ==
                                        OpenClawConnectionState.connected,
                                    agentOnline: _agentEffectivelyOnline,
                                    pendingCount: _pendingTurns.length,
                                    agentName: thread.name,
                                  );
                                },
                              ),
                  ),
                  if (_loadingOlderMessages)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: theme.secondaryBackground,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ),
                  if (_showScrollToBottom && !_loadingMessages)
                    Positioned(
                      right: 16,
                      bottom: 14,
                      child: FloatingActionButton.small(
                        heroTag: 'chat-scroll-to-bottom',
                        tooltip: 'Volver al mensaje más reciente',
                        onPressed: _scrollToBottomSoon,
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!thread.isMainThread &&
              (!_deliveryAvailable ||
                  _socketState != OpenClawConnectionState.connected ||
                  !_agentEffectivelyOnline ||
                  _selectedOutboxCount > 0))
            _buildDeliveryBanner(theme),
          if (!thread.canWrite)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: theme.secondaryBackground,
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: theme.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Estás observando este canal. Entra como soporte para escribir.',
                    ),
                  ),
                ],
              ),
            ),
          _buildPendingActionsBar(theme),
          MessageComposer(
            enabled: !_loadingMessages && thread.canWrite,
            allowAttachments: !thread.isMainThread,
            hintText: thread.isMainThread
                ? 'Escribe a Query IA…'
                : 'Escribe a ${thread.name}…',
            onUpload: thread.isMainThread ? null : _uploadAttachment,
            onError: _showSnack,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  /// Barra para cerrar todas las propuestas de una vez.
  ///
  /// Solo desde dos: con una sola tarjeta su propio botón ya está a la vista y
  /// una barra encima sobra.
  Widget _buildPendingActionsBar(FlutterFlowTheme theme) {
    final pending = _pendingActions;
    if (pending.length < 2) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(color: theme.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, size: 17, color: theme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '${pending.length} propuestas esperando tu aprobación',
              style: theme.bodySmall.override(
                fontFamily: 'Outfit',
                color: theme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(
            onPressed: _resolvingBatch
                ? null
                : () => unawaited(_resolveAllPendingActions(false)),
            child: const Text('Descartar todas'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _resolvingBatch
                ? null
                : () => unawaited(_resolveAllPendingActions(true)),
            child: Text(
              _resolvingBatch ? 'Aplicando…' : 'Confirmar las ${pending.length}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBanner(FlutterFlowTheme theme) {
    final pendingCount = _selectedOutboxCount;
    final String text;
    final IconData icon;
    if (!_deliveryAvailable) {
      text = pendingCount == 0
          ? 'Sin conexión. Puedes seguir escribiendo.'
          : 'Sin conexión. $pendingCount mensaje${pendingCount == 1 ? '' : 's'} se enviará${pendingCount == 1 ? '' : 'n'} automáticamente.';
      icon = Icons.cloud_off_outlined;
    } else if (!_agentEffectivelyOnline) {
      text = pendingCount == 0
          ? 'El agente está desconectado.'
          : 'El agente está desconectado. Tus mensajes quedaron guardados.';
      icon = Icons.schedule_send_outlined;
    } else if (_socketState != OpenClawConnectionState.connected) {
      text = 'Reconectando el canal. Puedes seguir enviando mensajes.';
      icon = Icons.sync_outlined;
    } else {
      text = 'Enviando $pendingCount mensaje${pendingCount == 1 ? '' : 's'}…';
      icon = Icons.schedule_send_outlined;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.secondaryBackground,
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.secondaryText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.bodySmall.override(
                fontFamily: 'Outfit',
                color: theme.secondaryText,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _selectedOutboxCount {
    final threadId = _selected?.id;
    if (threadId == null) return 0;
    return _outboxPendingThreads.values
        .where((pendingThreadId) => pendingThreadId == threadId)
        .length;
  }

  String _pendingLabel(AgentPendingTurn turn, Duration elapsed) {
    if (_socketState != OpenClawConnectionState.connected) {
      return 'Reconectando para continuar';
    }
    if (!_agentEffectivelyOnline) return 'El agente perdió la conexión';
    if (turn.label != null) return turn.label!;
    if (elapsed.inSeconds < 6) return 'Tu agente recibió el mensaje';
    if (elapsed.inSeconds < 25) return 'Tu agente está trabajando';
    if (elapsed.inSeconds < 75) return 'Consultando archivos o herramientas';
    if (elapsed.inSeconds < 180) return 'La tarea está tomando más tiempo';
    return 'Aún estamos esperando la respuesta';
  }

  String _pendingDetail(Duration elapsed) {
    if (_socketState != OpenClawConnectionState.connected ||
        !_agentEffectivelyOnline) {
      return 'Tu solicitud sigue registrada; no necesitas volver a enviarla.';
    }
    if (elapsed.inSeconds >= 180) {
      return 'No necesitas reenviar el mensaje; puedes continuar esperando.';
    }
    if (_pendingTurns.length > 1) {
      return '${_pendingTurns.length} solicitudes están en proceso.';
    }
    return 'La respuesta aparecerá aquí cuando termine.';
  }

  Widget _buildEmptyConversation(FlutterFlowTheme theme) {
    final isMain = _selected?.isMainThread ?? false;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMain ? Icons.auto_awesome : Icons.chat_bubble_outline,
              size: 50,
              color: theme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              isMain ? 'Habla con Query IA' : 'Tu agente está listo',
              style: theme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              isMain
                  ? 'Escribe un mensaje para comenzar.'
                  : 'Envía texto, imágenes, archivos o una nota de voz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetup(FlutterFlowTheme theme, BotConnection bot) {
    if (!bot.canManage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 52, color: theme.primary),
              const SizedBox(height: 14),
              Text('Conexión pendiente', style: theme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'El propietario debe terminar la conexión antes de que puedas conversar.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final bundle = _bundleBotId == bot.id ? _bundle : null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primary.withValues(alpha: 0.14),
                      child:
                          Icon(Icons.smart_toy_outlined, color: theme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONEXIÓN GUIADA',
                              style: TextStyle(
                                  color: theme.primary, fontSize: 11)),
                          Text(bot.displayName, style: theme.titleLarge),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Mensaje listo para copiar', style: theme.titleMedium),
                const SizedBox(height: 6),
                const Text(
                  'Copia este mensaje completo y envíalo al agente externo para terminar la conexión.',
                ),
                const SizedBox(height: 14),
                if (_loadingBundle && bundle == null)
                  const Center(child: CircularProgressIndicator())
                else if (bundle == null)
                  OutlinedButton.icon(
                    onPressed: () => _loadBundle(bot),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Preparar mensaje'),
                  )
                else ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 330),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        bundle.setupMessage,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: bundle.setupMessage));
                      _showSnack('Mensaje de inicialización copiado.');
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copiar mensaje'),
                  ),
                  if (bundle.warning.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: theme.warning),
                        const SizedBox(width: 8),
                        Expanded(child: Text(bundle.warning)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateBotInput {
  final String name;
  final Uint8List? avatarBytes;
  final String? avatarName;
  final String? avatarMimeType;

  const _CreateBotInput({
    required this.name,
    this.avatarBytes,
    this.avatarName,
    this.avatarMimeType,
  });
}

class _CreateTopicDialog extends StatefulWidget {
  final String botName;

  const _CreateTopicDialog({required this.botName});

  @override
  State<_CreateTopicDialog> createState() => _CreateTopicDialogState();
}

class _CreateTopicDialogState extends State<_CreateTopicDialog> {
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para el canal.');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33091836),
                blurRadius: 44,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Icon(Icons.tag_rounded, color: theme.primary),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUEVO ESPACIO',
                              style: theme.bodySmall.override(
                                fontFamily: 'Outfit',
                                color: theme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Crear canal temático',
                              style: theme.titleMedium.override(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text.rich(
                    TextSpan(
                      text: 'Crea un espacio compartido para conversar con ',
                      children: [
                        TextSpan(
                          text: widget.botName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' sobre un tema específico.'),
                      ],
                    ),
                    style: theme.bodyMedium.override(
                      fontFamily: 'Outfit',
                      color: theme.secondaryText,
                      letterSpacing: 0,
                      lineHeight: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nombre del canal',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    maxLength: 200,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Ej. Lanzamiento del proyecto',
                      prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                      errorText: _error,
                      counterText: '',
                      filled: true,
                      fillColor: theme.secondaryBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: theme.alternate),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: theme.alternate),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            BorderSide(color: theme.primary, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los miembros autorizados podrán encontrarlo en la lista de canales.',
                    style: theme.bodySmall.override(
                      fontFamily: 'Outfit',
                      color: theme.secondaryText,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Divider(height: 1, color: theme.alternate),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: const Text('Crear canal'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateBotDialog extends StatefulWidget {
  const _CreateBotDialog();

  @override
  State<_CreateBotDialog> createState() => _CreateBotDialogState();
}

class _CreateBotDialogState extends State<_CreateBotDialog> {
  final _nameController = TextEditingController();
  Uint8List? _avatarBytes;
  String? _avatarName;
  String? _avatarMimeType;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() {
      _avatarBytes = file!.bytes;
      _avatarName = file.name;
      _avatarMimeType = mime(file.name) ?? 'image/jpeg';
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre del agente es obligatorio.');
      return;
    }
    Navigator.pop(
      context,
      _CreateBotInput(
        name: name,
        avatarBytes: _avatarBytes,
        avatarName: _avatarName,
        avatarMimeType: _avatarMimeType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear agente'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 42,
                backgroundImage:
                    _avatarBytes == null ? null : MemoryImage(_avatarBytes!),
                child: _avatarBytes == null
                    ? const Icon(Icons.add_a_photo_outlined, size: 30)
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Nombre del agente',
                hintText: 'Ej. Agente de ventas',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Query creará automáticamente la credencial, el workspace y el canal.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Crear agente')),
      ],
    );
  }
}
