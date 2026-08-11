import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transport_app/backend/api_requests/api_calls.dart';
import 'package:transport_app/components/default_firma/default_firma_widget.dart';
import 'package:transport_app/components/default_firmaext/default_firmaext_widget.dart';
import 'package:transport_app/components/default_new_image/default_new_image_widget.dart';
import 'package:transport_app/components/default_text_field/default_text_field_widget.dart';
import 'package:transport_app/flutter_flow/flutter_flow_util.dart';
import 'package:signature/signature.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '../../app_state.dart';
import '../../components/page_components/screens_background/background_widget.dart';
import '../../components/pop_up_password/pop_up_password_widget.dart';
import '../../flutter_flow/custom_functions.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '/custom_code/BiometricAuthService.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../backend/api_requests/api_base_url.dart';
import '../../services/avatar_cache_service.dart';

class UserSettingsWidget extends StatefulWidget {
  const UserSettingsWidget({super.key});

  static String routeName = 'UserSettings';
  static String routePath = '/userSettings';

  @override
  State<UserSettingsWidget> createState() => _UserSettingsWidgetState();
}

class _UserSettingsWidgetState extends State<UserSettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  FFUploadedFile avatarController =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  TextControllerNotifier fullNameController = TextControllerNotifier('');
  TextControllerNotifier usernameController = TextControllerNotifier('');
  TextControllerNotifier emailController = TextControllerNotifier('');
  SignatureController firmaController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportPenColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final ValueNotifier<bool> canEditNotifier = ValueNotifier<bool>(false);
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    fullNameController = TextControllerNotifier(FFAppState().fullName);
    usernameController = TextControllerNotifier(FFAppState().username);
    emailController = TextControllerNotifier(FFAppState().email);
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await _biometricAuth.isBiometricAvailable();
    final enabled = await _biometricAuth.isEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> sendUserProfileUpdate({
    required String userId,
    required String fullName,
    required String username,
    required String email,
    required String token,
    required FFUploadedFile avatarController,
    required SignatureController firmaController,
  }) async {
    final uri = Uri.parse(ApiBaseUrl.forTenantCall(
        tenant: FFAppState().organizacion, apiPath: 'update-user/$userId/'));

    var request = http.MultipartRequest('PATCH', uri);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Campos normales
    request.fields['id'] = userId;
    request.fields['token'] = token;
    request.fields['full_name'] = fullName;
    request.fields['username'] = username;
    request.fields['email'] = email;

    final avatarBytes = avatarController.bytes;
    final previousAvatarUrl = buildMediaUrl(FFAppState().avatar);
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'avatar',
        avatarBytes,
        filename: 'avatar.png',
        contentType: MediaType('image', 'png'),
      ));
    }

    // Firma
    //final signatureBytes = await firmaController.toPngBytes();
    //final Uint8List? signatureBinary = await functions.getSignatureBinary(_signatureController);
    final Uint8List? signatureBytes = await getSignatureBinary(firmaController);
    if (signatureBytes != null && signatureBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'firma',
        signatureBytes,
        filename: 'firma.png',
        contentType: MediaType('image', 'png'),
      ));
    }

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseData);

        if (jsonResponse['firma'] != null) {
          String url = jsonResponse['firma'];
          String normalizedUrl = normalizeFirmaUrl(url);
          FFAppState().firma = normalizedUrl;
        }

        if (jsonResponse['avatar'] != null) {
          String url = jsonResponse['avatar'];
          String normalizedUrl = normalizeFirmaUrl(url);
          if (avatarBytes != null && avatarBytes.isNotEmpty) {
            await AvatarCacheService.evict(previousAvatarUrl);
            await AvatarCacheService.evict(buildMediaUrl(normalizedUrl));
          }
          FFAppState().avatar = normalizedUrl;
        }

        if (jsonResponse['full_name'] != null) {
          FFAppState().fullName = jsonResponse['full_name'];
        }

        if (jsonResponse['username'] != null) {
          FFAppState().username = jsonResponse['username'];
        }

        if (jsonResponse['email'] != null) {
          FFAppState().email = jsonResponse['email'];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Datos actualizados correctamente',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).white,
              ),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).secondary,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          context.pop();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudieron actualizar los datos',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).white,
              ),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron actualizar los datos.',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          duration: const Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bottomLeftColor = const Color(0xFFD7D7D7).withOpacity(0.98);
    Color topRightColor = FlutterFlowTheme.of(context).primary;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        iconTheme: IconThemeData(color: FlutterFlowTheme.of(context).primary),
        automaticallyImplyLeading: true,
        toolbarHeight: 74.0,
        title: Align(
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Pantalla',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Outfit',
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                    ),
              ),
              Text(
                'Editar perfil',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Outfit',
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              GestureDetector(
                onTap: () {
                  context.pushNamed('notificationsScreen');
                },
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 10.0, 5.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 30.0,
                      ),
                      if (FFAppState().unreadNotifications > 0)
                        Positioned(
                          right: -4.0,
                          top: -2.0,
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                              color: Colors.red, // Color del contador
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18.0,
                              minHeight: 18.0,
                            ),
                            child: Text(
                              FFAppState().unreadNotifications.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
        centerTitle: true,
        elevation: 1.0,
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
          valueListenable: canEditNotifier,
          builder: (context, canEdit, child) {
            return Stack(children: [
              Positioned(
                bottom: 0,
                right: 0,
                child: FloatingActionButton(
                  onPressed: () async {
                    if (!canEdit) canEditNotifier.value = !canEdit;

                    if (canEdit) {
                      sendUserProfileUpdate(
                        token: FFAppState().token,
                        userId: FFAppState().id,
                        fullName: fullNameController.value,
                        username: usernameController.value,
                        email: emailController.value,
                        avatarController: avatarController,
                        firmaController: firmaController,
                      );
                    }
                  },
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  elevation: 8.0,
                  child: Icon(
                    canEdit ? Icons.check : Icons.edit_outlined,
                    color: FlutterFlowTheme.of(context).white,
                    size: 28.0,
                  ),
                ),
              ),
              if (canEdit)
                Positioned(
                    bottom: 60,
                    right: 0,
                    child: FloatingActionButton(
                      onPressed: () async {
                        canEditNotifier.value = !canEdit;
                      },
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      elevation: 8.0,
                      child: Icon(
                        Icons.clear,
                        color: FlutterFlowTheme.of(context).white,
                        size: 28.0,
                      ),
                    )),
              Positioned(
                bottom: 0,
                right: 60,
                child: FloatingActionButton(
                  onPressed: () async {
                    await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (dialogContext) {
                          return Dialog(
                            elevation: 0,
                            insetPadding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            alignment: AlignmentDirectional(0.0, 0.0)
                                .resolve(Directionality.of(context)),
                            child: WebViewAware(
                              child: GestureDetector(
                                  onTap: () {
                                    FocusScope.of(dialogContext).unfocus();
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  child: PopUpPasswordWidget()),
                            ),
                          );
                        });
                  },
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  elevation: 8.0,
                  child: Icon(
                    Icons.key_outlined,
                    color: FlutterFlowTheme.of(context).white,
                    size: 28.0,
                  ),
                ),
              ),
            ]);
          }),
      body: SafeArea(
        top: true,
        child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                DynamicBackground(
                  bottomLeftColor: bottomLeftColor,
                  topRightColor: topRightColor,
                ),
                SingleChildScrollView(
                    primary: true,
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.9,
                        child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              ValueListenableBuilder<bool>(
                                  valueListenable: canEditNotifier,
                                  builder: (context, canEdit, child) {
                                    return Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.65,
                                        padding: const EdgeInsets.all(2.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            width: 3.0,
                                          ),
                                        ),
                                        child: DefaultNewImageWidget(
                                            text: FFAppState().avatar,
                                            isEdit: canEdit,
                                            controller: avatarController,
                                            watermarkUser:
                                                FFAppState().fullName,
                                            watermarkModule:
                                                'Ajustes de usuario',
                                            onFileSelected: (selectedFile) {
                                              setState(() {
                                                avatarController = selectedFile;
                                              });
                                            }));
                                  }),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                width: MediaQuery.of(context).size.width * 1.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: BorderRadius.circular(10.0),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 10.0,
                                      color: Color(0x33000000),
                                      offset: Offset(
                                        1.0,
                                        1.0,
                                      ),
                                      spreadRadius: 1.0,
                                    )
                                  ],
                                ),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: canEditNotifier,
                                  builder: (context, canEdit, child) {
                                    return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 0, horizontal: 16),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Nombre completo',
                                                    textAlign: TextAlign.start,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Outfit',
                                                          letterSpacing: 0.0,
                                                          fontSize: 16,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  DefaultTextFieldWidget(
                                                      text: 'Nombre completo',
                                                      isEdit: canEdit,
                                                      controllerNotifier:
                                                          fullNameController,
                                                      type: 'text',
                                                      slug: ''),
                                                  const SizedBox(height: 16),
                                                ]),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 0, horizontal: 16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Correo electronico',
                                                  textAlign: TextAlign.start,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        letterSpacing: 0.0,
                                                        fontSize: 16,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                      ),
                                                ),
                                                const SizedBox(height: 1),
                                                DefaultTextFieldWidget(
                                                    text: 'Correo electronico',
                                                    isEdit: canEdit,
                                                    controllerNotifier:
                                                        emailController,
                                                    type: 'text',
                                                    slug: ''),
                                                const SizedBox(height: 16),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 0, horizontal: 16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Usuario',
                                                  textAlign: TextAlign.start,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        letterSpacing: 0.0,
                                                        fontSize: 16,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                      ),
                                                ),
                                                const SizedBox(height: 1),
                                                DefaultTextFieldWidget(
                                                    text: 'Usuario',
                                                    isEdit: canEdit,
                                                    controllerNotifier:
                                                        usernameController,
                                                    type: 'text',
                                                    slug: ''),
                                                const SizedBox(height: 16),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 0, horizontal: 16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Firma',
                                                  textAlign: TextAlign.start,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        letterSpacing: 0.0,
                                                        fontSize: 16,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                      ),
                                                ),
                                                const SizedBox(height: 5),
                                                DefaultFirmaExt(
                                                  controller: firmaController,
                                                  isEdit: canEdit,
                                                  text:
                                                      FFAppState().firma ?? '',
                                                  height: double.infinity,
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                              .width *
                                                          1,
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            ),
                                          ),
                                          if (_biometricAvailable)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Divider(),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.fingerprint,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Inicio de sesión biométrico',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    fontFamily:
                                                                        'Outfit',
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontSize:
                                                                        16,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primaryText,
                                                                  ),
                                                            ),
                                                            Text(
                                                              'Usa Face ID o huella para acceder rápidamente',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmall
                                                                  .override(
                                                                    fontFamily:
                                                                        'Outfit',
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontSize:
                                                                        12,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Switch(
                                                        value:
                                                            _biometricEnabled,
                                                        activeThumbColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        onChanged:
                                                            (value) async {
                                                          if (value) {
                                                            // Activar
                                                            final username =
                                                                FFAppState()
                                                                    .loginUser;
                                                            final password =
                                                                FFAppState()
                                                                    .loginPassword;
                                                            if (username
                                                                    .isNotEmpty &&
                                                                password
                                                                    .isNotEmpty) {
                                                              await _biometricAuth
                                                                  .saveCredentials(
                                                                username:
                                                                    username,
                                                                password:
                                                                    password,
                                                              );
                                                              setState(() {
                                                                _biometricEnabled =
                                                                    true;
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Inicio de sesión biométrico activado',
                                                                    style:
                                                                        TextStyle(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondary,
                                                                ),
                                                              );
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Cierra sesión e inicia nuevamente para activar',
                                                                    style:
                                                                        TextStyle(
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                  backgroundColor:
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .error,
                                                                ),
                                                              );
                                                            }
                                                          } else {
                                                            // Desactivar
                                                            await _biometricAuth
                                                                .clearCredentials();
                                                            setState(() {
                                                              _biometricEnabled =
                                                                  false;
                                                            });
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Inicio de sesión biométrico desactivado',
                                                                  style:
                                                                      TextStyle(
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .white,
                                                                  ),
                                                                ),
                                                                backgroundColor:
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondary,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                ],
                                              ),
                                            ),
                                        ]
                                            .addToStart(
                                                const SizedBox(height: 30))
                                            .addToEnd(
                                                const SizedBox(height: 10)));
                                  },
                                ),
                              ),
                            ]
                                .addToStart(const SizedBox(height: 30))
                                .divide(const SizedBox(height: 20))
                                .addToEnd(const SizedBox(height: 80))),
                      ),
                    ))
              ],
            )),
      ),
    );
  }
}
