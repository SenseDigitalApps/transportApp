import '../types/solicitud_trabajo.dart';

/// Caché en memoria para el módulo TransportApp.
///
/// Almacena:
/// - Lista paginada de solicitudes (por pageKey)
/// - Registros individuales relacionados (conductor, vehículo, cliente)
/// - Colores de estado (default_status)
///
/// El caché se invalida completamente al hacer pull-to-refresh.
class TransportAppCache {
  TransportAppCache._();
  static final TransportAppCache _instance = TransportAppCache._();
  factory TransportAppCache() => _instance;

  // ── Solicitudes paginadas ──
  final Map<String, List<SolicitudTrabajo>> _solicitudes = {};

  // ── Registros relacionados (module → id → json) ──
  final Map<String, Map<String, Map<String, dynamic>>> _registers = {};

  // ── Colores de estado ──
  Map<String, dynamic>? _statusConfigRaw;

  // ── Metadatos ──
  DateTime? _lastFetch;

  // ================================================================
  // Solicitudes
  // ================================================================

  String _pageKey(int page) => 'page_$page';

  List<SolicitudTrabajo>? getSolicitudes(int page) =>
      _solicitudes[_pageKey(page)];

  void setSolicitudes(int page, List<SolicitudTrabajo> list) {
    _solicitudes[_pageKey(page)] = list;
    _lastFetch = DateTime.now();
  }

  bool hasPage(int page) => _solicitudes.containsKey(_pageKey(page));

  List<SolicitudTrabajo>? getSolicitudesByKey(String key) => _solicitudes[key];

  void setSolicitudesByKey(String key, List<SolicitudTrabajo> list) {
    _solicitudes[key] = list;
    _lastFetch = DateTime.now();
  }

  bool hasPageByKey(String key) => _solicitudes.containsKey(key);

  // ================================================================
  // Registros relacionados
  // ================================================================

  Map<String, dynamic>? getRegister(int moduleId, int registerId) {
    final moduleCache = _registers['$moduleId'];
    if (moduleCache == null) return null;
    return moduleCache['$registerId'];
  }

  void setRegister(int moduleId, int registerId, Map<String, dynamic> data) {
    _registers.putIfAbsent('$moduleId', () => {});
    _registers['$moduleId']!['$registerId'] = data;
  }

  bool hasRegister(int moduleId, int registerId) =>
      getRegister(moduleId, registerId) != null;

  // ================================================================
  // Status config
  // ================================================================

  Map<String, dynamic>? get statusConfigRaw => _statusConfigRaw;

  void setStatusConfig(Map<String, dynamic> raw) {
    _statusConfigRaw = raw;
  }

  bool get hasStatusConfig => _statusConfigRaw != null;

  // ================================================================
  // Global
  // ================================================================

  DateTime? get lastFetch => _lastFetch;

  /// Invalida TODO el caché (usar en pull-to-refresh o logout).
  void clear() {
    _solicitudes.clear();
    _registers.clear();
    _statusConfigRaw = null;
    _lastFetch = null;
  }

  /// Invalida solo las listas paginadas, manteniendo registros relacionados.
  void clearLists() {
    _solicitudes.clear();
    _lastFetch = null;
  }

  /// Elimina las entradas de caché cuyas keys comiencen con [prefix].
  void clearKeysByPrefix(String prefix) {
    _solicitudes.removeWhere((key, _) => key.startsWith(prefix));
    if (_solicitudes.isEmpty) _lastFetch = null;
  }
}
