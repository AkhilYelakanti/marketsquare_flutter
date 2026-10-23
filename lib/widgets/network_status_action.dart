import 'package:flutter/material.dart';

/// Port of the native `NetworkStatusAction` app-bar indicator.
/// Shown in the dashboard top bar. (Live connectivity wiring is a follow-up;
/// this renders the online state visual.)
class NetworkStatusAction extends StatelessWidget {
  const NetworkStatusAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(Icons.wifi, color: Colors.white),
    );
  }
}
