import 'dart:ui';
import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../types/solicitud_trabajo.dart';
import '../utils/status_colors.dart';
import '../utils/transport_app_cache.dart';
import '../widgets/glass_card/glass_card.dart';
import '../widgets/glass_card/glass_section.dart';
import '../widgets/glass_card/glass_info_row.dart';
import '../utils/time_formatter.dart';
import '../utils/currency_formatter.dart';

class SolicitudDetailPage extends StatefulWidget {
  const SolicitudDetailPage({
    super.key,
    required this.solicitud,
    this.statusColors,
  });

  final SolicitudTrabajo solicitud;
  final Map<String, StatusColor>? statusColors;

  @override
  State<SolicitudDetailPage> createState() => _SolicitudDetailPageState();
}

class _SolicitudDetailPageState extends State<SolicitudDetailPage> {
  Map<String, dynamic>? conductorData;
  Map<String, dynamic>? vehiculoData;
  Map<String, dynamic>? clienteData;
  bool loadingConductor = false;
  bool loadingVehiculo = false;
  bool loadingCliente = false;

  @override
  void initState() {
    super.initState();
    _loadRelatedData();
  }

  void _loadRelatedData() async {
    final s = widget.solicitud;
    final calls = <Future<void>>[];

    if (s.conductorRef.type == 'module' && s.conductorRef.hasValue) {
      setState(() => loadingConductor = true);
      calls.add(_loadConductor());
    }
    if (s.vehiculoRef.type == 'module' && s.vehiculoRef.hasValue) {
      setState(() => loadingVehiculo = true);
      calls.add(_loadVehiculo());
    }
    if (s.clienteRef.type == 'module' && s.clienteRef.hasValue) {
      setState(() => loadingCliente = true);
      calls.add(_loadCliente());
    }

    await Future.wait(calls);
  }

