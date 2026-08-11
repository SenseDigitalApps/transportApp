import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'empty_component_model.dart';
export 'empty_component_model.dart';

class EmptyComponentWidget extends StatefulWidget {
  const EmptyComponentWidget({
    super.key,
    this.title = 'No hay resultados',
    this.message = 'No encontramos información para mostrar en este momento.',
    this.hint = 'El contenido aparecerá aquí',
    this.icon = Icons.inbox_rounded,
  });

  final String title;
  final String message;
  final String hint;
  final IconData icon;

  @override
  State<EmptyComponentWidget> createState() => _EmptyComponentWidgetState();
}

class _EmptyComponentWidgetState extends State<EmptyComponentWidget>
    with TickerProviderStateMixin {
  late EmptyComponentModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmptyComponentModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeOut,
            delay: 0.0.ms,
            duration: 350.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeOutCubic,
            delay: 0.0.ms,
            duration: 350.0.ms,
            begin: const Offset(0.0, 12.0),
            end: Offset.zero,
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    const darkBlueAccent = Color(0xFF1D6288);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20.0, 12.0, 20.0, 12.0),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 240.0,
            maxWidth: 420.0,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: theme.primary.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 24.0,
                color: theme.primaryBlack.withValues(alpha: 0.06),
                offset: const Offset(0.0, 8.0),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -52.0,
                right: -34.0,
                child: Container(
                  width: 128.0,
                  height: 128.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primary.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -62.0,
                left: -42.0,
                child: Container(
                  width: 144.0,
                  height: 144.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkBlueAccent.withValues(alpha: 0.045),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  28.0,
                  20.0,
                  28.0,
                  20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 82.0,
                          height: 82.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.primary.withValues(alpha: 0.30),
                                darkBlueAccent.withValues(alpha: 0.10),
                              ],
                            ),
                            border: Border.all(
                              color: theme.primary.withValues(alpha: 0.34),
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 18.0,
                                color: theme.primary.withValues(alpha: 0.20),
                                offset: const Offset(0.0, 6.0),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 58.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primaryBackground
                                    .withValues(alpha: 0.86),
                              ),
                              child: Icon(
                                widget.icon,
                                color: darkBlueAccent,
                                size: 34.0,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -2.0,
                          right: -5.0,
                          child: Container(
                            width: 27.0,
                            height: 27.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: darkBlueAccent,
                              border: Border.all(
                                color: theme.primaryBackground,
                                width: 3.0,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: theme.white,
                              size: 12.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: theme.titleMedium.override(
                        fontFamily: 'Outfit',
                        color: theme.primaryText,
                        fontSize: 18.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 290.0),
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.override(
                          fontFamily: 'Outfit',
                          color: theme.secondaryText,
                          fontSize: 13.0,
                          letterSpacing: 0.0,
                          lineHeight: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12.0,
                        6.0,
                        12.0,
                        6.0,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13.0,
                            color: darkBlueAccent,
                          ),
                          const SizedBox(width: 6.0),
                          Flexible(
                            child: Text(
                              widget.hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.override(
                                fontFamily: 'Outfit',
                                color: darkBlueAccent,
                                fontSize: 11.5,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animateOnPageLoad(
          animationsMap['containerOnPageLoadAnimation']!,
        ),
      ),
    );
  }
}
