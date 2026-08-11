import '/backend/api_requests/api_calls.dart';
import 'relational_search_service.dart';

class RelationalCacheService {
  static final RelationalCacheService _instance =
      RelationalCacheService._internal();
  factory RelationalCacheService() => _instance;
  RelationalCacheService._internal();

  final Map<String, ApiCallResponse> _cache = {};
  final Map<String, DateTime> _timestamps = {};

  static const Duration _ttl = Duration(minutes: 5);
  static const int _maxEntries = 50;

  String _buildKey({
    required String typeRelation,
    required String? nameModule,
    required String query,
    String slugFormula = '',
    String valueFormula = '',
    String typeFormula = '',
  }) {
    return '$typeRelation|${nameModule ?? ''}|$query|$slugFormula|$valueFormula|$typeFormula';
  }

  ApiCallResponse? get({
    required String typeRelation,
    required String? nameModule,
    required String query,
    String slugFormula = '',
    String valueFormula = '',
    String typeFormula = '',
  }) {
    final key = _buildKey(
      typeRelation: typeRelation,
      nameModule: nameModule,
      query: query,
      slugFormula: slugFormula,
      valueFormula: valueFormula,
      typeFormula: typeFormula,
    );

    final cached = _cache[key];
    final timestamp = _timestamps[key];

    if (cached != null && timestamp != null) {
      if (DateTime.now().difference(timestamp) < _ttl) {
        return cached;
      }
      _cache.remove(key);
      _timestamps.remove(key);
    }

    return null;
  }

  void put({
    required String typeRelation,
    required String? nameModule,
    required String query,
    required ApiCallResponse response,
    String slugFormula = '',
    String valueFormula = '',
    String typeFormula = '',
  }) {
    if (_cache.length >= _maxEntries) {
      final oldestKey = _timestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _cache.remove(oldestKey);
      _timestamps.remove(oldestKey);
    }

    final key = _buildKey(
      typeRelation: typeRelation,
      nameModule: nameModule,
      query: query,
      slugFormula: slugFormula,
      valueFormula: valueFormula,
      typeFormula: typeFormula,
    );

    _cache[key] = response;
    _timestamps[key] = DateTime.now();
  }

  Future<ApiCallResponse> search({
    required String query,
    required String typeRelation,
    required String? nameModule,
    required String tenant,
    required String token,
    String slugFormula = '',
    String valueFormula = '',
    String typeFormula = '',
  }) async {
    final cached = get(
      typeRelation: typeRelation,
      nameModule: nameModule,
      query: query,
      slugFormula: slugFormula,
      valueFormula: valueFormula,
      typeFormula: typeFormula,
    );

    if (cached != null) {
      return cached;
    }

    final response = await RelationalSearchService.search(
      query: query,
      typeRelation: typeRelation,
      nameModule: nameModule,
      tenant: tenant,
      token: token,
      slugFormula: slugFormula,
      valueFormula: valueFormula,
      typeFormula: typeFormula,
    );

    if (response.succeeded) {
      put(
        typeRelation: typeRelation,
        nameModule: nameModule,
        query: query,
        response: response,
        slugFormula: slugFormula,
        valueFormula: valueFormula,
        typeFormula: typeFormula,
      );
    }

    return response;
  }

  Future<void> preload({
    required String typeRelation,
    required String? nameModule,
    required String tenant,
    required String token,
    String slugFormula = '',
    String valueFormula = '',
    String typeFormula = '',
  }) async {
    final response = await RelationalSearchService.search(
      query: '',
      typeRelation: typeRelation,
      nameModule: nameModule,
      tenant: tenant,
      token: token,
      slugFormula: slugFormula,
      valueFormula: valueFormula,
      typeFormula: typeFormula,
    );

    if (response.succeeded) {
      put(
        typeRelation: typeRelation,
        nameModule: nameModule,
        query: '',
        response: response,
        slugFormula: slugFormula,
        valueFormula: valueFormula,
        typeFormula: typeFormula,
      );
    }
  }

  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = _timestamps.entries
        .where((e) => now.difference(e.value) >= _ttl)
        .map((e) => e.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
      _timestamps.remove(key);
    }
  }
}
