import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/html_text.dart';
import '../../data/session/session_providers.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `OperationalGuideScreen`: shows the stored operational manual.
/// (Fetched during Data Sync in native; here it shows whatever is cached. HTML
/// is rendered as text — see core/html_text.dart.)
class OperationalGuideScreen extends ConsumerWidget {
  const OperationalGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manual = ref.watch(sessionManagerProvider).getOperationalManual();
    final text = manual == null ? '' : stripHtml(manual);
    return Scaffold(
      appBar: orderAppBar(subtitle: 'OPERATIONAL GUIDE', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: text.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'Operational guide not available.\nIt is retrieved during Data Sync.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(text, style: const TextStyle(fontSize: 14)),
            ),
    );
  }
}
