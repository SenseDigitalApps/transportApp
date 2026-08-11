import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'default_text_field_model.dart';
export 'default_text_field_model.dart';

class TextControllerNotifier extends ValueNotifier<String> {
  TextControllerNotifier(super.value);

  void updateText(String newValue) {
    value = newValue;
    notifyListeners();
  }
}

class DefaultTextFieldWidget extends StatefulWidget {
  const DefaultTextFieldWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controllerNotifier,
    required this.type,
    required this.slug,
    this.readOnly = false,
  });

  final String? text;
  final bool isEdit;
  final bool readOnly;
  final TextControllerNotifier controllerNotifier;
  final String type;
  final String slug;

  @override
  State<DefaultTextFieldWidget> createState() => _DefaultTextFieldWidgetState();
}

class _DefaultTextFieldWidgetState extends State<DefaultTextFieldWidget> {
  late DefaultTextFieldModel _model;
  late TextEditingController _textController;
  late FocusNode _textFieldFocusNode;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DefaultTextFieldModel());
    _textController = TextEditingController(text: widget.controllerNotifier.value.toString());
    _textFieldFocusNode = FocusNode();
    _textController.addListener(() {
      print('[TextField] _textController listener fired: slug=${widget.slug} type=${widget.type} text="${_textController.text}"');
      widget.controllerNotifier.updateText(_textController.text);
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();
    _textController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  bool get _hasText => _textController.text.trim().isNotEmpty;

  void _clear() {
    FocusScope.of(context).unfocus();
    _textController.clear();
    widget.controllerNotifier.updateText('');

    // Si tienes lógica de number ligada al slug, también la “actualizas”
    if (widget.type == 'number') {
      final index = FFAppState()
          .textoControlador
          .indexWhere((element) => element[0] == widget.slug);
      if (index != -1) {
        setState(() {
          FFAppState().updateTextoControladorAtIndex(index, widget.slug, _textController);
        });
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.controllerNotifier,
      builder: (context, value, child) {
        final stringValue = value.toString();
        if (_textController.text != stringValue) {
          _textController.value = _textController.value.copyWith(
            text: stringValue,
            selection: TextSelection.collapsed(offset: stringValue.length),
            composing: TextRange.empty,
          );
        }

        return TextFormField(
          controller: _textController,
          focusNode: _textFieldFocusNode,
          enabled: widget.isEdit || widget.readOnly,
          readOnly: widget.readOnly,
          autofocus: false,
          obscureText: false,
          maxLines: 1,
          minLines: 1,
          keyboardType: (widget.type == 'number')
              ? TextInputType.number
              : TextInputType.text,
          onChanged: (val) {
            print('[TextField] onChanged: slug=${widget.slug} type=${widget.type} val="$val"');
            // tu lógica actual (intacta)
            if (widget.type == 'number') {
              int index = FFAppState()
                  .textoControlador
                  .indexWhere((element) => element[0] == widget.slug);
              if (index != -1) {
                setState(() {
                  FFAppState().updateTextoControladorAtIndex(
                    index,
                    widget.slug,
                    _textController,
                  );
                });
              }
            }
            setState(() {}); // para refrescar suffixIcon
          },
          decoration: InputDecoration(
            hintText: widget.text?.toString() ?? '',
            hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
              fontFamily: 'Roboto',
              fontSize: 13,
              letterSpacing: 0,
              color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.5),
            ),
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            filled: false,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            suffixIcon: (_hasText && widget.isEdit)
                ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                    onPressed: _clear,
                  )
                : null,
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Outfit',
            fontSize: 13,
            letterSpacing: 0,
          ),
        );
      },
    );
  }
}
