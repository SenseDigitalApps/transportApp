import '../custom_code/TenantConfigService.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'splash_screen_model.dart';
export 'splash_screen_model.dart';

import '../login_equipo/widgets/widgets.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({super.key});

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget>
    with TickerProviderStateMixin {
  late SplashScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SplashScreenModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        final savedEmpresa = FFAppState().empresaRaw.trim();
        _model.textFieldEmpresaTextController?.text =
            savedEmpresa.isNotEmpty ? savedEmpresa : '';
        if (savedEmpresa.isNotEmpty) {
          _model.textFieldEmpresaTextController?.selection =
              TextSelection.collapsed(
                  offset: _model.textFieldEmpresaTextController!.text.length);
        }
      });
      setState(() {
        _model.radioButtonValueController?.reset();
      });
      if (FFAppState().token != '') {
        context.goNamed('home');
      } else {
        if (FFAppState().clientId != '') {
          context.goNamed(
            'homeClient',
            queryParameters: {
              'userId': serializeParam(
                FFAppState().clientId,
                ParamType.String,
              ),
            }.withoutNulls,
          );
        }
      }
    });

    _model.textFieldEmpresaTextController ??=
        TextEditingController(text: FFAppState().empresaRaw);
    _model.textFieldEmpresaFocusNode ??= FocusNode();

    animationsMap.addAll({
      'imageOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(-0.0, 64.0),
            end: const Offset(0.0, 0.0),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(1.0, 0.0),
            end: const Offset(1.0, 1.0),
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
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleIngresar() async {
    final rawText = _model.textFieldEmpresaTextController.text.trim();
    FFAppState().empresaRaw = rawText;
    FFAppState().organizacion =
        functions.formatName(_model.textFieldEmpresaTextController.text);
    setState(() {});

    if (_model.radioButtonValue == 'Cliente') {
      context.pushNamed('LoginClientes');
    } else {
      await loadTenantConfig(tenant: FFAppState().organizacion);
    }

    setState(() {});

    context.goNamed('LoginEquipo');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Query authentication background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://us.itsquery.com/mediafiles/auth/bg9-dark.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.48),
                    ],
                  ),
                ),
              ),
            ),

            // Scrollable content centered vertically
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),

                            // Logo header
                            GlassLogoHeader(
                              logoUrl:
                                  'https://us.itsquery.com/mediafiles/misc/Logos-Query-13.png',
                              size: 140,
                              contentPaddingFactor: 0.18,
                              darkSurface: true,
                            ).animateOnPageLoad(
                                animationsMap['imageOnPageLoadAnimation']!),
                            const SizedBox(height: 40),

                            // Auth card
                            GlassAuthCard(
                              darkSurface: true,
                              children: [
                                // Title
                                Animate(
                                  effects: const [
                                    FadeEffect(
                                        duration: Duration(milliseconds: 600)),
                                  ],
                                  child: Column(
                                    children: [
                                      Text(
                                        'Ingresar',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Outfit',
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 40,
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Empresa field
                                GlassTextField(
                                  controller:
                                      _model.textFieldEmpresaTextController!,
                                  focusNode: _model.textFieldEmpresaFocusNode!,
                                  labelText: 'Selecciona la empresa',
                                  prefixIcon: Icons.search_sharp,
                                  darkSurface: true,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) => EasyDebounce.debounce(
                                    '_model.textFieldEmpresaTextController',
                                    const Duration(milliseconds: 2000),
                                    () async {
                                      FFAppState().empresaRaw = value.trim();
                                      FFAppState().organizacion =
                                          functions.formatName(value);
                                      setState(() {});
                                    },
                                  ),
                                  suffixIcon: _model
                                          .textFieldEmpresaTextController!
                                          .text
                                          .isNotEmpty
                                      ? GestureDetector(
                                          onTap: () async {
                                            _model
                                                .textFieldEmpresaTextController
                                                ?.clear();
                                            FFAppState().empresaRaw = '';
                                            FFAppState().organizacion = '';
                                            setState(() {});
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 12),
                                            child: Icon(
                                              Icons.clear,
                                              color: const Color(0xFF587484),
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : null,
                                  onFieldSubmitted: (_) => _handleIngresar(),
                                ),
                                const SizedBox(height: 24),

                                // Ingresar button
                                GlassButton(
                                  onPressed: _handleIngresar,
                                  text: 'Ingresar',
                                  icon: Icons.rocket_rounded,
                                ),
                                const SizedBox(height: 20),

                                // Contact link
                                Animate(
                                  effects: const [
                                    FadeEffect(
                                        duration: Duration(milliseconds: 800)),
                                  ],
                                  child: Column(
                                    children: [
                                      Text(
                                        '¿Quieres una app cómo esta para tu empresa?',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          fontSize: 13,
                                          fontFamily: 'Outfit',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () async {
                                          await launchURL(
                                              'https://wa.me/573507890086?text=Hola%20Carlos%20te%20hablo%20desde%20la%20app%20de%20query%20para%20la%20siguiente%20consulta:');
                                        },
                                        child: Text(
                                          'Da clic aquí',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Outfit',
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
