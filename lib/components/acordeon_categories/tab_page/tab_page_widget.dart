import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../glass_form/glass_field_container.dart';

class TabPageWidget extends StatefulWidget {
  final Map<String, dynamic> category;
  final Function(String, int, Map<String, dynamic>, String) getController;
  final Function(String) getFieldWidget;
  final int startFieldIndex;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Set<String> inheritedSlugs;
  final Set<String> validationErrors;
  final Map<String, bool> fieldVisibility;

  const TabPageWidget({
    super.key,
    required this.category,
    required this.getController,
    required this.getFieldWidget,
    this.startFieldIndex = 0,
    this.shrinkWrap = false,
    this.physics,
    this.inheritedSlugs = const {},
    this.validationErrors = const {},
    this.fieldVisibility = const {},
  });

  @override
  State<TabPageWidget> createState() => _TabPageWidgetState();
}

class _TabPageWidgetState extends State<TabPageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildFieldsList();
  }

  Widget _buildFieldItem(Map<String, dynamic> campo, int fieldIndex) {
    final slug = campo['slug']?.toString() ?? '';
    final typeField = campo["type"];
    final widgetBuilder = widget.getFieldWidget(typeField);
    final fieldId = '${widget.category['category']}-${slug}';
    final globalIndex = fieldIndex + widget.startFieldIndex;
    widget.getController(typeField, globalIndex, campo, fieldId);

    final isHighlighted = widget.inheritedSlugs.contains(slug);
    final hasError = widget.validationErrors.contains(slug);
    final isRequired = campo['is_required'] == true;
    final childWidget = widgetBuilder(context, campo, globalIndex, fieldId);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            decoration: isHighlighted
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.shade600,
                      width: 2.5,
                    ),
                    color: Colors.amber.shade50,
                  )
                : (hasError
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      )
                    : null),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassFieldContainer(
                  label: campo['label']?.toString(),
                  isRequired: isRequired,
                  child: childWidget,
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, bottom: 8, top: 2),
                    child: Text(
                      'Este campo es obligatorio',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList() {
    final fields = widget.category['fields'] as List? ?? [];
    final filteredFields = fields.where((field) {
      if (field is! Map) return false;
      final slug = field['slug']?.toString() ?? '';
      if (slug.isEmpty) return true;
      return widget.fieldVisibility[slug] ?? true;
    }).toList();

    // Column mode: no inner scroll, outer scroll handles everything
    if (widget.shrinkWrap && widget.physics is NeverScrollableScrollPhysics) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: filteredFields.asMap().entries.map((entry) {
          return _buildFieldItem(entry.value, entry.key);
        }).toList(),
      );
    }

    return ListView.builder(
      primary: widget.physics == null && !widget.shrinkWrap,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      cacheExtent: double.infinity,
      padding: EdgeInsets.zero,
      itemCount: filteredFields.length,
      itemBuilder: (context, fieldIndex) {
        return _buildFieldItem(filteredFields[fieldIndex], fieldIndex);
      },
    );
  }
}
