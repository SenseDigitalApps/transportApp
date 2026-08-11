import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../empty_component/empty_component_widget.dart';
import 'relational_result_tile.dart';

class RelationalDropdown extends StatelessWidget {
  final bool isVisible;
  final bool loading;
  final List<dynamic> items;
  final String typeRelation;
  final ValueChanged<dynamic> onItemSelected;

  const RelationalDropdown({
    required this.isVisible,
    required this.loading,
    required this.items,
    required this.typeRelation,
    required this.onItemSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: loading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
              )
            : items.isEmpty
                ? const Center(child: EmptyComponentWidget())
                : ListView.builder(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                    shrinkWrap: true,
                    primary: false,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return RelationalResultTile(
                        item: item,
                        typeRelation: typeRelation,
                        onTap: () => onItemSelected(item),
                      )
                          .animate()
                          .fadeIn(
                            delay: (index * 40).ms,
                            duration: 200.ms,
                          )
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            delay: (index * 40).ms,
                            duration: 200.ms,
                          );
                    },
                  ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }
}
