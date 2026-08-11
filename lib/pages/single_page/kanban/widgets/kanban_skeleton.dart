import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class KanbanSkeletonWidget extends StatefulWidget {
  final int columnsCount;

  const KanbanSkeletonWidget({
    super.key,
    this.columnsCount = 3,
  });

  @override
  State<KanbanSkeletonWidget> createState() => _KanbanSkeletonWidgetState();
}

class _KanbanSkeletonWidgetState extends State<KanbanSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.15 + (_controller.value * 0.15);
        final baseColor = theme.secondaryText.withValues(alpha: opacity);
        final highlightColor = theme.secondaryText.withValues(alpha: opacity + 0.1);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(widget.columnsCount, (index) {
              return Container(
                width: 280.0,
                margin: const EdgeInsets.only(right: 12.0),
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.03),
                      blurRadius: 10.0,
                      offset: const Offset(0.0, 4.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header skeleton
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: baseColor,
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
                              color: highlightColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Container(
                              height: 14.0,
                              decoration: BoxDecoration(
                                color: highlightColor,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Container(
                            width: 32.0,
                            height: 18.0,
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Cards skeleton
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: List.generate(3, (cardIndex) {
                          return _buildCardSkeleton(baseColor, highlightColor);
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildCardSkeleton(Color baseColor, Color highlightColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: highlightColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50.0,
                height: 18.0,
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              Container(
                width: 60.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Container(
            width: double.infinity,
            height: 14.0,
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          const SizedBox(height: 4.0),
          Container(
            width: 120.0,
            height: 14.0,
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Container(
                width: 24.0,
                height: 24.0,
                decoration: BoxDecoration(
                  color: highlightColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6.0),
              Container(
                width: 100.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
