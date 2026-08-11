import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'login_clientes_model.dart';
export 'login_clientes_model.dart';

class LoginClientesWidget extends StatefulWidget {
  const LoginClientesWidget({super.key});

  @override
  State<LoginClientesWidget> createState() => _LoginClientesWidgetState();
}

class _LoginClientesWidgetState extends State<LoginClientesWidget>
    with TickerProviderStateMixin {
  late LoginClientesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginClientesModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 1,
      initialIndex: 0,
    )..addListener(() => setState(() {}));
    _model.clientIdTextController ??= TextEditingController();
    _model.clientIdFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF14181B),
        body: Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          height: MediaQuery.sizeOf(context).height * 1.0,
          decoration: BoxDecoration(
            color: const Color(0xFF14181B),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: Image.network(
                'https://sense-digital.co/wp-content/uploads/Diseno-sin-titulo-27-1024x512.png',
              ).image,
            ),
          ),
          child: Container(
            width: 100.0,
            height: 100.0,
            decoration: BoxDecoration(
              color: const Color(0x990F1113),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: Image.network(
                  '',
                ).image,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 70.0, 0.0, 20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://sense-digital.co/wp-content/uploads/Diseno-sin-titulo-27-1024x512.png',
                          width: 200.0,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 500.0,
                    decoration: const BoxDecoration(),
                    child: Padding(
                      padding:
                      const EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                      child: Column(
                        children: [
                          Align(
                            alignment: const Alignment(0.0, 0),
                            child: TabBar(
                              isScrollable: true,
                              labelColor: Colors.white,
                              labelStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                fontFamily: 'Outfit',
                                color: const Color(0xFF0F1113),
                                fontSize: 15.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w500,
                              ),
                              unselectedLabelStyle: const TextStyle(),
                              indicatorColor: Colors.white,
                              tabs: const [
                                Tab(
                                  text: 'Consultar',
                                ),
                              ],
                              controller: _model.tabBarController,
                              onTap: (i) async {
                                [() async {}][i]();
                              },
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _model.tabBarController,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      44.0, 20.0, 44.0, 0.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 20.0, 0.0, 0.0),
                                        child: TextFormField(
                                          controller:
                                          _model.clientIdTextController,
                                          focusNode: _model.clientIdFocusNode,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            labelText: 'Id de cliente',
                                            labelStyle:
                                            FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                              fontFamily: 'Lexend Deca',
                                              color: Colors.white,
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                              FontWeight.normal,
                                            ),
                                            hintStyle:
                                            FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                              fontFamily: 'Lexend Deca',
                                              color: const Color(0xFF95A1AC),
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                              FontWeight.normal,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                              BorderRadius.circular(8.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                              BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                              BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                            OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Color(0x00000000),
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                              BorderRadius.circular(8.0),
                                            ),
                                            filled: true,
                                            fillColor: const Color(0x3EFFFFFF),
                                            contentPadding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                20.0, 24.0, 20.0, 24.0),
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .titleSmall
                                              .override(
                                            fontFamily: 'Outfit',
                                            color: Colors.white,
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          maxLines: null,
                                          keyboardType: TextInputType.number,
                                          validator: _model
                                              .clientIdTextControllerValidator
                                              .asValidator(context),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 24.0, 0.0, 0.0),
                                        child: FFButtonWidget(
                                          onPressed: () async {
                                            var shouldSetState = false;
                                            if (_model.clientIdTextController
                                                .text !=
                                                '') {
                                              _model.clientSheetsObject =
                                              await TestSheetsCall.call(
                                                filter: '[idCliente]',
                                                valueFiltered: _model
                                                    .clientIdTextController
                                                    .text,
                                              );
                                              shouldSetState = true;
                                              if (TestSheetsCall.general(
                                                (_model.clientSheetsObject
                                                    ?.jsonBody ??
                                                    ''),
                                              )!.isNotEmpty) {
                                                context.pushNamed(
                                                  'homeClient',
                                                  queryParameters: {
                                                    'userId': serializeParam(
                                                      _model
                                                          .clientIdTextController
                                                          .text,
                                                      ParamType.String,
                                                    ),
                                                  }.withoutNulls,
                                                );

                                                FFAppState().clientId = _model
                                                    .clientIdTextController
                                                    .text;
                                                FFAppState().clienteEquipo =
                                                    valueOrDefault<String>(
                                                      getJsonField(
                                                        TestSheetsCall.general(
                                                          (_model.clientSheetsObject
                                                              ?.jsonBody ??
                                                              ''),
                                                        )?.first,
                                                        r'''$.cliente''',
                                                      )?.toString(),
                                                      'No data',
                                                    );
                                                if (shouldSetState) {
                                                  setState(() {});
                                                }
                                                return;
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'No hay resultados con ese ID',
                                                      style: TextStyle(
                                                        color:
                                                        FlutterFlowTheme.of(
                                                            context)
                                                            .accent1,
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
                                                if (shouldSetState) {
                                                  setState(() {});
                                                }
                                                return;
                                              }
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'No hay resultados con ese ID',
                                                    style: TextStyle(
                                                      color:
                                                      FlutterFlowTheme.of(
                                                          context)
                                                          .accent1,
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
                                              if (shouldSetState) {
                                                setState(() {});
                                              }
                                              return;
                                            }

                                            if (shouldSetState) {
                                              setState(() {});
                                            }
                                          },
                                          text: 'Consultar',
                                          options: FFButtonOptions(
                                            width: 230.0,
                                            height: 50.0,
                                            padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                            iconPadding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                                0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .companyColor,
                                            textStyle:
                                            FlutterFlowTheme.of(context)
                                                .titleSmall
                                                .override(
                                              fontFamily: 'Lexend Deca',
                                              color: Colors.white,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                              FontWeight.normal,
                                            ),
                                            elevation: 3.0,
                                            borderSide: const BorderSide(
                                              color: Colors.transparent,
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 20.0, 0.0, 0.0),
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            var shouldSetState = false;
                                            _model.clientSheetsObjectCopy =
                                            await TestSheetsCall.call(
                                              filter: '[idCliente]',
                                              valueFiltered: '2858751',
                                            );
                                            shouldSetState = true;
                                            if ((_model.clientSheetsObjectCopy
                                                ?.succeeded ??
                                                true)) {
                                              context.pushNamed(
                                                'homeClient',
                                                queryParameters: {
                                                  'userId': serializeParam(
                                                    '2858751',
                                                    ParamType.String,
                                                  ),
                                                }.withoutNulls,
                                              );

                                              FFAppState().clientId = '2858751';
                                              FFAppState().clienteEquipo =
                                                  valueOrDefault<String>(
                                                    getJsonField(
                                                      TestSheetsCall.general(
                                                        (_model.clientSheetsObjectCopy
                                                            ?.jsonBody ??
                                                            ''),
                                                      )?.first,
                                                      r'''$.cliente''',
                                                    )?.toString(),
                                                    'No data',
                                                  );
                                              if (shouldSetState) {
                                                setState(() {});
                                              }
                                              return;
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'No hay resultados con ese ID',
                                                    style: TextStyle(
                                                      color:
                                                      FlutterFlowTheme.of(
                                                          context)
                                                          .accent1,
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
                                              if (shouldSetState) {
                                                setState(() {});
                                              }
                                              return;
                                            }

                                            if (shouldSetState) {
                                              setState(() {});
                                            }
                                          },
                                          child: Text(
                                            'Probar Demo',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                              fontFamily: 'Outfit',
                                              color: FlutterFlowTheme.of(
                                                  context)
                                                  .white,
                                              letterSpacing: 0.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 20.0, 0.0, 0.0),
                                        child: InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () async {
                                            var shouldSetState = false;
                                            _model.clientSheetsObjectCopy =
                                            await TestSheetsCall.call(
                                              filter: '[idCliente]',
                                              valueFiltered: '2858751',
                                            );
                                            shouldSetState = true;
                                            if ((_model.clientSheetsObjectCopy
                                                ?.succeeded ??
                                                true)) {
                                              context.pushNamed(
                                                'homeClient',
                                                queryParameters: {
                                                  'userId': serializeParam(
                                                    '2858751',
                                                    ParamType.String,
                                                  ),
                                                }.withoutNulls,
                                              );

                                              FFAppState().clientId = '2858751';
                                              FFAppState().clienteEquipo =
                                                  valueOrDefault<String>(
                                                    getJsonField(
                                                      TestSheetsCall.general(
                                                        (_model.clientSheetsObjectCopy
                                                            ?.jsonBody ??
                                                            ''),
                                                      )?.first,
                                                      r'''$.cliente''',
                                                    )?.toString(),
                                                    'No data',
                                                  );
                                              if (shouldSetState) {
                                                setState(() {});
                                              }
                                              return;
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'No hay resultados con ese ID',
                                                    style: TextStyle(
                                                      color:
                                                      FlutterFlowTheme.of(
                                                          context)
                                                          .accent1,
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
                                              if (shouldSetState) {
                                                setState(() {});
                                              }
                                              return;
                                            }

                                            if (shouldSetState) {
                                              setState(() {});
                                            }
                                          },
                                          child: Text(
                                            'Probar Demo',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                              fontFamily: 'Outfit',
                                              color: FlutterFlowTheme.of(
                                                  context)
                                                  .white,
                                              letterSpacing: 0.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment:
                                        const AlignmentDirectional(0.0, 1.0),
                                        child: Padding(
                                          padding:
                                          const EdgeInsetsDirectional.fromSTEB(
                                              0.0, 20.0, 0.0, 0.0),
                                          child: Container(
                                            width: 39.0,
                                            height: 39.0,
                                            decoration: const BoxDecoration(
                                              color: Color(0x30E5E8EB),
                                              shape: BoxShape.circle,
                                            ),
                                            child: InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                              Colors.transparent,
                                              onTap: () async {
                                                context.goNamed('SplashScreen');
                                              },
                                              child: Icon(
                                                Icons.chevron_left,
                                                color:
                                                FlutterFlowTheme.of(context)
                                                    .white,
                                                size: 30.0,
                                              ),
                                            ),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
