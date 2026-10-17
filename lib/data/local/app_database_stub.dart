/// Stub web : sqflite n'est pas disponible dans le navigateur.
///
/// Sur Chrome, [database] reste `null` et aucune opération disque n'est faite.
/// Les repositories mock continuent de fonctionner.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  /// Toujours `null` sur web.
  Future<Object?> get database async => null;

  Future<void> close() async {}

  /// Indique que la persistence locale n'est pas active sur cette plateforme.
  bool get isSupported => false;
}
