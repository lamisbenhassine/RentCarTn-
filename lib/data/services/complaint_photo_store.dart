/// Stockage durable des photos de réclamation.
///
/// - Mobile → copie dans le dossier de l'app
///   (`<documents>/complaint_photos/`), le cache d'image_picker pouvant
///   être vidé par Android (`complaint_photo_store_io.dart`).
/// - Web → pas de système de fichiers : la photo est gardée en data URL
///   (`complaint_photo_store_stub.dart`).
library;

export 'complaint_photo_store_stub.dart'
    if (dart.library.io) 'complaint_photo_store_io.dart';
