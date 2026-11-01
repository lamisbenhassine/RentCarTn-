import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../core/services/location_service.dart';
import '../data/repositories/auth_repository.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Raccourcis : `context.l10n.loginTitle`, `context.dateLong(date)`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Date longue dans la langue de l'app (12 juin 1994 / June 12, 1994 /
  /// ١٢ يونيو ١٩٩٤).
  String dateLong(DateTime date) =>
      DateFormat.yMMMMd(Localizations.localeOf(this).toLanguageTag())
          .format(date);
}

/// Messages traduits pour les erreurs venant des services (qui, eux,
/// n'ont pas de BuildContext).
extension L10nMessages on AppLocalizations {
  /// Erreur d'authentification / de profil selon son code.
  String authError(AuthErrorCode? code) => switch (code) {
    AuthErrorCode.accountNotFound => loginNoAccountWithEmail,
    AuthErrorCode.wrongPassword => loginWrongPassword,
    AuthErrorCode.emailTaken => commonEmailTaken,
    AuthErrorCode.phoneTaken => commonPhoneTaken,
    AuthErrorCode.wrongCurrentPassword => changePwdWrongCurrent,
    AuthErrorCode.deleteFailed => deleteFailed,
    AuthErrorCode.locked => loginLockedTitle,
    null => commonSaveFailed,
  };

  /// Raison pour laquelle la position GPS n'a pas pu être obtenue.
  String locationError(LocationFailure reason) => switch (reason) {
    LocationFailure.serviceDisabled => locationServiceDisabled,
    LocationFailure.denied => locationDenied,
    LocationFailure.deniedForever => locationDeniedForever,
    LocationFailure.timeout => locationTimeout,
    LocationFailure.unknown => locationUnknown,
  };
}
