import 'package:shared_preferences/shared_preferences.dart';

import '../backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
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

    String? primaryMetaColor;
    String? secondaryMetaColor;
    String? tertiaryMetaColor;
    if (_model.radioButtonValue == 'Cliente') {
      context.pushNamed('LoginClientes');
    } else {
      _model.optionsPanel = await GetOptionsPanelCall.call(
        tenant: FFAppState().organizacion,
      );

      // Obtén el campo `$.results` si existe, de lo contrario intenta con `$.data`
      final jsonFieldResults =
          getJsonField((_model.optionsPanel?.jsonBody ?? ''), r'''$.results''');
      final jsonFieldData = (jsonFieldResults == null ||
              jsonFieldResults.isEmpty)
          ? getJsonField((_model.optionsPanel?.jsonBody ?? ''), r'''$.data''')
          : jsonFieldResults;

      bool foundLogoLink = false;
      bool foundFondoLink = false;
      bool foundLoaderLogo = false;
      bool foundLookerStudio = false;
      FFAppState().logoLink = '';
      FFAppState().fondoLink = '';
      FFAppState().lookerStudio = '';
      FFAppState().loaderLogo = '';

      for (var result in jsonFieldData ?? []) {
        switch (result['meta_key']) {
          case 'logo_link':
            FFAppState().logoLink = result['meta_value'].toString();
            foundLogoLink = true;
            break;
          case 'fondo_link':
            FFAppState().fondoLink = result['meta_value'].toString();
            foundFondoLink = true;
            break;
          case 'simple_app':
            FFAppState().simpleApp = result['meta_value'].toString();
            break;
          case 'role_simple_app':
            FFAppState().simpleAppRole = result['meta_value'].toString();
            break;
          case 'slug_modulo_simple_app':
            FFAppState().simpleAppSlugModule = result['meta_value'].toString();
            break;
          case 'slug_fecha_simple_app':
            FFAppState().simpleAppSlugFecha = result['meta_value'].toString();
            break;
          case 'slug_asignado_simple_app':
            FFAppState().simpleAppSlugUserAsignado =
                result['meta_value'].toString();
            break;
          case 'slug_formato_simple_app':
            FFAppState().simpleAppSlugFormato = result['meta_value'].toString();
            break;
          case 'slug_filter_simple_app':
            FFAppState().simpleSlugFilter = result['meta_value'].toString();
            break;
          case 'value_filter_simple_app':
            FFAppState().simpleValueFilter = result['meta_value'].toString();
            break;
          case 'slug_repeater_simple_app':
            FFAppState().simpleSlugRepeater = result['meta_value'].toString();
            break;
          case 'slug_repeater_label_simple_app':
            FFAppState().simpleSlugRepeaterLabel =
                result['meta_value'].toString();
            break;
          case 'slug_repeater_boolean_simple_app':
            FFAppState().simpleSlugRepeaterBoolean =
                result['meta_value'].toString();
            break;
          case 'slug_repeater_related_simple_app':
            FFAppState().simpleSlugRepeaterRelated =
                result['meta_value'].toString();
            break;
          case 'dashboard_link':
            FFAppState().lookerStudio = result['meta_value'].toString();
            foundLookerStudio = true;
            break;
          case 'app_loader_logo':
            FFAppState().loaderLogo = result['meta_value'].toString();
            foundLoaderLogo = true;
            break;
          case 'primary_color':
            primaryMetaColor = result['meta_value'].toString();
            break;
          case 'secondary_color':
            secondaryMetaColor = result['meta_value'].toString();
            break;
          case 'tertiary_color':
            tertiaryMetaColor = result['meta_value'].toString();
            break;
        }
      }

      if (!foundLogoLink) {
        FFAppState().logoLink = '';
      }

      if (!foundFondoLink) {
        FFAppState().fondoLink = '';
      }

      if (!foundLoaderLogo) {
        FFAppState().loaderLogo = '';
      }

      if (!foundLookerStudio) {
        FFAppState().lookerStudio = '';
      }
    }

    String? newPrimaryHex = primaryMetaColor;
    String? newSecondaryHex = secondaryMetaColor;
    String? newTertiaryHex = tertiaryMetaColor;

    final prefs = await SharedPreferences.getInstance();
    final primaryHexFromPrefs = prefs.getString(kPrimaryColorKey);
    final secondaryHexFromPrefs = prefs.getString(kSecondaryColorKey);
    final tertiaryHexFromPrefs = prefs.getString(kTertiaryColorKey);

    String? primaryHexToUse;
    String? secondaryHexToUse;
    String? tertiaryHexToUse;

    if (primaryHexFromPrefs == null) {
      primaryHexToUse = newPrimaryHex ?? '92E2FFFF';
    } else {
      primaryHexToUse = newPrimaryHex ?? primaryHexFromPrefs;
    }

    if (secondaryHexFromPrefs == null) {
      secondaryHexToUse = newSecondaryHex ?? '92E2FFFF';
    } else {
      secondaryHexToUse = newSecondaryHex ?? secondaryHexFromPrefs;
    }

    if (tertiaryHexFromPrefs == null) {
      tertiaryHexToUse = newTertiaryHex ?? 'E86969';
    } else {
      tertiaryHexToUse = newTertiaryHex ?? tertiaryHexFromPrefs;
    }

    Color? primaryColor = FlutterFlowTheme.getColorFromHex(primaryHexToUse);
    Color? secondaryColor = FlutterFlowTheme.getColorFromHex(secondaryHexToUse);
    Color? tertiaryColor = FlutterFlowTheme.getColorFromHex(tertiaryHexToUse);

    if (primaryColor != null &&
        secondaryColor != null &&
        tertiaryColor != null) {
      await FlutterFlowTheme.saveColors(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
      );

      if (mounted) {
        setState(() {});
      }
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
