import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Caché persistente exclusivo para avatares de usuarios y agentes.
///
/// Una entrada se vuelve a validar después de dos días. Mientras siga vigente,
/// todas las pantallas comparten el mismo archivo local y evitan otra descarga.
class AvatarCacheService {
  AvatarCacheService._();

  static const stalePeriod = Duration(days: 2);

  static final CacheManager manager = CacheManager(
    Config(
      'query_avatar_cache_v1',
      stalePeriod: stalePeriod,
      maxNrOfCacheObjects: 300,
    ),
  );

  static ImageProvider provider(
    String url, {
    double scale = 1,
  }) {
    return CachedNetworkImageProvider(
      url,
      scale: scale,
      cacheManager: manager,
    );
  }

  static Future<void> evict(String? url) async {
    final normalized = url?.trim() ?? '';
    if (normalized.isEmpty) return;
    await CachedNetworkImage.evictFromCache(
      normalized,
      cacheManager: manager,
    );
  }
}