  Future<void> _loadConductor() async {
    final ref = widget.solicitud.conductorRef;
    final cache = TransportAppCache();

    // 1) Revisar caché
    if (ref.module != null && ref.value != null) {
      final cached = cache.getRegister(ref.module!, ref.value!);
      if (cached != null) {
        setState(() => conductorData = cached);
        setState(() => loadingConductor = false);
        return;
      }
    }

    // 2) Llamar API
    try {
      final resp = await GetDataRegistersCall.call(
        tenant: FFAppState().organizacion,
        id: ref.value.toString(),
        token: FFAppState().token,
      );
      if (resp.succeeded && resp.jsonBody != null) {
        final data = GetDataRegistersCall.data(resp.jsonBody);
        if (data != null && data.isNotEmpty) {
          final item = data.first as Map<String, dynamic>?;
          setState(() => conductorData = item);
          if (ref.module != null && ref.value != null && item != null) {
            cache.setRegister(ref.module!, ref.value!, item);
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => loadingConductor = false);
  }

  Future<void> _loadVehiculo() async {
    final ref = widget.solicitud.vehiculoRef;
    final cache = TransportAppCache();

    if (ref.module != null && ref.value != null) {
      final cached = cache.getRegister(ref.module!, ref.value!);
      if (cached != null) {
        setState(() => vehiculoData = cached);
        setState(() => loadingVehiculo = false);
        return;
      }
    }

    try {
      final resp = await GetDataRegistersCall.call(
        tenant: FFAppState().organizacion,
        id: ref.value.toString(),
        token: FFAppState().token,
      );
      if (resp.succeeded && resp.jsonBody != null) {
        final data = GetDataRegistersCall.data(resp.jsonBody);
        if (data != null && data.isNotEmpty) {
          final item = data.first as Map<String, dynamic>?;
          setState(() => vehiculoData = item);
          if (ref.module != null && ref.value != null && item != null) {
            cache.setRegister(ref.module!, ref.value!, item);
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => loadingVehiculo = false);
  }

  Future<void> _loadCliente() async {
    final ref = widget.solicitud.clienteRef;
    final cache = TransportAppCache();

    if (ref.module != null && ref.value != null) {
      final cached = cache.getRegister(ref.module!, ref.value!);
      if (cached != null) {
        setState(() => clienteData = cached);
        setState(() => loadingCliente = false);
        return;
      }
    }

    try {
      final resp = await GetDataRegistersCall.call(
        tenant: FFAppState().organizacion,
        id: ref.value.toString(),
        token: FFAppState().token,
      );
      if (resp.succeeded && resp.jsonBody != null) {
        final data = GetDataRegistersCall.data(resp.jsonBody);
        if (data != null && data.isNotEmpty) {
          final item = data.first as Map<String, dynamic>?;
          setState(() => clienteData = item);
          if (ref.module != null && ref.value != null && item != null) {
            cache.setRegister(ref.module!, ref.value!, item);
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => loadingCliente = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);
    final s = widget.solicitud;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.secondaryBackground,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, isDark, theme),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primary.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.secondaryBackground,
                    theme.primaryBackground,
                  ],
                ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.transparent),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                      child: Column(
                        children: [
                          _buildHeaderCard(context, isDark, theme, s),
                          const SizedBox(height: 12),
                          _buildRouteSection(context, isDark, theme, s),
                          const SizedBox(height: 12),
                          _buildServiceInfoSection(context, isDark, theme, s),
                          const SizedBox(height: 12),
                          _buildVehicleSection(context, isDark, theme, s),
                          const SizedBox(height: 12),
                          _buildCargueSection(context, isDark, theme, s),
                          const SizedBox(height: 12),
                          _buildMetadataSection(context, isDark, theme, s),
                          const SizedBox(height: 24),
                          _buildCloseButton(context, theme),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, FlutterFlowTheme theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : theme.primaryText),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Detalle Solicitud',
        style: theme.titleMedium.override(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white : theme.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : theme.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isDark, FlutterFlowTheme theme, SolicitudTrabajo s) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${s.consecutive}',
                    style: TextStyle(
                      color: isDark ? Colors.white : theme.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildStatusBadge(context, s),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildBadge(context, s.tipoCarga, theme.primary),
                if (s.title.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildBadge(context, s.title, theme.secondaryText),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, SolicitudTrabajo s) {
    final color = getStatusColor(s.estado, widget.statusColors ?? {});

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.bgColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.bgColor.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            s.estado,
            style: TextStyle(
              color: color.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRouteSection(BuildContext context, bool isDark, FlutterFlowTheme theme, SolicitudTrabajo s) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassSection(
              title: 'Ruta',
              icon: Icons.route,
              content: Column(
                children: [
                  _buildRoutePoint(
                    context,
                    Icons.circle,
                    Colors.green,
                    s.ciudadOrigenRef.label,
                    null,
                  ),
                  _buildRouteConnector(context),
                  _buildRoutePoint(
                    context,
                    Icons.location_on,
                    Colors.red,
                    s.ciudadDestinoRef.label,
                    null,
                  ),
                ],
              ),
            ),
            GlassInfoRow(
              label: 'Producto',
              value: s.tipoCarga,
              icon: Icons.inventory_2_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePoint(BuildContext context, IconData icon, Color color, String city, String? zone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            zone != null && zone.isNotEmpty ? '$city — $zone' : city,
            style: TextStyle(
              color: isDark ? Colors.white : theme.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteConnector(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 7),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 20,
            color: theme.secondaryText.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoSection(BuildContext context, bool isDark, FlutterFlowTheme theme, SolicitudTrabajo s) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassSection(
              title: 'Información del Servicio',
              icon: Icons.business_outlined,
              content: Column(
                children: [
                  _buildInfoRowWithLoading(
                    label: 'Cliente',
                    value: s.clienteRef.label,
                    icon: Icons.business,
                    isLoading: loadingCliente,
                    loadedData: clienteData,
                    dataField: 'nombre_completo',
                  ),
                  GlassInfoRow(label: 'Remitente', value: s.remitenteRef.label, icon: Icons.person_outline),
                  GlassInfoRow(label: 'Destinatario', value: s.destinatarioRef.label, icon: Icons.person_pin),
                  GlassInfoRow(label: 'Forma pago', value: 'Por definir', icon: Icons.payments_outlined),
                  GlassInfoRow(
                    label: 'Observación',
                    value: s.observaciones,
                    icon: Icons.note_outlined,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection(BuildContext context, bool isDark, FlutterFlowTheme theme, SolicitudTrabajo s) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassSection(
              title: 'Vehículo y Conductor',
              icon: Icons.local_shipping_outlined,
              content: Column(
                children: [
                  _buildInfoRowWithLoading(
                    label: 'Vehículo',
                    value: s.vehiculoRef.label,
                    icon: Icons.fire_truck,
                    isLoading: loadingVehiculo,
                    loadedData: vehiculoData,
                    dataField: 'placa',
                  ),
                  _buildInfoRowWithLoading(
                    label: 'Conductor',
                    value: s.conductorRef.label,
                    icon: Icons.person,
                    isLoading: loadingConductor,
                    loadedData: conductorData,
                    dataField: 'nombre_completo',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowWithLoading({
    required String label,
    required String value,
    required IconData icon,
    required bool isLoading,
    Map<String, dynamic>? loadedData,
    String? dataField,
  }) {
    final displayValue = (loadedData != null && dataField != null)
        ? '${loadedData[dataField] ?? value}'
        : value;

    return Row(
      children: [
        Expanded(
          child: GlassInfoRow(label: label, value: displayValue, icon: icon),
        ),
        if (isLoading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildCargueSection(BuildContext context, bool isDark, FlutterFlowTheme theme, SolicitudTrabajo s) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassSection(
              title: 'Información del Cargue',
              icon: Icons.inventory,
              content: Column(
                children: [
                  GlassInfoRow(
                    label: 'Fecha',
                    value: formatDate(s.fechaSolicitud),
                    icon: Icons.calendar_today,
                  ),
                  GlassInfoRow(
                    label: 'Hora',
                    value: formatTime(s.fechaSolicitud),
                    icon: Icons.access_time,
                  ),
                  GlassInfoRow(label: 'Peso', value: '—', icon: Icons.scale),
                  GlassInfoRow(label: 'Empaque', value: '—', icon: Icons.inventory_2),
                  GlassInfoRow(
                    label: 'Valor estimado',
                    value: formatCurrencyCOP(s.valorEstimado),
                    icon: Icons.attach_money,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context, bool isDark, FlutterFlowTheme theme, SolicitudTrabajo s) {
    return GlassCard(
      opacity: 0.3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassSection(
              title: 'Metadatos',
              icon: Icons.info_outline,
              content: Column(
                children: [
                  GlassInfoRow(
                    label: 'Usuario',
                    value: s.usuarioRef.fullName ?? s.usuarioRef.label,
                    icon: Icons.person,
                  ),
                  GlassInfoRow(
                    label: 'Creado',
                    value: s.publishedDate != null ? formatDate(s.publishedDate!) : '—',
                    icon: Icons.add_circle_outline,
                  ),
                  GlassInfoRow(
                    label: 'Modificado',
                    value: s.lastUpdated != null ? formatDate(s.lastUpdated!) : '—',
                    icon: Icons.edit_calendar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, FlutterFlowTheme theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Cerrar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
