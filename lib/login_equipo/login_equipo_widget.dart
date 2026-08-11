import 'dart:ui';

import 'package:flutter/scheduler.dart';

import '../components/page_components/loader_image/loader_image.dart';
import '../pages/user_register/register_user_widget.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_equipo_model.dart';
export 'login_equipo_model.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/custom_code/BiometricAuthService.dart';

import 'widgets/widgets.dart';

class LoginEquipoWidget extends StatefulWidget {
  const LoginEquipoWidget({super.key});

  @override
  State<LoginEquipoWidget> createState() => _LoginEquipoWidgetState();
}

class _LoginEquipoWidgetState extends State<LoginEquipoWidget> {
  late LoginEquipoModel _model;
  bool _isLoading = false;

  ApiCallResponse? AllowedRolesRegister;
  List<dynamic> allowedRoles = [];
  bool publicRegisterEnabled = false;
  bool isLoadingPublicRoles = true;
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  bool _hasSavedCredentials = false;

  String _logoUrl = '';
  String _bgUrl = '';

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginEquipoModel());

    setState(() => _isLoading = false);
    _syncSettings();

    _model.emailAddressLoginTextController ??= TextEditingController();
    _model.emailAddressLoginFocusNode ??= FocusNode();
    _model.passwordLoginTextController ??= TextEditingController();
    _model.passwordLoginFocusNode ??= FocusNode();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final response = await PublicRegistrationOptions.call(
          tenant: FFAppState().organizacion,
        );

        final settings = PublicRegistrationSettings.fromJson(
          response.jsonBody as Map<String, dynamic>,
        );

        setState(() {
          publicRegisterEnabled = settings.enabled;
          allowedRoles = settings.allowedRoles.map((e) => e.toJson()).toList();
          isLoadingPublicRoles = false;
        });
      } catch (e) {
        setState(() {
          allowedRoles = [];
          isLoadingPublicRoles = false;
        });
      }

      // --- Biometric credentials check ---
      try {
        _hasSavedCredentials = await _biometricAuth.hasSavedCredentials();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('Biometric check error: $e');
      }
      // --- Fin Biometric credentials check ---
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.watch<FFAppState>();
    _syncSettings();
  }

  void _syncSettings() {
    // Si el tenant no configuró logo, GlassLogoHeader muestra su identidad
    // visual de IA. La URL predeterminada anterior correspondía a un camión.
    _logoUrl = FFAppState().logoLink.trim();
    _bgUrl = FFAppState().fondoLink.isEmpty
        ? 'https://us.itsquery.com/mediafiles/auth/bg9-dark.jpg'
        : FFAppState().fondoLink;
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    var shouldSetState = false;
    setState(() {
      _isLoading = true;
    });

    _model.loginResult = await LoginTenantCall.call(
      tenant: FFAppState().organizacion,
      username: _model.emailAddressLoginTextController.text,
      password: _model.passwordLoginTextController.text,
    );
    shouldSetState = true;
    if ((_model.loginResult?.statusCode ?? 200).toString() == '200') {
      FFAppState().token = LoginTenantCall.token(
        (_model.loginResult?.jsonBody ?? ''),
      )!;
      FFAppState().refreshToken = LoginTenantCall.refresh(
        (_model.loginResult?.jsonBody ?? ''),
      )!;
      FFAppState().loginUser = _model.emailAddressLoginTextController.text;
      FFAppState().loginPassword = _model.passwordLoginTextController.text;
      setState(() {});
      _model.userDataOut = await UserDataCall.call(
        token: FFAppState().token,
        tenant: FFAppState().organizacion,
      );
      shouldSetState = true;
      if ((_model.userDataOut?.statusCode ?? 200).toString() == '200') {
        FFAppState().id = UserDataCall.idUser(
          (_model.userDataOut?.jsonBody ?? ''),
        )!
            .toString();
        FFAppState().username = UserDataCall.userName(
          (_model.userDataOut?.jsonBody ?? ''),
        )!;
        FFAppState().email = UserDataCall.email(
          (_model.userDataOut?.jsonBody ?? ''),
        )!;
        FFAppState().fullName = UserDataCall.fullName(
          (_model.userDataOut?.jsonBody ?? ''),
        )!;
        FFAppState().avatar = UserDataCall.avatar(
          (_model.userDataOut?.jsonBody ?? ''),
        )!;
        FFAppState().shortname = functions.getShortName(
            UserDataCall.fullName((_model.userDataOut?.jsonBody ?? ''))!);
        try {
          NotificationSettings settings =
              await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) {
            String? pushToken = await FirebaseMessaging.instance.getToken();

            if (pushToken != null && pushToken.isNotEmpty) {
              await PatchUser.call(
                tenant: FFAppState().organizacion,
                token: FFAppState().token,
                pushToken: pushToken,
              );
            }
            functions.subscribeToOrganizacionTopic();
          } else {
            // Permiso de notificaciones denegado
          }
        } catch (e) {
          print('Error al obtener el token: $e');
        }

        FFAppState().role = UserDataCall.role(
          (_model.userDataOut?.jsonBody ?? ''),
        )!;
        FFAppState().permissions = UserDataCall.permissions(
          (_model.userDataOut?.jsonBody ?? ''),
        )!
            .toList()
            .cast<String>();
        final firmaFromApi =
            UserDataCall.firma((_model.userDataOut?.jsonBody ?? '')) ?? '';
        FFAppState().firma = functions.normalizeFirmaUrl(firmaFromApi);

        setState(() {});
        await actions.permissionSearch(
          FFAppState().permissions.toList(),
        );

        // --- INICIO: Preguntar guardar credenciales ---
        await _showSaveCredentialsDialog(
          username: _model.emailAddressLoginTextController.text,
          password: _model.passwordLoginTextController.text,
        );
        // --- FIN: Preguntar guardar credenciales ---

        // Obtener custom home desde el endpoint dedicado
        String? customPageName;
        try {
          final homeConfig = await fetchHomeConfig(
            FFAppState().organizacion,
            FFAppState().token,
          );
          if (homeConfig.replaceHome &&
              homeConfig.customPage != null &&
              homeConfig.customPage!.isNotEmpty) {
            customPageName = homeConfig.customPage;
          }
        } catch (e) {
          print('Error fetching home config: $e');
          customPageName = null;
        }

        // Guardar en AppState
        FFAppState().update(() {
          FFAppState().customHomePage = customPageName ?? '';
        });

        if (FFAppState().simpleApp == 'true' &&
            FFAppState().role.toLowerCase() ==
                FFAppState().simpleAppRole.toLowerCase()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.goNamed(
                'homeSimpleApp',
                extra: <String, dynamic>{
                  kTransitionInfoKey: const TransitionInfo(
                    hasTransition: true,
                    transitionType: PageTransitionType.rightToLeft,
                  ),
                },
              );
            }
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.goNamed('home');
            }
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudieron obtener los detalles de tu cuenta, intentalo de nuevo.',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).white,
              ),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).tertiary,
          ),
        );
      }
      if (shouldSetState) {
        setState(() {});
      }
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Credenciales incorrectas',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).white,
            ),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).tertiary,
        ),
      );
      if (shouldSetState) {
        setState(() {});
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }
  }

  Future<void> _handleDemo() async {
    var shouldSetState = false;

    setState(() {
      _isLoading = true;
    });

    _model.loginResultCopy = await LoginTenantCall.call(
      tenant: FFAppState().organizacion,
      username: 'SenseQuery',
      password: 'gp=cp6N+]o-EyRY??55H9',
    );
    shouldSetState = true;
    if ((_model.loginResultCopy?.statusCode ?? 200).toString() == '200') {
      FFAppState().token = LoginTenantCall.token(
        (_model.loginResultCopy?.jsonBody ?? ''),
      )!;
      setState(() {});
      _model.userDataOutCopy = await UserDataCall.call(
        token: FFAppState().token,
        tenant: FFAppState().organizacion,
      );
      shouldSetState = true;
      if ((_model.loginResultCopy?.statusCode ?? 200).toString() == '200') {
        FFAppState().id = UserDataCall.idUser(
          (_model.userDataOutCopy?.jsonBody ?? ''),
        )!
            .toString();
        FFAppState().username = UserDataCall.userName(
          (_model.userDataOutCopy?.jsonBody ?? ''),
        )!;
        FFAppState().email = UserDataCall.email(
          (_model.userDataOutCopy?.jsonBody ?? ''),
        )!;
        FFAppState().fullName = UserDataCall.fullName(
          (_model.userDataOutCopy?.jsonBody ?? ''),
        )!;
        FFAppState().avatar = UserDataCall.avatar(
          (_model.userDataOutCopy?.jsonBody ?? ''),
        )!;

        try {
          NotificationSettings settings =
              await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) {
            String? pushToken = await FirebaseMessaging.instance.getToken();

            if (pushToken != null && pushToken.isNotEmpty) {
              await PatchUser.call(
                tenant: FFAppState().organizacion,
                token: FFAppState().token,
                pushToken: pushToken,
              );
            }

            functions.subscribeToOrganizacionTopic();
          } else {
            // Permiso de notificaciones denegado
          }
        } catch (e) {
          print('Error al obtener el token: $e');
        }

        FFAppState().role = UserDataCall.role(
          (_model.userDataOutCopy?.jsonBody ?? ''),
        )!;
        FFAppState().permissions = UserDataCall.permissions(
          (_model.userDataOutCopy?.jsonBody ?? ''),
        )!
            .toList()
            .cast<String>();

        final firmaFromApiCopy =
            UserDataCall.firma((_model.userDataOutCopy?.jsonBody ?? '')) ?? '';
        FFAppState().firma = functions.normalizeFirmaUrl(firmaFromApiCopy);
        setState(() {});
        await actions.permissionSearch(
          FFAppState().permissions.toList(),
        );

        // --- INICIO: Preguntar guardar credenciales (Demo) ---
        await _showSaveCredentialsDialog(
          username: 'SenseQuery',
          password: 'gp=cp6N+]o-EyRY??55H9',
        );
        // --- FIN: Preguntar guardar credenciales ---

        // Obtener custom home desde el endpoint dedicado (demo login)
        String? customPageName;
        try {
          final homeConfig = await fetchHomeConfig(
            FFAppState().organizacion,
            FFAppState().token,
          );
          if (homeConfig.replaceHome &&
              homeConfig.customPage != null &&
              homeConfig.customPage!.isNotEmpty) {
            customPageName = homeConfig.customPage;
          }
        } catch (e) {
          print('Error fetching home config: $e');
          customPageName = null;
        }

        // Guardar en AppState
        FFAppState().update(() {
          FFAppState().customHomePage = customPageName ?? '';
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pushNamed('home');
          }
        });
        setState(() {
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudieron obtener los detalles de tu cuenta, intentalo de nuevo.',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).white,
              ),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).tertiary,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }

      if (shouldSetState) {
        setState(() {});
      }
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Credenciales incorrectas',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).white,
            ),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).tertiary,
        ),
      );
      if (shouldSetState) {
        setState(() {});
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }
  }

  Future<void> _handleRegister() async {
    final result = await context.pushNamed(
      RegistrationUserScreen.routeName,
      queryParameters: {
        'publicRoles': serializeParam(
          allowedRoles,
          ParamType.JSON,
        ),
      },
    );

    debugPrint('[LOGIN] Resultado del registro: $result');

    if (result == null) return;

    if (result is Map) {
      debugPrint('[LOGIN] Map recibido: $result');
      _model.emailAddressLoginTextController.text =
          result['username'] ?? result['email'] ?? '';
      _model.passwordLoginTextController.text = result['password'] ?? '';
    }
  }

  Future<void> _showSaveCredentialsDialog({
    required String username,
    required String password,
  }) async {
    if (!mounted) return;

    final available = await _biometricAuth.isBiometricAvailable();
    if (!available) return;

    // Si el biométrico ya está activo, mantener las credenciales guardadas
    // sincronizadas con el último login manual exitoso. Si cambiaron (p. ej.
    // el usuario actualizó su contraseña o inició sesión con otra cuenta), se
    // actualizan en silencio para no dejar credenciales viejas en el Keychain.
    if (_hasSavedCredentials) {
      final saved = await _biometricAuth.getSavedCredentials();
      // saved == null significa que el biométrico fue desactivado externamente;
      // no lo re-activamos automáticamente.
      if (saved == null) return;
      final changed =
          saved['username'] != username || saved['password'] != password;
      if (changed) {
        await _biometricAuth.saveCredentials(
          username: username,
          password: password,
        );
      }
      return;
    }

    final shouldSave = await GlassSaveCredentialsDialog.show(context);
    if (shouldSave == true && mounted) {
      await _biometricAuth.saveCredentials(
        username: username,
        password: password,
      );
      setState(() => _hasSavedCredentials = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => _model.unfocusNode.canRequestFocus
            ? FocusScope.of(context).requestFocus(_model.unfocusNode)
            : FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background image + dark overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_bgUrl),
                  fit: BoxFit.cover,
                  alignment: const AlignmentDirectional(-0.4, 0.5),
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),

            // Sutil overlay de gradiente para profundidad
            const Positioned.fill(
              child: AnimatedBackground(),
            ),

            // Scrollable content
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
                              logoUrl: _logoUrl,
                              size: 120,
                              contentPaddingFactor: 0.10,
                            ),
                            const SizedBox(height: 36),

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
                                        'Iniciar sesión',
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
                                const SizedBox(height: 28),

                                // Username field
                                GlassTextField(
                                  controller:
                                      _model.emailAddressLoginTextController!,
                                  focusNode: _model.emailAddressLoginFocusNode!,
                                  labelText: 'Username',
                                  prefixIcon: Icons.person_outline,
                                  darkSurface: true,
                                  textInputAction: TextInputAction.next,
                                  validator: _model
                                      .emailAddressLoginTextControllerValidator
                                      .asValidator(context),
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(
                                      _model.passwordLoginFocusNode,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                GlassTextField(
                                  controller:
                                      _model.passwordLoginTextController!,
                                  focusNode: _model.passwordLoginFocusNode!,
                                  labelText: 'Contraseña',
                                  prefixIcon: Icons.lock_outline,
                                  darkSurface: true,
                                  obscureText: !_model.passwordLoginVisibility,
                                  suffixIcon: _EyeToggle(
                                    visible: _model.passwordLoginVisibility,
                                    onToggle: () => setState(() {
                                      _model.passwordLoginVisibility =
                                          !_model.passwordLoginVisibility;
                                    }),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  validator: _model
                                      .passwordLoginTextControllerValidator
                                      .asValidator(context),
                                  onFieldSubmitted: (_) => _handleLogin(),
                                ),
                                const SizedBox(height: 28),

                                // Login button
                                GlassButton(
                                  onPressed: _handleLogin,
                                  text: 'Iniciar sesión',
                                  isLoading: _isLoading,
                                  icon: Icons.login,
                                ),
                                const SizedBox(height: 20),

                                // Botón biométrico — siempre visible
                                if (!_isLoading) ...[
                                  const SizedBox(height: 12),
                                  GlassButton(
                                    onPressed: () async {
                                      final available = await _biometricAuth
                                          .isBiometricAvailable();
                                      if (!available) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'La biometría no está disponible en este dispositivo'),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .tertiary,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      final hasCreds = await _biometricAuth
                                          .hasSavedCredentials();
                                      if (!hasCreds) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'Inicia sesión manualmente primero para guardar tus credenciales'),
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .tertiary,
                                              duration: const Duration(
                                                  milliseconds: 3000),
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      final authenticated =
                                          await _biometricAuth.authenticate(
                                        reason: 'Inicia sesión rápidamente',
                                      );
                                      if (authenticated && mounted) {
                                        final creds = await _biometricAuth
                                            .getSavedCredentials();
                                        if (creds != null) {
                                          _model.emailAddressLoginTextController
                                              ?.text = creds['username']!;
                                          _model.passwordLoginTextController
                                              ?.text = creds['password']!;
                                          await _handleLogin();
                                        }
                                      }
                                    },
                                    text: 'Login con Face ID / Biometrico',
                                    isPrimary: false,
                                    icon: Icons.fingerprint,
                                  ),
                                  const SizedBox(height: 4),
                                ],

                                // Acceso secundario a la demo
                                Center(
                                  child: Semantics(
                                    button: true,
                                    label: 'Probar demo',
                                    child: InkWell(
                                      onTap: _handleDemo,
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          'Probar demo',
                                          style: const TextStyle(
                                            color: Color(0x99FFFFFF),
                                            fontFamily: 'Outfit',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            height: 1.1,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Register button (conditional)
                                if (publicRegisterEnabled) ...[
                                  const SizedBox(height: 16),
                                  GlassButton(
                                    onPressed: isLoadingPublicRoles
                                        ? null
                                        : _handleRegister,
                                    text: 'Registro de usuario',
                                    isPrimary: false,
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Back button
                                Center(
                                  child: GlassIconButton(
                                    icon: Icons.chevron_left,
                                    onTap: () => context
                                        .pushReplacementNamed('SplashScreen'),
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

            // Loader overlay
            if (_isLoading)
              LoaderImage(
                backgroundUrl: _bgUrl,
                loadingText: 'Iniciando sesión...',
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets helper privados ───────────────────────────────────────────────

/// Toggle de visibilidad de contraseña.
class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.visible, required this.onToggle});

  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: const Color(0xFF587484),
          size: 20,
        ),
      ),
    );
  }
}
