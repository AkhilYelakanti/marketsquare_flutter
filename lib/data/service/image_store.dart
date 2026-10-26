import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Local store for downloaded item images (native `filesDir/item_images`).
/// Initialized once at startup; the catalog tile renderer resolves an item's
/// IMAGE_ID to a file here synchronously.
class ImageStore {
  ImageStore._();

  static Directory? _dir;

  /// Resolves and creates the image directory. Safe to call more than once.
  static Future<void> init() async {
    if (_dir != null) return;
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory('${docs.path}/item_images');
    if (!d.existsSync()) d.createSync(recursive: true);
    _dir = d;
  }

  static Directory? get dir => _dir;

  /// The file for [imageId] (tries the id as-is, then .jpg/.jpeg/.png), or null.
  static File? fileFor(String imageId) {
    final base = _dir;
    if (base == null || imageId.trim().isEmpty) return null;
    final id = imageId.trim();
    for (final name in [id, '$id.jpg', '$id.jpeg', '$id.png']) {
      final f = File('${base.path}/$name');
      if (f.existsSync()) return f;
    }
    return null;
  }

  /// Count of files currently stored.
  static int count() {
    final base = _dir;
    if (base == null || !base.existsSync()) return 0;
    return base.listSync().whereType<File>().length;
  }
}
