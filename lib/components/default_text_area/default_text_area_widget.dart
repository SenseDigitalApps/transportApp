import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'default_text_area_model.dart';
export 'default_text_area_model.dart';

class TextAreaControllerNotifier extends ValueNotifier<String> {
  TextAreaControllerNotifier(super.value);

  void updateText(String newValue) {
    value = newValue;
    notifyListeners();
  }
}

class DefaultTextAreaWidget extends StatefulWidget {
  const DefaultTextAreaWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controllerNotifier,
  });

  final String? text;
  final bool isEdit;
  final TextAreaControllerNotifier controllerNotifier;

  @override
  State<DefaultTextAreaWidget> createState() => _DefaultTextAreaWidgetState();
}

class _DefaultTextAreaWidgetState extends State<DefaultTextAreaWidget> {
  late DefaultTextAreaModel _model;
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
    _model = createModel(context, () => DefaultTextAreaModel());

    _textController = TextEditingController(text: widget.controllerNotifier.value);
    _textFieldFocusNode = FocusNode();

    _textController.addListener(() {
      widget.controllerNotifier.updateText(_textController.text);
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.controllerNotifier,
      builder: (context, value, child) {
        return TextFormField(
          controller: _textController,
          focusNode: _textFieldFocusNode,
          autofocus: false,
          obscureText: false,
          enabled: widget.isEdit ? true : false,
          decoration: InputDecoration(
            hintText: widget.text,
            hintStyle: FlutterFlowTheme.of(context).bodyLarge.override(
              fontFamily: 'Roboto',
              letterSpacing: 0.0,
              color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.5),
            ),
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            filled: false,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
          ),
          style: FlutterFlowTheme.of(context).bodyLarge.override(
            fontFamily: 'Roboto',
            letterSpacing: 0.0,
          ),
          maxLines: 10,
          minLines: 5,
          validator: _model.textControllerValidator.asValidator(context),
        );
      },
    );
  }
}
