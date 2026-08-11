import 'dart:ui';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/cargo_request.dart';
import '../widgets/glass_card/glass_card.dart';
import '../widgets/glass_card/glass_section.dart';
import '../widgets/glass_card/glass_info_row.dart';
import '../utils/time_formatter.dart';
import '../utils/currency_formatter.dart';

class CargoRequestDetailPage extends StatelessWidget {
  const CargoRequestDetailPage({
    super.key,
    required this.cargoRequest,
  });

  final CargoRequest cargoRequest;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);

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
            // Fondo con blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Contenido scrollable
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                      child: Column(
                        children: [
                          _buildHeaderCard(context, isDark, theme),
                          const SizedBox(height: 12),
                          _buildRouteSection(context, isDark, theme),
                          const SizedBox(height: 12),
                          _buildServiceInfoSection(context, isDark, theme),
                          const SizedBox(height: 12),
                          _buildVehicleSection(context, isDark, theme),
                          const SizedBox(height: 12),
                          _buildCargueSection(context, isDark, theme),
                          if (cargoRequest.imagenes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildImagesSection(context, isDark, theme),
                          ],
                          const SizedBox(height: 12),
                          _buildMetadataSection(context, isDark, theme),
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

  Widget _buildHeaderCard(BuildContext context, bool isDark, FlutterFlowTheme theme) {
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
                    '#${cargoRequest.codigo}',
                    style: TextStyle(
                      color: isDark ? Colors.white : theme.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildBadge(
                  context,
                  cargoRequest.tipoViaje,
                  theme.primary,
                ),
                if (cargoRequest.servicio != null) ...[
                  const SizedBox(width: 8),
                  _buildBadge(
                    context,
                    cargoRequest.servicio!,
                    theme.secondaryText,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final estado = cargoRequest.estado.toUpperCase();

    Color bgColor;
    Color textColor = Colors.white;
    if (estado == 'DESPACHADA') {
      bgColor = Colors.green;
    } else if (estado == 'CANCELADA') {
      bgColor = Colors.red;
    } else if (estado == 'PENDIENTE') {
      bgColor = Colors.orange;
    } else {
      bgColor = theme.secondaryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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

  Widget _buildRouteSection(BuildContext context, bool isDark, FlutterFlowTheme theme) {
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
                    cargoRequest.ciudadOrigen,
                    cargoRequest.zonaOrigen,
                  ),
                  _buildRouteConnector(context),
                  _buildRoutePoint(
                    context,
                    Icons.location_on,
                    Colors.red,
                    cargoRequest.ciudadDestino,
                    cargoRequest.zonaDestino,
                  ),
                ],
              ),
            ),
            GlassInfoRow(
              label: 'Producto',
              value: cargoRequest.producto,
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

  Widget _buildServiceInfoSection(BuildContext context, bool isDark, FlutterFlowTheme theme) {
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
                  GlassInfoRow(label: 'Cliente', value: cargoRequest.cliente, icon: Icons.business),
                  GlassInfoRow(label: 'Remitente', value: cargoRequest.remitente, icon: Icons.person_outline),
                  GlassInfoRow(label: 'Destinatario', value: cargoRequest.destinatario, icon: Icons.person_pin),
                  GlassInfoRow(label: 'Forma pago', value: cargoRequest.formaPago, icon: Icons.payments_outlined),
                  GlassInfoRow(
                    label: 'Observación',
                    value: cargoRequest.observacion,
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

  Widget _buildVehicleSection(BuildContext context, bool isDark, FlutterFlowTheme theme) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassSection(
              title: 'Información del Vehículo',
              icon: Icons.local_shipping_outlined,
              content: Column(
                children: [
                  GlassInfoRow(label: 'Carrocería', value: cargoRequest.carroceria, icon: Icons.fire_truck),
                  GlassInfoRow(label: 'Clase', value: cargoRequest.claseVehiculo ?? '—', icon: Icons.category),
                  GlassInfoRow(label: 'No. vehículos', value: cargoRequest.noVehiculos, icon: Icons.numbers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargueSection(BuildContext context, bool isDark, FlutterFlowTheme theme) {
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
                    value: formatDate(cargoRequest.fechaCargue),
                    icon: Icons.calendar_today,
                  ),
                  GlassInfoRow(
                    label: 'Hora',
                    value: formatTime(cargoRequest.horaCargue),
                    icon: Icons.access_time,
                  ),
                  GlassInfoRow(
                    label: 'Peso',
                    value: '${cargoRequest.peso.toStringAsFixed(1)} kg',
                    icon: Icons.scale,
                  ),
                  GlassInfoRow(label: 'Empaque', value: cargoRequest.empaque, icon: Icons.inventory_2),
                  GlassInfoRow(label: 'Cantidad', value: cargoRequest.cantidad, icon: Icons.tag),
                  if (cargoRequest.valorMercancia != null)
                    GlassInfoRow(
                      label: 'Valor mercancía',
                      value: formatCurrencyCOP(cargoRequest.valorMercancia!),
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

  Widget _buildImagesSection(BuildContext context, bool isDark, FlutterFlowTheme theme) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassSection(
              title: 'Imágenes (${cargoRequest.imagenes.length})',
              icon: Icons.photo_library_outlined,
              content: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cargoRequest.imagenes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.secondaryBackground,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          cargoRequest.imagenes[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image,
                            color: theme.secondaryText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context, bool isDark, FlutterFlowTheme theme) {
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
                  GlassInfoRow(label: 'Usuario', value: cargoRequest.usuario, icon: Icons.person),
                  GlassInfoRow(
                    label: 'Creado',
                    value: formatDate(cargoRequest.fechaCreacion),
                    icon: Icons.add_circle_outline,
                  ),
                  GlassInfoRow(
                    label: 'Modificado',
                    value: formatDate(cargoRequest.fechaModificacion),
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
