import '../local/app_database.dart';
import '../models/complaint.dart';
import 'complaint_repository_prefs.dart';
import 'complaint_repository_sqflite.dart';

/// Contrat CRUD des réclamations (module Réclamations, front office).
abstract class ComplaintRepository {
  /// Réclamations d'un utilisateur, les plus récentes d'abord.
  Future<List<Complaint>> getByUser(String userId);

  Future<Complaint?> byId(String id);

  Future<Complaint> create(Complaint complaint);

  Future<Complaint> update(Complaint complaint);

  Future<void> delete(String id);

  /// Prochaine référence libre REC-AAAA-NNNN (unique sur l'appareil).
  Future<String> nextReference({DateTime? now});
}

/// - Mobile / APK → **sqflite**
/// - Web (Chrome) → **shared_preferences**
class ComplaintRepositoryFactory {
  static ComplaintRepository create() {
    if (AppDatabase.instance.isSupported) {
      return SqfliteComplaintRepository();
    }
    return PrefsComplaintRepository();
  }
}
