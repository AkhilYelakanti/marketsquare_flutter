import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../orderentry/order_widgets.dart';

/// Port of native `ItemImagesScreen`. Item images come from downloaded image
/// packages (the image-download service is a follow-up), so this shows the
/// state when none are present. An optional item code is passed via `extra`.
class ItemImagesScreen extends StatelessWidget {
  final String? itemCode;
  const ItemImagesScreen({super.key, this.itemCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: orderAppBar(subtitle: 'ITEM IMAGES', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_not_supported, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                itemCode == null
                    ? 'No images available.'
                    : 'No images for item $itemCode.',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              const Text(
                'Image packages are downloaded during Data Sync (image download is a follow-up).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
