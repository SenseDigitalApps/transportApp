import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../backend/api_requests/api_calls_mercadopago.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';

/// Widget para campos de tipo "mercadopago" en formularios dinámicos de Query.
///
/// Soporta:
/// - Pagos puntuales (Checkout Pro) via Mercado Pago
/// - Suscripciones con plan (preapproval_plan)
/// - Suscripciones sin plan (preapproval directo)
///
/// Flujo móvil:
/// 1. Muestra botón de pago/suscripción
/// 2. POST a backend para crear preferencia/suscripción
/// 3. Abre navegador externo con init_point
/// 4. Detecta retorno via AppLifecycleState.resumed
/// 5. Sincroniza estado llamando a payment-status o sync-payment
class MercadoPagoField extends StatefulWidget {
  final Map<String, dynamic> field;
  final Map<String, dynamic> jsonData;
  final Function(String slug, dynamic value, int? index, String? mainSlug)
      handleDynamicFieldChanges;
  final String? moduleName;
  final int? recordId;
  final String? recordType;
  final bool onlyView;
  final bool canEdit;
  final int? index;
  final String? mainSlug;

  const MercadoPagoField({
    super.key,
    required this.field,
    required this.jsonData,
    required this.handleDynamicFieldChanges,
    this.moduleName,
    this.recordId,
    this.recordType = 'register',
    this.onlyView = false,
    this.canEdit = true,
    this.index,
    this.mainSlug,
  });

  @override
  State<MercadoPagoField> createState() => _MercadoPagoFieldState();
}

