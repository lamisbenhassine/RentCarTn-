import 'user_profile.dart';

/// Éléments qui comptent dans la complétion du profil (même poids chacun).
/// L'ordre est celui des actions proposées à l'utilisateur.
enum ProfileStep {
  photo,
  phone,
  cin,
  licenceNumber,
  licenceExpiry,
  address,
  position,
  emailVerified,
}

extension ProfileStepX on ProfileStep {
  /// Action affichée sous la barre (« prochaine étape »).
  String get action => switch (this) {
    ProfileStep.photo => 'Ajoutez une photo de profil',
    ProfileStep.phone => 'Ajoutez votre numéro de téléphone',
    ProfileStep.cin => 'Ajoutez votre numéro de CIN',
    ProfileStep.licenceNumber => 'Ajoutez votre permis de conduire',
    ProfileStep.licenceExpiry => 'Indiquez la date d’expiration du permis',
    ProfileStep.address => 'Ajoutez votre adresse',
    ProfileStep.position => 'Enregistrez votre position',
    ProfileStep.emailVerified => 'Vérifiez votre adresse e-mail',
  };
}

/// Pourcentage de complétion calculé depuis un [UserProfile].
class ProfileCompletion {
  ProfileCompletion._(this.missing);

  factory ProfileCompletion.of(UserProfile u) {
    bool filled(String? v) => v != null && v.trim().isNotEmpty;

    final done = <ProfileStep, bool>{
      ProfileStep.photo: filled(u.avatarUrl),
      ProfileStep.phone: filled(u.phone),
      ProfileStep.cin: filled(u.cin),
      ProfileStep.licenceNumber: filled(u.licenceNumber),
      ProfileStep.licenceExpiry: u.licenceExpiry != null,
      ProfileStep.address: filled(u.address),
      ProfileStep.position: u.latitude != null && u.longitude != null,
      ProfileStep.emailVerified: u.emailVerified,
    };
    return ProfileCompletion._([
      for (final step in ProfileStep.values)
        if (done[step] != true) step,
    ]);
  }

  /// Éléments encore manquants, dans l'ordre de [ProfileStep].
  final List<ProfileStep> missing;

  int get total => ProfileStep.values.length;
  int get doneCount => total - missing.length;

  /// 0 à 100, arrondi (8 éléments → paliers de 12,5 %).
  int get percent => (doneCount * 100 / total).round();

  bool get isComplete => missing.isEmpty;

  /// Prochaine action à proposer, `null` si le profil est complet.
  ProfileStep? get nextStep => missing.isEmpty ? null : missing.first;
}

extension UserProfileCompletion on UserProfile {
  ProfileCompletion get completion => ProfileCompletion.of(this);
}
