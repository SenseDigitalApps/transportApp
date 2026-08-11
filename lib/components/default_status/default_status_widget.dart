import '../../flutter_flow/form_field_controller.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'default_status_model.dart';
export 'default_status_model.dart';

class DefaultStatusWidget extends StatefulWidget {
  DefaultStatusWidget({
    super.key,
    required this.text,
    required this.options,
    required this.isEdit,
    required this.controller,
    required this.onChanged,
  });

  final String? text;
  final List<String> options;
  final bool isEdit;
  late FormFieldController<String> controller;
  final Function() onChanged;

  @override
  State<DefaultStatusWidget> createState() => _DefaultStatusWidgetState();
}

class _DefaultStatusWidgetState extends State<DefaultStatusWidget> {
  late DefaultStatusModel _model;

  String? finalColor;
  String? dropDownValue;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  Color getColor(String colorText) {
    switch (colorText) {
      case 'warning':
        return Colors.orangeAccent;
      case 'info':
        return Colors.deepPurpleAccent;
      case 'primary':
        return Colors.blueAccent;
      case 'success':
        return Colors.green;
      case 'danger':
        return Colors.red;
      case 'dark':
        return Colors.black54;
      default:
        return Colors.grey;
    }
  }

  void extractColor() {
    for (var option in widget.options) {
      final parts = option.split('|');
      if (parts.isNotEmpty && parts.first.trim() == widget.text) {
        finalColor = parts.length > 1 ? parts[1].trim() : null;
        dropDownValue = parts.first.trim();
        break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultStatusModel());
    extractColor();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.isEdit) {
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropDownValue,
          isDense: true,
          isExpanded: true,
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              dropDownValue = val;
              finalColor = widget.options
                  .firstWhere((option) => option.startsWith('$val|'),
                  orElse: () => val)
                  .split('|')
                  .last
                  .trim();
              widget.controller.value = dropDownValue;
            });
            widget.onChanged();
          },
          items: widget.options.map((option) {
            final parts = option.split('|');
            final label = parts.first.trim();
            final color = parts.length > 1
                ? getColor(parts[1].trim())
                : Colors.grey;
            return DropdownMenuItem<String>(
              value: label,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context)
                          .bodyMedium
                          .override(
                        fontFamily: 'Outfit',
                        color: color,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          hint: Text(
            widget.text ?? '',
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Outfit',
              color: finalColor != null
                  ? getColor(finalColor!)
                  : FlutterFlowTheme.of(context).secondaryText,
              letterSpacing: 0.0,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: FlutterFlowTheme.of(context).secondaryText,
            size: 18.0,
          ),
          dropdownColor: isDark
              ? Colors.black.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.95),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: (finalColor != null
                  ? getColor(finalColor!)
                  : FlutterFlowTheme.of(context).secondaryText)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: (finalColor != null
                    ? getColor(finalColor!)
                    : FlutterFlowTheme.of(context).secondaryText)
                .withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        child: Text(
          valueOrDefault<String>(
            widget.text,
            'Sin Estado',
          ),
          overflow: TextOverflow.ellipsis,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Outfit',
            letterSpacing: 0.0,
            color: finalColor != null
                ? getColor(finalColor!)
                : FlutterFlowTheme.of(context).secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
  }
}