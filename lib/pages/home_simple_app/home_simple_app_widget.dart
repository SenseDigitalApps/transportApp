import 'package:flutter/scheduler.dart';
import 'package:transport_app/pages/chat_mode/widgets/chat_mode_toggle_button.dart';
import 'package:transport_app/components/default_dropdown/default_dropdown_widget.dart';
import 'package:transport_app/components/default_status/default_status_widget.dart';
import 'package:transport_app/components/page_components/screens_background/background_widget.dart';
import 'package:transport_app/flutter_flow/form_field_controller.dart';

import '../../components/empty_component/empty_component_widget.dart';
import '../../flutter_flow/custom_functions.dart';
import '/backend/api_requests/api_calls.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import '/services/home_initialization_service.dart';
import '/widgets/cached_avatar_image.dart';

import 'home_simple_app_model.dart';
export 'home_simple_app_model.dart';

class HomeSimpleAppWidget extends StatefulWidget {
  const HomeSimpleAppWidget({super.key});

  @override
  State<HomeSimpleAppWidget> createState() => _HomeSimpleAppWidgetState();
}

class _HomeSimpleAppWidgetState extends State<HomeSimpleAppWidget> {
  late HomeSimpleAppModel _model;
  ApiCallResponse? configModule;
  late List<dynamic> dataConfig;
  late Map<String, dynamic> extractedSlugFilterConfig = {};
  List<String> optionsListDropdown = [];
  late String valueFilter = 'en revision';
  String? dropDownValue;
  String? finalColor;
  FormFieldController<String> dropdownController = FormFieldController('');

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeSimpleAppModel());

    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formattedDate = formatter.format(now);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await HomeInitializationService.checkSignature(context);
      configModule = await GetCustomFieldsPerModuleCall.call(
        tenant: FFAppState().organizacion,
        moduleName: FFAppState().simpleAppSlugModule,
        token: FFAppState().token,
      );

      dataConfig = getJsonField((configModule?.jsonBody ?? ''), r'''$.data''');
      final slugFilter = FFAppState().simpleSlugFilter;

      extractedSlugFilterConfig = dataConfig.firstWhere(
        (item) => item["slug"] == slugFilter,
        orElse: () => {},
      );

      if (extractedSlugFilterConfig['options'] != null) {
        optionsListDropdown = (extractedSlugFilterConfig['options'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.toLowerCase() != 'terminada|primary')
            .toList();
      }
      if (mounted) {
        extractColor();
      }
      valueFilter = FFAppState().simpleValueFilter;
      dropdownController = FormFieldController<String>(valueFilter);
      dropdownController.value = valueFilter;

      setState(() {});
      refreshListView();
      setState(() {});
    });
    _model.datePicked = now;
    _model.textController ??= TextEditingController(text: formattedDate);
    _model.textFieldFocusNode ??= FocusNode();
    setState(() {});
    refreshListView();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Coloca aquí el código que quieres ejecutar cuando el widget vuelve a mostrarse

    // Puedes refrescar datos o hacer otra acción
    refreshListView();
  }

  refreshListView() async {
    setState(() => _model.listViewPagingController?.refresh());
    await _model.waitForOnePageForListView();
  }

  void extractColor() {
    for (var option in optionsListDropdown) {
      final parts = option.split('|');
      if (parts.isNotEmpty && parts.first.trim() == valueFilter) {
        finalColor = parts.length > 1 ? parts[1].trim() : null;
        dropDownValue = parts.first.trim();
        break;
      }
    }
    setState(() {});
    refreshListView();
    setState(() {});
  }

  Color getColor(String colorText) {
    final c = colorText.trim().toLowerCase();

    // ✅ soporta hex directo: "#C0ECFF" o "C0ECFF"
    if (RegExp(r'^#?[0-9a-f]{6}$').hasMatch(c)) {
      final hex = c.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }

    switch (c) {
      case 'warning':
        return const Color(0xFFE6D18C);
      case 'info':
        return const Color(0xFF9D97F3);
      case 'primary':
        return const Color(0xFF72B7FF);
      case 'success':
        return const Color(0xFF68D697);
      case 'danger':
        return const Color(0xFFE87F7F);
      case 'dark':
        return const Color(0xFF4F4F4F);

      // ✅ tu tono
      case 'sky':
        return const Color(0xFFC0ECFF);

      default:
        return const Color(0xFFBDBDBD);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    dropdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bottomLeftColor = Colors.grey.shade300.withOpacity(0.98);
    Color topRightColor = FlutterFlowTheme.of(context).primary;
    context.watch<FFAppState>();
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
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
                IconThemeData(color: FlutterFlowTheme.of(context).primary),
            automaticallyImplyLeading: false,
            leadingWidth: 96.0,
            leading: ChatModeLeading(scaffoldKey: scaffoldKey),
            toolbarHeight: 74.0,
            title: Column(
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
                        onTap: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.fade,
                              child: FlutterFlowExpandedImageView(
                                image: CachedAvatarImage(
                                  imageUrl:
                                      'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/app_launcher_icon.png',
                                      width: 300.0,
                                      height: 200.0,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                                allowRotation: false,
                                tag:
                                    'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}home_simple',
                                useHeroAnimation: true,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag:
                              'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}home_simple2',
                          transitionOnUserGestures: true,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedAvatarImage(
                              imageUrl:
                                  'https://${FFAppState().organizacion}.itsquery.com${FFAppState().avatar}',
                              width: 300.0,
                              height: 200.0,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/app_launcher_icon.png',
                                  width: 300.0,
                                  height: 200.0,
                                  fit: BoxFit.contain,
                                );
                              },
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
          body: SafeArea(
            child: Stack(
                // width: double.infinity,
                // height: double.infinity,
                // decoration: BoxDecoration(
                //   image: DecorationImage(
                //     fit: BoxFit.cover,
                //     image: Image.asset(
                //       'assets/images/fondoQuery.png',
                //     ).image,
                //   ),
                // ),
                children: [
                  DynamicBackground(
                    bottomLeftColor: bottomLeftColor,
                    topRightColor: topRightColor,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // ----HEADER---
                      Container(
                        width: double.infinity,
                        height: 70.0,
                        decoration: const BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BIENVENIDO,',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontSize: 28.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ].divide(const SizedBox(width: 5.0)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  FFAppState().fullName,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 22.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                      ),
                                ),
                              ].divide(const SizedBox(width: 5.0)),
                            ),
                          ],
                        ),
                      ),
                      // ----FILTRO---
                      Container(
                        width: double.infinity,
                        height: 50.0,
                        decoration: const BoxDecoration(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Filtra por estado:  ',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 18.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                            Container(
                              height: 40,
                              width: 150,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                borderRadius: BorderRadius.circular(12),
                                // boxShadow: const [
                                //   BoxShadow(
                                //     blurRadius: 3.0,
                                //     color: Color(0x6D000000),
                                //     offset: Offset(0.0, 2.0),
                                //     spreadRadius: 2.0,
                                //   ),
                                // ],
                              ),
                              child: Center(
                                  child: DropdownButton<String>(
                                value: valueFilter,
                                onChanged: (val) async {
                                  setState(() {
                                    valueFilter = val!;
                                    dropDownValue = val;
                                    finalColor = optionsListDropdown
                                        .firstWhere((option) =>
                                            option.contains('$val|'))
                                        .split('|')
                                        .last
                                        .trim();
                                    dropdownController.value = dropDownValue;
                                  });
                                  setState(() => _model.listViewPagingController
                                      ?.refresh());
                                  await _model.waitForOnePageForListView();
                                  //widget.onChanged();
                                },
                                items: optionsListDropdown.map((option) {
                                  final parts = option.split('|');
                                  final label = parts.first.trim();
                                  final color = parts.length > 1
                                      ? getColor(parts[1].trim())
                                      : Colors.grey;
                                  return DropdownMenuItem<String>(
                                    value: label,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8.0,
                                          height: 8.0,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        Text(
                                          label,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Outfit',
                                                color: color,
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                hint: Text(
                                  valueFilter ?? '',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: finalColor != null
                                            ? getColor(finalColor!)
                                            : FlutterFlowTheme.of(context)
                                                .secondaryText,
                                        letterSpacing: 0.0,
                                      ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 24.0,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Outfit',
                                      color: finalColor != null
                                          ? getColor(finalColor!)
                                          : FlutterFlowTheme.of(context)
                                              .secondaryText,
                                      letterSpacing: 0.0,
                                    ),
                                dropdownColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                underline: Container(),
                              )),
                            )
                          ].divide(const SizedBox(width: 5.0)),
                        ),
                      ),
                      // --- LISTA SCROLLEABLE ---
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              30.0, 0.0, 30.0, 0.0),
                          child: RefreshIndicator(
                            color: FlutterFlowTheme.of(context).companyColor,
                            onRefresh: () async {
                              setState(() =>
                                  _model.listViewPagingController?.refresh());
                              await _model.waitForOnePageForListView();
                            },
                            child: PagedListView<ApiPagingParams,
                                dynamic>.separated(
                              pagingController: _model.setListViewController(
                                (nextPageMarker) => GetDataModulesCall.call(
                                  tenant: FFAppState().organizacion,
                                  module: FFAppState().simpleAppSlugModule,
                                  moduleType: 'registers',
                                  token: FFAppState().token,
                                  jsonKey:
                                      '${FFAppState().simpleSlugFilter}^${FFAppState().simpleAppSlugUserAsignado.split(',')[0].trim()}|${FFAppState().simpleAppSlugUserAsignado.split(',')[1].trim()}',
                                  jsonValue:
                                      '${(dropdownController.value == '' || dropdownController.value == null) ? valueFilter : dropdownController.value}^${FFAppState().fullName}|${FFAppState().fullName}',
                                  jsonCondition: 'exacto^igual|igual',
                                  page: nextPageMarker.nextPageNumber + 1,
                                  limit: 10,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              shrinkWrap: false,
                              physics: const AlwaysScrollableScrollPhysics(),
                              primary: false,
                              scrollDirection: Axis.vertical,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 15.0),
                              builderDelegate:
                                  PagedChildBuilderDelegate<dynamic>(
                                // Customize what your widget looks like when it's loading the first page.
                                firstPageProgressIndicatorBuilder: (_) =>
                                    Center(
                                  child: SizedBox(
                                    width: 30.0,
                                    height: 30.0,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                  ),
                                ),
                                // Customize what your widget looks like when it's loading another page.
                                newPageProgressIndicatorBuilder: (_) => Center(
                                  child: SizedBox(
                                    width: 30.0,
                                    height: 30.0,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                  ),
                                ),
                                noItemsFoundIndicatorBuilder: (_) => SizedBox(
                                  width: MediaQuery.sizeOf(context).width * 0.8,
                                  height: 200.0,
                                  child: const EmptyComponentWidget(),
                                ),
                                noMoreItemsIndicatorBuilder: (_) =>
                                    const Text(''),
                                itemBuilder: (context, _, dataIndex) {
                                  final dataItem = _model
                                      .listViewPagingController!
                                      .itemList![dataIndex];
                                  final jsonData = dataItem;
                                  return InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      final Map<String, dynamic> detailData =
                                          getJsonField(
                                        dataItem,
                                        r'''$''',
                                      );
                                      final slugToSearch =
                                          FFAppState().simpleSlugRepeater;
                                      final extractedData = detailData;
                                      String jsonString =
                                          jsonEncode(detailData);
                                      await context.pushNamed(
                                        'detailGrouped',
                                        queryParameters: {
                                          'title': serializeParam(
                                            'a',
                                            ParamType.String,
                                          ),
                                          'body': serializeParam(
                                            'aa',
                                            ParamType.String,
                                          ),
                                          'general': serializeParam(
                                            getJsonField(
                                              dataItem,
                                              r'''$''',
                                            ),
                                            ParamType.JSON,
                                          ),
                                        }.withoutNulls,
                                      );
                                      setState(() => _model
                                          .listViewPagingController
                                          ?.refresh());
                                      _model.waitForOnePageForListView();
                                    },
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          0.8,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        boxShadow: const [
                                          BoxShadow(
                                            blurRadius: 1.0,
                                            color: Color(0x6D000000),
                                            offset: Offset(
                                              0.0,
                                              1.0,
                                            ),
                                            spreadRadius: 1.0,
                                          )
                                        ],
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(25.0, 0.0, 25.0, 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 200.0,
                                                  constraints:
                                                      const BoxConstraints(
                                                    maxWidth: 200.0,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(),
                                                  child: Text(
                                                    jsonData["json_data"][
                                                        FFAppState()
                                                            .simpleSlugFilter],
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .headlineSmall
                                                        .override(
                                                          fontFamily: 'Outfit',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          fontSize: 16.0,
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ),
                                              ].divide(
                                                  const SizedBox(width: 20.0)),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 50.0,
                                                  height: 50.0,
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    getIconData(getJsonField(
                                                      dataItem,
                                                      r'''$.modulo_info.icon''',
                                                    ).toString()),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .white,
                                                    size: 24.0,
                                                  ),
                                                ),
                                                Container(
                                                  width: 200.0,
                                                  constraints:
                                                      const BoxConstraints(
                                                    maxWidth: 200.0,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(),
                                                  child: Text(
                                                    getJsonField(
                                                      dataItem,
                                                      r'''$.title''',
                                                    ).toString(),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .headlineSmall
                                                        .override(
                                                          fontFamily: 'Outfit',
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                ),
                                              ].divide(
                                                  const SizedBox(width: 20.0)),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Consecutivo:',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                Text(
                                                  getJsonField(
                                                    dataItem,
                                                    r'''$.consecutivo''',
                                                  ).toString(),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 13.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                ),
                                              ].divide(
                                                  const SizedBox(width: 10.0)),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Fecha publicación: ',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                Text(
                                                  getJsonField(
                                                    dataItem,
                                                    r'''$.published_date''',
                                                  ).toString(),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 13.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                ),
                                              ].divide(
                                                  const SizedBox(width: 10.0)),
                                            ),
                                          ]
                                              .divide(
                                                  const SizedBox(height: 10.0))
                                              .addToStart(
                                                  const SizedBox(height: 20.0))
                                              .addToEnd(
                                                  const SizedBox(height: 20.0)),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                        .divide(const SizedBox(height: 15.0))
                        .addToStart(const SizedBox(height: 30.0))
                        .addToEnd(const SizedBox(height: 30.0)),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
