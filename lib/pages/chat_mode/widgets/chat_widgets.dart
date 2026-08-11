import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transport_app/app_state.dart';
import 'package:transport_app/flutter_flow/flutter_flow_theme.dart';
import 'package:transport_app/services/avatar_cache_service.dart';
import 'package:record/record.dart';

import '../models/chat_models.dart';
import '../services/external_link_service.dart';

const Color _queryChatInk = Color(0xFF0B3040);
const String _queryAiAgentAvatarUrl =
    'https://us.itsquery.com/mediafiles/custom_assets/query-ai-agent-avatar.png';

Color _chatBubbleStart(FlutterFlowTheme theme, bool isDark) => Color.lerp(
      theme.primary,
      const Color(0xFF299FCB),
      isDark ? 0.46 : 0.36,
    )!;

Color _chatBubbleEnd(FlutterFlowTheme theme, bool isDark) => Color.lerp(
      theme.secondary,
      const Color(0xFF45B3DC),
      isDark ? 0.36 : 0.26,
    )!;

typedef ChatSendCallback = FutureOr<void> Function(
  String text,
  List<ChatAttachment> attachments,
);

typedef ChatUploadCallback = Future<ChatAttachment> Function(
  Uint8List bytes,
  String filename,
  String mimeType,
  ChatAttachmentKind kind,
);

class ChatConversationSurface extends StatelessWidget {
  final Widget child;

