import 'package:flutter/material.dart';

import '../../widgets/brand_logo.dart';
import '../../widgets/network_status_action.dart';

/// Red order-flow app bar: OPTIONS logo at left, stacked titles, network status.
/// Mirrors the shared TopAppBar used across every order-entry screen.
PreferredSizeWidget orderAppBar({
  required String subtitle,
  String? third,
  double height = 72,
}) {
  return AppBar(
    toolbarHeight: height,
    leading: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        BrandLogo(size: 34),
        Text('OPTIONS',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    ),
    title: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('MS ORDERING',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(subtitle,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        if (third != null)
          Text(third,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
      ],
    ),
    actions: const [NetworkStatusAction()],
  );
}

/// Standard BACK-only bottom bar, optionally with a trailing accept action.
class OrderBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final String? acceptLabel;
  final VoidCallback? onAccept;
  const OrderBottomBar(
      {super.key, required this.onBack, this.acceptLabel, this.onAccept});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment:
            onAccept != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: onBack,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Text('BACK',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (acceptLabel != null && onAccept != null)
            InkWell(
              onTap: onAccept,
              child: Row(
                children: [
                  Text(acceptLabel!,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
