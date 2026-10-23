import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session/session_providers.dart';

/// Port of the native `BrandLogo` composable. Shows the branded logo from the
/// login response URL; falls back to a store icon when none is set.
class BrandLogo extends ConsumerWidget {
  final double size;
  const BrandLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(sessionManagerProvider).getBrandLogoUrl();
    if (url == null || url.isEmpty) {
      return Icon(Icons.storefront, size: size, color: Colors.white);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (_, _) => SizedBox(
        width: size,
        height: size,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      ),
      errorWidget: (_, _, _) =>
          Icon(Icons.storefront, size: size, color: Colors.white),
    );
  }
}
