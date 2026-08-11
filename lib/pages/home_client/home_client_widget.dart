import 'package:transport_app/pages/chat_mode/widgets/chat_mode_toggle_button.dart';
import '/backend/api_requests/api_calls.dart';
import '/components/empty_component/empty_component_widget.dart';
import '/components/loading_card/loading_card_widget.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/services/home_initialization_service.dart';
import 'home_client_model.dart';
export 'home_client_model.dart';

class HomeClientWidget extends StatefulWidget {
  const HomeClientWidget({
    super.key,
    required this.userId,
  });

  final String? userId;

  @override
  State<HomeClientWidget> createState() => _HomeClientWidgetState();
}

class _HomeClientWidgetState extends State<HomeClientWidget> {
  late HomeClientModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeClientModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HomeInitializationService.runPostLoginChecks(context);
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFE5E8EB),
      drawer: Drawer(
        elevation: 16.0,
        child: WebViewAware(
          child: wrapWithModel(
            model: _model.sideNavModel,
            updateCallback: () => setState(() {}),
            child: const SideNavWidget(),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        iconTheme:
            IconThemeData(color: FlutterFlowTheme.of(context).companyColor),
        automaticallyImplyLeading: false,
        leadingWidth: 96.0,
        leading: ChatModeLeading(scaffoldKey: scaffoldKey),
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
                'Home',
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
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(5.0, 5.0, 5.0, 5.0),
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).companyColor,
                    shape: BoxShape.circle,
                  ),
                  child: Align(
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: Text(
                      '${(String var1) {
                        return var1[0];
                      }(valueOrDefault<String>(
                        FFAppState().clienteEquipo,
                        'No data',
                      ))}${(String var1) {
                        return var1.split(' ')[1][0];
                      }(valueOrDefault<String>(
                        FFAppState().clienteEquipo,
                        'No data',
                      ))}',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Outfit',
                            color: FlutterFlowTheme.of(context).white,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        centerTitle: true,
        elevation: 1.0,
      ),
      body: SafeArea(
        top: true,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(30.0, 0.0, 30.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    decoration: const BoxDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: const AlignmentDirectional(1.0, 0.0),
                          child: CachedNetworkImage(
                            fadeInDuration: const Duration(milliseconds: 3000),
                            fadeOutDuration: const Duration(milliseconds: 3000),
                            imageUrl:
                                'https://sense-digital.co/wp-content/uploads/Diseno-sin-titulo-27-1024x512.png',
                            width: 100.0,
                            fit: BoxFit.cover,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: MediaQuery.sizeOf(context).width * 0.4,
                          decoration: const BoxDecoration(),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Align(
                                alignment: const AlignmentDirectional(1.0, 0.0),
                                child: Text(
                                  'Bienvenido',
                                  textAlign: TextAlign.end,
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        fontFamily: 'Outfit',
                                        letterSpacing: 0.0,
                                      ),
                                ),
                              ),
                              Text(
                                valueOrDefault<String>(
                                  FFAppState().clienteEquipo,
                                  'No data',
                                ),
                                textAlign: TextAlign.end,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Outfit',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              Text(
                                'Tu id de cliente es : ${valueOrDefault<String>(
                                  widget.userId,
                                  'No data',
                                )}',
                                textAlign: TextAlign.end,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Outfit',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(30.0, 0.0, 0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    decoration: const BoxDecoration(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(30.0, 0.0, 0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    decoration: const BoxDecoration(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(30.0, 20.0, 0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    decoration: const BoxDecoration(),
                    child: Text(
                      'Proyectos',
                      style:
                          FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'Outfit',
                                letterSpacing: 0.0,
                              ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(),
                  child: FutureBuilder<ApiCallResponse>(
                    future: TestSheetsCall.call(
                      filter: '[idCliente]',
                      valueFiltered: widget.userId,
                    ),
                    builder: (context, snapshot) {
                      // Customize what your widget looks like when it's loading.
                      if (!snapshot.hasData) {
                        return SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.8,
                          height: 300.0,
                          child: const LoadingCardWidget(),
                        );
                      }
                      final listViewTestSheetsResponse = snapshot.data!;
                      return Builder(
                        builder: (context) {
                          final projects = TestSheetsCall.dealId(
                                listViewTestSheetsResponse.jsonBody,
                              )?.toList() ??
                              [];
                          if (projects.isEmpty) {
                            return const SizedBox(
                              height: 200.0,
                              child: EmptyComponentWidget(),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              10.0,
                              0,
                              30.0,
                            ),
                            primary: false,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: projects.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                            itemBuilder: (context, projectsIndex) {
                              final projectsItem = projects[projectsIndex];
                              return Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    30.0, 0.0, 30.0, 0.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    context.pushNamed(
                                      'detailSense',
                                      queryParameters: {
                                        'title': serializeParam(
                                          valueOrDefault<String>(
                                            (TestSheetsCall.dealId(
                                              listViewTestSheetsResponse
                                                  .jsonBody,
                                            )?[projectsIndex])
                                                ?.toString(),
                                            'No data',
                                          ),
                                          ParamType.String,
                                        ),
                                        'body': serializeParam(
                                          valueOrDefault<String>(
                                            TestSheetsCall.producto(
                                              listViewTestSheetsResponse
                                                  .jsonBody,
                                            )?[projectsIndex],
                                            'No data',
                                          ),
                                          ParamType.String,
                                        ),
                                        'general': serializeParam(
                                          TestSheetsCall.general(
                                            listViewTestSheetsResponse.jsonBody,
                                          )?[projectsIndex],
                                          ParamType.JSON,
                                        ),
                                        'precio': serializeParam(
                                          valueOrDefault<int>(
                                            TestSheetsCall.precio(
                                              listViewTestSheetsResponse
                                                  .jsonBody,
                                            )?[projectsIndex],
                                            0,
                                          ),
                                          ParamType.int,
                                        ),
                                        'anticipo': serializeParam(
                                          valueOrDefault<int>(
                                            TestSheetsCall.anticipo(
                                              listViewTestSheetsResponse
                                                  .jsonBody,
                                            )?[projectsIndex],
                                            0,
                                          ),
                                          ParamType.int,
                                        ),
                                        'saldo': serializeParam(
                                          valueOrDefault<int>(
                                            TestSheetsCall.saldo(
                                              listViewTestSheetsResponse
                                                  .jsonBody,
                                            )?[projectsIndex],
                                            0,
                                          ),
                                          ParamType.int,
                                        ),
                                        'avance': serializeParam(
                                          valueOrDefault<double>(
                                            getJsonField(
                                              TestSheetsCall.general(
                                                listViewTestSheetsResponse
                                                    .jsonBody,
                                              )?[projectsIndex],
                                              r'''$["%AvanceProduccion"]''',
                                            ),
                                            0.0,
                                          ),
                                          ParamType.double,
                                        ),
                                        'estadoProductoEnCartera':
                                            serializeParam(
                                          valueOrDefault<String>(
                                            getJsonField(
                                              TestSheetsCall.general(
                                                listViewTestSheetsResponse
                                                    .jsonBody,
                                              )?[projectsIndex],
                                              r'''$.estadoProductoEnCartera''',
                                            )?.toString(),
                                            '0',
                                          ),
                                          ParamType.String,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                  child: Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 0.8,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
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
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(
                                          25.0, 20.0, 25.0, 20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 44.0,
                                                height: 44.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .info,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Align(
                                                  alignment:
                                                      const AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Icon(
                                                    Icons.rocket_outlined,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .white,
                                                    size: 23.0,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        20.0, 0.0, 0.0, 0.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      valueOrDefault<String>(
                                                        TestSheetsCall.linea(
                                                          listViewTestSheetsResponse
                                                              .jsonBody,
                                                        )?[projectsIndex],
                                                        'No data',
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineSmall
                                                              .override(
                                                                fontFamily:
                                                                    'Outfit',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                    ),
                                                    Align(
                                                      alignment:
                                                          const AlignmentDirectional(
                                                              -1.0, 0.0),
                                                      child: Text(
                                                        valueOrDefault<String>(
                                                          getJsonField(
                                                            TestSheetsCall
                                                                .general(
                                                              listViewTestSheetsResponse
                                                                  .jsonBody,
                                                            )?[projectsIndex],
                                                            r'''$.responsable''',
                                                          )?.toString(),
                                                          'Sin asignar',
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 20.0, 0.0, 20.0),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Align(
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  -1.0, 0.0),
                                                          child: Text(
                                                            valueOrDefault<
                                                                String>(
                                                              formatNumber(
                                                                TestSheetsCall
                                                                    .saldo(
                                                                  listViewTestSheetsResponse
                                                                      .jsonBody,
                                                                )?[projectsIndex],
                                                                formatType:
                                                                    FormatType
                                                                        .compact,
                                                                currency: '\$ ',
                                                              ),
                                                              'No data',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .labelLarge
                                                                .override(
                                                                  fontFamily:
                                                                      'Roboto',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                  fontSize:
                                                                      33.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                          ),
                                                        ),
                                                        Align(
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  -1.0, 0.0),
                                                          child: Text(
                                                            'Saldo pendiente',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        CircularPercentIndicator(
                                                          percent:
                                                              valueOrDefault<
                                                                  double>(
                                                            double.parse(
                                                                valueOrDefault<
                                                                    String>(
                                                              getJsonField(
                                                                TestSheetsCall
                                                                    .general(
                                                                  listViewTestSheetsResponse
                                                                      .jsonBody,
                                                                )?[projectsIndex],
                                                                r'''$["%AvanceProduccion"]''',
                                                              )?.toString(),
                                                              'No data',
                                                            )),
                                                            0.00,
                                                          ),
                                                          radius: 34.0,
                                                          lineWidth: 11.0,
                                                          animation: true,
                                                          animateFromLastPercent:
                                                              true,
                                                          progressColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary,
                                                          backgroundColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .accent4,
                                                          center: Text(
                                                            (String var1) {
                                                              return "${double.parse(
                                                                              var1) *
                                                                          100} %";
                                                            }(valueOrDefault<
                                                                String>(
                                                              getJsonField(
                                                                TestSheetsCall
                                                                    .general(
                                                                  listViewTestSheetsResponse
                                                                      .jsonBody,
                                                                )?[projectsIndex],
                                                                r'''$["%AvanceProduccion"]''',
                                                              )?.toString(),
                                                              'No data',
                                                            )),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .headlineSmall
                                                                .override(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  fontSize:
                                                                      15.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                          ),
                                                        ),
                                                        Align(
                                                          alignment:
                                                              const AlignmentDirectional(
                                                                  -1.0, 0.0),
                                                          child: Text(
                                                            valueOrDefault<
                                                                String>(
                                                              getJsonField(
                                                                TestSheetsCall
                                                                    .general(
                                                                  listViewTestSheetsResponse
                                                                      .jsonBody,
                                                                )?[projectsIndex],
                                                                r'''$.fase''',
                                                              )?.toString(),
                                                              'No data',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(-1.0, 0.0),
                                            child: Padding(
                                              padding: const EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 10.0, 0.0, 0.0),
                                              child: Text(
                                                valueOrDefault<String>(
                                                  TestSheetsCall.producto(
                                                    listViewTestSheetsResponse
                                                        .jsonBody,
                                                  )?[projectsIndex],
                                                  'No data',
                                                ),
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .override(
                                                          fontFamily: 'Roboto',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          fontSize: 21.0,
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(-1.0, 0.0),
                                            child: Text(
                                              valueOrDefault<String>(
                                                TestSheetsCall.fechaVenta(
                                                  listViewTestSheetsResponse
                                                      .jsonBody,
                                                )?[projectsIndex],
                                                'No data',
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(1.0, 0.0),
                                            child: Text(
                                              'Ver más',
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ].addToStart(const SizedBox(height: 20.0)),
            ),
          ),
        ),
      ),
    );
  }
}
