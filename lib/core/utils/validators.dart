import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Validations de formulaires, messages traduits (fr / en / ar).
///
/// Les validateurs sont utilisés sans BuildContext (`validator:
/// Validators.email`) : la langue est fournie par [LocaleProvider] via
/// [setLocale]. Français par défaut (tests, avant le chargement).
class Validators {
  Validators._();

  static AppLocalizations _t = lookupAppLocalizations(const Locale('fr'));

  /// Appelé par LocaleProvider à chaque changement de langue.
  static void setLocale(Locale locale) {
    _t = lookupAppLocalizations(locale);
  }

  static final RegExp _email = RegExp(r'^[\w.+-]+@([\w-]+\.)+[A-Za-z]{2,}$');

  /// Numéro tunisien : 8 chiffres, éventuellement préfixé +216.
  static final RegExp _phone = RegExp(r'^(\+?216)?[2-59]\d{7}$');

  /// CIN tunisienne : 8 chiffres.
  static final RegExp _cin = RegExp(r'^\d{8}$');

  /// [champ] : nom du champ déjà traduit (ex. `l10n.editAliasField`).
  static String? required(String? value, {String? champ}) {
    if (value == null || value.trim().isEmpty) {
      return _t.validatorRequired(champ ?? _t.validatorFieldDefault);
    }
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _t.validatorNameRequired;
    if (v.length < 2) return _t.validatorNameShort;
    if (v.length > 40) return _t.validatorNameLong;
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _t.validatorEmailRequired;
    if (!_email.hasMatch(v)) return _t.validatorEmailInvalid;
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return _t.validatorPasswordRequired;
    if (v.length < 6) return _t.validatorPasswordShort;
    if (!v.contains(RegExp(r'[A-Za-z]'))) return _t.validatorPasswordLetter;
    if (!v.contains(RegExp(r'\d'))) return _t.validatorPasswordDigit;
    return null;
  }

  /// Champ mot de passe simplement obligatoire (écran de connexion).
  static String? passwordRequired(String? value) =>
      (value == null || value.isEmpty) ? _t.validatorPasswordRequired : null;

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return _t.validatorConfirmRequired;
    if (value != original) return _t.validatorPasswordMismatch;
    return null;
  }

  static String? phone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s.-]'), '');
    if (v.isEmpty) return _t.validatorPhoneRequired;
    if (!_phone.hasMatch(v)) return _t.validatorPhoneInvalid;
    return null;
  }

  static String? cin(String? value) {
    final v = (value ?? '').replaceAll(' ', '');
    if (v.isEmpty) return _t.validatorCinRequired;
    if (!_cin.hasMatch(v)) return _t.validatorCinInvalid;
    return null;
  }

  static String? licenceNumber(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _t.validatorLicenceRequired;
    if (v.length < 6) return _t.validatorLicenceInvalid;
    return null;
  }

  static String? cardNumber(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (v.isEmpty) return _t.validatorCardRequired;
    if (!RegExp(r'^\d{16}$').hasMatch(v)) return _t.validatorCardInvalid;
    return null;
  }

  static String? cardExpiry(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _t.validatorExpiryRequired;
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v);
    if (match == null) return _t.validatorExpiryFormat;
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return _t.validatorMonthInvalid;
    final expiry = DateTime(year, month + 1, 0);
    if (expiry.isBefore(DateTime.now())) return _t.validatorCardExpired;
    return null;
  }

  static String? cvv(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _t.validatorCvvRequired;
    if (!RegExp(r'^\d{3,4}$').hasMatch(v)) return _t.validatorCvvInvalid;
    return null;
  }

  static String? positiveAmount(String? value) {
    final v = (value ?? '').replaceAll(',', '.').trim();
    if (v.isEmpty) return _t.validatorAmountRequired;
    final parsed = double.tryParse(v);
    if (parsed == null) return _t.validatorAmountInvalid;
    if (parsed <= 0) return _t.validatorAmountPositive;
    return null;
  }
}
