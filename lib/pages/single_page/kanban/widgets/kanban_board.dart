import 'package:flutter/material.dart';
import 'kanban_column.dart';

class KanbanBoardWidget extends StatelessWidget {
  final List<KanbanColumnData> columns;
  final Function(dynamic card) onCardTap;
  final Function(String columnId)? onLoadMore;
  final Function(dynamic card, String sourceColumnId, String targetColumnId)? onCardDropped;
  final List<int> timeIntervals;

  const KanbanBoardWidget({
    super.key,
    required this.columns,
    required this.onCardTap,
    this.onLoadMore,
    this.onCardDropped,
    this.timeIntervals = const [5, 10, 15],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((column) {
          return KanbanColumnWidget(
            column: column,
            onCardTap: onCardTap,
            onLoadMore: onLoadMore != null ? () => onLoadMore!(column.id) : null,
            onCardDropped: onCardDropped,
            timeIntervals: timeIntervals,
          );
        }).toList(),
      ),
    );
  }
}
