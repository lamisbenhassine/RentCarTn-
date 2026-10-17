/// Profil utilisateur simulé (aucune authentification réelle).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.cin = '',
    this.licenceNumber = '',
    this.city = 'Tunis',
    this.address = '',
    this.birthDate,
    this.avatarUrl,
    this.memberSince,
    this.publicUsername = 'Utilisateur_TN',
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String cin;
  final String licenceNumber;
  final String city;
  final String address;
  final DateTime? birthDate;
  final String? avatarUrl;
  final DateTime? memberSince;

  /// Pseudonyme affiché dans les enchères publiques.
  final String publicUsername;

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? cin,
    String? licenceNumber,
    String? city,
    String? address,
    DateTime? birthDate,
    String? avatarUrl,
    String? publicUsername,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cin: cin ?? this.cin,
      licenceNumber: licenceNumber ?? this.licenceNumber,
      city: city ?? this.city,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberSince: memberSince,
      publicUsername: publicUsername ?? this.publicUsername,
    );
  }
}
