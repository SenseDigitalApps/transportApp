import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:transport_app/components/acordeon_simple/acordeon_simple_widget.dart';
import 'package:transport_app/components/certificadora_modal/certificadora_aprobaci%C3%B3n_widget.dart';
import 'package:transport_app/components/certificadora_modal/certificadora_modal_widget.dart';
import 'package:transport_app/components/certificadora_modal/certificadora_notification_widget.dart';
import '../../flutter_flow/flutter_flow_icon_button.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/widgets/cached_avatar_image.dart';

class DetailSimpleAppWidget extends StatefulWidget {
  const DetailSimpleAppWidget({super.key, required this.detail});

  final dynamic detail;

  @override
  State<DetailSimpleAppWidget> createState() => _DetailSimpleAppWidgetState();
}

class _DetailSimpleAppWidgetState extends State<DetailSimpleAppWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController _controller = TextEditingController();
  List<dynamic> activitysFiltrados = [];
  late dynamic detail;
  late List<dynamic> data;
  late List<dynamic> dataListaChequeo = [];
  late List<dynamic> dataActasVisita = [];
  late List<dynamic> dataRegistroFotografico = [];
  bool existeFechaActual = false;
  var registroCoincidente = null;
  bool mostrarWarning = true;
  bool isLoading = false;
  bool isModalShown = false;
  final List<dynamic> optionsListaChequeo = [
    {
      "slug": "form_documento",
      "label": "Documento",
      "options": "",
      "field_type": "formato",
      "related_module": 0,
      "relations_type": "",
      "format_relation_id": "",
      "slug_format_actual_relation": "ref_formato_diligenciado",
      "slug_format_destination_relation": "ref_inspeccion_relacionada"
    },
    {
      "slug": "ref_formato_diligenciado",
      "label": "Formato diligenciado",
      "options": "",
      "field_type": "relational",
      "related_module": "3",
      "relations_type": "master",
      "format_relation_id": "",
      "slug_format_actual_relation": "",
      "slug_format_destination_relation": ""
    }
  ];
  final List<dynamic> optionsActasVisita = [
    {
      "slug": "form_formato",
      "label": "Formato",
      "options": "",
      "field_type": "formato",
      "related_module": 0,
      "relations_type": "",
      "format_relation_id": "",
      "slug_format_actual_relation": "ref_formato_diligenciado",
      "slug_format_destination_relation": "ref_inspeccion_relacionada"
    },
    {
      "slug": "ref_formato_diligenciado",
      "label": "Formato diligenciado",
      "options": "",
      "field_type": "relational",
      "related_module": 0,
      "relations_type": "master",
      "format_relation_id": "",
      "slug_format_actual_relation": "",
      "slug_format_destination_relation": ""
    },
    {
      "slug": "fecha",
      "label": "Fecha",
      "options": "",
      "field_type": "calendar",
      "related_module": 0,
      "relations_type": "",
      "format_relation_id": "",
      "slug_format_actual_relation": "",
      "slug_format_destination_relation": ""
    }
  ];
  final List<dynamic> optionsRegistroFotografico = [
    {
      "slug": "img_foto",
      "label": "Foto",
      "options": "",
      "field_type": "image",
      "related_module": 0,
      "relations_type": "",
      "format_relation_id": "",
      "slug_format_actual_relation": "",
      "slug_format_destination_relation": ""
    },
    {
      "slug": "descripcion",
      "label": "Descripción",
      "options": "",
      "field_type": "textarea",
      "related_module": 0,
      "relations_type": "",
      "format_relation_id": "",
      "slug_format_actual_relation": "",
      "slug_format_destination_relation": ""
    }
  ];
  late List<dynamic> repeaterFotos = [];
  late List<dynamic> repeaterActasVisita = [];
  late List<dynamic> repeaterListaChequeo = [];
  Map<String, dynamic> jsonConfigToSend = {};
  final GlobalKey<AcordeonSimpleWidgetState> _repeaterFotosKey =
      GlobalKey<AcordeonSimpleWidgetState>();
  final GlobalKey<AcordeonSimpleWidgetState> _repeaterActasVisitasKey =
      GlobalKey<AcordeonSimpleWidgetState>();
  final GlobalKey<AcordeonSimpleWidgetState> _repeaterListaChequeoKey =
      GlobalKey<AcordeonSimpleWidgetState>();
  final slugToSearch = FFAppState().simpleSlugRepeater;

  @override
  void initState() {
    super.initState();
    detail = widget.detail;
    initFunction();
  }

  void initFunction() {
    detail.forEach((key, value) {});
    detail["json_data"].forEach((key, value) {});
    dataListaChequeo = detail["json_data"]['rep_documentos'] is List
        ? detail["json_data"]['rep_documentos']
        : [];
    dataActasVisita = detail["json_data"]['rep_actas_de_visita'] is List
        ? detail["json_data"]['rep_actas_de_visita']
        : [];
    dataRegistroFotografico =
        detail["json_data"]['rep_fotos_adicionales'] is List
            ? detail["json_data"]['rep_fotos_adicionales']
            : [];
    data = detail["json_data"][slugToSearch] ?? [];
    ;
    activitysFiltrados = data;
    createJsonConfigToSend();
  }

  void createJsonConfigToSend() {
    jsonConfigToSend = {
      "id": getJsonField(detail, r'''$.id'''),
      "title": detail["title"],
      "json_data": {},
      "modulo": detail["modulo_info"]["id"],
    };
    detail["json_data"].keys.forEach((key) {
      jsonConfigToSend["json_data"][key] = detail["json_data"][key];
    });
    jsonConfigToSend['json_data']['rep_fotos_adicionales'] = [];
  }

  void updateJsonConfigToSend() {
    repeaterFotos = [];
    if (kDebugMode) {}

    repeaterFotos = _repeaterFotosKey.currentState!.getRepeater();
    repeaterActasVisita = _repeaterActasVisitasKey.currentState!.getRepeater();
    repeaterListaChequeo = _repeaterListaChequeoKey.currentState!.getRepeater();
    jsonConfigToSend["json_data"]["rep_fotos_adicionales"] = repeaterFotos;
    jsonConfigToSend["json_data"]["rep_documentos"] = repeaterListaChequeo;
    jsonConfigToSend["json_data"]["rep_actas_de_visita"] = repeaterActasVisita;
  }

  void _filterFields(String text) {
    setState(() {
      if (text.isEmpty) {
        activitysFiltrados = data;
      } else {
        // Filtra la lista según el texto ingresado
        activitysFiltrados = data
                .where(
                  (campo) => campo['nombre']
                      .toLowerCase()
                      .contains(text.toLowerCase()),
                )
                .toList() ??
            [];
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    // Mostrar el modal si existeFechaActual es verdadero
    if (!existeFechaActual && !isModalShown) {
      isModalShown = true; // Marca que el modal ya fue mostrado
      Future.microtask(() => showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      20), // Define el radio de los bordes
                ),
                title: Text(
                  'No tienes un acta de visita para el día de hoy',
                  textAlign: TextAlign.center, // Centra el texto del título
                ),
                content: Text(
                  'Debes crear uno para poder continuar usando la aplicación',
                  textAlign: TextAlign.center, // Centra el texto del contenido
                ),
                actionsAlignment:
                    MainAxisAlignment.center, // Centra las acciones
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Crear acta visita'),
                    onPressed: isLoading
                        ? null
                        : () async {
                            Navigator.of(context).pop();
                            setState(() {
                              isLoading = true;
                            });

                            setState(() {
                              isLoading = false;
                            });
                            isModalShown = false;
                          },
                  ),
                ],
              );
            },
          ));
    }
    return GestureDetector(
        child: PopScope(
      canPop: true,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        floatingActionButton: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Primer botón flotante
            Positioned(
              bottom: 16, // Posición desde la parte inferior
              right: 16, // Posición desde la derecha
              child: FloatingActionButton(
                onPressed: () async {
                  setState(() {
                    existeFechaActual = true;
                    isLoading = true;
                  });
                  updateJsonConfigToSend();

                  ApiCallResponse? editResult = await EditRegister.call(
                    tenant: FFAppState().organizacion,
                    moduleName: jsonConfigToSend["modulo"].toString(),
                    moduleType: detail["modulo_info"]["type"],
                    token: FFAppState().token,
                    body: jsonEncode(jsonConfigToSend),
                    id: jsonConfigToSend["id"],
                  );

                  if (editResult.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '¡Registro editado exitosamente!',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).white,
                          ),
                        ),
                        duration: const Duration(milliseconds: 4000),
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                      ),
                    );
                    setState(() {
                      isLoading = false;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Algo salió mal al editar el registro',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).white,
                          ),
                        ),
                        duration: const Duration(milliseconds: 4000),
                        backgroundColor: FlutterFlowTheme.of(context).tertiary,
                      ),
                    );

                    setState(() {
                      isLoading = false;
                    });
                  }
                },
                backgroundColor: FlutterFlowTheme.of(context).primary,
                elevation: 8.0,
                child: isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Icon(
                        Icons.check,
                        color: FlutterFlowTheme.of(context).white,
                        size: 24.0,
                      ),
              ),
            ),

            // Segundo botón flotante
          ],
        ),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          iconTheme: IconThemeData(color: FlutterFlowTheme.of(context).primary),
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30,
            borderWidth: 1,
            buttonSize: 60,
            icon: Icon(
              Icons.arrow_back,
              color: FlutterFlowTheme.of(context).primary,
              size: 30,
            ),
            onPressed: () {
              Navigator.pop(context);

              // context.goNamed(
              //   'homeSimpleApp',
              //   extra: <String, dynamic>{
              //     kTransitionInfoKey:
              //     const TransitionInfo(
              //       hasTransition: true,
              //       transitionType:
              //       PageTransitionType
              //           .rightToLeft,
              //     ),
              //   },
              // );
            },
          ),
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
                  'Proyecto',
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
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child: FlutterFlowExpandedImageView(
                              image: CachedAvatarImage(
                                imageUrl:
                                    'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}',
                                fit: BoxFit.contain,
                              ),
                              allowRotation: false,
                              tag:
                                  'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}detail_simple',
                              useHeroAnimation: true,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag:
                            'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}detail_simple2',
                        transitionOnUserGestures: true,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedAvatarImage(
                            imageUrl:
                                'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}',
                            width: 300.0,
                            height: 200.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: Image.asset(
                'assets/images/fondoQuery.png',
              ).image,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.max, children: [
                const SizedBox(height: 10),
                Container(
                    width: double.infinity,
                    height: MediaQuery.sizeOf(context).height * 0.9,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
                    child: SingleChildScrollView(
                        primary: true,
                        child:
                            Column(mainAxisSize: MainAxisSize.max, children: [
                          if (mostrarWarning)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(
                                          20), // Aplica el padding solo al contenido interno
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            existeFechaActual
                                                ? "Cerrar o editar acta de visita"
                                                : "Crear acta de visita",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 15),
                                          Text(
                                            existeFechaActual
                                                ? "Ya cuentas con un acta de visita para el día de hoy, no olvides cerrarla al finalizar el día."
                                                : "NO cuentas con un acta de visita para el día de hoy, no olvides crearla para poder comenzar con el día.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          // Text(
                                          //   "Visitas totales: "+(detail["json_data"]["cantidad_visitas"]??0),
                                          //   textAlign: TextAlign.center,
                                          //   style: TextStyle(
                                          //     fontSize: 14,
                                          //     fontWeight: FontWeight.w800,
                                          //     color: Colors.blueGrey,
                                          //   ),
                                          // ),
                                          // Text(
                                          //   "Visitas hechas: "+(dataActasVisita.length).toString(),
                                          //   textAlign: TextAlign.center,
                                          //   style: TextStyle(
                                          //     fontSize: 14,
                                          //     fontWeight: FontWeight.w800,
                                          //     color: Colors.blueGrey,
                                          //   ),
                                          // ),
                                          SizedBox(height: 10),
                                          Text(
                                            "Visitas restantes: " +
                                                (int.parse(detail["json_data"][
                                                                "cantidad_visitas"] ??
                                                            0) -
                                                        dataActasVisita.length)
                                                    .toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          ElevatedButton(
                                            onPressed: isLoading
                                                ? null
                                                : () async {
                                                    if (existeFechaActual) {
                                                      ApiCallResponse?
                                                          actualRegister =
                                                          await GetDataMastersCall
                                                              .call(
                                                        tenant: FFAppState()
                                                            .organizacion,
                                                        id: registroCoincidente[
                                                                    "ref_formato_diligenciado"]
                                                                ['value']
                                                            .toString(),
                                                        token:
                                                            FFAppState().token,
                                                      );
                                                      context.pushNamed(
                                                        'detailGrouped',
                                                        queryParameters: {
                                                          'title':
                                                              serializeParam(
                                                            'a',
                                                            ParamType.String,
                                                          ),
                                                          'body':
                                                              serializeParam(
                                                            'aa',
                                                            ParamType.String,
                                                          ),
                                                          'general':
                                                              serializeParam(
                                                            (actualRegister
                                                                    .jsonBody ??
                                                                ''),
                                                            ParamType.JSON,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    } else {
                                                      setState(() {
                                                        existeFechaActual =
                                                            true;
                                                        isLoading = true;
                                                      });
                                                      setState(() {
                                                        isLoading = false;
                                                      });
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: existeFechaActual
                                                  ? FlutterFlowTheme.of(context)
                                                      .primary
                                                  : FlutterFlowTheme.of(context)
                                                      .error,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    existeFechaActual
                                                        ? "Cerrar o editar acta de visita"
                                                        : "Crear Acta de Visita",
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: IconButton(
                                        icon: Icon(Icons.close,
                                            color: Colors.grey),
                                        onPressed: () {
                                          setState(() {
                                            mostrarWarning =
                                                false; // Cierra la advertencia
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 20),
                          AcordeonSimpleWidget(
                              key: _repeaterListaChequeoKey,
                              repeater: dataListaChequeo,
                              title: 'LISTAS DE CHEQUEO',
                              options: optionsListaChequeo,
                              updateJsonRepeater: (data) {}),
                          SizedBox(height: 30),
                          AcordeonSimpleWidget(
                              key: _repeaterActasVisitasKey,
                              repeater: dataActasVisita,
                              title: 'ACTAS DE VISITA',
                              options: optionsActasVisita,
                              updateJsonRepeater: (data) {}),
                          SizedBox(height: 30),
                          AcordeonSimpleWidget(
                              key: _repeaterFotosKey,
                              repeater: dataRegistroFotografico,
                              title: 'REGISTRO FOTOGRÁFICO',
                              options: optionsRegistroFotografico,
                              updateJsonRepeater: (repeaterFotos) {
                                setState(() {
                                  this.repeaterFotos = repeaterFotos;
                                });
                              }),
                          SizedBox(height: 50),
                        ]))),
              ] //.addToEnd(const SizedBox(height: 30.0)),
                  ),
            ),
          ),
        ),
      ),
    ));
  }
}
