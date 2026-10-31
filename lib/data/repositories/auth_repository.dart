import '../local/app_database.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_repository_prefs.dart';
import 'auth_repository_sqflite.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Contrat auth locale (sign-in / sign-up).
abstract class AuthRepository {
  Future<UserProfile> login(String email, String password);

  Future<UserProfile> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String city = 'Tunis',
    UserRole role = UserRole.user,
  });

  Future<UserProfile?> byId(String id);

  Future<void> sendResetLink(String email);

  Future<void> saveSession(String userId);

  Future<String?> readSessionUserId();

  Future<void> clearSession();

  /// Compte admin par défaut si aucun admin n'existe encore.
  Future<void> ensureDefaultAdmin();
}

/// - Mobile / APK → **sqflite**
/// - Web (Chrome) → **shared_preferences**
class AuthRepositoryFactory {
  static AuthRepository create() {
    if (AppDatabase.instance.isSupported) {
      return SqfliteAuthRepository();
    }
    return PrefsAuthRepository();
  }
}
