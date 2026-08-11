import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/avatar_cache_service.dart';

class CachedAvatarImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext context)? placeholderBuilder;
  final Widget Function(
    BuildContext context,
    String url,
    Object error,
  )? errorBuilder;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CachedAvatarImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
    this.errorBuilder,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: AvatarCacheService.manager,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: placeholderBuilder == null
          ? null
          : (context, _) => placeholderBuilder!(context),
      errorWidget: errorBuilder,
    );
  }
}
