/// Validations de formulaires (messages en français).
class Validators {
  Validators._();

  static final RegExp _email = RegExp(
    r'^[\w.+-]+@([\w-]+\.)+[A-Za-z]{2,}$',
  );

  /// Numéro tunisien : 8 chiffres, éventuellement préfixé +216.
  static final RegExp _phone = RegExp(r'^(\+?216)?[2-59]\d{7}$');

  /// CIN tunisienne : 8 chiffres.
  static final RegExp _cin = RegExp(r'^\d{8}$');

  static String? required(String? value, {String champ = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) return '$champ est obligatoire';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Le nom est obligatoire';
    if (v.length < 2) return 'Le nom est trop court';
    if (v.length > 40) return 'Le nom est trop long';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return "L'adresse e-mail est obligatoire";
    if (!_email.hasMatch(v)) return 'Adresse e-mail invalide (ex. nom@mail.tn)';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Le mot de passe est obligatoire';
    if (v.length < 6) return 'Au moins 6 caractères requis';
    if (!v.contains(RegExp(r'[A-Za-z]'))) {
      return 'Doit contenir au moins une lettre';
    }
    if (!v.contains(RegExp(r'\d'))) return 'Doit contenir au moins un chiffre';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Veuillez confirmer';
    if (value != original) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  static String? phone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s.-]'), '');
    if (v.isEmpty) return 'Le numéro de téléphone est obligatoire';
    if (!_phone.hasMatch(v)) {
      return 'Numéro tunisien invalide (8 chiffres, ex. 22 345 678)';
    }
    return null;
  }

  static String? cin(String? value) {
    final v = (value ?? '').replaceAll(' ', '');
    if (v.isEmpty) return 'Le numéro CIN est obligatoire';
    if (!_cin.hasMatch(v)) return 'La CIN doit contenir 8 chiffres';
    return null;
  }

  static String? licenceNumber(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Le numéro de permis est obligatoire';
    if (v.length < 6) return 'Numéro de permis invalide';
    return null;
  }

  static String? cardNumber(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (v.isEmpty) return 'Le numéro de carte est obligatoire';
    if (!RegExp(r'^\d{16}$').hasMatch(v)) {
      return 'Le numéro doit contenir 16 chiffres';
    }
    return null;
  }

  static String? cardExpiry(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return "La date d'expiration est obligatoire";
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v);
    if (match == null) return 'Format attendu MM/AA';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return 'Mois invalide';
    final expiry = DateTime(year, month + 1, 0);
    if (expiry.isBefore(DateTime.now())) return 'Carte expirée';
    return null;
  }

  static String? cvv(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Le CVV est obligatoire';
    if (!RegExp(r'^\d{3,4}$').hasMatch(v)) return 'CVV invalide';
    return null;
  }

  static String? positiveAmount(String? value) {
    final v = (value ?? '').replaceAll(',', '.').trim();
    if (v.isEmpty) return 'Le montant est obligatoire';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Montant invalide';
    if (parsed <= 0) return 'Le montant doit être supérieur à 0';
    return null;
  }
}
