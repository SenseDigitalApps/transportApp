import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Campo de texto con glassmorphism premium empresarial.
/// Sin glows de color, solo blur y bordes blancos sutiles.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.darkSurface = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final TextAlign textAlign;
  final void Function(String)? onChanged;
  final bool darkSurface;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);
    final useLightField = widget.darkSurface;
    final fieldColor = useLightField
        ? const Color(0xFFF7FAFC).withValues(alpha: 0.94)
        : isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55);
    final contentColor = useLightField
        ? const Color(0xFF142631)
        : isDark
            ? Colors.white
            : theme.primaryText;
    final supportingColor = useLightField
        ? const Color(0xFF526A79)
        : isDark
            ? Colors.white.withValues(alpha: 0.68)
            : const Color(0xFF586A78);
    final idleIconColor = useLightField
        ? const Color(0xFF587484)
        : isDark
            ? Colors.white.withValues(alpha: 0.62)
            : const Color(0xFF607381);

    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (fieldState) {
        final bool hasError = fieldState.hasError;
        return Animate(
          effects: const [
            FadeEffect(duration: Duration(milliseconds: 600)),
            SlideEffect(
              begin: Offset(0, 0.08),
              end: Offset.zero,
              duration: Duration(milliseconds: 600),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasError
                            ? Colors.red.withValues(alpha: 0.7)
                            : (_isFocused
                                ? (useLightField
                                    ? theme.primary.withValues(alpha: 0.90)
                                    : isDark
                                        ? Colors.white.withValues(alpha: 0.35)
                                        : Colors.white.withValues(alpha: 0.8))
                                : (useLightField
                                    ? const Color(0xFFD7E3E9)
                                    : isDark
                                        ? Colors.white.withValues(alpha: 0.10)
                                        : Colors.white
                                            .withValues(alpha: 0.45))),
                        width: hasError ? 1.2 : (_isFocused ? 1.2 : 0.8),
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      obscureText: widget.obscureText,
                      textInputAction: widget.textInputAction,
                      onSubmitted: widget.onFieldSubmitted,
                      textAlign: widget.textAlign,
                      onChanged: (value) {
                        fieldState.didChange(value);
                        if (widget.onChanged != null) {
                          widget.onChanged!(value);
                        }
                      },
                      cursorColor:
                          useLightField ? const Color(0xFF278DB5) : null,
                      style: TextStyle(
                        color: contentColor,
                        fontSize: useLightField ? 16 : 15,
                        fontWeight:
                            useLightField ? FontWeight.w600 : FontWeight.w400,
                        fontFamily: 'Outfit',
                        letterSpacing: 0.2,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.labelText,
                        labelStyle: TextStyle(
                          color: hasError
                              ? Colors.red.withValues(alpha: 0.8)
                              : supportingColor,
                          fontSize: useLightField ? 12.5 : 14,
                          fontWeight:
                              useLightField ? FontWeight.w500 : FontWeight.w400,
                          fontFamily: 'Outfit',
                        ),
                        floatingLabelStyle: TextStyle(
                          color: hasError
                              ? Colors.red.withValues(alpha: 0.85)
                              : useLightField && _isFocused
                                  ? const Color(0xFF176F94)
                                  : supportingColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Outfit',
                        ),
                        prefixIcon: Icon(
                          widget.prefixIcon,
                          color: hasError
                              ? Colors.red.withValues(alpha: 0.8)
                              : (_isFocused
                                  ? useLightField
                                      ? const Color(0xFF176F94)
                                      : isDark
                                          ? Colors.white
                                          : theme.primaryText
                                  : idleIconColor),
                          size: 20,
                        ),
                        suffixIcon: widget.suffixIcon,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    fieldState.errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
