import '../mock/mock_users.dart';
import '../models/user_profile.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Authentification **simulée** : aucune requête réseau, aucun jeton, aucun
/// stockage sécurisé. À remplacer par un vrai service d'identité.
class AuthRepository {
  const AuthRepository();

  static const Duration _latency = Duration(milliseconds: 900);

  Future<UserProfile> login(String email, String password) async {
    await Future<void>.delayed(_latency);
    final normalized = email.trim().toLowerCase();
    final expected = MockUsers.credentials[normalized];

    if (expected == null) {
      throw const AuthException('Aucun compte ne correspond à cet e-mail.');
    }
    if (expected != password) {
      throw const AuthException('Mot de passe incorrect.');
    }

    if (normalized == MockUsers.demoEmail) return MockUsers.demoUser;

    final local = normalized.split('@').first;
    return UserProfile(
      id: 'usr-${local.hashCode.abs()}',
      firstName: local.isEmpty ? 'Client' : _capitalize(local),
      lastName: 'Tunisie',
      email: normalized,
      phone: '20 000 000',
      memberSince: DateTime.now(),
      publicUsername: '${_capitalize(local)}_TN',
    );
  }

  Future<UserProfile> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String city = 'Tunis',
  }) async {
    await Future<void>.delayed(_latency);
    final normalized = email.trim().toLowerCase();

    if (MockUsers.credentials.containsKey(normalized)) {
      throw const AuthException('Un compte existe déjà avec cet e-mail.');
    }
    MockUsers.credentials[normalized] = password;

    return UserProfile(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      phone: phone.trim(),
      city: city,
      memberSince: DateTime.now(),
      publicUsername: '${firstName.trim()}_TN',
    );
  }

  Future<void> sendResetLink(String email) async {
    await Future<void>.delayed(_latency);
    // Simulation : aucun e-mail n'est réellement envoyé.
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