  const ChatConversationSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = theme.primaryBackground;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color.alphaBlend(
                        theme.primary.withValues(alpha: 0.055),
                        base,
                      ),
                      base,
                      Color.alphaBlend(
                        theme.secondary.withValues(alpha: 0.035),
                        theme.secondaryBackground,
                      ),
                    ]
                  : [
                      Color.alphaBlend(
                        theme.primary.withValues(alpha: 0.16),
                        const Color(0xFFF8FCFF),
                      ),
                      const Color(0xFFFCFEFF),
                      Color.alphaBlend(
                        theme.secondary.withValues(alpha: 0.11),
                        const Color(0xFFF2F9FD),
                      ),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -110,
          child: _ChatGlow(
            size: 330,
            color: theme.primary,
            opacity: isDark ? 0.09 : 0.20,
          ),
        ),
        Positioned(
          bottom: -145,
          left: -115,
          child: _ChatGlow(
            size: 390,
            color: theme.secondary,
            opacity: isDark ? 0.055 : 0.14,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ChatWavePainter(
                color: theme.primary,
                isDark: isDark,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ChatGlow extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _ChatGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _ChatWavePainter extends CustomPainter {
  final Color color;
  final bool isDark;

  const _ChatWavePainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = color.withValues(alpha: isDark ? 0.055 : 0.115);

    for (var index = 0; index < 3; index++) {
      final offset = index * 24.0;
      final path = Path()
        ..moveTo(-35, size.height * 0.76 + offset)
        ..cubicTo(
          size.width * 0.22,
          size.height * 0.66 + offset,
          size.width * 0.57,
          size.height * 0.89 + offset,
          size.width + 45,
          size.height * 0.69 + offset,
        );
      canvas.drawPath(path, paint);
    }

    final upperPath = Path()
      ..moveTo(size.width * 0.52, -25)
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.12,
        size.width * 0.82,
        size.height * 0.04,
        size.width + 25,
        size.height * 0.24,
      );
    canvas.drawPath(
      upperPath,
      paint..color = color.withValues(alpha: isDark ? 0.035 : 0.075),
    );
  }

  @override
  bool shouldRepaint(covariant _ChatWavePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final int? currentUserId;

  /// Propuestas ya resueltas, para dejar de ofrecer botones que no aplican.
  final Set<String> resolvedActionIds;
  final void Function(String actionId, bool confirm)? onResolveAction;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onDelete,
    this.currentUserId,
    this.resolvedActionIds = const {},
    this.onResolveAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isMine = message.role == ChatRole.user &&
        (message.author == null || message.author?.id == currentUserId);
    final isSystem = message.role == ChatRole.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isSystem) {
      final proposal = _proposedAction(message.metadata);
      if (proposal != null) {
        return _ProposedActionCard(
          action: proposal,
          settled: proposal['status'] != 'pending' ||
              resolvedActionIds.contains(proposal['action_id']),
          onResolve: onResolveAction,
        );
      }
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: theme.bodySmall.override(
              fontFamily: 'Outfit',
              color: theme.secondaryText,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ),
      );
    }

    final bubbleStart = _chatBubbleStart(theme, isDark);
    final bubbleEnd = _chatBubbleEnd(theme, isDark);
    final assistantBubbleColor = isDark
        ? theme.secondaryBackground.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.88);
    final textColor = isMine ? _queryChatInk : theme.primaryText;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? null : assistantBubbleColor,
          gradient: isMine
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bubbleStart, bubbleEnd],
                )
              : null,
          border: Border.all(
            color: isMine
                ? Colors.white.withValues(alpha: isDark ? 0.13 : 0.40)
                : theme.primary.withValues(alpha: isDark ? 0.09 : 0.13),
          ),
          boxShadow: [
            BoxShadow(
              color: isMine
                  ? bubbleStart.withValues(alpha: isDark ? 0.12 : 0.18)
                  : Colors.black.withValues(alpha: isDark ? 0.13 : 0.045),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.author case final author?)
              if (!isMine || author.isSupport)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        author.name,
                        style: theme.bodySmall.override(
                          fontFamily: 'Outfit',
                          color: author.isSupport
                              ? theme.warning
                              : textColor.withValues(alpha: 0.76),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      if (author.isSupport) ...[
                        const SizedBox(width: 5),
                        Icon(
                          Icons.support_agent,
                          size: 13,
                          color: theme.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Soporte',
                          style: theme.bodySmall.override(
                            fontFamily: 'Outfit',
                            color: theme.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            if (message.attachments.isNotEmpty) ...[
              for (final attachment in message.attachments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AttachmentView(
                    attachment: attachment,
                    foregroundColor: textColor,
                  ),
                ),
            ],
            if (message.content.isNotEmpty)
              isMine
                  ? ExternalLinkText(
                      text: message.content,
                      style: theme.bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: textColor,
                        letterSpacing: 0,
                      ),
                    )
                  : AgentMarkdown(content: message.content),
            // Lo que Query hizo al leer este mensaje. Sin esto, decir "confirmo"
            // cerraba propuestas sin dejar rastro visible de que surtió efecto.
            if (writtenDecisionSummary(message.metadata) case final summary?) ...[
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 12,
                    color: textColor.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      summary,
                      style: theme.bodySmall.override(
                        fontFamily: 'Outfit',
                        color: textColor.withValues(alpha: 0.72),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimestamp(message.timestamp),
                  style: theme.bodySmall.override(
                    fontFamily: 'Outfit',
                    color: textColor.withValues(alpha: 0.68),
                    fontSize: 10,
                    letterSpacing: 0,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  if (onRetry != null &&
                      (message.status == ChatMessageStatus.failed ||
                          message.status == ChatMessageStatus.queued))
                    GestureDetector(
                      onTap: onRetry,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            message.status == ChatMessageStatus.failed
                                ? Icons.error_outline
                                : Icons.schedule_send_outlined,
                            size: 13,
                            color: textColor.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Reenviar',
                            style: theme.bodySmall.override(
                              fontFamily: 'Outfit',
                              color: textColor.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      switch (message.status) {
                        ChatMessageStatus.queued =>
                          Icons.schedule_send_outlined,
                        ChatMessageStatus.sending => Icons.access_time,
                        ChatMessageStatus.failed => Icons.error_outline,
                        ChatMessageStatus.sent => Icons.done_all,
                      },
                      size: 13,
                      color: textColor.withValues(alpha: 0.75),
                    ),
                  if (onDelete != null &&
                      message.status == ChatMessageStatus.failed) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onDelete,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 13,
                            color: textColor.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Eliminar',
                            style: theme.bodySmall.override(
                              fontFamily: 'Outfit',
                              color: textColor.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class AgentMarkdown extends StatelessWidget {
  final String content;

  const AgentMarkdown({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    // `selectable: true` construye un SelectableText por bloque de markdown
    // (parrafo, lista, bloque de codigo), y cada uno es un ambito de seleccion
    // independiente: solo se podia copiar un parrafo a la vez. Con
    // `selectable: false` los bloques son Text.rich y el SelectionArea los une
    // en una sola seleccion, asi se copia el mensaje completo.
    return SelectionArea(
      child: MarkdownBody(
        data: content,
        selectable: false,
        shrinkWrap: true,
        styleSheet: base.copyWith(
          p: theme.bodyMedium.override(
            fontFamily: 'Outfit',
            color: theme.primaryText,
            letterSpacing: 0,
          ),
          strong: theme.bodyMedium.override(
            fontFamily: 'Outfit',
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          code: TextStyle(
            color: theme.primaryText,
            backgroundColor: theme.primaryBackground.withValues(alpha: 0.8),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          blockquoteDecoration: BoxDecoration(
            color: theme.primaryBackground.withValues(alpha: 0.65),
            border: Border(left: BorderSide(color: theme.primary, width: 3)),
          ),
          a: TextStyle(
            color: theme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        onTapLink: (_, href, __) => ExternalLinkService.open(href),
      ),
    );
  }
}

class ExternalLinkText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const ExternalLinkText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<ExternalLinkText> createState() => _ExternalLinkTextState();
}

class _ExternalLinkTextState extends State<ExternalLinkText> {
  static final _urlPattern = RegExp(
    r'(?:(?:https?://|www\.)[^\s<]+)',
    caseSensitive: false,
  );

  late List<_ExternalLinkPart> _parts;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _parseText();
  }

  @override
  void didUpdateWidget(covariant ExternalLinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) _parseText();
  }

  void _parseText() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    _parts = [];

    var cursor = 0;
    for (final match in _urlPattern.allMatches(widget.text)) {
      final candidate = match.group(0) ?? '';
      final url = _trimTrailingPunctuation(candidate);
      if (url.isEmpty || ExternalLinkService.browserUri(url) == null) continue;
      if (match.start > cursor) {
        _parts
            .add(_ExternalLinkPart(widget.text.substring(cursor, match.start)));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => ExternalLinkService.open(url);
      _recognizers.add(recognizer);
      _parts.add(_ExternalLinkPart(url, recognizer: recognizer));
      cursor = match.start + url.length;
    }
    if (cursor < widget.text.length) {
      _parts.add(_ExternalLinkPart(widget.text.substring(cursor)));
    }
    if (_parts.isEmpty) _parts.add(_ExternalLinkPart(widget.text));
  }

  String _trimTrailingPunctuation(String value) {
    var result = value;
    while (RegExp(r'[.,!?:;]$').hasMatch(result)) {
      result = result.substring(0, result.length - 1);
    }
    while (result.endsWith(')') &&
        RegExp(r'\(').allMatches(result).length <
            RegExp(r'\)').allMatches(result).length) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: widget.style,
        children: _parts
            .map(
              (part) => TextSpan(
                text: part.text,
                recognizer: part.recognizer,
                mouseCursor:
                    part.recognizer == null ? null : SystemMouseCursors.click,
                style: part.recognizer == null
                    ? null
                    : widget.style.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: widget.style.color,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ExternalLinkPart {
  final String text;
  final TapGestureRecognizer? recognizer;

  const _ExternalLinkPart(this.text, {this.recognizer});
}

class AttachmentView extends StatelessWidget {
  final ChatAttachment attachment;
  final Color foregroundColor;

  const AttachmentView({
    super.key,
    required this.attachment,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (attachment.kind) {
      case ChatAttachmentKind.image:
        return GestureDetector(
          onTap: attachment.isUploaded
              ? () => _openAttachment(context, attachment)
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: attachment.isLocal
                ? Image.memory(
                    attachment.localBytes!,
                    width: 240,
                    height: 170,
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: attachment.url,
                    width: 240,
                    height: 170,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      width: 240,
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox(
                      width: 220,
                      height: 90,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
          ),
        );
      case ChatAttachmentKind.audio:
        return AudioAttachmentPlayer(
          url: attachment.url,
          bytes: attachment.localBytes,
          foregroundColor: foregroundColor,
        );
      case ChatAttachmentKind.file:
        return InkWell(
          onTap: attachment.isUploaded
              ? () => _openAttachment(context, attachment)
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minWidth: 190),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: foregroundColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: foregroundColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_fileAttachmentIcon(attachment), color: foregroundColor),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _fileAttachmentHint(attachment),
                        style: TextStyle(
                          color: foregroundColor.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.open_in_new, size: 17, color: foregroundColor),
              ],
            ),
          ),
        );
    }
  }

  /// Abre el adjunto y avisa si no se pudo, en vez de fallar en silencio.
  ///
  /// Un agente puede mandar una url que el telefono no sabe abrir (una ruta de
  /// su propio disco, por ejemplo). Antes eso era un toque que no hacia nada.
  Future<void> _openAttachment(
    BuildContext context,
    ChatAttachment attachment,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final opened = await ExternalLinkService.open(attachment.url);
    if (opened || messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('No se pudo abrir ${attachment.name}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Los artifacts que genera un agente (HTML, PDF, hojas de calculo) llegan como
/// ``file``: sin esta distincion todos se veian como un documento generico.
bool _isHtmlAttachment(ChatAttachment attachment) {
  final mimeType = attachment.mimeType.toLowerCase();
  if (mimeType.contains('html')) return true;
  final name = attachment.name.toLowerCase();
  return name.endsWith('.html') || name.endsWith('.htm');
}

IconData _fileAttachmentIcon(ChatAttachment attachment) {
  if (_isHtmlAttachment(attachment)) return Icons.code_outlined;
  final mimeType = attachment.mimeType.toLowerCase();
  if (mimeType.contains('pdf')) return Icons.picture_as_pdf_outlined;
  if (mimeType.contains('sheet') ||
      mimeType.contains('excel') ||
      mimeType.contains('csv')) {
    return Icons.table_chart_outlined;
  }
  if (mimeType.contains('word') || mimeType.contains('document')) {
    return Icons.article_outlined;
  }
  if (mimeType.contains('zip')) return Icons.folder_zip_outlined;
  return Icons.description_outlined;
}

String _fileAttachmentHint(ChatAttachment attachment) {
  final size = _formatBytes(attachment.size);
  if (!_isHtmlAttachment(attachment)) return size;
  return size.isEmpty ? 'Abrir HTML' : 'Abrir HTML · $size';
}

class AudioAttachmentPlayer extends StatefulWidget {
  final String url;
  final Uint8List? bytes;
  final Color foregroundColor;

  const AudioAttachmentPlayer({
    super.key,
    required this.url,
    this.bytes,
    required this.foregroundColor,
  });

  @override
  State<AudioAttachmentPlayer> createState() => _AudioAttachmentPlayerState();
}

class _AudioAttachmentPlayerState extends State<AudioAttachmentPlayer> {
  final _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((value) {
      if (mounted) setState(() => _state = value);
    });
    _positionSub = _player.onPositionChanged.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    _durationSub = _player.onDurationChanged.listen((value) {
      if (mounted) setState(() => _duration = value);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else {
      final bytes = widget.bytes;
      await _player.play(
        bytes != null && bytes.isNotEmpty
            ? BytesSource(bytes)
            : UrlSource(widget.url),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = _duration.inMilliseconds <= 0
        ? 1.0
        : _duration.inMilliseconds.toDouble();
    final value = _position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    return Container(
      width: 245,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.foregroundColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _toggle,
            icon: Icon(
              _state == PlayerState.playing ? Icons.pause : Icons.play_arrow,
              color: widget.foregroundColor,
            ),
          ),
          Expanded(
            child: Slider(
              min: 0,
              max: max,
              value: value,
              activeColor: widget.foregroundColor,
              inactiveColor: widget.foregroundColor.withValues(alpha: 0.25),
              onChanged: _duration == Duration.zero
                  ? null
                  : (next) =>
                      _player.seek(Duration(milliseconds: next.round())),
            ),
          ),
          Text(
            _formatDuration(_duration == Duration.zero ? _position : _duration),
            style: TextStyle(color: widget.foregroundColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  final String label;
  final String? detail;
  final Duration elapsed;

  const TypingIndicator({
    super.key,
    this.label = 'Pensando',
    this.detail,
    this.elapsed = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.alternate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.bodySmall.override(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: theme.bodySmall.override(
                        fontFamily: 'Outfit',
                        color: theme.secondaryText,
                        fontSize: 10,
                        letterSpacing: 0,
                      ),
                    ),
                ],
              ),
            ),
            if (elapsed > Duration.zero) ...[
              const SizedBox(width: 10),
              Text(
                _formatDuration(elapsed),
                style: TextStyle(color: theme.secondaryText, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AgentActivityIndicator extends StatefulWidget {
  final String label;
  final String? detail;
  final Duration elapsed;
  final List<AgentActivity> activities;
  final bool gatewayConnected;
  final bool? agentOnline;
  final int pendingCount;
  final String agentName;

  const AgentActivityIndicator({
    super.key,
    required this.label,
    required this.elapsed,
    required this.activities,
    required this.gatewayConnected,
    required this.agentOnline,
    required this.pendingCount,
    required this.agentName,
    this.detail,
  });

  @override
  State<AgentActivityIndicator> createState() => _AgentActivityIndicatorState();
}

class _AgentActivityIndicatorState extends State<AgentActivityIndicator> {
  bool _expanded = false;

  bool get _operational =>
      widget.gatewayConnected && widget.agentOnline == true;

  String get _connectionLabel {
    if (!widget.gatewayConnected) return 'Reconectando';
    if (widget.agentOnline == false) return 'Agente desconectado';
    if (widget.agentOnline == null) return 'Verificando agente';
    return 'Agente en línea';
  }

  Color _statusColor(FlutterFlowTheme theme) {
    if (_operational) return const Color(0xFF2FA66D);
    if (widget.agentOnline == false) return theme.error;
    return const Color(0xFFE0A32A);
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      final compactLabel = !widget.gatewayConnected
          ? 'Reconectando para continuar'
          : widget.agentOnline == false
              ? 'Esperando al agente'
              : widget.label;
      final compactStatus =
          '$compactLabel · ${_formatDuration(widget.elapsed)}';
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.activities.isEmpty
            ? null
            : () => setState(() => _expanded = true),
        child: TypingIndicator(label: compactStatus),
      );
    }

    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(theme);
    final delayed = widget.elapsed >= const Duration(minutes: 2);
    final cardColor = Color.alphaBlend(
      theme.primary.withValues(alpha: isDark ? 0.06 : 0.035),
      theme.secondaryBackground,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 410),
        margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (delayed ? const Color(0xFFE0A32A) : statusColor)
                .withValues(alpha: isDark ? 0.55 : 0.30),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ActivityPulse(
                        color: statusColor,
                        active: _operational,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodyMedium.override(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.detail ??
                                  'Toca para ver la actividad en vivo.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.override(
                                fontFamily: 'Outfit',
                                color: theme.secondaryText,
                                fontSize: 10.5,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDuration(widget.elapsed),
                            style: TextStyle(
                              color: theme.secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 19,
                            color: theme.secondaryText,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ActivityStatusPill(
                        label: _connectionLabel,
                        color: statusColor,
                      ),
                      if (widget.pendingCount > 1)
                        _ActivityStatusPill(
                          label: '${widget.pendingCount} solicitudes',
                          color: theme.primary,
                        ),
                      if (delayed)
                        const _ActivityStatusPill(
                          label: 'Está tardando más de lo habitual',
                          color: Color(0xFFE0A32A),
                        ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: !_expanded
                        ? const SizedBox.shrink()
                        : _buildExpanded(theme, statusColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(FlutterFlowTheme theme, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: theme.alternate),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Actividad de ${widget.agentName}',
                style: theme.bodySmall.override(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            _ActivityStatusPill(
              label: _operational ? 'EN VIVO' : 'EN ESPERA',
              color: statusColor,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.activities.isEmpty)
          _EmptyActivity(theme: theme)
        else
          ...widget.activities.reversed.map(
            (activity) => _ActivityRow(activity: activity, theme: theme),
          ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 15, color: theme.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Se muestran estados operativos, no razonamiento interno.',
                  style: theme.bodySmall.override(
                    fontFamily: 'Outfit',
                    color: theme.secondaryText,
                    fontSize: 9.5,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityPulse extends StatelessWidget {
  final Color color;
  final bool active;

  const _ActivityPulse({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      padding: const EdgeInsets.all(7),
      child: active
          ? CircularProgressIndicator(strokeWidth: 2.2, color: color)
          : Icon(Icons.cloud_off_outlined, size: 20, color: color),
    );
  }
}

class _ActivityStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ActivityStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final AgentActivity activity;
  final FlutterFlowTheme theme;

  const _ActivityRow({required this.activity, required this.theme});

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      if (activity.toolName != null) activity.toolName!,
      if (activity.stage != null) activity.stage!,
      if (activity.progress != null) '${activity.progress!.round()}%',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.28),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.label,
                  style: theme.bodySmall.override(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                if (activity.detail != null && activity.detail!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      activity.detail!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.override(
                        fontFamily: 'Outfit',
                        color: theme.secondaryText,
                        fontSize: 10,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: theme.primary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  final FlutterFlowTheme theme;

  const _EmptyActivity({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 16, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'El agente recibió la solicitud. Las actividades aparecerán aquí.',
              style: theme.bodySmall.override(
                fontFamily: 'Outfit',
                color: theme.secondaryText,
                fontSize: 10,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AttachmentOption { file, gallery, camera }

class MessageComposer extends StatefulWidget {
  final bool enabled;
  final bool allowAttachments;
  final ChatSendCallback onSend;
  final ChatUploadCallback? onUpload;
  final ValueChanged<String>? onError;
  final String hintText;

  const MessageComposer({
    super.key,
    required this.onSend,
    this.onUpload,
    this.onError,
    this.enabled = true,
    this.allowAttachments = false,
    this.hintText = 'Escribe un mensaje...',
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _recorder = AudioRecorder();
  final _imagePicker = ImagePicker();
  final List<ChatAttachment> _attachments = [];
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _recording = false;
  bool _uploading = false;

  // Waveform en vivo mientras se graba: buffer de niveles 0..1 que se desplaza
  // a medida que llega audio del micrófono (estilo Telegram).
  static const int _kWaveBars = 46;
  StreamSubscription<Amplitude>? _ampSub;
  List<double> _waveLevels = List<double>.filled(_kWaveBars, 0.0);

  bool get _hasContent =>
      _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Convierte la amplitud (dBFS, negativa; 0 = más fuerte) a un nivel 0..1.
  double _normalizeAmplitude(double db) {
    const minDb = -45.0;
    if (db.isNaN) return 0.0;
    final clamped = db.clamp(minDb, 0.0);
    return ((clamped - minDb) / (0.0 - minDb)).clamp(0.0, 1.0);
  }

  void _resetWaveform() {
    _waveLevels = List<double>.filled(_kWaveBars, 0.0);
  }

  Future<void> _send() async {
    if (!_hasContent || !widget.enabled || _uploading) return;
    final text = _controller.text.trim();
    final attachments = List<ChatAttachment>.from(_attachments);
    try {
      await widget.onSend(text, attachments);
      _controller.clear();
      if (mounted) setState(_attachments.clear);
      if (mounted) _focus.requestFocus();
    } catch (error) {
      widget.onError?.call(_friendlyError(error));
    }
  }

  Future<void> _pickFile() async {
    if (!widget.allowAttachments || widget.onUpload == null || _uploading) {
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );
      final selected = result?.files.single;
      if (selected == null) return;
      final bytes = selected.bytes ??
          (selected.path == null
              ? null
              : await XFile(selected.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        throw Exception('No fue posible leer el archivo.');
      }
      final mimeType = mime(selected.name) ?? 'application/octet-stream';
      final kind = mimeType.startsWith('image/')
          ? ChatAttachmentKind.image
          : ChatAttachmentKind.file;
      await _upload(bytes, selected.name, mimeType, kind);
    } catch (error) {
      widget.onError?.call(_friendlyError(error));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!widget.allowAttachments || widget.onUpload == null || _uploading) {
      return;
    }
    try {
      final selected = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2560,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (bytes.isEmpty) throw Exception('No fue posible leer la imagen.');
      final mimeType = selected.mimeType ?? mime(selected.name) ?? 'image/jpeg';
      await _upload(
        bytes,
        selected.name.isEmpty
            ? 'foto-${DateTime.now().millisecondsSinceEpoch}.jpg'
            : selected.name,
        mimeType,
        ChatAttachmentKind.image,
      );
    } catch (_) {
      widget.onError?.call('No fue posible adjuntar la imagen.');
    }
  }

  Future<void> _showAttachmentOptions() async {
    if (!widget.allowAttachments || widget.onUpload == null || _uploading) {
      return;
    }
    final option = await showModalBottomSheet<_AttachmentOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Subir archivo'),
              subtitle: const Text('PDF, documento, audio u otro archivo'),
              onTap: () => Navigator.pop(context, _AttachmentOption.file),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir imagen'),
              subtitle: const Text('Seleccionar desde la galería'),
              onTap: () => Navigator.pop(context, _AttachmentOption.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              subtitle: const Text('Abrir la cámara del dispositivo'),
              onTap: () => Navigator.pop(context, _AttachmentOption.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || option == null) return;
    switch (option) {
      case _AttachmentOption.file:
        await _pickFile();
        break;
      case _AttachmentOption.gallery:
        await _pickImage(ImageSource.gallery);
        break;
      case _AttachmentOption.camera:
        await _pickImage(ImageSource.camera);
        break;
    }
  }

  Future<void> _startRecording() async {
    if (!widget.allowAttachments || widget.onUpload == null || _uploading) {
      return;
    }
    try {
      if (!await _recorder.hasPermission()) {
        widget.onError?.call('Query necesita permiso para usar el micrófono.');
        return;
      }
      final supportsAac =
          await _recorder.isEncoderSupported(AudioEncoder.aacLc);
      final encoder = supportsAac ? AudioEncoder.aacLc : AudioEncoder.opus;
      final extension = supportsAac ? 'm4a' : 'opus';
      final filename =
          'voz-${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = kIsWeb
          ? filename
          : '${(await getTemporaryDirectory()).path}/$filename';
      await _recorder.start(
        RecordConfig(
          encoder: encoder,
          bitRate: 96000,
          sampleRate: 44100,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recordingSeconds = 0;
        _resetWaveform();
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
      // Empuja un nuevo nivel al buffer cada vez que llega audio, desplazando
      // el waveform para que se note que el micrófono está capturando.
      _ampSub?.cancel();
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 90))
          .listen((amplitude) {
        if (!mounted) return;
        final level = _normalizeAmplitude(amplitude.current);
        setState(() {
          _waveLevels = [..._waveLevels.skip(1), level];
        });
      });
    } catch (error) {
      widget.onError?.call('No fue posible iniciar la grabación.');
    }
  }

  Future<void> _finishRecording({required bool keep}) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    await _ampSub?.cancel();
    _ampSub = null;
    final path = await _recorder.stop();
    if (mounted) {
      setState(() {
        _recording = false;
        _resetWaveform();
      });
    }
    if (!keep || path == null || path.isEmpty) return;
    try {
      final file = XFile(path);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw Exception('La grabación quedó vacía.');
      final isOpus = path.toLowerCase().endsWith('.opus');
      final filename =
          'voz-${DateTime.now().millisecondsSinceEpoch}.${isOpus ? 'opus' : 'm4a'}';
      await _upload(
        bytes,
        filename,
        isOpus ? 'audio/ogg' : 'audio/mp4',
        ChatAttachmentKind.audio,
      );
    } catch (error) {
      widget.onError?.call('No fue posible adjuntar la grabación.');
    }
  }

  Future<void> _upload(
    Uint8List bytes,
    String filename,
    String mimeType,
    ChatAttachmentKind kind,
  ) async {
    setState(() => _uploading = true);
    try {
      final attachment = await widget.onUpload!(
        bytes,
        filename,
        mimeType,
        kind,
      );
      if (mounted) setState(() => _attachments.add(attachment));
    } catch (error) {
      widget.onError?.call(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('25 MB')) return 'El archivo supera el límite de 25 MB.';
    return 'No fue posible adjuntar el archivo.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: isDark ? 0.94 : 0.80),
        border: Border(
          top: BorderSide(color: theme.primary.withValues(alpha: 0.16)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.055),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _recording
            ? _buildRecording(theme)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_attachments.isNotEmpty) _buildPendingAttachments(theme),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.allowAttachments)
                        IconButton(
                          tooltip: 'Adjuntar',
                          onPressed: widget.enabled && !_uploading
                              ? _showAttachmentOptions
                              : null,
                          icon: const Icon(Icons.attach_file),
                        ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            enabled: widget.enabled && !_uploading,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: _uploading
                                  ? 'Adjuntando archivo...'
                                  : widget.hintText,
                              hintStyle: theme.bodyMedium.override(
                                fontFamily: 'Outfit',
                                color: theme.secondaryText,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: widget.enabled && !_uploading
                            ? _chatBubbleStart(theme, isDark)
                            : theme.alternate,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: !widget.enabled || _uploading
                              ? null
                              : _hasContent
                                  ? _send
                                  : widget.allowAttachments
                                      ? _startRecording
                                      : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _uploading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _hasContent
                                        ? Icons.arrow_upward_rounded
                                        : widget.allowAttachments
                                            ? Icons.mic_none_rounded
                                            : Icons.send_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRecording(FlutterFlowTheme theme) {
    return Row(
      children: [
        Icon(Icons.fiber_manual_record, color: theme.error, size: 15),
        const SizedBox(width: 8),
        Text(
          _formatDuration(Duration(seconds: _recordingSeconds)),
          style: theme.bodyMedium.override(
            fontFamily: 'Outfit',
            color: theme.secondaryText,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 26,
            child: CustomPaint(
              size: Size.infinite,
              painter: _WaveformPainter(
                levels: _waveLevels,
                color: theme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Cancelar grabación',
          onPressed: () => _finishRecording(keep: false),
          icon: const Icon(Icons.delete_outline),
        ),
        FilledButton.icon(
          onPressed: () => _finishRecording(keep: true),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Adjuntar'),
        ),
      ],
    );
  }

  Widget _buildPendingAttachments(FlutterFlowTheme theme) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 7),
        itemCount: _attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = _attachments[index];
          return Container(
            constraints: const BoxConstraints(maxWidth: 210),
            padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  attachment.kind == ChatAttachmentKind.audio
                      ? Icons.graphic_eq
                      : attachment.kind == ChatAttachmentKind.image
                          ? Icons.image_outlined
                          : Icons.description_outlined,
                  color: theme.primary,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.kind == ChatAttachmentKind.audio
                            ? 'Mensaje de voz'
                            : attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(_formatBytes(attachment.size),
                          style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _attachments.removeAt(index)),
                  icon: const Icon(Icons.close, size: 17),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dibuja el waveform en vivo de la grabación: una barra por muestra reciente,
/// centrada verticalmente, que se desplaza a medida que llega audio.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.width <= 0) return;
    final barCount = levels.length;
    final slot = size.width / barCount;
    // Barras finas (máx 2px) centradas en su celda: efecto sutil, no bloques.
    final double barWidth = (slot * 0.45).clamp(1.0, 2.0).toDouble();
    final centerY = size.height / 2;
    final radius = Radius.circular(barWidth / 2);
    const minHeight = 2.0;
    final span = size.height * 0.58 - minHeight;

    for (var i = 0; i < barCount; i++) {
      final level = levels[i].clamp(0.0, 1.0);
      final barHeight = minHeight + span * level;
      final left = slot * i + (slot - barWidth) / 2;
      // Suave: las más recientes (derecha) apenas un poco más marcadas.
      final opacity = 0.22 + 0.28 * (i / (barCount - 1));
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, centerY - barHeight / 2, barWidth, barHeight),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}

class AgentThreadGroupTile extends StatelessWidget {
  final BotConnection bot;
  final List<ChatThread> threads;
  final bool expanded;
  final bool selected;
  final int? selectedThreadId;
  final VoidCallback onToggle;
  final ValueChanged<ChatThread> onSelectThread;
  final VoidCallback? onCreateTopic;
  final VoidCallback? onLongPress;

  const AgentThreadGroupTile({
    super.key,
    required this.bot,
    required this.threads,
    required this.expanded,
    required this.selected,
    required this.selectedThreadId,
    required this.onToggle,
    required this.onSelectThread,
    this.onCreateTopic,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
          child: Material(
            color: selected
                ? theme.primary.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onToggle,
              onLongPress: onLongPress,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: (bot.avatar ?? '').isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: bot.avatar!,
                              cacheManager: AvatarCacheService.manager,
                              fit: BoxFit.cover,
                              memCacheWidth: 192,
                              memCacheHeight: 192,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.smart_toy_outlined,
                                color: theme.primary,
                              ),
                            )
                          : Icon(
                              Icons.smart_toy_outlined,
                              color: theme.primary,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bot.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleSmall.override(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            expanded
                                ? '${threads.length} canales disponibles'
                                : 'Mostrar canales',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall.override(
                              fontFamily: 'Outfit',
                              color: theme.secondaryText,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 180),
                      turns: expanded ? 0.25 : 0,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final thread in threads)
                        _AgentChannelTile(
                          thread: thread,
                          selected: selectedThreadId == thread.id,
                          onTap: () => onSelectThread(thread),
                        ),
                      if (onCreateTopic != null)
                        _AgentChannelActionTile(
                          label: 'Nuevo canal',
                          onTap: onCreateTopic!,
                        ),
                      const SizedBox(height: 4),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _AgentChannelTile extends StatelessWidget {
  final ChatThread thread;
  final bool selected;
  final VoidCallback onTap;

  const _AgentChannelTile({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final ownerName = thread.owner?.name.trim() ?? '';
    final showOwner =
        thread.isPrivateChannel && thread.canManage && ownerName.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 1, 10, 1),
      child: Material(
        color: selected
            ? theme.primary.withValues(alpha: 0.09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Icon(
                    switch (thread.threadType) {
                      AgentThreadType.general => Icons.campaign_outlined,
                      AgentThreadType.topic => Icons.tag_rounded,
                      AgentThreadType.privateChannel =>
                        Icons.lock_outline_rounded,
                      AgentThreadType.standalone => Icons.smart_toy_outlined,
                    },
                    size: 18,
                    color: selected ? theme.primary : theme.secondaryText,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: thread.name,
                        children: [
                          if (showOwner)
                            TextSpan(
                              text: ' · $ownerName',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? theme.primary
                                    : theme.secondaryText,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.override(
                        fontFamily: 'Outfit',
                        color: selected ? theme.primary : theme.secondaryText,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (!thread.notificationsEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Icon(
                        Icons.notifications_off_outlined,
                        size: 15,
                        color: theme.secondaryText,
                      ),
                    ),
                  if (thread.unreadCount > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 19),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        thread.unreadCount > 99
                            ? '99+'
                            : '${thread.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _AgentChannelActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AgentChannelActionTile({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 1, 10, 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Icon(Icons.add_rounded, size: 18, color: theme.primary),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: theme.bodyMedium.override(
                    fontFamily: 'Outfit',
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ThreadTile({
    super.key,
    required this.thread,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final avatar = thread.isMainThread
        ? _queryAiAgentAvatarUrl
        : (thread.bot?.avatar ?? '');
    return Material(
      color:
          selected ? theme.primary.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: thread.isMainThread
                      ? theme.primary.withValues(alpha: 0.15)
                      : theme.tertiary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatar,
                        cacheManager: AvatarCacheService.manager,
                        fit: BoxFit.cover,
                        memCacheWidth: 176,
                        memCacheHeight: 176,
                        placeholder: (_, __) => _threadIcon(theme),
                        errorWidget: (_, __, ___) => _threadIcon(theme),
                      )
                    : _threadIcon(theme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleSmall.override(
                              fontFamily: 'Outfit',
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        if (thread.bot?.isConfigured == true)
                          const Icon(Icons.circle,
                              size: 8, color: Colors.green),
                        if (!thread.notificationsEnabled) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 16,
                            color: theme.secondaryText,
                          ),
                        ],
                        if (thread.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              thread.unreadCount > 99
                                  ? '99+'
                                  : '${thread.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      thread.isMainThread
                          ? 'Canal interno de Query'
                          : _threadSubtitle(thread),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.override(
                        fontFamily: 'Outfit',
                        color: theme.secondaryText,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _threadIcon(FlutterFlowTheme theme) => Icon(
        thread.isMainThread
            ? Icons.auto_awesome
            : switch (thread.threadType) {
                AgentThreadType.general => Icons.tag_rounded,
                AgentThreadType.topic => Icons.forum_outlined,
                AgentThreadType.privateChannel => Icons.lock_outline_rounded,
                AgentThreadType.standalone => Icons.smart_toy_outlined,
              },
        color: thread.isMainThread ? theme.primary : theme.tertiary,
      );

  String _threadSubtitle(ChatThread thread) {
    final agentName = thread.bot?.displayName ?? 'Agente';
    if (thread.bot?.isConfigured != true) {
      return '$agentName · conexión pendiente';
    }
    return switch (thread.threadType) {
      AgentThreadType.general => '$agentName · canal general',
      AgentThreadType.topic => '$agentName · canal temático',
      AgentThreadType.privateChannel => '$agentName · canal privado',
      AgentThreadType.standalone => '$agentName · agente conectado',
    };
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Qué hizo Query con las propuestas al leer este mensaje.
///
/// Escribir "confirmo" cierra las propuestas a la vista sin pulsar ningún
/// botón. Sin este aviso, el mensaje se veía igual que cualquier otro y no
/// quedaba claro si la frase había surtido efecto o no.
String? writtenDecisionSummary(Map<String, dynamic>? metadata) {
  final resolved = metadata?['resolved_action'];
  if (resolved is! Map) return null;
  final data = resolved.cast<String, dynamic>();
  final confirming = data['decision'] != 'cancel';
  switch (data['status']) {
    case 'applied':
      return confirming
          ? 'Query aplicó la propuesta con este mensaje.'
          : 'Query descartó la propuesta con este mensaje.';
    case 'batch_applied':
      final count = data['applied'] ?? 0;
      return confirming
          ? 'Query aplicó $count propuestas con este mensaje.'
          : 'Query descartó $count propuestas con este mensaje.';
    case 'batch_partial':
      final applied = data['applied'] ?? 0;
      final requested = data['requested'] ?? 0;
      return confirming
          ? 'Se aplicaron $applied de $requested propuestas. El resto quedó '
              'pendiente: revísalas una por una.'
          : 'Se descartaron $applied de $requested propuestas. El resto quedó '
              'pendiente.';
    case 'not_allowed':
      return 'No tienes permiso para aplicar esa propuesta; sigue pendiente.';
    case 'ambiguous':
      return 'Había varias propuestas y no quedó claro cuál; siguen pendientes.';
    case 'failed':
      return 'Query no pudo cerrar la propuesta con este mensaje; sigue '
          'pendiente.';
    default:
      return null;
  }
}

/// Propuesta que trae un mensaje de sistema, si la trae.
///
/// La expone la pantalla del chat para contar las pendientes sin repetir el
/// criterio: si cada lado decidiera por su cuenta que es una propuesta viva,
/// la barra y las tarjetas acabarian diciendo cosas distintas.
Map<String, dynamic>? proposedActionFromMetadata(
  Map<String, dynamic>? metadata,
) =>
    _proposedAction(metadata);

/// Igual que arriba: el permiso se evalua con el mismo criterio en los dos
/// sitios, no con una copia.
bool canApplyProposedAction(
  Map<String, dynamic> action,
  List<String> permissions,
) =>
    _canApplyAction(action, permissions);

/// Cambio que un agente propone sobre un registro. Solo lo aplica una persona.
Map<String, dynamic>? _proposedAction(Map<String, dynamic>? metadata) {
  if (metadata == null) return null;
  if (metadata['event'] != 'agent.action.proposed') return null;
  final action = metadata['action'];
  if (action is! Map) return null;
  final normalized = action.cast<String, dynamic>();
  return normalized['action_id'] is String ? normalized : null;
}

/// El evento es uno solo para todo el canal, asi que no dice si "tu" puedes
/// aplicarlo: dice que permiso hace falta y aqui se compara con los del usuario.
/// El backend lo vuelve a exigir al confirmar; esto solo evita ofrecer un boton
/// que iba a responder 403.
bool _canApplyAction(Map<String, dynamic> action, List<String> permissions) {
  final permission = action['permission'];
  if (permission is! Map) return true;
  final required = permission['required'];
  if (required is! String || required.isEmpty) return true;
  if (permissions.contains(required)) return true;
  final override = permission['override'];
  return override is String && permissions.contains(override);
}

String _formatActionValue(dynamic value, {dynamic displayValue}) {
  final displayText = displayValue?.toString().trim() ?? '';
  if (displayText.isNotEmpty) return displayText;
  if (value == null) return '—';
  if (value is List) {
    if (value.isEmpty) return '—';
    return value.map((item) => _formatActionValue(item)).join(', ');
  }
  if (value is Map) {
    for (final key in const ['label', 'title', 'name']) {
      final candidate = value[key];
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        return candidate.toString();
      }
    }
    final referenceId = value['value'] ?? value['id'];
    if (referenceId != null && referenceId.toString().trim().isNotEmpty) {
      return referenceId.toString();
    }
  }
  final text = value.toString();
  return text.isEmpty ? '—' : text;
}

/// Bloques por registro de una propuesta en lote.
///
/// En un lote `proposed_changes` no trae cambios sueltos sino un bloque por
/// registro, cada uno con los suyos dentro. Pintarlo con el recorrido plano
/// mostraba una fila "null" por registro y ningun valor.
List<Map<String, dynamic>> batchItemsOfAction(Map<String, dynamic> action) {
  if (action['is_batch'] != true) return const [];
  return ((action['proposed_changes'] as List?) ?? const [])
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .where((item) => item['changes'] is List)
      .toList();
}

/// Pasos de un plan de configuracion: llamadas a la API, no cambios de campo.
List<Map<String, dynamic>> planStepsOfAction(Map<String, dynamic> action) {
  if (action['is_plan'] != true) return const [];
  return ((action['proposed_changes'] as List?) ?? const [])
      .whereType<Map>()
      .map((step) => step.cast<String, dynamic>())
      .where((step) => step['method'] is String)
      .toList();
}

/// Cambios planos de una propuesta de un solo registro.
List<Map<String, dynamic>> flatChangesOfAction(Map<String, dynamic> action) {
  if (action['is_batch'] == true || action['is_plan'] == true) return const [];
  return ((action['proposed_changes'] as List?) ?? const [])
      .whereType<Map>()
      .map((change) => change.cast<String, dynamic>())
      .toList();
}

String actionHeadline(Map<String, dynamic> action) {
  if (action['is_plan'] == true) {
    final steps = action['step_count'] ?? planStepsOfAction(action).length;
    return '$steps cambios de configuración';
  }
  if (action['is_batch'] == true) {
    final records = action['record_count'] ?? batchItemsOfAction(action).length;
    return '$records cambios';
  }
  return action['action_type'] == 'create_record'
      ? 'Crear registro'
      : 'Actualizar registro';
}

class _ProposedActionCard extends StatelessWidget {
  final Map<String, dynamic> action;
  final bool settled;
  final void Function(String actionId, bool confirm)? onResolve;

  const _ProposedActionCard({
    required this.action,
    required this.settled,
    this.onResolve,
  });

  Widget _changeRow(BuildContext context, Map<String, dynamic> change) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            '${change['label'] ?? change['slug'] ?? ''}',
            style: theme.bodySmall.override(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
          Text(
            _formatActionValue(
              change['from'],
              displayValue: change['display_from'],
            ),
            style: theme.bodySmall.override(
              fontFamily: 'Outfit',
              color: theme.secondaryText,
              fontSize: 11,
              letterSpacing: 0,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Icon(Icons.arrow_right_alt, size: 14, color: theme.secondaryText),
          Text(
            _formatActionValue(
              change['to'],
              displayValue: change['display_to'],
            ),
            style: theme.bodySmall.override(
              fontFamily: 'Outfit',
              color: theme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  /// Un registro del lote con sus cambios agrupados debajo.
  Widget _batchBlock(BuildContext context, Map<String, dynamic> item) {
    final theme = FlutterFlowTheme.of(context);
    final recordId = item['record_id'];
    final label = recordId == null
        ? (item['fallback_title']?.toString().trim().isNotEmpty == true
            ? item['fallback_title'].toString()
            : 'Registro nuevo')
        : (item['record_title']?.toString().trim().isNotEmpty == true
            ? item['record_title'].toString()
            : 'Registro #$recordId');
    final changes = ((item['changes'] as List?) ?? const [])
        .whereType<Map>()
        .map((change) => change.cast<String, dynamic>());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recordId == null ? Icons.add_circle_outline : Icons.edit,
                size: 13,
                color: theme.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.bodySmall.override(
                    fontFamily: 'Outfit',
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ...changes.map((change) => _changeRow(context, change)),
        ],
      ),
    );
  }

  /// Un paso del plan. Los borrados se marcan: no se deshacen.
  Widget _planRow(BuildContext context, Map<String, dynamic> step) {
    final theme = FlutterFlowTheme.of(context);
    final method = (step['method'] ?? '').toString().toUpperCase();
    final destructive = method == 'DELETE';
    final label = step['label']?.toString().trim();
    final path = (step['path'] ?? '').toString();
    final color = destructive ? theme.error : theme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: theme.bodySmall.override(
                fontFamily: 'Outfit',
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label?.isNotEmpty == true ? label! : path,
                  style: theme.bodySmall.override(
                    fontFamily: 'Outfit',
                    color: destructive ? theme.error : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0,
                  ),
                ),
                if (label?.isNotEmpty == true)
                  Text(
                    path,
                    style: theme.bodySmall.override(
                      fontFamily: 'Outfit',
                      color: theme.secondaryText,
                      fontSize: 9,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
          if (destructive)
            Icon(Icons.warning_amber_rounded, size: 14, color: theme.error),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final actionId = action['action_id'] as String;
    final intent = (action['intent'] ?? '').toString();
    final isPlan = action['is_plan'] == true;
    final isBatch = action['is_batch'] == true;
    final allowed = _canApplyAction(action, FFAppState().permissions);
    final title = '${actionHeadline(action)} · '
        '${action['module_label'] ?? action['module'] ?? ''}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Opacity(
        opacity: settled ? 0.65 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPlan
                      ? Icons.tune
                      : isBatch
                          ? Icons.layers
                          : Icons.edit_note,
                  size: 20,
                  color: theme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.bodyMedium.override(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            if (intent.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                intent,
                style: theme.bodySmall.override(
                  fontFamily: 'Outfit',
                  color: theme.secondaryText,
                  fontSize: 11,
                  letterSpacing: 0,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (isPlan)
              ...planStepsOfAction(action).map((step) => _planRow(context, step))
            else if (isBatch)
              ...batchItemsOfAction(action).map((item) => _batchBlock(context, item))
            else
              ...flatChangesOfAction(action).map((change) => _changeRow(context, change)),
            const SizedBox(height: 4),
            if (settled || !allowed)
              Text(
                settled
                    ? 'Esta propuesta ya se resolvió.'
                    : isPlan
                        // Un plan no cuelga de un módulo: lo exige el permiso
                        // de administrador, no el de editar algo concreto.
                        ? 'Solo un administrador puede aplicar esta '
                            'configuración.'
                        : 'Solo alguien con permiso para editar '
                            '${action['module_label'] ?? action['module'] ?? 'este módulo'} '
                            'puede aplicar este cambio.',
                style: theme.bodySmall.override(
                  fontFamily: 'Outfit',
                  color: theme.secondaryText,
                  fontSize: 11,
                  letterSpacing: 0,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onResolve == null
                        ? null
                        : () => onResolve!(actionId, false),
                    child: const Text('Descartar'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: onResolve == null
                        ? null
                        : () => onResolve!(actionId, true),
                    child: Text(
                      isPlan
                          ? 'Aprobar el plan'
                          : isBatch
                              ? 'Aplicar los ${action['record_count'] ?? batchItemsOfAction(action).length}'
                              : 'Aplicar cambio',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
