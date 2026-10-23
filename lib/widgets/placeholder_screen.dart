import 'package:flutter/material.dart';

/// Stand-in for screens not yet ported from the native app. Keeps navigation
/// and the route graph intact so the full app shell is browsable while modules
/// are ported area-by-area.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '$title\nnot yet ported',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
