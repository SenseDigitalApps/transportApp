import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/solicitud_trabajo.dart';
import 'solicitud_card.dart';
import 'glass_card/glass_card.dart';

class ActiveRequestsSection extends StatefulWidget {
  final List<SolicitudTrabajo> requests;
  final List<Map<String, dynamic>> requestsJson;
  final bool isLoading;
  final Function(int index) onRequestTap;

  const ActiveRequestsSection({
    Key? key,
    required this.requests,
    required this.requestsJson,
    required this.isLoading,
    required this.onRequestTap,
  }) : super(key: key);

  @override
  State<ActiveRequestsSection> createState() => _ActiveRequestsSectionState();
}

class _ActiveRequestsSectionState extends State<ActiveRequestsSection> {
  final _controller = DraggableScrollableController();

  double _currentSize = 0.35;
  static const double _minChildSize = 0.10;
  static const double _maxChildSize = 1.0;
  static const double _collapsedSize = 0.10;
  static const List<double> _snapSizes = [_collapsedSize, 0.35, 0.65, _maxChildSize];

  bool get _isCollapsed => _currentSize <= _collapsedSize + 0.05;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (_controller.isAttached) {
      setState(() {
        _currentSize = _controller.size;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: _currentSize,
          minChildSize: _minChildSize,
          maxChildSize: _maxChildSize,
          snap: true,
          snapSizes: _snapSizes,
          builder: (context, scrollController) {
            return GlassCard(
              borderRadius: _isCollapsed ? 16 : 24,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleExpand,
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta != null && details.primaryDelta != 0) {
                        final delta = details.primaryDelta! / constraints.maxHeight;
                        final newSize = (_controller.size - delta).clamp(_minChildSize, _maxChildSize);
                        _controller.jumpTo(newSize);
                      }
                    },
                    onVerticalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -300) {
                        _snapTo(_maxChildSize);
                      } else if (velocity > 300) {
                        _snapTo(_collapsedSize);
                      } else {
                        _snapToClosest();
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: theme.secondaryText.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, color: theme.primary, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Solicitudes Activas',
                                  style: theme.titleMedium.copyWith(color: theme.primaryText),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${widget.requests.length}',
                                    style: theme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _toggleExpand,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      _isCollapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: theme.primaryText,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!_isCollapsed)
                    Divider(height: 1, color: theme.primaryText.withValues(alpha: 0.1)),
                  _isCollapsed
                      ? Expanded(child: SizedBox.shrink())
                      : Expanded(
                          child: widget.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : widget.requests.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.inbox_outlined, size: 48, color: theme.secondaryText),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No hay solicitudes activas',
                                              style: theme.bodyMedium.copyWith(color: theme.primaryText),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: scrollController,
                                      padding: const EdgeInsets.all(8),
                                      itemCount: widget.requests.length,
                                      itemBuilder: (context, index) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: SolicitudCard(
                                          request: widget.requests[index],
                                          onTap: () => widget.onRequestTap(index),
                                        ),
                                      ),
                                    ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleExpand() {
    final target = _isCollapsed ? 0.65 : _collapsedSize;
    _snapTo(target);
  }

  void _snapTo(double size) {
    _controller.animateTo(
      size,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _snapToClosest() {
    double closest = _snapSizes.first;
    double minDiff = (_currentSize - closest).abs();
    for (final size in _snapSizes) {
      final diff = (_currentSize - size).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = size;
      }
    }
    _snapTo(closest);
  }
}