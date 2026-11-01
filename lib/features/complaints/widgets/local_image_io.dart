import 'dart:io';

import 'package:flutter/widgets.dart';

/// Mobile : image depuis un chemin de fichier local.
ImageProvider? localFileImage(String path) {
  final file = File(path);
  return file.existsSync() ? FileImage(file) : null;
}
