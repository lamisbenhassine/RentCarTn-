import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Web : la photo est conservée en data URL (stockée avec la réclamation).
class ComplaintPhotoStore {
  const ComplaintPhotoStore();

  Future<String> save(XFile file) async {
    final bytes = await file.readAsBytes();
    final mime = file.name.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  /// Rien à supprimer : les data URL disparaissent avec la réclamation.
  Future<void> delete(Iterable<String> paths) async {}
}
