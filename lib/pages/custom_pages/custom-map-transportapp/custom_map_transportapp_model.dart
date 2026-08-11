import '/backend/api_requests/api_calls.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'custom_map_transportapp_widget.dart' show CustomMapTransportappWidget;
import 'types/solicitud_trabajo.dart';
import 'utils/ciudad_coords.dart';
import 'utils/status_colors.dart';
import 'utils/transport_app_cache.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

enum SolicitudesTab { disponibles, activas, historial }

const _filterJsonKey = 'estado_de_la_solicitud^ref_usuario_encargado_de_la_solicitud';
const _valueDisponibles = 'pendiente^__query__empty__';
const _valueActivas = 'en transito^me';
const _valueHistorial = 'entregado^me';

String _cachePrefix(String jsonValue) => '${_filterJsonKey}_${jsonValue}_page_';

/// Modelo de estado para CustomMapTransportapp.
class CustomMapTransportappModel extends FlutterFlowModel<CustomMapTransportappWidget> {
  late SideNavModel sideNavModel;

  // PagingControllers para scroll infinito del bottom sheet.
  PagingController<ApiPagingParams, SolicitudTrabajo>? listViewPagingController;
  Function(ApiPagingParams nextPageMarker)? listViewApiCall;

  // Tabs
  PagingController<ApiPagingParams, SolicitudTrabajo>? disponiblesPagingController;
  PagingController<ApiPagingParams, SolicitudTrabajo>? activasPagingController;
  PagingController<ApiPagingParams, SolicitudTrabajo>? historialPagingController;

  SolicitudesTab currentTab = SolicitudesTab.disponibles;

  // Historial: suma total (ValueNotifier para rebuild automático)
  final ValueNotifier<double> historialTotalEstimado = ValueNotifier<double>(0.0);
  final ValueNotifier<int> historialTotalCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> historialLoading = ValueNotifier<bool>(false);

  // Activa con GPS: primera solicitud activa que tenga coordenadas válidas
  final ValueNotifier<SolicitudTrabajo?> firstActiveWithGps = ValueNotifier<SolicitudTrabajo?>(null);

