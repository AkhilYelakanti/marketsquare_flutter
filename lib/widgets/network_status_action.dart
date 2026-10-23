import 'package:flutter/material.dart';

/// Port of the native `NetworkStatusAction` app-bar indicator: a green
/// broadcast circle shown in screen top bars (online state). Live connectivity
/// wiring (red when offline) is a follow-up.
class NetworkStatusAction extends StatelessWidget {
  const NetworkStatusAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: _StatusDot(online: true),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool online;
  const _StatusDot({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF39B54A) : const Color(0xFFD32F2F);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25), width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        online ? Icons.wifi_tethering : Icons.wifi_tethering_off,
        color: Colors.black,
        size: 24,
      ),
    );
  }
}
