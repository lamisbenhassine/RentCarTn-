import '../models/user_profile.dart';

/// Comptes de démonstration. Aucune authentification réelle n'est effectuée :
/// les identifiants sont comparés en mémoire.
class MockUsers {
  MockUsers._();

  static const String demoEmail = 'demo@rentcar.tn';
  static const String demoPassword = 'demo123';

  static final UserProfile demoUser = UserProfile(
    id: 'usr-001',
    firstName: 'Sofien',
    lastName: 'Ben Amor',
    email: demoEmail,
    phone: '22 345 678',
    cin: '09876543',
    licenceNumber: 'TN-2015-884512',
    city: 'Tunis',
    address: '14 rue de Marseille, Tunis 1000',
    birthDate: DateTime(1994, 6, 12),
    memberSince: DateTime(2023, 2, 18),
    publicUsername: 'Sofien_TN',
  );

  /// Comptes créés pendant la session (inscription simulée).
  static final Map<String, String> credentials = {
    demoEmail: demoPassword,
  };
}
