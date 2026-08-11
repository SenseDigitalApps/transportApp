import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class KanbanCardWidget extends StatelessWidget {
  final dynamic card;
  final Color color;
  final VoidCallback onTap;
  final String? sourceColumnId;
  final bool isDraggable;
  final List<int> timeIntervals;

  const KanbanCardWidget({
    super.key,
    required this.card,
    required this.color,
    required this.onTap,
    this.sourceColumnId,
    this.isDraggable = false,
    this.timeIntervals = const [5, 10, 15],
  });

  Color? _getTimeColor(String lastUpdated) {
    if (lastUpdated.isEmpty || lastUpdated == 'null') return null;
    DateTime? updated;
    try {
      updated = DateTime.parse(lastUpdated);
    } catch (_) {
      return null;
    }
    final hours = DateTime.now().difference(updated).inHours;
    final warning = timeIntervals.length > 0 ? timeIntervals[0] : 5;
    final danger = timeIntervals.length > 1 ? timeIntervals[1] : 10;
    final critical = timeIntervals.length > 2 ? timeIntervals[2] : 15;

    if (hours < warning) return null;
    if (hours < danger) return const Color(0xFFFFA726); // Orange
    if (hours < critical) return const Color(0xFFEF5350); // Red
    return const Color(0xFFB71C1C); // Deep red
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final title = getJsonField(card, r'''$.title''').toString();
    final consecutivo = getJsonField(card, r'''$.consecutivo''').toString();
    final lastUpdated = getJsonField(card, r'''$.last_updated''').toString();
    final fullName = getJsonField(card, r'''$.profile_info.full_name''').toString();
    final avatar = getJsonField(card, r'''$.profile_info.avatar''').toString();
    final hasAuthor = fullName.isNotEmpty && fullName != 'null';
    final timeColor = _getTimeColor(lastUpdated);

    final cardWidget = _buildCardContent(
      context: context,
      title: title,
      consecutivo: consecutivo,
      lastUpdated: lastUpdated,
      fullName: fullName,
      avatar: avatar,
      hasAuthor: hasAuthor,
      opacity: 1.0,
      timeColor: timeColor,
    );

    if (!isDraggable) {
      return cardWidget;
    }

    return LongPressDraggable<Map<String, dynamic>>(
      delay: const Duration(milliseconds: 400),
      data: {
        'card': card,
        'sourceColumnId': sourceColumnId,
      },
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: SizedBox(
            width: 260,
            child: _buildCardContent(
              context: context,
              title: title,
              consecutivo: consecutivo,
              lastUpdated: lastUpdated,
              fullName: fullName,
              avatar: avatar,
              hasAuthor: hasAuthor,
              opacity: 0.95,
              elevation: 12,
              timeColor: timeColor,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardWidget,
      ),
      child: cardWidget,
    );
  }

  Widget _buildCardContent({
    required BuildContext context,
    required String title,
    required String consecutivo,
    required String lastUpdated,
    required String fullName,
    required String avatar,
    required bool hasAuthor,
    required double opacity,
    double elevation = 8,
    Color? timeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
            child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: timeColor ?? const Color(0x0D000000),
                width: timeColor != null ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.08),
                  blurRadius: elevation,
                  offset: const Offset(0.0, 2.0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Outfit',
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                          ),
                          Text(
                            consecutivo,
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Outfit',
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (lastUpdated.isNotEmpty && lastUpdated != 'null')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11.0,
                            color: FlutterFlowTheme.of(context).secondaryText.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3.0),
                          Text(
                            lastUpdated,
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Outfit',
                              color: FlutterFlowTheme.of(context).secondaryText.withValues(alpha: 0.7),
                              fontSize: 10.0,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Outfit',
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                    letterSpacing: 0.0,
                  ),
                ),
                if (hasAuthor) ...[
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14.0),
                        child: Image.network(
                          'https://${FFAppState().organizacion}.itsquery.com$avatar',
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 24.0,
                              height: 24.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 14.0,
                                color: FlutterFlowTheme.of(context).primary,
                              ),
                            );
                          },
                          width: 24.0,
                          height: 24.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 11.5,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
