import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../backend/api_requests/api_calls_mercadopago.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';

/// Pantalla de resultado de pago Mercado Pago (equivalente a PaymentResult.tsx).
///
/// Se muestra cuando el deep link queryapp://pago-exitoso/fallido/pendiente
/// abre la app. Sincroniza el pago y muestra el resultado.
class PaymentResultScreen extends StatefulWidget {
  final String type; // 'success', 'failure', 'pending'

  const PaymentResultScreen({super.key, required this.type});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  bool _syncing = true;
  String? _status;
  String? _paymentId;
  String? _errorMessage;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 3;

  // Configuración por tipo de resultado
  late final _config = _resultConfigs[widget.type]!;

  static const Map<String, _ResultConfig> _resultConfigs = {
    'success': _ResultConfig(
      icon: Icons.check_circle,
      iconColor: Color(0xFF28A745),
      title: 'Pago exitoso',
      description: 'Tu pago fue procesado correctamente.',
      bgColor: Color(0xFFD4EDDA),
    ),
    'failure': _ResultConfig(
      icon: Icons.cancel,
      iconColor: Color(0xFFDC3545),
      title: 'Pago fallido',
      description: 'No pudimos procesar tu pago. Puedes intentarlo nuevamente.',
      bgColor: Color(0xFFF8D7DA),
    ),
    'pending': _ResultConfig(
      icon: Icons.access_time,
      iconColor: Color(0xFFFFC107),
      title: 'Pago pendiente',
      description: 'Tu pago está siendo procesado. Te notificaremos cuando se confirme.',
      bgColor: Color(0xFFFFF3CD),
    ),
  };

  bool _syncStarted = false;

  @override
  void initState() {
    super.initState();
    // No llamar _syncPayment aquí — GoRouterState.of(context) no está disponible en initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_syncStarted) {
      _syncStarted = true;
      _syncPayment();
    }
  }

  Future<void> _syncPayment() async {
    // Usar la URI guardada en el redirect (GoRouter strippea los query params)
    final uri = FFAppState().mpDeepLinkUri;
    final paymentId = uri?.queryParameters['collection_id'] ??
        uri?.queryParameters['payment_id'] ??
        '';

    if (paymentId.isEmpty) {
      setState(() {
        _syncing = false;
        _errorMessage = 'No se encontró ID de pago en el deep link.';
      });
      return;
    }

    try {
      final response = await MercadoPagoSyncPaymentCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        paymentId: paymentId,
      );

      if (response.succeeded && response.jsonBody is Map) {
        final body = response.jsonBody as Map<String, dynamic>;
        final newStatus = body['status']?.toString() ?? 'pending';
        final synced = body['synced'] as bool? ?? false;

        setState(() {
          _status = newStatus;
          _paymentId = body['payment_id']?.toString() ?? paymentId;
          _syncing = false;
        });

        // Si sigue pendiente y no se ha sync, poll
        if ((newStatus == 'pending' || newStatus == 'in_process') &&
            _pollAttempts < _maxPollAttempts) {
          _pollAttempts++;
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) _syncPayment();
        }
      } else {
        setState(() {
          _syncing = false;
          _errorMessage = 'Error al sincronizar el pago.';
        });
      }
    } catch (e) {
      setState(() {
        _syncing = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  String _formatCurrency(dynamic amount, {String currency = 'COP'}) {
    if (amount == null) return '';
    final value = (amount is num) ? amount : num.tryParse(amount.toString());
    if (value == null) return '';
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: currency == 'COP' ? '\$' : currency,
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  void _navigateToRecord() {
    final moduleName = FFAppState().mpDeepLinkModuleName;
    final recordId = FFAppState().mpDeepLinkRecordId;

    if (moduleName.isEmpty || recordId == 0) {
      context.go('/home');
      return;
    }

    _fetchAndNavigate(moduleName, recordId);
  }

  Future<void> _fetchAndNavigate(String moduleName, int recordId) async {
    try {
      // Buscar en recientes (tiene el full record data de cuando el usuario lo visitó)
      for (final item in FFAppState().recientes) {
        if (item is Map<String, dynamic>) {
          final itemModuleName = getJsonField(item, r'''$.modulo_info.name''').toString();
          final itemId = getJsonField(item, r'''$.id''');
          if (itemModuleName == moduleName && itemId.toString() == recordId.toString()) {
            if (mounted) {
              context.pushNamed(
                'detailGrouped',
                queryParameters: {
                  'title': serializeParam(
                    getJsonField(item, r'''$.title''').toString(),
                    ParamType.String,
                  ),
                  'body': serializeParam(
                    getJsonField(item, r'''$.body''').toString(),
                    ParamType.String,
                  ),
                  'general': serializeParam(item, ParamType.JSON),
                }.withoutNulls,
              );
              FFAppState().clearMpDeepLink();
              return;
            }
          }
        }
      }

      // Fallback: ir a home si no encontró en recientes
      debugPrint('PaymentResult: record not found in recientes, going home');
      if (mounted) context.go('/home');
    } catch (e) {
      debugPrint('PaymentResult _fetchAndNavigate error: $e');
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono resultado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _config.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _config.icon,
                      size: 64,
                      color: _config.iconColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    _config.title,
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Descripción
                  Text(
                    _config.description,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Outfit',
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Detalles del pago
                  if (_paymentId != null || _status != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (_paymentId != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ID de pago:',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(fontFamily: 'Outfit'),
                                ),
                                Text(
                                  _paymentId!,
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_status != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estado:',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(fontFamily: 'Outfit'),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusLabel,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Sync indicator
                  if (_syncing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Verificando estado con Mercado Pago...',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(fontFamily: 'Outfit'),
                        ),
                      ],
                    ),

                  // Error
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Botones
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _syncing ? null : _navigateToRecord,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Volver al registro'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home, size: 18),
                      label: const Text('Ir al inicio'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  Color get _statusColor {
    switch (_status) {
      case 'approved':
        return const Color(0xFF28A745);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFDC3545);
      case 'pending':
      case 'in_process':
        return const Color(0xFFFFC107);
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      case 'pending':
        return 'Pendiente';
      case 'in_process':
        return 'En Proceso';
      case 'refunded':
        return 'Reembolsado';
      default:
        return _status ?? '';
    }
  }
}

class _ResultConfig {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Color bgColor;

  const _ResultConfig({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.bgColor,
  });
}
