import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'kanban_card.dart';

class KanbanColumnData {
  final String id;
  final String name;
  final Color color;
  List<dynamic> cards;
  int currentPage;
  bool hasMore;
  bool isLoadingMore;
  int total;

  KanbanColumnData({
    required this.id,
    required this.name,
    required this.color,
    this.cards = const [],
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.total = 0,
  });
}

class KanbanColumnWidget extends StatefulWidget {
  final KanbanColumnData column;
  final Function(dynamic card) onCardTap;
  final VoidCallback? onLoadMore;
  final Function(dynamic card, String sourceColumnId, String targetColumnId)? onCardDropped;
  final List<int> timeIntervals;

  const KanbanColumnWidget({
    super.key,
    required this.column,
    required this.onCardTap,
    this.onLoadMore,
    this.onCardDropped,
    this.timeIntervals = const [5, 10, 15],
  });

  @override
  State<KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends State<KanbanColumnWidget> {
  bool _isDraggingOver = false;

  Widget _buildLoadMoreButton(BuildContext context) {
    if (widget.column.isLoadingMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.column.color,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton(
        onPressed: widget.onLoadMore,
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.column.color,
          side: BorderSide(color: widget.column.color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Cargar más',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget columnContent = Container(
      width: 280.0,
      margin: const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: _isDraggingOver
            ? Border.all(color: widget.column.color.withValues(alpha: 0.6), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.06),
            blurRadius: 10.0,
            offset: const Offset(0.0, 4.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: widget.column.color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10.0,
                  height: 10.0,
                  decoration: BoxDecoration(
                    color: widget.column.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    widget.column.name,
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Outfit',
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.0,
                      letterSpacing: 0.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: widget.column.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    widget.column.total > 0 ? '${widget.column.cards.length} / ${widget.column.total}' : '${widget.column.cards.length}',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Outfit',
                      color: widget.column.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: widget.column.cards.isEmpty && !widget.column.isLoadingMore
                ? Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Sin registros',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Outfit',
                          color: FlutterFlowTheme.of(context).secondaryText.withValues(alpha: 0.6),
                          fontSize: 12.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: widget.column.cards.length + ((widget.column.hasMore || widget.column.isLoadingMore) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == widget.column.cards.length) {
                        return _buildLoadMoreButton(context);
                      }
                      final card = widget.column.cards[index];
                      return KanbanCardWidget(
                        card: card,
                        color: widget.column.color,
                        onTap: () => widget.onCardTap(card),
                        sourceColumnId: widget.column.id,
                        isDraggable: widget.onCardDropped != null,
                        timeIntervals: widget.timeIntervals,
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    if (widget.onCardDropped == null) {
      return columnContent;
    }

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final sourceColumnId = details.data['sourceColumnId']?.toString();
        return sourceColumnId != widget.column.id;
      },
      onAcceptWithDetails: (details) {
        final card = details.data['card'];
        final sourceColumnId = details.data['sourceColumnId']?.toString() ?? '';
        widget.onCardDropped!(card, sourceColumnId, widget.column.id);
        setState(() => _isDraggingOver = false);
      },
      onLeave: (_) {
        setState(() => _isDraggingOver = false);
      },
      onMove: (_) {
        if (!_isDraggingOver) {
          setState(() => _isDraggingOver = true);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return columnContent;
      },
    );
  }
}
