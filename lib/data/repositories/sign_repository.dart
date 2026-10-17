import '../local/app_database.dart';
import '../mock/mock_learning.dart';
import '../models/learning.dart';
import 'sign_repository_prefs.dart';
import 'sign_repository_sqflite.dart';

/// Contrat CRUD des panneaux (frontend ↔ backend local).
abstract class SignRepository {
  Future<List<RoadSign>> getAll();

  Future<List<RoadSign>> byCategory(SignCategory category);

  Future<RoadSign?> byId(String id);

  Future<RoadSign> create(RoadSign sign);

  Future<RoadSign> update(RoadSign sign);

  Future<void> delete(String id);

  /// Insère le contenu initial si la table / le store est vide.
  Future<void> seedIfEmpty({List<RoadSign>? seed});
}

/// - Mobile / APK → **sqflite**
/// - Web (Chrome) → **shared_preferences** (localStorage), car sqflite
///   n'est pas supporté sur le navigateur.
class SignRepositoryFactory {
  static SignRepository create() {
    if (AppDatabase.instance.isSupported) {
      return SqfliteSignRepository();
    }
    return PrefsSignRepository();
  }
}

/// Contenu de départ partagé (seed).
List<RoadSign> defaultRoadSignSeed() => List<RoadSign>.from(MockLearning.signs);
