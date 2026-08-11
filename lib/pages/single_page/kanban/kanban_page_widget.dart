import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'kanban_page_model.dart';
import 'widgets/kanban_board.dart';
import 'widgets/kanban_skeleton.dart';
export 'kanban_page_model.dart';

class KanbanPageWidget extends StatefulWidget {
  final String? moduleName;
  final dynamic moduleConfig;
  final dynamic moduleData;
  final String? moduleType;
  final dynamic filters;

  const KanbanPageWidget({
    super.key,
    required this.moduleName,
    required this.moduleConfig,
    required this.moduleData,
    this.moduleType,
    this.filters,
  });

  @override
  State<KanbanPageWidget> createState() => _KanbanPageWidgetState();
}

class _KanbanPageWidgetState extends State<KanbanPageWidget> {
  late KanbanPageModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KanbanPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _model.initializeKanban(
        widget.moduleConfig,
        widget.moduleName ?? '',
        widget.moduleType,
        filters: widget.filters,
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant KanbanPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters?.toString() != widget.filters?.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _model.initializeKanban(
          widget.moduleConfig,
          widget.moduleName ?? '',
          widget.moduleType,
          filters: widget.filters,
        );
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _model.initializeKanban(
      widget.moduleConfig,
      widget.moduleName ?? '',
      widget.moduleType,
      filters: widget.filters,
    );
    if (mounted) setState(() {});
  }

  Future<void> _navigateToDetail(dynamic card) async {
    final result = await context.pushNamed(
      'detailGrouped',
      queryParameters: {
        'title': serializeParam('a', ParamType.String),
        'body': serializeParam('aa', ParamType.String),
        'general': serializeParam(
          getJsonField(card, r'''$'''),
          ParamType.JSON,
        ),
        'moduleData': serializeParam(
          widget.moduleData,
          ParamType.JSON,
        ),
        'moduleConfigData': serializeParam(
          getJsonField((widget.moduleConfig ?? ''), r'''$.data'''),
          ParamType.JSON,
        ),
      }.withoutNulls,
    );

    if (result == true) {
      await _model.initializeKanban(
        widget.moduleConfig,
        widget.moduleName ?? '',
        widget.moduleType,
        filters: widget.filters,
      );
      if (mounted) setState(() {});
    }

    String newItemId = getJsonField(card, r'''$.id''').toString();
    int existingIndex = -1;

    for (int i = 0; i < FFAppState().recientes.length; i++) {
      String currentItemId = getJsonField(FFAppState().recientes[i], r'''$.id''').toString();
      if (currentItemId == newItemId) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      FFAppState().removeAtIndexFromRecientes(existingIndex);
    }

    if (FFAppState().recientes.length >= 11) {
      FFAppState().removeAtIndexFromRecientes(11);
    }
    FFAppState().insertAtIndexInRecientes(0, getJsonField(card, r'''$'''));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_model.isLoading) {
      return KanbanSkeletonWidget(
        columnsCount: _model.columns.isNotEmpty ? _model.columns.length : 3,
      );
    }

    if (_model.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: FlutterFlowTheme.of(context).error,
            ),
            const SizedBox(height: 16),
            Text(
              _model.error!,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Outfit',
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await _model.initializeKanban(
                    widget.moduleConfig,
                    widget.moduleName ?? '',
                    widget.moduleType,
                    filters: widget.filters,
                  );
                  if (mounted) setState(() {});
                },
                child: const Text('Reintentar'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: FlutterFlowTheme.of(context).primary,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxHeight: constraints.maxHeight,
              ),
              child: KanbanBoardWidget(
                columns: _model.columns,
                onCardTap: _navigateToDetail,
                timeIntervals: _model.timeIntervals,
                onLoadMore: (columnId) async {
                  await _model.loadMoreForColumn(
                    columnId: columnId,
                    moduleName: widget.moduleName ?? '',
                    moduleType: widget.moduleType,
                    filters: widget.filters,
                  );
                  if (mounted) setState(() {});
                },
                onCardDropped: (card, sourceColumnId, targetColumnId) async {
                  setState(() {}); // Trigger UI update for optimistic move
                  final error = await _model.moveCard(
                    card: card,
                    sourceColumnId: sourceColumnId,
                    targetColumnId: targetColumnId,
                    moduleName: widget.moduleName ?? '',
                    moduleType: widget.moduleType,
                  );
                  if (error != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: FlutterFlowTheme.of(context).error,
                      ),
                    );
                  }
                  if (mounted) setState(() {});
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