class _MercadoPagoFieldState extends State<MercadoPagoField>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _mpConfig;
  Map<String, dynamic>? _mpData;

  // Suscripción sin plan
  final TextEditingController _emailController = TextEditingController();
  int? _selectedPlanIndex;

  // Tracking de retorno del navegador
  bool _wasInBackground = false;

  // Colores branding Mercado Pago
  static const Color _mpBlue = Color(0xFF009EE3);

  // Estados posibles
  static const Map<String, Map<String, dynamic>> _statusBadges = {
    'pending': {
      'label': 'Pendiente',
      'color': Color(0xFFFFF3CD),
      'textColor': Color(0xFF856404),
      'icon': Icons.access_time,
    },
    'approved': {
      'label': 'Pagado',
      'color': Color(0xFFD4EDDA),
      'textColor': Color(0xFF155724),
      'icon': Icons.check_circle,
    },
    'rejected': {
      'label': 'Rechazado',
      'color': Color(0xFFF8D7DA),
      'textColor': Color(0xFF721C24),
      'icon': Icons.cancel,
    },
    'in_process': {
      'label': 'En Proceso',
      'color': Color(0xFFD1ECF1),
      'textColor': Color(0xFF0C5460),
      'icon': Icons.hourglass_bottom,
    },
    'cancelled': {
      'label': 'Cancelado',
      'color': Color(0xFFE2E3E5),
      'textColor': Color(0xFF383D41),
      'icon': Icons.block,
    },
    'refunded': {
      'label': 'Reembolsado',
      'color': Color(0xFFE2D4F0),
      'textColor': Color(0xFF4A235A),
      'icon': Icons.replay,
    },
    'authorized': {
      'label': 'Activa',
      'color': Color(0xFFD4EDDA),
      'textColor': Color(0xFF155724),
      'icon': Icons.check_circle,
    },
    'paused': {
      'label': 'Pausada',
      'color': Color(0xFFFFF3CD),
      'textColor': Color(0xFF856404),
      'icon': Icons.pause_circle,
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _parseConfig();
    _loadExistingData();
    // Fetch status on mount (como web mountFetchDoneRef)
    // Maneja el caso donde el backend ya actualizó via webhook pero el widget tiene datos stale
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _fetchStatusOnMount();
    });
  }

  @override
  void didUpdateWidget(covariant MercadoPagoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonData != widget.jsonData) {
      _loadExistingData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasInBackground = true;
    }
    if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      if (_mpData != null &&
          (_mpData!['status'] == 'pending' || _mpData!['status'] == null)) {
        _handleAppResumed();
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // Helpers de configuración
  // ──────────────────────────────────────────────────────────

  void _parseConfig() {
    final options = widget.field['options'];
    if (options == null || options.toString().isEmpty) {
      _mpConfig = null;
      return;
    }
    try {
      if (options is Map<String, dynamic>) {
        _mpConfig = options;
      } else if (options is String) {
        _mpConfig = jsonDecode(options) as Map<String, dynamic>;
      } else {
        _mpConfig = jsonDecode(options.toString()) as Map<String, dynamic>;
      }
    } catch (_) {
      _mpConfig = null;
    }
  }

  void _loadExistingData() {
    final slug = widget.field['slug']?.toString() ?? '';
    final data = widget.jsonData[slug];
    if (data is Map<String, dynamic>) {
      _mpData = Map<String, dynamic>.from(data);
    } else if (data is String && data.isNotEmpty) {
      try {
        _mpData = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        _mpData = null;
      }
    } else {
      _mpData = null;
    }
    if (mounted) setState(() {});
  }

  dynamic _readJsonData(String slug) {
    return widget.jsonData[slug];
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

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy HH:mm', 'es_CO').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Lógica de precio / datos
  // ──────────────────────────────────────────────────────────

  double? _getPrice() {
    if (_mpConfig == null) return null;
    final priceSlug = _mpConfig!['unit_price_slug']?.toString() ?? '';
    if (priceSlug.isEmpty) return null;
    final raw = _readJsonData(priceSlug);
    if (raw == null) return null;
    final price =
        (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
    if (price == null || price <= 0) return null;

    final qtySlug = _mpConfig!['quantity_slug']?.toString() ?? '';
    double qty = 1;
    if (qtySlug.isNotEmpty) {
      final rawQty = _readJsonData(qtySlug);
      qty = (rawQty is num)
          ? rawQty.toDouble()
          : double.tryParse(rawQty.toString()) ?? 1;
      if (qty <= 0) qty = 1;
    }
    return price * qty;
  }

  String _getCurrency() {
    return _mpConfig?['currency_id']?.toString() ?? 'COP';
  }

  bool _isSubscriptionEnabled() {
    return _mpConfig?['subscription_enabled'] == true;
  }

  String _getSubscriptionMode() {
    return _mpConfig?['subscription_mode']?.toString() ?? '';
  }

  List<dynamic> _getSubscriptionPlans() {
    final plans = _mpConfig?['subscription_plans'];
    if (plans is List) return plans;
    return [];
  }

  String _getNormalizedRecordType() {
    var recordType = widget.recordType ?? 'register';
    if (recordType.endsWith('s')) {
      recordType = recordType.substring(0, recordType.length - 1);
    }
    return recordType;
  }

  bool _hasRecordId() {
    return widget.recordId != null && widget.recordId! > 0;
  }

  // ──────────────────────────────────────────────────────────
  // API Calls
  // ──────────────────────────────────────────────────────────

  Future<void> _createPreference() async {
    if (!_hasRecordId()) {
      _showSnackBar('Guarda el registro primero para poder pagar.');
      return;
    }
    final price = _getPrice();
    if (price == null || price <= 0) {
      _showSnackBar('El precio debe ser mayor a 0.');
      return;
    }

    setState(() => _isLoading = true);
    _errorMessage = null;

    final fieldSlug = widget.field['slug']?.toString() ?? '';
    final moduleName = widget.moduleName ?? '';
    final recordId = widget.recordId;
    var recordType = widget.recordType ?? 'register';

    if (recordType.endsWith('s')) {
      recordType = recordType.substring(0, recordType.length - 1);
    }

    if (fieldSlug.isEmpty) {
      _showSnackBar('Error: field_slug no está definido en la configuración del campo.');
      setState(() => _isLoading = false);
      return;
    }

    if (moduleName.isEmpty) {
      _showSnackBar('Error: module_name no está definido.');
      setState(() => _isLoading = false);
      return;
    }

    if (recordId == null || recordId <= 0) {
      _showSnackBar('Error: record_id no es válido.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await MercadoPagoCreatePreferenceCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        moduleName: moduleName,
        recordId: recordId,
        recordType: recordType,
        fieldSlug: fieldSlug,
        backUrlSuccess: 'queryapp://pago-exitoso',
      );

      if (response.succeeded) {
        final body = response.jsonBody;
        if (body is Map<String, dynamic>) {
          final initPoint = body['init_point']?.toString() ?? '';
          final sandboxInitPoint = body['sandbox_init_point']?.toString() ?? '';
          final preferenceId = body['preference_id']?.toString() ?? '';
          final amount = body['amount'];
          final currencyId = body['currency_id']?.toString() ?? 'COP';

          // Guardar en json_data
          final mpPayload = {
            'preference_id': preferenceId,
            'init_point': initPoint,
            'sandbox_init_point': sandboxInitPoint,
            'status': 'pending',
            'amount': amount,
            'currency_id': currencyId,
            'created_at': DateTime.now().toIso8601String(),
          };
          widget.handleDynamicFieldChanges(
            widget.field['slug']?.toString() ?? '',
            mpPayload,
            widget.index,
            widget.mainSlug,
          );
          _mpData = mpPayload;

          // Guardar contexto de módulo para deep link post-pago
          FFAppState().mpDeepLinkModuleName = moduleName;
          FFAppState().mpDeepLinkRecordId = recordId;

          // Abrir checkout en navegador externo
          final urlToOpen = initPoint.isNotEmpty ? initPoint : sandboxInitPoint;
          if (urlToOpen.isNotEmpty) {
            await _openExternalUrl(urlToOpen);
          }
        }
      } else {
        _errorMessage = 'Error al crear la preferencia de pago.';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createSubscriptionPlan() async {
    if (!_hasRecordId()) {
      _showSnackBar('Guarda el registro primero para poder suscribirte.');
      return;
    }
    if (_selectedPlanIndex == null) {
      _showSnackBar('Selecciona un plan primero.');
      return;
    }

    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final response = await MercadoPagoCreateSubscriptionPlanCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        moduleName: widget.moduleName,
        recordId: widget.recordId,
        recordType: _getNormalizedRecordType(),
        fieldSlug: widget.field['slug']?.toString(),
        planIndex: _selectedPlanIndex,
      );

      if (response.succeeded) {
        final body = response.jsonBody;
        if (body is Map<String, dynamic>) {
          final planId = body['plan_id']?.toString() ?? '';
          final initPoint = body['init_point']?.toString() ?? '';
          final reason = body['reason']?.toString() ?? '';
          final amount = body['amount'];
          final frequency = body['frequency']?.toString() ?? '';
          final frequencyType = body['frequency_type']?.toString() ?? '';
          final currencyId = body['currency_id']?.toString() ?? 'COP';

          final mpPayload = {
            'subscription_plan_id': planId,
            'subscription_mode': 'with_plan',
            'init_point': initPoint,
            'status': 'pending',
            'reason': reason,
            'amount': amount,
            'frequency': frequency,
            'frequency_type': frequencyType,
            'currency_id': currencyId,
            'created_at': DateTime.now().toIso8601String(),
          };
          widget.handleDynamicFieldChanges(
            widget.field['slug']?.toString() ?? '',
            mpPayload,
            widget.index,
            widget.mainSlug,
          );
          _mpData = mpPayload;

          // Guardar contexto de módulo para deep link post-pago
          FFAppState().mpDeepLinkModuleName = widget.moduleName ?? '';
          FFAppState().mpDeepLinkRecordId = widget.recordId ?? 0;

          if (initPoint.isNotEmpty) {
            await _openExternalUrl(initPoint);
          }
        }
      } else {
        _errorMessage = 'Error al crear el plan de suscripción.';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createSubscription() async {
    if (!_hasRecordId()) {
      _showSnackBar('Guarda el registro primero para poder suscribirte.');
      return;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Ingresa un email válido.');
      return;
    }

    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final response = await MercadoPagoCreateSubscriptionCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        moduleName: widget.moduleName,
        recordId: widget.recordId,
        recordType: _getNormalizedRecordType(),
        fieldSlug: widget.field['slug']?.toString(),
        payerEmail: email,
      );

      if (response.succeeded) {
        final body = response.jsonBody;
        if (body is Map<String, dynamic>) {
          final subscriptionId = body['subscription_id']?.toString() ?? '';
          final initPoint = body['init_point']?.toString() ?? '';
          final status = body['status']?.toString() ?? 'pending';
          final reason = body['reason']?.toString() ?? '';
          final amount = body['amount'];

          final mpPayload = {
            'subscription_id': subscriptionId,
            'subscription_mode': 'without_plan',
            'init_point': initPoint,
            'status': status,
            'reason': reason,
            'amount': amount,
            'payer_email': email,
            'created_at': DateTime.now().toIso8601String(),
          };
          widget.handleDynamicFieldChanges(
            widget.field['slug']?.toString() ?? '',
            mpPayload,
            widget.index,
            widget.mainSlug,
          );
          _mpData = mpPayload;

          // Guardar contexto de módulo para deep link post-pago
          FFAppState().mpDeepLinkModuleName = widget.moduleName ?? '';
          FFAppState().mpDeepLinkRecordId = widget.recordId ?? 0;

          if (initPoint.isNotEmpty) {
            await _openExternalUrl(initPoint);
          }
        }
      } else {
        _errorMessage = 'Error al crear la suscripción.';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppResumed() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1) Intentar payment-status primero
      final statusResponse = await MercadoPagoPaymentStatusCall.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        moduleName: widget.moduleName,
        recordId: widget.recordId,
        recordType: _getNormalizedRecordType(),
        fieldSlug: widget.field['slug']?.toString(),
      );

      if (statusResponse.succeeded && statusResponse.jsonBody is Map) {
        final body = statusResponse.jsonBody as Map<String, dynamic>;
        final newStatus = body['status']?.toString() ?? 'pending';

        // Actualizar json_data local
        final updated = Map<String, dynamic>.from(_mpData ?? {});
        updated['status'] = newStatus;
        if (body['payment_id'] != null)
          updated['payment_id'] = body['payment_id'];
        if (body['paid_at'] != null) updated['paid_at'] = body['paid_at'];
        if (body['amount'] != null) updated['amount'] = body['amount'];

        widget.handleDynamicFieldChanges(
          widget.field['slug']?.toString() ?? '',
          updated,
          widget.index,
          widget.mainSlug,
        );
        _mpData = updated;
      } else {
        // 2) Fallback: sync-payment si tenemos payment_id
        final paymentId = _mpData?['payment_id']?.toString() ?? '';
        if (paymentId.isNotEmpty) {
          final syncResponse = await MercadoPagoSyncPaymentCall.call(
            tenant: FFAppState().organizacion,
            token: FFAppState().token,
            paymentId: paymentId,
          );
          if (syncResponse.succeeded && syncResponse.jsonBody is Map) {
            final body = syncResponse.jsonBody as Map<String, dynamic>;
            final newStatus = body['status']?.toString() ?? 'pending';
            final updated = Map<String, dynamic>.from(_mpData ?? {});
            updated['status'] = newStatus;
            if (body['status_changed'] == true) {
              widget.handleDynamicFieldChanges(
                widget.field['slug']?.toString() ?? '',
                updated,
                widget.index,
                widget.mainSlug,
              );
              _mpData = updated;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('MercadoPagoField _handleAppResumed error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Fetch payment status on mount — handles case where webhook updated backend
  /// but widget has stale data. Equivalent to web's mountFetchDoneRef effect.
  void _fetchStatusOnMount() {
    if (!mounted) return;
    final status = _mpData?['status']?.toString() ?? '';
    final preferenceId = _mpData?['preference_id']?.toString() ?? '';

    // Only fetch if there's a preference but status is still pending
    if (preferenceId.isEmpty) return;
    if (status.isNotEmpty && status != 'pending') return;

    MercadoPagoPaymentStatusCall.call(
      tenant: FFAppState().organizacion,
      token: FFAppState().token,
      moduleName: widget.moduleName,
      recordId: widget.recordId,
      recordType: _getNormalizedRecordType(),
      fieldSlug: widget.field['slug']?.toString(),
    ).then((response) {
      if (!mounted) return;
      if (response.succeeded && response.jsonBody is Map) {
        final body = response.jsonBody as Map<String, dynamic>;
        final newStatus = body['status']?.toString() ?? '';
        if (newStatus.isNotEmpty && newStatus != status) {
          final updated = Map<String, dynamic>.from(_mpData ?? {});
          updated['status'] = newStatus;
          if (body['payment_id'] != null) updated['payment_id'] = body['payment_id'];
          if (body['paid_at'] != null) updated['paid_at'] = body['paid_at'];
          if (body['amount'] != null) updated['amount'] = body['amount'];

          widget.handleDynamicFieldChanges(
            widget.field['slug']?.toString() ?? '',
            updated,
            widget.index,
            widget.mainSlug,
          );
          _mpData = updated;
          if (mounted) setState(() {});
        }
      }
    }).catchError((e) {
      debugPrint('MercadoPagoField _fetchStatusOnMount error: $e');
    });
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      // Usar flutter_custom_tabs como recomienda Mercado Pago
      // para una experiencia nativa en Android (Custom Tabs)
      // y iOS (SFSafariViewController)
      await launchUrl(
        uri,
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: _mpBlue,
          ),
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
          closeButton: CustomTabsCloseButton(
            icon: CustomTabsCloseButtonIcons.back,
          ),
        ),
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: _mpBlue,
          preferredControlTintColor: Colors.white,
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.done,
        ),
      );
    } catch (e) {
      // Fallback a url_launcher si flutter_custom_tabs falla
      debugPrint(
          'flutter_custom_tabs falló: $e. Intentando con url_launcher...');
      try {
        await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } catch (e2) {
        _showSnackBar('No se pudo abrir el navegador: $e2');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // UI Builders
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_mpConfig == null) {
      return _buildError('Campo de Mercado Pago no configurado.');
    }

    if (!_hasRecordId()) {
      return _buildInfoCard(
        icon: Icons.info_outline,
        message: 'Guarda el registro primero para habilitar los pagos.',
      );
    }

    // Si ya está pagado/reembolsado, mostrar badge de estado (no se puede pagar de nuevo)
    final status = _mpData?['status']?.toString() ?? '';
    if (status == 'approved' || status == 'refunded') {
      return _buildReadOnlyView();
    }

    if (_isSubscriptionEnabled()) {
      final mode = _getSubscriptionMode();
      if (mode == 'with_plan') {
        return _buildSubscriptionWithPlan();
      }
      if (mode == 'without_plan') {
        return _buildSubscriptionWithoutPlan();
      }
      return _buildError('Modo de suscripción no configurado.');
    }

    return _buildPaymentPuntual();
  }

  Widget _buildReadOnlyView() {
    final status = _mpData?['status']?.toString() ?? 'pending';
    final badge = _statusBadges[status] ?? _statusBadges['pending']!;
    final amount = _mpData?['amount'];
    final currency = _mpData?['currency_id']?.toString() ?? _getCurrency();
    final paidAt = _mpData?['paid_at']?.toString();
    final paymentId = _mpData?['payment_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(badge['icon'] as IconData,
                  color: badge['textColor'] as Color, size: 18),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badge['color'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge['label'] as String,
                  style: TextStyle(
                    color: badge['textColor'] as Color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (amount != null)
                Text(
                  _formatCurrency(amount, currency: currency),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
            ],
          ),
          if (paidAt != null && paidAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Pagado: ${_formatDate(paidAt)}',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Outfit',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
          if (paymentId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'ID: $paymentId',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Outfit',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final badge = _statusBadges[status] ?? _statusBadges['pending']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badge['color'] as Color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge['icon'] as IconData,
              color: badge['textColor'] as Color, size: 16),
          const SizedBox(width: 6),
          Text(
            badge['label'] as String,
            style: TextStyle(
              color: badge['textColor'] as Color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPuntual() {
    final status = _mpData?['status']?.toString() ?? '';
    final amount = _mpData?['amount'] ?? _getPrice();
    final currency = _mpData?['currency_id']?.toString() ?? _getCurrency();

    // Solo mostrar read-only cuando ya está pagado o reembolsado
    if (status == 'approved' || status == 'refunded') {
      return _buildReadOnlyView();
    }

    // Badge de estado + botón de pago
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.isNotEmpty) ...[
          _buildStatusBadge(status),
          const SizedBox(height: 8),
        ],
        _buildMercadoPagoButton(
          amount: amount,
          currency: currency,
          existingInitPoint: _mpData?['init_point']?.toString(),
          status: status,
        ),
      ],
    );
  }

  Widget _buildMercadoPagoButton({
    dynamic amount,
    String currency = 'COP',
    String? existingInitPoint,
    String status = '',
  }) {
    final price = amount ?? _getPrice();
    final priceText =
        price != null ? _formatCurrency(price, currency: currency) : '';
    final bool hasInitPoint =
        existingInitPoint != null && existingInitPoint.isNotEmpty;

    // Texto del botón según estado
    String buttonText = 'Pagar con Mercado Pago';
    if (status == 'rejected' || status == 'cancelled') {
      buttonText = 'Reintentar pago';
    } else if (status == 'pending' && hasInitPoint) {
      buttonText = 'Continuar pago';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: _mpBlue,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _mpBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handlePaymentTap(
                          hasInitPoint, existingInitPoint, status),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.credit_card,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  buttonText,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                ),
                              ],
                            ),
                            if (priceText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                priceText,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Outfit',
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handlePaymentTap(
      bool hasInitPoint, String? existingInitPoint, String status) async {
    // Si rechazado/cancelado: crear nueva preferencia (reintentar)
    if (status == 'rejected' || status == 'cancelled') {
      await _createPreference();
      return;
    }
    if (hasInitPoint && existingInitPoint != null) {
      // Ya existe preferencia: abrir directamente
      await _openExternalUrl(existingInitPoint);
    } else {
      // No existe: crear preferencia y abrir
      await _createPreference();
    }
  }

  // ──────────────────────────────────────────────────────────
  // Suscripción con Plan
  // ──────────────────────────────────────────────────────────

  Widget _buildSubscriptionWithPlan() {
    final plans = _getSubscriptionPlans();
    if (plans.isEmpty) {
      return _buildError('No hay planes configurados.');
    }

    final status = _mpData?['status']?.toString() ?? '';
    final initPoint = _mpData?['init_point']?.toString() ?? '';

    // Si ya está autorizada/pagada, mostrar read-only
    if (status == 'authorized' || status == 'approved') {
      return _buildReadOnlyView();
    }

    // Si ya hay init_point pero no completada: botón directo a MP
    final bool hasInitPoint = initPoint.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasInitPoint ? 'Plan seleccionado' : 'Selecciona un plan',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          ...plans.asMap().entries.map((entry) {
            final idx = entry.key;
            final plan = entry.value is Map<String, dynamic>
                ? entry.value as Map<String, dynamic>
                : <String, dynamic>{};
            final isSelected = _selectedPlanIndex == idx;
            final wasSelectedInData =
                _mpData?['subscription_plan_id'] != null &&
                    _selectedPlanIndex == idx;
            final reason = plan['reason']?.toString() ?? 'Plan ${idx + 1}';
            final amount = plan['amount']?.toString() ?? '0';
            final frequency = plan['frequency']?.toString() ?? '1';
            final freqType =
                _translateFrequency(plan['frequency_type']?.toString() ?? '');

            // Si ya hay init_point, solo mostrar el plan que estaba seleccionado
            if (hasInitPoint && !isSelected && !wasSelectedInData) {
              return const SizedBox.shrink();
            }

            return GestureDetector(
              onTap: hasInitPoint
                  ? null
                  : () => setState(() => _selectedPlanIndex = idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected || wasSelectedInData
                      ? _mpBlue.withOpacity(0.1)
                      : FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected || wasSelectedInData
                        ? _mpBlue
                        : FlutterFlowTheme.of(context).alternate,
                    width: isSelected || wasSelectedInData ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reason,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_formatNumber(amount)} / $frequency $freqType',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Outfit',
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected || wasSelectedInData)
                      const Icon(Icons.check_circle, color: _mpBlue, size: 24),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              decoration: BoxDecoration(
                color: _mpBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _mpBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasInitPoint
                      ? () => _openExternalUrl(initPoint)
                      : _createSubscriptionPlan,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sync,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasInitPoint
                              ? 'Completar suscripción en Mercado Pago'
                              : 'Seleccionar plan',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // Suscripción sin Plan
  // ──────────────────────────────────────────────────────────

  Widget _buildSubscriptionWithoutPlan() {
    final status = _mpData?['status']?.toString() ?? '';
    final initPoint = _mpData?['init_point']?.toString() ?? '';
    final hasInitPoint = initPoint.isNotEmpty;

    // Si ya está autorizada/pagada, mostrar read-only
    if (status == 'authorized' || status == 'approved') {
      return _buildReadOnlyView();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !hasInitPoint,
            decoration: InputDecoration(
              labelText: 'Email del suscriptor',
              hintText: 'correo@ejemplo.com',
              filled: true,
              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: FlutterFlowTheme.of(context).alternate,
                ),
              ),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              decoration: BoxDecoration(
                color: _mpBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _mpBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasInitPoint
                      ? () => _openExternalUrl(initPoint)
                      : _createSubscription,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sync,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasInitPoint
                              ? 'Completar suscripción en Mercado Pago'
                              : 'Suscribir',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // Helpers de UI
  // ──────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String message}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: FlutterFlowTheme.of(context).secondaryText, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Outfit',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateFrequency(String value) {
    switch (value.toLowerCase()) {
      case 'days':
      case 'dias':
        return 'días';
      case 'months':
      case 'meses':
        return 'meses';
      default:
        return value;
    }
  }

  String _formatNumber(String value) {
    final numVal = num.tryParse(value);
    if (numVal == null) return value;
    final formatter = NumberFormat('#,##0', 'es_CO');
    return formatter.format(numVal);
  }
}