  // Colores de estado cargados desde default_status del módulo.
  Map<String, StatusColor> statusColors = {};

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
  }

  Future<void> loadStatusColors() async {
    final cache = TransportAppCache();

    // 1) Intentar usar caché en memoria
    if (cache.hasStatusConfig && cache.statusConfigRaw != null) {
      statusColors = parseDefaultStatus(cache.statusConfigRaw);
      return;
    }

    try {
      final resp = await GetCustomFieldsPerModuleCall.call(
        tenant: FFAppState().organizacion,
        moduleName: 'solicitud_de_trabajo',
        token: FFAppState().token,
      );
      if (resp.succeeded && resp.jsonBody != null) {
        cache.setStatusConfig(resp.jsonBody as Map<String, dynamic>);
        statusColors = parseDefaultStatus(resp.jsonBody);
      }
    } catch (_) {
      statusColors = Map<String, StatusColor>.from(fallbackStatusColors);
    }
  }

  // ================================================================
  // Active service detection
  // ================================================================

  /// Recalcula firstActiveWithGps a partir de los items cargados en el controller.
  void _recomputeFirstActiveWithGps() {
    final items = activasPagingController?.itemList ?? [];
    for (final s in items) {
      if (s.origenCoords != null && s.destinoCoords != null) {
        if (firstActiveWithGps.value?.id != s.id) {
          firstActiveWithGps.value = s;
        }
        return;
      }
    }
    if (firstActiveWithGps.value != null) {
      firstActiveWithGps.value = null;
    }
  }

  /// Chequeo inicial liviero (limit=1) para detectar si hay un servicio activo
  /// antes de que el usuario cambie a la pestaña de Activas.
  Future<void> checkForActiveService() async {
    try {
      final response = await GetDataModulesCall.call(
        tenant: FFAppState().organizacion,
        module: 'solicitud_de_trabajo',
        token: FFAppState().token,
        page: 1,
        limit: 1,
        moduleType: 'registers',
        jsonKey: _filterJsonKey,
        jsonValue: _valueActivas,
        jsonCondition: 'exacto^igual',
        searchMode: 'false',
      );

      if (!response.succeeded) {
        firstActiveWithGps.value = null;
        return;
      }

      final data = GetDataModulesCall.data(response.jsonBody) ?? [];
      if (data.isEmpty) {
        firstActiveWithGps.value = null;
        return;
      }

      final items = data.map((item) => SolicitudTrabajo.fromJson(
            item as Map<String, dynamic>,
            ciudadCoords: ciudadCoordsMap,
          )).toList();

      for (final s in items) {
        if (s.origenCoords != null && s.destinoCoords != null) {
          firstActiveWithGps.value = s;
          return;
        }
      }
      firstActiveWithGps.value = null;
    } catch (_) {
      firstActiveWithGps.value = null;
    }
  }

  @override
  void dispose() {
    listViewPagingController?.dispose();
    disponiblesPagingController?.dispose();
    activasPagingController?.dispose();
    historialPagingController?.dispose();
    historialTotalEstimado.dispose();
    historialTotalCount.dispose();
    historialLoading.dispose();
    firstActiveWithGps.dispose();
    sideNavModel.dispose();
  }

  // ================================================================
  // PagingControllers por tab
  // ================================================================

  PagingController<ApiPagingParams, SolicitudTrabajo> getControllerForTab(SolicitudesTab tab) {
    switch (tab) {
      case SolicitudesTab.disponibles:
        return disponiblesPagingController ??= _createPagingController(_fetchDisponiblesPage);
      case SolicitudesTab.activas:
        return activasPagingController ??= _createPagingController(_fetchActivasPage);
      case SolicitudesTab.historial:
        return historialPagingController ??= _createPagingController(_fetchHistorialPage);
    }
  }

  PagingController<ApiPagingParams, SolicitudTrabajo> _createPagingController(
    Future<void> Function(ApiPagingParams) fetchPage,
  ) {
    final controller = PagingController<ApiPagingParams, SolicitudTrabajo>(
      firstPageKey: ApiPagingParams(
        nextPageNumber: 0,
        numItems: 0,
        lastResponse: null,
      ),
    );
    controller.addPageRequestListener(fetchPage);
    return controller;
  }

  // ================================================================
  // Fetchers por tab
  // ================================================================

  Future<void> _fetchDisponiblesPage(ApiPagingParams nextPageMarker) async {
    await _fetchPageWithFilter(
      nextPageMarker,
      jsonKey: 'estado_de_la_solicitud^ref_usuario_encargado_de_la_solicitud',
      jsonValue: 'pendiente^__query__empty__',
      jsonCondition: 'exacto^igual',
      searchMode: 'false',
      controller: disponiblesPagingController,
    );
  }

  Future<void> _fetchActivasPage(ApiPagingParams nextPageMarker) async {
    await _fetchPageWithFilter(
      nextPageMarker,
      jsonKey: 'estado_de_la_solicitud^ref_usuario_encargado_de_la_solicitud',
      jsonValue: 'en transito^me',
      jsonCondition: 'exacto^igual',
      searchMode: 'false',
      controller: activasPagingController,
    );
    _recomputeFirstActiveWithGps();
  }

  Future<void> _fetchHistorialPage(ApiPagingParams nextPageMarker) async {
    final pageNumber = nextPageMarker.nextPageNumber + 1;
    final cache = TransportAppCache();
    final cacheKey = 'historial_page_$pageNumber';

    if (pageNumber == 1) historialLoading.value = true;

    if (cache.hasPageByKey(cacheKey)) {
      final cached = cache.getSolicitudesByKey(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        _appendHistorialPage(cached, pageNumber, nextPageMarker);
        if (pageNumber == 1) historialLoading.value = false;
        return;
      }
    }

    try {
      final response = await GetDataModulesCall.call(
        tenant: FFAppState().organizacion,
        module: 'solicitud_de_trabajo',
        token: FFAppState().token,
        page: pageNumber,
        limit: 10,
        moduleType: 'registers',
        jsonKey: 'estado_de_la_solicitud^ref_usuario_encargado_de_la_solicitud',
        jsonValue: 'entregado^me',
        jsonCondition: 'exacto^igual',
        searchMode: 'false',
      );

      final pageItems = _parseSolicitudes(response);
      if (pageItems.isNotEmpty) {
        cache.setSolicitudesByKey(cacheKey, pageItems);
      }
      _appendHistorialPage(pageItems, pageNumber, nextPageMarker);
    } catch (e) {
      _handlePagingError(historialPagingController, e);
    } finally {
      if (pageNumber == 1) historialLoading.value = false;
    }
  }

  // ================================================================
  // Helper genérico para fetch con filtro
  // ================================================================

  Future<void> _fetchPageWithFilter(
    ApiPagingParams nextPageMarker, {
    required String jsonKey,
    required String jsonValue,
    required String jsonCondition,
    String searchMode = 'false',
    required PagingController<ApiPagingParams, SolicitudTrabajo>? controller,
  }) async {
    final pageNumber = nextPageMarker.nextPageNumber + 1;
    final cache = TransportAppCache();
    final cacheKey = '${jsonKey}_${jsonValue}_page_$pageNumber';

    if (cache.hasPageByKey(cacheKey)) {
      final cached = cache.getSolicitudesByKey(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final newNumItems = nextPageMarker.numItems + cached.length;
        controller?.appendPage(
          cached,
          ApiPagingParams(
            nextPageNumber: pageNumber,
            numItems: newNumItems,
            lastResponse: nextPageMarker.lastResponse,
          ),
        );
        return;
      }
    }

    try {
      final response = await GetDataModulesCall.call(
        tenant: FFAppState().organizacion,
        module: 'solicitud_de_trabajo',
        token: FFAppState().token,
        page: pageNumber,
        limit: 10,
        moduleType: 'registers',
        jsonKey: jsonKey,
        jsonValue: jsonValue,
        jsonCondition: jsonCondition,
        searchMode: searchMode,
      );

      final pageItems = _parseSolicitudes(response);
      if (pageItems.isNotEmpty) {
        cache.setSolicitudesByKey(cacheKey, pageItems);
      }

      final newNumItems = nextPageMarker.numItems + pageItems.length;
      controller?.appendPage(
        pageItems,
        pageItems.isNotEmpty
            ? ApiPagingParams(
                nextPageNumber: pageNumber,
                numItems: newNumItems,
                lastResponse: response,
              )
            : null,
      );
    } catch (e) {
      _handlePagingError(controller, e);
    }
  }

  List<SolicitudTrabajo> _parseSolicitudes(ApiCallResponse response) {
    return (GetDataModulesCall.data(response.jsonBody) ?? [])
        .map((item) => SolicitudTrabajo.fromJson(
              item as Map<String, dynamic>,
              ciudadCoords: ciudadCoordsMap,
            ))
        .toList();
  }

  void _appendHistorialPage(List<SolicitudTrabajo> items, int pageNumber, ApiPagingParams marker) {
    double suma = 0;
    for (final s in items) {
      suma += s.valorEstimado;
    }
    historialTotalEstimado.value = historialTotalEstimado.value + suma;
    historialTotalCount.value = historialTotalCount.value + items.length;

    final newNumItems = marker.numItems + items.length;
    historialPagingController?.appendPage(
      items,
      items.isNotEmpty
          ? ApiPagingParams(
              nextPageNumber: pageNumber,
              numItems: newNumItems,
              lastResponse: marker.lastResponse,
            )
          : null,
    );
  }

  void _handlePagingError(PagingController<ApiPagingParams, SolicitudTrabajo>? controller, Object error) {
    controller?.error = error;
  }

  // ================================================================
  // Validaciones previas a aceptar
  // ================================================================

  /// Verifica que la solicitud siga disponible (nadie más la tomó).
  /// Retorna null si está disponible, o un mensaje de error si ya fue tomada.
  Future<String?> _checkDisponibilidad(SolicitudTrabajo solicitud) async {
    try {
      final resp = await GetDataRegistersCall.call(
        tenant: FFAppState().organizacion,
        id: solicitud.id.toString(),
        token: FFAppState().token,
      );

      if (!resp.succeeded) {
        return 'Error al verificar disponibilidad del servicio';
      }

      final currentData = resp.jsonBody;
      final rawData = getJsonField(currentData, r'''$.data''');
      Map<String, dynamic>? registerData;
      if (rawData is Map<String, dynamic>) {
        registerData = rawData;
      } else if (rawData is List && rawData.isNotEmpty) {
        registerData = rawData.first as Map<String, dynamic>?;
      } else if (currentData is Map<String, dynamic>) {
        // El endpoint v2/register/{id}/ devuelve el objeto directamente, sin envoltura "data"
        registerData = currentData;
      }

      if (registerData == null) {
        debugPrint('DEBUG _checkDisponibilidad - registerData es null. Body: $currentData');
        return 'No se pudo obtener el registro';
      }

      final jsonData = registerData['json_data'] as Map<String, dynamic>? ?? {};
      final usuarioAsignado = jsonData['ref_usuario_encargado_de_la_solicitud'];

      // Si ya tiene un usuario asignado (label no vacío), alguien más lo tomó
      if (usuarioAsignado is Map<String, dynamic> &&
          (usuarioAsignado['label'] as String? ?? '').isNotEmpty) {
        return 'Este servicio ya fue tomado por otro conductor';
      }

      return null; // Disponible
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// Verifica si el usuario ya tiene un servicio activo (estado = "en transito").
  /// Retorna el consecutivo del servicio activo si existe, null si no.
  Future<int?> _checkTieneActivo() async {
    try {
      final response = await GetDataModulesCall.call(
        tenant: FFAppState().organizacion,
        module: 'solicitud_de_trabajo',
        token: FFAppState().token,
        page: 1,
        limit: 1,
        moduleType: 'registers',
        jsonKey: 'estado_de_la_solicitud^ref_usuario_encargado_de_la_solicitud',
        jsonValue: 'en transito^me',
        jsonCondition: 'exacto^igual',
        searchMode: 'false',
      );

      if (!response.succeeded) return null;

      final data = GetDataModulesCall.data(response.jsonBody) ?? [];
      if (data.isEmpty) return null;

      final firstItem = data.first as Map<String, dynamic>?;
      return firstItem?['consecutivo'] as int?;
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // Cambiar estado genérico (Entregado / Con novedad)
  // ================================================================

  Future<String?> cambiarEstado(SolicitudTrabajo solicitud, String nuevoEstado, {String? observaciones}) async {
    try {
      // 1. Obtener registro actual completo
      final currentResp = await GetDataRegistersCall.call(
        tenant: FFAppState().organizacion,
        id: solicitud.id.toString(),
        token: FFAppState().token,
      );

      if (!currentResp.succeeded) {
        return 'No se pudo obtener el registro (${currentResp.statusCode})';
      }

      // 2. Parsear igual que en aceptarSolicitud
      final currentData = currentResp.jsonBody;
      final rawData = getJsonField(currentData, r'''$.data''');
      Map<String, dynamic>? registerData;
      if (rawData is Map<String, dynamic>) {
        registerData = rawData;
      } else if (rawData is List && rawData.isNotEmpty) {
        final first = rawData.first;
        if (first is Map<String, dynamic>) {
          registerData = first;
        }
      } else if (currentData is Map<String, dynamic>) {
        registerData = currentData;
      }

      if (registerData == null) {
        return 'Registro no encontrado';
      }

      // 3. Extraer json_data y modificar
      final jsonData = Map<String, dynamic>.from(
        (registerData['json_data'] as Map<String, dynamic>?) ?? {},
      );

      jsonData['estado_de_la_solicitud'] = nuevoEstado;

      // Si hay observaciones, actualizar
      if (observaciones != null) {
        jsonData['observaciones_de_la_solicitud'] = observaciones;
      }

      // 4. Construir body mínimo: solo title, modulo y json_data
      final moduloId = registerData['modulo'] ??
          (registerData['modulo_info'] as Map<String, dynamic>?)?['id'];

      final fullBody = {
        'title': registerData['title'] ?? '',
        'modulo': moduloId,
        'json_data': jsonData,
      };

      // 5. PUT
      final putResp = await EditRegister.call(
        tenant: FFAppState().organizacion,
        moduleType: 'registers',
        token: FFAppState().token,
        id: solicitud.id,
        body: jsonEncode(fullBody),
      );

      if (putResp.succeeded) {
        // Limpiar caché de activas + historial (no tocar disponibles)
        final cache = TransportAppCache();
        cache.clearKeysByPrefix(_cachePrefix(_valueActivas));
        cache.clearKeysByPrefix(_cachePrefix(_valueHistorial));
        cache.clearKeysByPrefix('historial_page_');
        refreshList();
        return null;
      }

      final errorBody = putResp.jsonBody;
      return 'Error del servidor (${putResp.statusCode}): $errorBody';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // ================================================================
  // Aceptar solicitud
  // ================================================================

  Future<String?> aceptarSolicitud(SolicitudTrabajo solicitud) async {
    try {
      // 0a. Verificar que nadie más tomó el servicio
      final dispError = await _checkDisponibilidad(solicitud);
      if (dispError != null) return dispError;

      // 0b. Verificar que el usuario no tiene otro activo
      final activoConsecutive = await _checkTieneActivo();
      if (activoConsecutive != null) {
        return 'Ya tienes un servicio activo (#$activoConsecutive). Finalízalo antes de aceptar otro.';
      }

      // 1. Obtener el registro completo actual
      final currentResp = await GetDataRegistersCall.call(
        tenant: FFAppState().organizacion,
        id: solicitud.id.toString(),
        token: FFAppState().token,
      );

      if (!currentResp.succeeded) {
        return 'No se pudo obtener el registro actual (${currentResp.statusCode})';
      }

      // 2. Obtener el objeto completo del registro
      final currentData = currentResp.jsonBody;
      debugPrint('DEBUG aceptarSolicitud - status: ${currentResp.statusCode}');
      debugPrint('DEBUG aceptarSolicitud - body: $currentData');

      final rawData = getJsonField(currentData, r'''$.data''');
      debugPrint('DEBUG aceptarSolicitud - rawData type: ${rawData.runtimeType}, value: $rawData');

      Map<String, dynamic>? registerData;
      if (rawData is Map<String, dynamic>) {
        registerData = rawData;
      } else if (rawData is List && rawData.isNotEmpty) {
        final first = rawData.first;
        if (first is Map<String, dynamic>) {
          registerData = first;
        }
      } else if (currentData is Map<String, dynamic>) {
        // El endpoint v2/register/{id}/ devuelve el objeto directamente, sin envoltura "data"
        registerData = currentData;
      }

      if (registerData == null) {
        final bodyStr = currentData.toString();
        final preview = bodyStr.length > 400 ? bodyStr.substring(0, 400) : bodyStr;
        return 'Registro no encontrado. Status: ${currentResp.statusCode}. Body preview: $preview';
      }

      // 3. Extraer json_data y modificar
      final jsonData = Map<String, dynamic>.from(
        (registerData['json_data'] as Map<String, dynamic>?) ?? {},
      );

      final appState = FFAppState();
      final userId = int.tryParse(appState.id) ?? 0;

      jsonData['ref_usuario_encargado_de_la_solicitud'] = {
        'type': 'user',
        'label': appState.fullName.isNotEmpty ? appState.fullName : appState.username,
        'value': userId,
        'avatar': appState.avatar.isNotEmpty ? appState.avatar : 'avatars/blank.svg',
        'full_name': appState.fullName.isNotEmpty ? appState.fullName : appState.username,
      };

      // Cambiar estado a "en transito"
      jsonData['estado_de_la_solicitud'] = 'en transito';

      // 4. Construir body mínimo: solo title, modulo y json_data
      final moduloId = registerData['modulo'] ??
          (registerData['modulo_info'] as Map<String, dynamic>?)?['id'];

      final fullBody = {
        'title': registerData['title'] ?? '',
        'modulo': moduloId,
        'json_data': jsonData,
      };

      // 5. Hacer PUT
      final putResp = await EditRegister.call(
        tenant: FFAppState().organizacion,
        moduleType: 'registers',
        token: FFAppState().token,
        id: solicitud.id,
        body: jsonEncode(fullBody),
      );

      if (putResp.succeeded) {
        // 6. Limpiar cache y refrescar
        final cache = TransportAppCache();
        cache.clearKeysByPrefix(_cachePrefix(_valueDisponibles));
        cache.clearKeysByPrefix(_cachePrefix(_valueActivas));
        cache.clearKeysByPrefix('historial_page_');
        refreshList();
        return null;
      }

      // 7. Si falla, loguear el error para debug
      final errorBody = putResp.jsonBody;
      return 'Error del servidor (${putResp.statusCode}): $errorBody';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // ================================================================
  // Refresh
  // ================================================================

  /// Configura el PagingController para el listado paginado (legacy).
  PagingController<ApiPagingParams, SolicitudTrabajo> setListViewController(
    Function(ApiPagingParams) apiCall,
  ) {
    listViewApiCall = apiCall;
    return listViewPagingController ??= _createListViewController(apiCall);
  }

  PagingController<ApiPagingParams, SolicitudTrabajo> _createListViewController(
    Function(ApiPagingParams) query,
  ) {
    final controller = PagingController<ApiPagingParams, SolicitudTrabajo>(
      firstPageKey: ApiPagingParams(
        nextPageNumber: 0,
        numItems: 0,
        lastResponse: null,
      ),
    );
    return controller..addPageRequestListener(listViewGetDataModulesPage);
  }

  void listViewGetDataModulesPage(ApiPagingParams nextPageMarker) async {
    final cache = TransportAppCache();
    final pageNumber = nextPageMarker.nextPageNumber + 1;

    // 1) Revisar caché en memoria primero
    final cached = cache.getSolicitudes(pageNumber);
    if (cached != null && cached.isNotEmpty) {
      final newNumItems = nextPageMarker.numItems + cached.length;
      listViewPagingController?.appendPage(
        cached,
        ApiPagingParams(
          nextPageNumber: pageNumber,
          numItems: newNumItems,
          lastResponse: nextPageMarker.lastResponse,
        ),
      );
      return;
    }

    // 2) Si no hay caché, llamar al API
    try {
      final response = await listViewApiCall!(nextPageMarker);
      final pageItems = (GetDataModulesCall.data(response.jsonBody) ?? [])
          .map((item) => SolicitudTrabajo.fromJson(
                item as Map<String, dynamic>,
                ciudadCoords: ciudadCoordsMap,
              ))
          .toList();

      // Guardar en caché
      if (pageItems.isNotEmpty) {
        cache.setSolicitudes(pageNumber, pageItems);
      }

      final newNumItems = nextPageMarker.numItems + pageItems.length;
      listViewPagingController?.appendPage(
        pageItems,
        (pageItems.isNotEmpty)
            ? ApiPagingParams(
                nextPageNumber: pageNumber,
                numItems: newNumItems,
                lastResponse: response,
              )
            : null,
      );
    } catch (e) {
      // En caso de error, propagar al PagingController
      listViewPagingController?.error = e;
    }
  }

  /// Invalida el caché de listas y refresca todos los PagingControllers.
  Future<void> refreshList() async {
    TransportAppCache().clearLists();
    historialTotalEstimado.value = 0.0;
    historialTotalCount.value = 0;
    historialLoading.value = false;
    listViewPagingController?.refresh();
    disponiblesPagingController?.refresh();
    activasPagingController?.refresh();
    historialPagingController?.refresh();
  }

  /// Invalida el caché y refresca solo la pestaña actual.
  Future<void> refreshCurrentTab() async {
    final cache = TransportAppCache();
    switch (currentTab) {
      case SolicitudesTab.disponibles:
        cache.clearKeysByPrefix(_cachePrefix(_valueDisponibles));
        disponiblesPagingController?.refresh();
        break;
      case SolicitudesTab.activas:
        cache.clearKeysByPrefix(_cachePrefix(_valueActivas));
        activasPagingController?.refresh();
        break;
      case SolicitudesTab.historial:
        cache.clearKeysByPrefix('historial_page_');
        historialTotalEstimado.value = 0.0;
        historialTotalCount.value = 0;
        historialLoading.value = false;
        historialPagingController?.refresh();
        break;
    }
  }

  Future waitForOnePageForListView({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(const Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete =
          (listViewPagingController?.nextPageKey?.nextPageNumber ?? 0) > 0;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }
}
