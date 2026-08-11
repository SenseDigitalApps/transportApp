import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '/backend/api_requests/api_calls.dart';
import '/components/side_nav/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/home_initialization_service.dart';

import 'custom_map_transportapp_model.dart';
import 'types/solicitud_trabajo.dart';
import 'types/map_config.dart';
import 'pages/solicitud_detail_page.dart';
import 'widgets/activa_card.dart';
import 'widgets/cargo_request_card.dart';
import 'widgets/disponible_card.dart';
import 'widgets/historial_card.dart';
import 'widgets/glass_card/glass_card.dart';
import 'widgets/novedad_bottom_sheet.dart';
import 'utils/currency_formatter.dart';
import 'widgets/transport_app_bar.dart';
import 'widgets/transport_map_view.dart';

class CustomMapTransportappWidget extends StatefulWidget {
  const CustomMapTransportappWidget({super.key});

  @override
  State<CustomMapTransportappWidget> createState() =>
      _CustomMapTransportappWidgetState();
}

class _CustomMapTransportappWidgetState
    extends State<CustomMapTransportappWidget> {
  // Controllers
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final mapController = Completer<GoogleMapController>();
  final _sheetKey = GlobalKey<_TransportTabbedBottomSheetState>();

  late CustomMapTransportappModel _model;
  final ValueNotifier<SolicitudTrabajo?> selectedNotifier = ValueNotifier(null);
  List<FlutterFlowMarker> markers = [];
  Set<Polyline> polylines = {};

  SolicitudesTab _currentTab = SolicitudesTab.disponibles;
  SolicitudTrabajo? _activeSolicitud;
  // ignore: unused_field
  bool _aceptando = false;

  // --- Lifecycle -------------------------------------------------

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomMapTransportappModel());
    _model.firstActiveWithGps.addListener(_onActiveServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await HomeInitializationService.runPostLoginChecks(context);
      await _model.loadStatusColors();
      await _model.checkForActiveService();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _model.firstActiveWithGps.removeListener(_onActiveServiceChanged);
    selectedNotifier.dispose();
    _model.dispose();
    super.dispose();
  }

  // --- Active service handling -----------------------------------

  void _onActiveServiceChanged() {
    final active = _model.firstActiveWithGps.value;
    if (active != null && _activeSolicitud?.id != active.id) {
      setState(() => _activeSolicitud = active);
      _selectSolicitud(active);
    } else if (active == null && _activeSolicitud != null) {
      setState(() {
        _activeSolicitud = null;
        selectedNotifier.value = null;
        markers = [];
        polylines = {};
      });
    }
  }

  void _onSelectSolicitud(SolicitudTrabajo solicitud) {
    if (_activeSolicitud != null && solicitud.id != _activeSolicitud!.id) {
      return;
    }
    _selectSolicitud(solicitud);
  }

  // --- Map actions -----------------------------------------------

  Future<void> _openCreateConductor() async {
    final moduleConfigResponse = await GetCustomFieldsPerModuleCall.call(
      tenant: FFAppState().organizacion,
      moduleName: 'conductores',
      token: FFAppState().token,
    );

    if (!mounted) return;

    await context.pushNamed(
      'newRegistersModule',
      queryParameters: {
        'moduleConfigData': serializeParam(
          getJsonField(moduleConfigResponse.jsonBody, r'''$.data'''),
          ParamType.JSON,
        ),
        'moduleName': serializeParam('conductores', ParamType.String),
        'moduleId': serializeParam(44, ParamType.int),
        'moduleType': serializeParam('registers', ParamType.String),
      }.withoutNulls,
    );
  }

  Future<void> _openCreateVehiculo() async {
    final moduleConfigResponse = await GetCustomFieldsPerModuleCall.call(
      tenant: FFAppState().organizacion,
      moduleName: 'vehiculos',
      token: FFAppState().token,
    );

    if (!mounted) return;

    await context.pushNamed(
      'newRegistersModule',
      queryParameters: {
        'moduleConfigData': serializeParam(
          getJsonField(moduleConfigResponse.jsonBody, r'''$.data'''),
          ParamType.JSON,
        ),
        'moduleName': serializeParam('vehiculos', ParamType.String),
        'moduleId': serializeParam(45, ParamType.int),
        'moduleType': serializeParam('registers', ParamType.String),
      }.withoutNulls,
    );
  }

  void _selectSolicitud(SolicitudTrabajo solicitud) {
    selectedNotifier.value = solicitud;

    final newMarkers = <FlutterFlowMarker>[];
    final newPolylines = <Polyline>{};

    if (solicitud.origenCoords != null) {
      newMarkers.add(FlutterFlowMarker('origin', solicitud.origenCoords!));
    }
    if (solicitud.destinoCoords != null) {
      newMarkers.add(FlutterFlowMarker('destination', solicitud.destinoCoords!));
    }

    // Polyline recto origen -> destino (rápido para demo)
    if (solicitud.origenCoords != null && solicitud.destinoCoords != null) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            solicitud.origenCoords!.toGoogleMaps(),
            solicitud.destinoCoords!.toGoogleMaps(),
          ],
          color: const Color(0xFF2196F3),
          width: 4,
          geodesic: true,
        ),
      );
    }

    setState(() {
      markers = newMarkers;
      polylines = newPolylines;
    });

    _animateToSolicitud(solicitud);
    const sheetMidSize = 0.45;
    final sc = _sheetKey.currentState?.sheetController;
    if (sc != null && sc.isAttached) {
      sc.animateTo(
        sheetMidSize,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sc2 = _sheetKey.currentState?.sheetController;
        if (sc2 != null && sc2.isAttached) {
          sc2.animateTo(
            sheetMidSize,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  Future<void> _animateToSolicitud(SolicitudTrabajo solicitud) async {
    if (!mapController.isCompleted) return;
    final controller = await mapController.future;

    final origin = solicitud.origenCoords;
    final destination = solicitud.destinoCoords;

    if (origin != null && destination != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(origin.latitude, destination.latitude),
          math.min(origin.longitude, destination.longitude),
        ).toGoogleMaps(),
        northeast: LatLng(
          math.max(origin.latitude, destination.latitude),
          math.max(origin.longitude, destination.longitude),
        ).toGoogleMaps(),
      );
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, MapConfig.routeBoundsPadding),
      );
    } else {
      final target = origin ?? MapConfig.defaultOrigin;
      await controller.animateCamera(
        CameraUpdate.newLatLng(target.toGoogleMaps()),
      );
    }
  }

  // --- Aceptar flow ----------------------------------------------

  Future<void> _handleAceptarSolicitud(SolicitudTrabajo solicitud) async {
    final confirmed = await _showAceptarConfirmModal(solicitud);
    if (!confirmed || !mounted) return;

    setState(() => _aceptando = true);
    final error = await _model.aceptarSolicitud(solicitud);
    setState(() => _aceptando = false);

    if (!mounted) return;

    if (error == null) {
      _showAceptarSuccessAnimation(solicitud);
      if (selectedNotifier.value?.id == solicitud.id) {
        selectedNotifier.value = null;
      }
    } else {
      // Detectar tipo de error para icono y acción
      final isConflict = error.contains('ya fue tomado') || error.contains('Ya tienes');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: isConflict ? Colors.orange.shade700 : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      // Si fue tomado, refrescar disponibles para que desaparezca
      if (error.contains('ya fue tomado')) {
        _model.refreshCurrentTab();
      }
    }
  }

  Future<bool> _showAceptarConfirmModal(SolicitudTrabajo solicitud) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _AceptarConfirmSheet(solicitud: solicitud),
        ) ??
        false;
  }

  void _showAceptarSuccessAnimation(SolicitudTrabajo solicitud) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => _SuccessAnimationDialog(
        solicitud: solicitud,
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _handleEntregar(SolicitudTrabajo solicitud) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EntregarConfirmSheet(solicitud: solicitud),
    ) ?? false;

    if (!confirmed || !mounted) return;

    setState(() => _aceptando = true);
    final error = await _model.cambiarEstado(solicitud, 'entregado');
    setState(() => _aceptando = false);

    if (!mounted) return;

    if (error == null) {
      _showEntregadoSuccessPopup(solicitud);
      if (selectedNotifier.value?.id == solicitud.id) {
        selectedNotifier.value = null;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEntregadoSuccessPopup(SolicitudTrabajo solicitud) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => _EntregadoSuccessDialog(solicitud: solicitud),
    );
  }

  Future<void> _handleNovedad(SolicitudTrabajo solicitud) async {
    final observaciones = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NovedadBottomSheet(solicitud: solicitud),
    );

    if (observaciones == null || !mounted) return;

    setState(() => _aceptando = true);
    final error = await _model.cambiarEstado(
      solicitud,
      'con_novedad',
      observaciones: observaciones,
    );
    setState(() => _aceptando = false);

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Novedad reportada para #${solicitud.consecutive}'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (selectedNotifier.value?.id == solicitud.id) {
        selectedNotifier.value = null;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openDetail(SolicitudTrabajo solicitud) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SolicitudDetailPage(
          solicitud: solicitud,
          statusColors: _model.statusColors,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // --- Build -----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : FlutterFlowTheme.of(context).secondaryBackground,
      drawer: _buildDrawer(),
      appBar: TransportAppBar(
        scaffoldKey: scaffoldKey,
        title: 'TransportApp',
        onCreateConductorTap: _openCreateConductor,
        onCreateVehiculoTap: _openCreateVehiculo,
      ),
      body: Stack(
        children: [
          TransportMapView(
            controller: mapController,
            initialLocation: MapConfig.defaultOrigin,
            markers: markers,
            polylines: polylines,
            initialZoom: MapConfig.defaultZoom,
          ),
          ValueListenableBuilder<SolicitudTrabajo?>(
            valueListenable: selectedNotifier,
            builder: (context, selected, _) {
              if (selected?.origenCoords == null || selected?.destinoCoords == null) {
                return _buildNoGpsBanner(isDark);
              }
              return const SizedBox.shrink();
            },
          ),
          if (_activeSolicitud != null) _buildActiveServiceBanner(isDark),
          Positioned.fill(
            child: Column(
              children: [
                const Spacer(),
                Expanded(
                  flex: 52,
                  child: _TransportTabbedBottomSheet(
                    key: _sheetKey,
                    model: _model,
                    selectedNotifier: selectedNotifier,
                    currentTab: _currentTab,
                    hasActiveService: _activeSolicitud != null,
                    onTabChanged: (tab) {
                      setState(() {
                        _currentTab = tab;
                        if (_activeSolicitud == null) {
                          selectedNotifier.value = null;
                        }
                      });
                      _model.currentTab = tab;
                    },
                    onSelect: _onSelectSolicitud,
                    onAceptar: _handleAceptarSolicitud,
                    onEntregar: _handleEntregar,
                    onNovedad: _handleNovedad,
                    onDetailTap: _openDetail,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGpsBanner(bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + (_activeSolicitud != null ? 110 : 70),
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gps_off, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Ruta sin datos GPS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveServiceBanner(bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping, size: 16, color: Colors.blue.shade400),
              const SizedBox(width: 8),
              Text(
                'Servicio #${_activeSolicitud!.consecutive} en tránsito — ruta activa',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      elevation: 16.0,
      child: WebViewAware(
        child: wrapWithModel(
          model: _model.sideNavModel,
          updateCallback: () => setState(() {}),
          child: const SideNavWidget(),
        ),
      ),
    );
  }
}

// ============================================================================
// Bottom Sheet con Tabs
// ============================================================================

class _TransportTabbedBottomSheet extends StatefulWidget {
  const _TransportTabbedBottomSheet({
    super.key,
    required this.model,
    required this.selectedNotifier,
    required this.currentTab,
    required this.hasActiveService,
    required this.onTabChanged,
    required this.onSelect,
    required this.onAceptar,
    required this.onEntregar,
    required this.onNovedad,
    required this.onDetailTap,
  });

  final CustomMapTransportappModel model;
  final ValueNotifier<SolicitudTrabajo?> selectedNotifier;
  final SolicitudesTab currentTab;
  final bool hasActiveService;
  final void Function(SolicitudesTab) onTabChanged;
  final void Function(SolicitudTrabajo) onSelect;
  final void Function(SolicitudTrabajo) onAceptar;
  final void Function(SolicitudTrabajo) onEntregar;
  final void Function(SolicitudTrabajo) onNovedad;
  final void Function(SolicitudTrabajo) onDetailTap;

  @override
  State<_TransportTabbedBottomSheet> createState() => _TransportTabbedBottomSheetState();
}

class _TransportTabbedBottomSheetState extends State<_TransportTabbedBottomSheet> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  ScrollController? _listScrollController;

  DraggableScrollableController get sheetController => _sheetController;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_listScrollController != null && _listScrollController!.hasClients) {
      _listScrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: MapConfig.initialSheetChildSize,
      minChildSize: MapConfig.minSheetChildSize,
      maxChildSize: MapConfig.maxSheetChildSize,
      builder: (context, scrollController) {
        _listScrollController = scrollController;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.78),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 4),
                    width: 60,
                    height: 28,
                    alignment: Alignment.center,
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  _buildTabHeader(isDark),
                  Expanded(
                    child: _buildContentForTab(scrollController),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Disponibles',
                      icon: Icons.flight_takeoff,
                      isSelected: widget.currentTab == SolicitudesTab.disponibles,
                      onTap: () => widget.onTabChanged(SolicitudesTab.disponibles),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Activas',
                      icon: Icons.play_circle_outline,
                      isSelected: widget.currentTab == SolicitudesTab.activas,
                      onTap: () => widget.onTabChanged(SolicitudesTab.activas),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Historial',
                      icon: Icons.history,
                      isSelected: widget.currentTab == SolicitudesTab.historial,
                      onTap: () => widget.onTabChanged(SolicitudesTab.historial),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: Material(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => widget.model.refreshCurrentTab(),
                child: const Icon(Icons.refresh, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentForTab(ScrollController scrollController) {
    final controller = widget.model.getControllerForTab(widget.currentTab);

    return Column(
      children: [
        if (widget.currentTab == SolicitudesTab.historial)
          _buildHistorialSummary(),
        Expanded(
          child: PagedListView<ApiPagingParams, SolicitudTrabajo>(
            key: ValueKey('paged_list_${widget.currentTab.name}'),
            scrollController: scrollController,
            pagingController: controller,
            padding: const EdgeInsets.only(bottom: 8),
            builderDelegate: PagedChildBuilderDelegate<SolicitudTrabajo>(
              firstPageProgressIndicatorBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
              firstPageErrorIndicatorBuilder: (context) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Error al cargar solicitudes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => controller.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
              newPageProgressIndicatorBuilder: (_) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              noItemsFoundIndicatorBuilder: (_) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    widget.currentTab == SolicitudesTab.disponibles
                        ? 'No hay solicitudes disponibles'
                        : widget.currentTab == SolicitudesTab.activas
                            ? 'No tienes solicitudes activas'
                            : 'No hay historial de solicitudes',
                  ),
                ),
              ),
              itemBuilder: (context, solicitud, index) {
                return ValueListenableBuilder<SolicitudTrabajo?>(
                  valueListenable: widget.selectedNotifier,
                  builder: (context, selected, _) {
                    return _buildCardForTab(solicitud, selected);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialSummary() {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: widget.model.historialLoading,
      builder: (context, loading, _) {
        return ValueListenableBuilder<double>(
          valueListenable: widget.model.historialTotalEstimado,
          builder: (context, totalEstimado, _) {
            return ValueListenableBuilder<int>(
              valueListenable: widget.model.historialTotalCount,
              builder: (context, totalCount, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GlassCard(
                    opacity: 0.6,
                    borderRadius: 14,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: theme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total estimado',
                                  style: TextStyle(
                                    color: theme.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                if (loading)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Calculando...',
                                        style: TextStyle(
                                          color: theme.secondaryText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    formatCurrencyCOP(totalEstimado),
                                    style: TextStyle(
                                      color: isDark ? Colors.white : theme.primaryText,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '$totalCount solicitudes',
                            style: TextStyle(
                              color: theme.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCardForTab(SolicitudTrabajo solicitud, SolicitudTrabajo? selected) {
    final isSelected = selected?.id == solicitud.id;

    if (widget.currentTab == SolicitudesTab.disponibles) {
      return DisponibleCard(
        solicitud: solicitud,
        isSelected: isSelected,
        onTap: () {
          widget.onSelect(solicitud);
          _scrollToTop();
        },
        onAceptar: () => widget.onAceptar(solicitud),
        onCardTap: () => widget.onDetailTap(solicitud),
        statusColors: widget.model.statusColors,
      );
    } else if (widget.currentTab == SolicitudesTab.historial) {
      return HistorialCard(
        solicitud: solicitud,
        isSelected: isSelected,
        onTap: () => widget.onSelect(solicitud),
        onCardTap: () => widget.onDetailTap(solicitud),
        statusColors: widget.model.statusColors,
      );
    } else if (widget.currentTab == SolicitudesTab.activas) {
      return ActivaCard(
        solicitud: solicitud,
        isSelected: isSelected,
        onTap: () => widget.onSelect(solicitud),
        onCardTap: () => widget.onDetailTap(solicitud),
        onEntregar: () => widget.onEntregar(solicitud),
        onNovedad: () => widget.onNovedad(solicitud),
        statusColors: widget.model.statusColors,
      );
    } else {
      return CargoRequestCard(
        solicitud: solicitud,
        isSelected: isSelected,
        onTap: () => widget.onSelect(solicitud),
        onCardTap: () => widget.onDetailTap(solicitud),
        statusColors: widget.model.statusColors,
      );
    }
  }
}

// ============================================================================
// Tab Button
// ============================================================================

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.primary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Modal de Confirmación
// ============================================================================

class _AceptarConfirmSheet extends StatelessWidget {
  const _AceptarConfirmSheet({required this.solicitud});

  final SolicitudTrabajo solicitud;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.4,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_shipping, size: 32, color: theme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Aceptar este servicio?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('#${solicitud.consecutive} — ${solicitud.title}'),
                _buildDetailRow('${solicitud.ciudadOrigenRef.label} → ${solicitud.ciudadDestinoRef.label}'),
                _buildDetailRow(formatCurrencyCOP(solicitud.valorEstimado)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Sí, aceptar servicio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================================================
// Modal de Confirmación Entregado
// ============================================================================

class _EntregarConfirmSheet extends StatelessWidget {
  const _EntregarConfirmSheet({required this.solicitud});

  final SolicitudTrabajo solicitud;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 32, color: Colors.green.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Marcar como entregado?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  '#${solicitud.consecutive} — ${solicitud.title}',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Sí, marcar entregado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Animación de Éxito
// ============================================================================

class _SuccessAnimationDialog extends StatefulWidget {
  const _SuccessAnimationDialog({
    required this.solicitud,
    required this.onDismiss,
  });

  final SolicitudTrabajo solicitud;
  final VoidCallback onDismiss;

  @override
  State<_SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0)),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none),
              child: GlassCard(
                blur: 30,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        '¡Servicio aceptado!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '#${widget.solicitud.consecutive} — ${widget.solicitud.title}',
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.none,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mírala en "Activas"',
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.none,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// Dialog de Éxito - Entregado
// ============================================================================

class _EntregadoSuccessDialog extends StatefulWidget {
  const _EntregadoSuccessDialog({required this.solicitud});

  final SolicitudTrabajo solicitud;

  @override
  State<_EntregadoSuccessDialog> createState() => _EntregadoSuccessDialogState();
}

class _EntregadoSuccessDialogState extends State<_EntregadoSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0)),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none),
              child: GlassCard(
                blur: 30,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Servicio entregado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '#${widget.solicitud.consecutive} — ${widget.solicitud.title}',
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.none,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
