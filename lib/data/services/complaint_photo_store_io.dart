import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Photos copiées dans `<documents>/complaint_photos/`.
class ComplaintPhotoStore {
  const ComplaintPhotoStore();

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'complaint_photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copie [file] dans le dossier de l'app et retourne le nouveau chemin.
  Future<String> save(XFile file) async {
    final dir = await _dir();
    final ext = p.extension(file.name).toLowerCase();
    final name =
        'cmp_${DateTime.now().microsecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}';
    final target = p.join(dir.path, name);
    await file.saveTo(target);
    return target;
  }

  /// Supprime les fichiers de [paths]. Par sécurité, seuls les fichiers du
  /// dossier des réclamations sont touchés.
  Future<void> delete(Iterable<String> paths) async {
    if (paths.isEmpty) return;
    final dir = await _dir();
    for (final path in paths) {
      if (!p.isWithin(dir.path, path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('[ComplaintPhotos] Suppression impossible ($path) : $e');
      }
    }
  }
}
