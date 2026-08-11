import 'package:transport_app/components/default_text_field/default_text_field_widget.dart';

import '../../backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_web_view.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';

class PopUpPasswordWidget extends StatefulWidget {
  const PopUpPasswordWidget({
    super.key,
  });

  @override
  State<PopUpPasswordWidget> createState() => _PopUpPasswordWidgetState();
}

class _PopUpPasswordWidgetState extends State<PopUpPasswordWidget> {

  TextControllerNotifier passwordController = TextControllerNotifier('');
  TextControllerNotifier passwordConfirmController = TextControllerNotifier('');

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const AlignmentDirectional(0.0, 0.0),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.85,
        height: MediaQuery.sizeOf(context).height * 0.55,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary,
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                'Cambiar contraseña',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).primaryText,
                  letterSpacing: 0.0,
                  fontSize: 22.0,
                ),
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.47,
                width: MediaQuery.sizeOf(context).width * 1,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: FlutterFlowTheme.of(context).primaryBackground,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contraseña',
                                textAlign: TextAlign.start,
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0.0,
                                  fontSize: 16,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              const SizedBox(height: 1),
                              DefaultTextFieldWidget(
                                  text: 'Contraseña',
                                  isEdit: true,
                                  controllerNotifier:passwordController,
                                  type: 'text',
                                  slug: ''
                              ),
                            ]
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: FlutterFlowTheme.of(context).primaryBackground,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirmar contraseña',
                                textAlign: TextAlign.start,
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0.0,
                                  fontSize: 16,
                                  color: FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              const SizedBox(height: 1),
                              DefaultTextFieldWidget(
                                  text: 'Confirmar contraseña',
                                  isEdit: true,
                                  controllerNotifier: passwordConfirmController,
                                  type: 'text',
                                  slug: ''
                              ),
                            ]
                        ),
                      ),
                    ),
                    FFButtonWidget(
                      onPressed: () async {

                        if (passwordController.value.isEmpty || passwordConfirmController.value.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'Debe rellenar ambas contraseñas',
                                style: TextStyle(
                                  color:
                                  FlutterFlowTheme.of(
                                      context)
                                      .white,
                                ),
                              ),
                              duration: const Duration(
                                  milliseconds: 4000),
                              backgroundColor:
                              FlutterFlowTheme.of(
                                  context)
                                  .error,
                            ),
                          );
                          return;
                        }

                        if (passwordController.value != passwordConfirmController.value) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'Las contraseñas no coinciden',
                                style: TextStyle(
                                  color:
                                  FlutterFlowTheme.of(
                                      context)
                                      .white,
                                ),
                              ),
                              duration: const Duration(
                                  milliseconds: 4000),
                              backgroundColor:
                              FlutterFlowTheme.of(
                                  context)
                                  .error,
                            ),
                          );
                          return;
                        }

                        final password = passwordConfirmController.value;
                        final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~.,;:_\-])[^\s]{8,}$');

                        if (!passwordRegex.hasMatch(password)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'La contraseña debe tener al menos 8 caracteres, una mayúscula, un número, un caracter especial y no debe contener espacios o saltos de línea.',
                                style: TextStyle(
                                  color: FlutterFlowTheme.of(context).white,
                                ),
                              ),
                              duration: const Duration(milliseconds: 4000),
                              backgroundColor: FlutterFlowTheme.of(context).error,
                            ),
                          );
                          return;
                        }

                        ApiCallResponse? response = await ChangePassword.call(
                          id: FFAppState().id,
                          password: password,
                          token: FFAppState().token,
                        );

                        if (response.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Contraseña actualizada',
                                style: TextStyle(
                                  color: FlutterFlowTheme.of(context).white,
                                ),
                              ),
                              duration: const Duration(milliseconds: 4000),
                              backgroundColor: FlutterFlowTheme.of(context).success,
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No se pudo actualizar la contraseña',
                                style: TextStyle(
                                  color: FlutterFlowTheme.of(context).white,
                                ),
                              ),
                              duration: const Duration(milliseconds: 4000),
                              backgroundColor: FlutterFlowTheme.of(context).error,
                            ),
                          );
                        }

                      },
                      text: 'Aceptar',
                      options: FFButtonOptions(
                        width: MediaQuery.sizeOf(context).width * 0.65,
                        height: 40.0,
                        padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                        iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Readex Pro',
                          color: Colors.white,
                          letterSpacing: 0.0,
                        ),
                        elevation: 3.0,
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    FFButtonWidget(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      text: 'Cancelar',
                      options: FFButtonOptions(
                        width: MediaQuery.sizeOf(context).width * 0.65,
                        height: 40.0,
                        padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                        iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Readex Pro',
                          color: FlutterFlowTheme.of(context).primary,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 3.0,
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),


                  ].divide(const SizedBox(height: 10.0)),
                ),
              ),
            ].addToStart(const SizedBox(height: 15.0)),
          ),
        ),
      ),
    );
  }
}
