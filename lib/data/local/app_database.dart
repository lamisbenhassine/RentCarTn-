/// Point d'entrée unique pour la base locale **sqflite**.
///
/// - Mobile / desktop (`dart.library.io`) → [AppDatabase] réel (sqflite)
/// - Web → stub : pas de fichier SQLite, l'app mock continue de tourner
library;

export 'app_database_stub.dart'
    if (dart.library.io) 'app_database_io.dart';
