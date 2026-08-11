import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
import 'package:octo_image/octo_image.dart';
import 'package:transport_app/components/default_firmaext/default_firmaext_widget.dart';
import 'package:signature/signature.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/custom_code/BiometricAuthService.dart';

import '../../app_state.dart';
import '../../backend/api_requests/api_base_url.dart';
import '../../flutter_flow/custom_functions.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class UploadSignWidget extends StatefulWidget {
  const UploadSignWidget({Key? key}) : super(key: key);

  @override
  _UploadSignWidgetState createState() => _UploadSignWidgetState();
}

class _UploadSignWidgetState extends State<UploadSignWidget> {

  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();

    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportPenColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

  }

  Future<void> sendSignatureFile() async {

    final Uint8List? signatureBinary = await functions.getSignatureBinary(_signatureController);

    if (signatureBinary == null) {
      return;
    }

    final userId = FFAppState().id;
    final token = FFAppState().token;
    final org = FFAppState().organizacion;

    if (userId.isEmpty || token.isEmpty || org.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No pudo ser firmado'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }

    final url = ApiBaseUrl.forTenantCall(tenant: org, apiPath: 'update-user/$userId/');

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse(url),
    );

    /// ✅ HEADER CORRECTO
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    request.fields['userID'] = userId;
    request.fields['token'] = token;

    request.files.add(
      http.MultipartFile.fromBytes(
        'firma',
        signatureBinary,
        filename: 'signature.png',
        contentType: MediaType('image', 'png'),
      ),
    );

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final dynamic json = body.isNotEmpty ? jsonDecode(body) : <String, dynamic>{};
        final firmaUrl =
            json is Map<String, dynamic> && json['firma'] is String
                ? json['firma'] as String
                : '';

        FFAppState().firma = normalizeFirmaUrl(firmaUrl);
        _signatureController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Firmado exitosamente',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).white,
              ),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );

        context.goNamed('home');
      } else {
        debugPrint(
          'UploadSignWidget.sendSignatureFile status=${response.statusCode} body=$body',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No pudo ser firmado'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('UploadSignWidget.sendSignatureFile exception: $e');
      debugPrintStack(stackTrace: st);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No pudo ser firmado'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        //key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primary,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 280.0, 0.0, 0.0),
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 200.0, 0.0, 0.0),
                          child: Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Container(
                        width: 100.0,
                        height: 330.0,
                        decoration: BoxDecoration(
                          color:
                          FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(0.0),
                            bottomRight: Radius.circular(50.0),
                            topLeft: Radius.circular(0.0),
                            topRight: Radius.circular(0.0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 50.0, 16.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OctoImage(
                                placeholderBuilder: (_) => SizedBox.expand(
                                  child: Image(
                                    image: BlurHashImage('L9I5f1wf00~q-Vk;aKoL00we0000'),
                                    fit: BoxFit.cover,

                                  ),
                                ),
                                image: NetworkImage(
                                  'https://query.itsquery.com/mediafiles/misc/queryLogoWhite.png'
                                //   (FFAppState().logoLink == '')
                                //       ? 'https://query.itsquery.com/mediafiles/misc/queryLogoWhite.png'
                                //       : FFAppState().logoLink,
                                ),
                                width: 200,
                                height: 200,
                                color: FlutterFlowTheme.of(context).primary,
                                fit: BoxFit.fitWidth,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                      const EdgeInsetsDirectional.fromSTEB(0.0, 330.0, 0.0, 0.0),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(0.0),
                            bottomRight: Radius.circular(0.0),
                            topLeft: Radius.circular(50.0),
                            topRight: Radius.circular(0.0),
                          ),
                        ),
                        child: Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                25.0, 70.0, 25.0, 32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Form(
                                  //key: _model.formKey,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            'Carga tu firma en tu perfil:',
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                              fontFamily: 'Readex Pro',
                                              letterSpacing: 0.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 10.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: FlutterFlowTheme.of(context).primary,
                                                ),
                                                borderRadius: BorderRadius.circular(12.0),
                                              ),
                                              width: MediaQuery.sizeOf(context).width * 1.0,
                                              height: 200.0,
                                              child: Stack(
                                                children: [

                                                  //if (editSign)
                                                    Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color: FlutterFlowTheme.of(context).primary,
                                                              width: 2
                                                          ),
                                                          borderRadius: BorderRadius.circular(8.0),

                                                        ),
                                                        width: MediaQuery.sizeOf(context).width * 1.0,
                                                        height: 200.0,
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(12),
                                                          child: ClipRect(
                                                            child: Signature(
                                                              controller: _signatureController,
                                                              backgroundColor: Colors.white,
                                                              height: 200,
                                                              width: MediaQuery.sizeOf(context).width * 1.0,
                                                            ),
                                                          ),
                                                        )
                                                    ),

                                                  //if (editSign)
                                                    Positioned(
                                                      right: 10.0,
                                                      top: 10.0,
                                                      child: Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(50),
                                                          color: FlutterFlowTheme.of(context).secondaryBackground,
                                                        ),
                                                        child: IconButton(
                                                          icon: Icon(
                                                              Icons.delete_outlined,
                                                              color: Colors.red
                                                          ),
                                                          onPressed: () async {
                                                            _signatureController.clear();
                                                          },
                                                        ),
                                                      ),
                                                    ),

                                                ],
                                              ),
                                            ),
                                          ),

                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 16.0),
                                        child: FFButtonWidget(
                                          onPressed: () async {
                                            if (functions.isSignatureEmpty(_signatureController)) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Proporciona una firma antes de enviarla',
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
                                            } else {
                                              await sendSignatureFile();
                                            }
                                          },
                                          text: 'Cargar mi firma',
                                          options: FFButtonOptions(
                                            width: double.infinity,
                                            height: 44.0,
                                            padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                            iconPadding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            textStyle:
                                            FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                              fontFamily: 'Readex Pro',
                                              color:
                                              FlutterFlowTheme.of(
                                                  context)
                                                  .primary,
                                              letterSpacing: 0.0,
                                            ),
                                            elevation: 3.0,
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                            BorderRadius.circular(12.0),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 16.0),
                                        child: FFButtonWidget(
                                          onPressed: () {
                                            FFAppState().clienteEquipo = '';
                                            FFAppState().token = '';
                                            FFAppState().refreshToken = '';
                                            FFAppState().loginUser = '';
                                            FFAppState().loginPassword = '';
                                            FFAppState().id = '';
                                            FFAppState().clientId = '';
                                            FFAppState().permissions.clear();
                                            FFAppState().modulesPermissions.clear();
                                            FFAppState().recientes.clear();
                                            //FFAppState().firma = '';
                                            FFAppState().role = '';
                                            FFAppState().textoControlador.clear();
                                            FFAppState().fullName = '';
                                            FFAppState().username = '';
                                            FFAppState().email = '';
                                            FFAppState().avatar = '';
                                            FFAppState().shortname = '';
                                            context.pushReplacementNamed('LoginEquipo');
                                          },
                                          text: 'Cerrar sesión',
                                          options: FFButtonOptions(
                                            width: double.infinity,
                                            height: 44.0,
                                            padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                            iconPadding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            textStyle:
                                            FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                              fontFamily: 'Readex Pro',
                                              color:
                                              FlutterFlowTheme.of(
                                                  context)
                                                  .primary,
                                              letterSpacing: 0.0,
                                            ),
                                            elevation: 3.0,
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                            BorderRadius.circular(12.0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
