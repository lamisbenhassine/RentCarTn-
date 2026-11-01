import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @commonEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get commonEmail;

  /// No description provided for @commonEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'nom@exemple.tn'**
  String get commonEmailHint;

  /// No description provided for @commonPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get commonPassword;

  /// No description provided for @commonNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get commonNewPassword;

  /// No description provided for @commonConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get commonConfirmPassword;

  /// No description provided for @commonPasswordHelper.
  ///
  /// In fr, this message translates to:
  /// **'6 caractères minimum, lettres et chiffres'**
  String get commonPasswordHelper;

  /// No description provided for @commonPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get commonPhone;

  /// No description provided for @commonFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get commonFirstName;

  /// No description provided for @commonLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get commonLastName;

  /// No description provided for @commonLogin.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get commonLogin;

  /// No description provided for @commonLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get commonLogout;

  /// No description provided for @commonCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get commonCreateAccount;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get commonNext;

  /// No description provided for @commonOpenSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les paramètres'**
  String get commonOpenSettings;

  /// No description provided for @commonSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible.'**
  String get commonSaveFailed;

  /// No description provided for @commonChangeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Modification impossible.'**
  String get commonChangeFailed;

  /// No description provided for @commonNotProvided.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get commonNotProvided;

  /// No description provided for @commonNotProvidedFem.
  ///
  /// In fr, this message translates to:
  /// **'Non renseignée'**
  String get commonNotProvidedFem;

  /// No description provided for @commonLocating.
  ///
  /// In fr, this message translates to:
  /// **'Localisation en cours…'**
  String get commonLocating;

  /// No description provided for @commonAddressUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Adresse indisponible'**
  String get commonAddressUnavailable;

  /// No description provided for @commonPositionUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible'**
  String get commonPositionUnavailable;

  /// No description provided for @commonNearestAgency.
  ///
  /// In fr, this message translates to:
  /// **'Agence la plus proche : {city} ({km} km)'**
  String commonNearestAgency(String city, String km);

  /// No description provided for @commonEmailTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet e-mail.'**
  String get commonEmailTaken;

  /// No description provided for @commonPhoneTaken.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro de téléphone est déjà utilisé.'**
  String get commonPhoneTaken;

  /// No description provided for @commonLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get commonLanguage;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In fr, this message translates to:
  /// **'La localisation (GPS) est désactivée sur votre appareil.'**
  String get locationServiceDisabled;

  /// No description provided for @locationDenied.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez refusé l\'accès à votre position.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès à la position est bloqué. Autorisez-le dans les paramètres de l\'application.'**
  String get locationDeniedForever;

  /// No description provided for @locationTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Position introuvable pour l\'instant. Réessayez à l\'extérieur ou choisissez votre ville.'**
  String get locationTimeout;

  /// No description provided for @locationUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer votre position.'**
  String get locationUnknown;

  /// No description provided for @authBrandTagline.
  ///
  /// In fr, this message translates to:
  /// **'Votre mobilité,\nnotre métier.'**
  String get authBrandTagline;

  /// No description provided for @authBrandDescription.
  ///
  /// In fr, this message translates to:
  /// **'Location, enchères et apprentissage du code de la route réunis dans une seule plateforme.'**
  String get authBrandDescription;

  /// No description provided for @authStatCars.
  ///
  /// In fr, this message translates to:
  /// **'Véhicules'**
  String get authStatCars;

  /// No description provided for @authStatCities.
  ///
  /// In fr, this message translates to:
  /// **'Villes'**
  String get authStatCities;

  /// No description provided for @authStatRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get authStatRating;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Content de vous revoir'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour gérer vos locations et vos enchères.'**
  String get loginSubtitle;

  /// No description provided for @loginNoAccountWithEmail.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte avec cet e-mail'**
  String get loginNoAccountWithEmail;

  /// No description provided for @loginWrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect'**
  String get loginWrongPassword;

  /// No description provided for @loginRememberMe.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get loginForgotPassword;

  /// No description provided for @loginRetryIn.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer dans {seconds} s'**
  String loginRetryIn(int seconds);

  /// No description provided for @loginNoAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get loginNoAccountYet;

  /// No description provided for @loginAttemptsLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Il vous reste 1 tentative} other{Il vous reste {count} tentatives}}'**
  String loginAttemptsLeft(int count);

  /// No description provided for @loginAccountNotFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte introuvable'**
  String get loginAccountNotFoundTitle;

  /// No description provided for @loginAccountNotFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte n\'est associé à cette adresse e-mail. Vérifiez l\'orthographe ou créez un compte. {attempts}.'**
  String loginAccountNotFoundMessage(String attempts);

  /// No description provided for @loginWrongPasswordMessage.
  ///
  /// In fr, this message translates to:
  /// **'{attempts} avant un blocage de 60 secondes. Mot de passe oublié ? Utilisez le lien ci-dessus.'**
  String loginWrongPasswordMessage(String attempts);

  /// No description provided for @loginLockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion temporairement bloquée'**
  String get loginLockedTitle;

  /// No description provided for @loginLockedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives échouées. Réessayez dans {time}.'**
  String loginLockedMessage(String time);

  /// No description provided for @loginVerifyEmailFirst.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre adresse e-mail pour accéder à votre compte.'**
  String get loginVerifyEmailFirst;

  /// No description provided for @loginWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue {name} !'**
  String loginWelcome(String name);

  /// No description provided for @registerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre compte'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques informations suffisent pour réserver votre première voiture.'**
  String get registerSubtitle;

  /// No description provided for @registerStepIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Identité'**
  String get registerStepIdentity;

  /// No description provided for @registerStepLocation.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get registerStepLocation;

  /// No description provided for @registerStepSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get registerStepSecurity;

  /// No description provided for @registerStepProgress.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total} · {title}'**
  String registerStepProgress(int current, int total, String title);

  /// No description provided for @registerUseLocationOrCity.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez votre position ou choisissez votre ville.'**
  String get registerUseLocationOrCity;

  /// No description provided for @registerAcceptTermsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez accepter les conditions d\'utilisation.'**
  String get registerAcceptTermsRequired;

  /// No description provided for @registerSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé. Vérifiez votre adresse e-mail pour l\'activer.'**
  String get registerSuccess;

  /// No description provided for @registerFailed.
  ///
  /// In fr, this message translates to:
  /// **'Inscription impossible.'**
  String get registerFailed;

  /// No description provided for @registerCreateMyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get registerCreateMyAccount;

  /// No description provided for @registerAlreadyRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Déjà inscrit ?'**
  String get registerAlreadyRegistered;

  /// No description provided for @registerAgencyIntro.
  ///
  /// In fr, this message translates to:
  /// **'Nous choisissons pour vous l\'agence RentCar la plus proche.'**
  String get registerAgencyIntro;

  /// No description provided for @registerUseMyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position'**
  String get registerUseMyLocation;

  /// No description provided for @registerFarFromAgencies.
  ///
  /// In fr, this message translates to:
  /// **'Vous semblez loin de nos agences. Vérifiez la ville proposée ou choisissez-la manuellement.'**
  String get registerFarFromAgencies;

  /// No description provided for @registerChooseOtherCity.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une autre ville'**
  String get registerChooseOtherCity;

  /// No description provided for @registerAgencyCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville de votre agence'**
  String get registerAgencyCity;

  /// No description provided for @registerPreferChooseCity.
  ///
  /// In fr, this message translates to:
  /// **'Je préfère choisir ma ville'**
  String get registerPreferChooseCity;

  /// No description provided for @registerAcceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les conditions générales de location et la politique de confidentialité.'**
  String get registerAcceptTerms;

  /// No description provided for @registerSecurityNotice.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte est enregistré sur cet appareil. Le mot de passe est chiffré (SHA-256) et jamais stocké en clair.'**
  String get registerSecurityNotice;

  /// No description provided for @registerChooseCityBelow.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre ville ci-dessous.'**
  String get registerChooseCityBelow;

  /// No description provided for @strengthWeak.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get strengthWeak;

  /// No description provided for @strengthMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get strengthMedium;

  /// No description provided for @strengthGood.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get strengthGood;

  /// No description provided for @strengthExcellent.
  ///
  /// In fr, this message translates to:
  /// **'Excellent'**
  String get strengthExcellent;

  /// No description provided for @otpExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré. Demandez un nouveau code.'**
  String get otpExpired;

  /// No description provided for @otpTooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais incorrects. Demandez un nouveau code.'**
  String get otpTooManyAttempts;

  /// No description provided for @otpIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez les 6 chiffres du code.'**
  String get otpIncomplete;

  /// No description provided for @otpRequestNew.
  ///
  /// In fr, this message translates to:
  /// **'Demandez un nouveau code.'**
  String get otpRequestNew;

  /// No description provided for @otpWrongCode.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Code incorrect. Il vous reste 1 essai.} other{Code incorrect. Il vous reste {count} essais.}}'**
  String otpWrongCode(int count);

  /// No description provided for @otpSendFailedNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer l\'e-mail. Vérifiez votre connexion Internet puis réessayez.'**
  String get otpSendFailedNetwork;

  /// No description provided for @otpSendFailedService.
  ///
  /// In fr, this message translates to:
  /// **'Le service d\'envoi a refusé la demande (erreur {code}). Réessayez dans un instant.'**
  String otpSendFailedService(int code);

  /// No description provided for @otpValidFor.
  ///
  /// In fr, this message translates to:
  /// **'Valable encore {time}'**
  String otpValidFor(String time);

  /// No description provided for @otpAttemptsLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 essai restant} other{{count} essais restants}}'**
  String otpAttemptsLeft(int count);

  /// No description provided for @otpVerify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le code'**
  String get otpVerify;

  /// No description provided for @otpSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get otpSending;

  /// No description provided for @otpResend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get otpResend;

  /// No description provided for @otpResendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer dans {seconds} s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpEmailNotSent.
  ///
  /// In fr, this message translates to:
  /// **'E-mail non envoyé'**
  String get otpEmailNotSent;

  /// No description provided for @otpEmailSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'E-mail envoyé'**
  String get otpEmailSentTitle;

  /// No description provided for @otpEmailSentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Consultez la boîte de réception de {destination}. L\'e-mail peut prendre une minute et arriver dans les spams.'**
  String otpEmailSentMessage(String destination);

  /// No description provided for @otpNewCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau code a été envoyé.'**
  String get otpNewCodeSent;

  /// No description provided for @forgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez comment recevoir votre code de vérification.'**
  String get forgotSubtitle;

  /// No description provided for @forgotCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code'**
  String get forgotCodeTitle;

  /// No description provided for @forgotCodeSubtitleEmail.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres envoyé par e-mail à {destination}.'**
  String forgotCodeSubtitleEmail(String destination);

  /// No description provided for @forgotCodeSubtitleSms.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres envoyé par SMS à {destination}.'**
  String forgotCodeSubtitleSms(String destination);

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un mot de passe que vous n\'utilisez pas ailleurs.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get forgotSuccessTitle;

  /// No description provided for @forgotSuccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant vous connecter.'**
  String get forgotSuccessSubtitle;

  /// No description provided for @forgotChannelEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get forgotChannelEmail;

  /// No description provided for @forgotChannelSms.
  ///
  /// In fr, this message translates to:
  /// **'SMS'**
  String get forgotChannelSms;

  /// No description provided for @forgotAccountEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail du compte'**
  String get forgotAccountEmail;

  /// No description provided for @forgotAccountPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone du compte'**
  String get forgotAccountPhone;

  /// No description provided for @forgotNoAccountEmail.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte n\'est associé à cet e-mail.'**
  String get forgotNoAccountEmail;

  /// No description provided for @forgotNoAccountPhone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte n\'est associé à ce numéro.'**
  String get forgotNoAccountPhone;

  /// No description provided for @forgotReceiveCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code'**
  String get forgotReceiveCode;

  /// No description provided for @forgotSendingEmail.
  ///
  /// In fr, this message translates to:
  /// **'Envoi de l\'e-mail en cours…'**
  String get forgotSendingEmail;

  /// No description provided for @forgotEmailNotice.
  ///
  /// In fr, this message translates to:
  /// **'Un code à 6 chiffres sera envoyé à l\'adresse e-mail du compte. Pensez à vérifier le dossier Spam.'**
  String get forgotEmailNotice;

  /// No description provided for @forgotSmsNotice.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo : aucun SMS n\'est réellement envoyé. Le code s\'affichera à l\'écran suivant.'**
  String get forgotSmsNotice;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get forgotBackToLogin;

  /// No description provided for @forgotSmsDemoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo SMS — votre code'**
  String get forgotSmsDemoTitle;

  /// No description provided for @forgotSmsDemoFooter.
  ///
  /// In fr, this message translates to:
  /// **'(En production, il serait envoyé par SMS.)'**
  String get forgotSmsDemoFooter;

  /// No description provided for @forgotChangeMethod.
  ///
  /// In fr, this message translates to:
  /// **'Changer de méthode'**
  String get forgotChangeMethod;

  /// No description provided for @forgotSavePassword.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le mot de passe'**
  String get forgotSavePassword;

  /// No description provided for @forgotResetDone.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé'**
  String get forgotResetDone;

  /// No description provided for @forgotResetDoneMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre nouveau mot de passe est enregistré de façon sécurisée. Utilisez-le pour vous connecter.'**
  String get forgotResetDoneMessage;

  /// No description provided for @forgotRedirectIn.
  ///
  /// In fr, this message translates to:
  /// **'Redirection vers la connexion dans {seconds} s…'**
  String forgotRedirectIn(int seconds);

  /// No description provided for @verifyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre e-mail'**
  String get verifyTitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code à 6 chiffres envoyé à {email} pour activer votre compte.'**
  String verifySubtitle(String email);

  /// No description provided for @verifySendingCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoi du code en cours…'**
  String get verifySendingCode;

  /// No description provided for @verifyRetrySend.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer l\'envoi'**
  String get verifyRetrySend;

  /// No description provided for @verifyChangeEmail.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'adresse e-mail'**
  String get verifyChangeEmail;

  /// No description provided for @verifySuccess.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail vérifiée. Bienvenue !'**
  String get verifySuccess;

  /// No description provided for @verifyNewEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse e-mail'**
  String get verifyNewEmailLabel;

  /// No description provided for @verifySameEmail.
  ///
  /// In fr, this message translates to:
  /// **'C\'est déjà votre adresse actuelle'**
  String get verifySameEmail;

  /// No description provided for @verifySendCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un code'**
  String get verifySendCode;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profileTitle;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous serez redirigé vers l\'écran d\'accueil. Les données de la session de démonstration (panier, enchères, progression) seront conservées jusqu\'à la fermeture de l\'application.'**
  String get profileLogoutMessage;

  /// No description provided for @profileStayLoggedIn.
  ///
  /// In fr, this message translates to:
  /// **'Rester connecté'**
  String get profileStayLoggedIn;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Photo supprimée.'**
  String get profilePhotoRemoved;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil mise à jour.'**
  String get profilePhotoUpdated;

  /// No description provided for @profileGroupTrust.
  ///
  /// In fr, this message translates to:
  /// **'Confiance et fidélité'**
  String get profileGroupTrust;

  /// No description provided for @profileGroupInfo.
  ///
  /// In fr, this message translates to:
  /// **'Mes informations'**
  String get profileGroupInfo;

  /// No description provided for @profileGroupAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get profileGroupAccount;

  /// No description provided for @profileGroupAuctions.
  ///
  /// In fr, this message translates to:
  /// **'Enchères'**
  String get profileGroupAuctions;

  /// No description provided for @profileGroupLearning.
  ///
  /// In fr, this message translates to:
  /// **'Apprentissage'**
  String get profileGroupLearning;

  /// No description provided for @profileGroupApp.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get profileGroupApp;

  /// No description provided for @profileEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get profileEdit;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo, nom, téléphone, permis, adresse'**
  String get profileEditSubtitle;

  /// No description provided for @profileChangePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer mon mot de passe'**
  String get profileChangePassword;

  /// No description provided for @profileChangePasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ancien puis nouveau mot de passe'**
  String get profileChangePasswordSubtitle;

  /// No description provided for @profileReservations.
  ///
  /// In fr, this message translates to:
  /// **'Mes réservations'**
  String get profileReservations;

  /// No description provided for @profileRentalsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 location} =1{1 location} other{{count} locations}}'**
  String profileRentalsCount(int count);

  /// No description provided for @profileCart.
  ///
  /// In fr, this message translates to:
  /// **'Mon panier'**
  String get profileCart;

  /// No description provided for @profileCartSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicules en attente de réservation'**
  String get profileCartSubtitle;

  /// No description provided for @profileMyAuctions.
  ///
  /// In fr, this message translates to:
  /// **'Mes enchères et offres'**
  String get profileMyAuctions;

  /// No description provided for @profileMyAuctionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{ongoing} en cours · {won, plural, =0{0 gagnée} =1{1 gagnée} other{{won} gagnées}}'**
  String profileMyAuctionsSubtitle(int ongoing, int won);

  /// No description provided for @profileMarketplace.
  ///
  /// In fr, this message translates to:
  /// **'Place de marché'**
  String get profileMarketplace;

  /// No description provided for @profileMarketplaceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Véhicules d\'occasion aux enchères'**
  String get profileMarketplaceSubtitle;

  /// No description provided for @profileFleet.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de flotte (démo)'**
  String get profileFleet;

  /// No description provided for @profileFleetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord des ventes'**
  String get profileFleetSubtitle;

  /// No description provided for @profileRoadCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de la route'**
  String get profileRoadCode;

  /// No description provided for @profileProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression : {percent} %'**
  String profileProgress(int percent);

  /// No description provided for @profileQuizResults.
  ///
  /// In fr, this message translates to:
  /// **'Mes résultats de quiz'**
  String get profileQuizResults;

  /// No description provided for @profileQuizCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 quiz réalisé} =1{1 quiz réalisé} other{{count} quiz réalisés}}'**
  String profileQuizCount(int count);

  /// No description provided for @profileAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get profileAbout;

  /// No description provided for @profileAboutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'RentCar Tunisia · version démo 1.0.0'**
  String get profileAboutSubtitle;

  /// No description provided for @profileAboutVersion.
  ///
  /// In fr, this message translates to:
  /// **'Démo 1.0.0'**
  String get profileAboutVersion;

  /// No description provided for @profileAboutText.
  ///
  /// In fr, this message translates to:
  /// **'Application frontend de location de voitures, de ventes aux enchères de véhicules d\'occasion et d\'apprentissage du code de la route en Tunisie.\n\nToutes les données sont simulées localement. Aucun backend, aucune base de données, aucun paiement réel.'**
  String get profileAboutText;

  /// No description provided for @profileSupport.
  ///
  /// In fr, this message translates to:
  /// **'Assistance'**
  String get profileSupport;

  /// No description provided for @profileSupportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'contact@rentcar.tn · +216 71 000 000 (fictif)'**
  String get profileSupportSubtitle;

  /// No description provided for @profileSupportSnack.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées fictives : aucun service réel.'**
  String get profileSupportSnack;

  /// No description provided for @profileLogoutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Fermer la session de démonstration'**
  String get profileLogoutSubtitle;

  /// No description provided for @profileAuctionAlias.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo enchères : {name}'**
  String profileAuctionAlias(String name);

  /// No description provided for @profileStatReservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get profileStatReservations;

  /// No description provided for @profileStatAuctions.
  ///
  /// In fr, this message translates to:
  /// **'Enchères'**
  String get profileStatAuctions;

  /// No description provided for @profileStatCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get profileStatCode;

  /// No description provided for @profileStatSpent.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get profileStatSpent;

  /// No description provided for @profileComplete.
  ///
  /// In fr, this message translates to:
  /// **'Profil complet ✓'**
  String get profileComplete;

  /// No description provided for @profileCompletion.
  ///
  /// In fr, this message translates to:
  /// **'Profil complété à {percent} %'**
  String profileCompletion(int percent);

  /// No description provided for @profileCompletionMore.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{encore 1 autre} other{encore {count} autres}}'**
  String profileCompletionMore(int count);

  /// No description provided for @stepPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une photo de profil'**
  String get stepPhoto;

  /// No description provided for @stepPhone.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre numéro de téléphone'**
  String get stepPhone;

  /// No description provided for @stepCin.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre numéro de CIN'**
  String get stepCin;

  /// No description provided for @stepLicenceNumber.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre permis de conduire'**
  String get stepLicenceNumber;

  /// No description provided for @stepLicenceExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez la date d\'expiration du permis'**
  String get stepLicenceExpiry;

  /// No description provided for @stepAddress.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre adresse'**
  String get stepAddress;

  /// No description provided for @stepPosition.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez votre position'**
  String get stepPosition;

  /// No description provided for @stepEmailVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre adresse e-mail'**
  String get stepEmailVerified;

  /// No description provided for @trustTitle.
  ///
  /// In fr, this message translates to:
  /// **'Score de confiance'**
  String get trustTitle;

  /// No description provided for @trustClient.
  ///
  /// In fr, this message translates to:
  /// **'Client {tier}'**
  String trustClient(String tier);

  /// No description provided for @tierBronze.
  ///
  /// In fr, this message translates to:
  /// **'Bronze'**
  String get tierBronze;

  /// No description provided for @tierSilver.
  ///
  /// In fr, this message translates to:
  /// **'Silver'**
  String get tierSilver;

  /// No description provided for @tierGold.
  ///
  /// In fr, this message translates to:
  /// **'Gold'**
  String get tierGold;

  /// No description provided for @trustGoldAdvantage.
  ///
  /// In fr, this message translates to:
  /// **'-10 % sur toutes vos réservations'**
  String get trustGoldAdvantage;

  /// No description provided for @trustToSilver.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Encore 1 location terminée pour passer Silver} other{Encore {count} locations terminées pour passer Silver}}'**
  String trustToSilver(int count);

  /// No description provided for @trustToGold.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Encore 1 location terminée pour passer Gold (-10 %)} other{Encore {count} locations terminées pour passer Gold (-10 %)}}'**
  String trustToGold(int count);

  /// No description provided for @trustClean.
  ///
  /// In fr, this message translates to:
  /// **'{count} sans problème'**
  String trustClean(int count);

  /// No description provided for @trustLate.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 retard} =1{1 retard} other{{count} retards}}'**
  String trustLate(int count);

  /// No description provided for @trustComplaints.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 réclamation} =1{1 réclamation} other{{count} réclamations}}'**
  String trustComplaints(int count);

  /// No description provided for @trustRules.
  ///
  /// In fr, this message translates to:
  /// **'Départ à 50 · +5 par location sans problème · -10 par retard · -15 par réclamation justifiée · -10 par réclamation abusive.'**
  String get trustRules;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profilePersonalInfo;

  /// No description provided for @profileFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get profileFullName;

  /// No description provided for @profileEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get profileEmail;

  /// No description provided for @profileCin.
  ///
  /// In fr, this message translates to:
  /// **'CIN'**
  String get profileCin;

  /// No description provided for @profileBirth.
  ///
  /// In fr, this message translates to:
  /// **'Naissance'**
  String get profileBirth;

  /// No description provided for @profileAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get profileAddress;

  /// No description provided for @profileMemberSince.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis'**
  String get profileMemberSince;

  /// No description provided for @profileLicence.
  ///
  /// In fr, this message translates to:
  /// **'Permis de conduire'**
  String get profileLicence;

  /// No description provided for @profileLicenceNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro'**
  String get profileLicenceNumber;

  /// No description provided for @profileLicenceExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Expiration'**
  String get profileLicenceExpiry;

  /// No description provided for @licenceValid.
  ///
  /// In fr, this message translates to:
  /// **'Valide'**
  String get licenceValid;

  /// No description provided for @licenceExpiringSoon.
  ///
  /// In fr, this message translates to:
  /// **'Expire bientôt'**
  String get licenceExpiringSoon;

  /// No description provided for @licenceExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get licenceExpired;

  /// No description provided for @profilePositionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Position et agence'**
  String get profilePositionTitle;

  /// No description provided for @profileDefaultAgency.
  ///
  /// In fr, this message translates to:
  /// **'Agence par défaut'**
  String get profileDefaultAgency;

  /// No description provided for @profileCoordinates.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées'**
  String get profileCoordinates;

  /// No description provided for @profileUpdatePosition.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour ma position'**
  String get profileUpdatePosition;

  /// No description provided for @profileNewPosition.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle position'**
  String get profileNewPosition;

  /// No description provided for @profileUnchanged.
  ///
  /// In fr, this message translates to:
  /// **'inchangée'**
  String get profileUnchanged;

  /// No description provided for @profileUseThisAddress.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser aussi cette adresse'**
  String get profileUseThisAddress;

  /// No description provided for @profileDefaultAgencySet.
  ///
  /// In fr, this message translates to:
  /// **'Agence par défaut : {city}.'**
  String profileDefaultAgencySet(String city);

  /// No description provided for @changePwdTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePwdTitle;

  /// No description provided for @changePwdSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre mot de passe actuel puis le nouveau.'**
  String get changePwdSubtitle;

  /// No description provided for @changePwdCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get changePwdCurrent;

  /// No description provided for @changePwdCurrentRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe actuel est obligatoire'**
  String get changePwdCurrentRequired;

  /// No description provided for @changePwdMustDiffer.
  ///
  /// In fr, this message translates to:
  /// **'Doit être différent de l\'actuel'**
  String get changePwdMustDiffer;

  /// No description provided for @changePwdConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get changePwdConfirm;

  /// No description provided for @changePwdDone.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié.'**
  String get changePwdDone;

  /// No description provided for @changePwdWrongCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel incorrect.'**
  String get changePwdWrongCurrent;

  /// No description provided for @avatarSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get avatarSheetTitle;

  /// No description provided for @avatarGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie photos'**
  String get avatarGallery;

  /// No description provided for @avatarFiles.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers'**
  String get avatarFiles;

  /// No description provided for @avatarFilesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargements, Drive…'**
  String get avatarFilesSubtitle;

  /// No description provided for @avatarRemove.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get avatarRemove;

  /// No description provided for @avatarOpenFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la sélection d\'image.'**
  String get avatarOpenFailed;

  /// No description provided for @avatarUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire l\'image choisie.'**
  String get avatarUnreadable;

  /// No description provided for @avatarTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Image trop lourde (1,5 Mo maximum).'**
  String get avatarTooLarge;

  /// No description provided for @editSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations utilisées pour vos contrats'**
  String get editSubtitle;

  /// No description provided for @editPhotoSource.
  ///
  /// In fr, this message translates to:
  /// **'Depuis la galerie ou vos fichiers'**
  String get editPhotoSource;

  /// No description provided for @editAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get editAddPhoto;

  /// No description provided for @editChangePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get editChangePhoto;

  /// No description provided for @editSectionIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Identité'**
  String get editSectionIdentity;

  /// No description provided for @editBirthDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get editBirthDate;

  /// No description provided for @editSectionContact.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées'**
  String get editSectionContact;

  /// No description provided for @editCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get editCity;

  /// No description provided for @editSectionDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents de conduite'**
  String get editSectionDocuments;

  /// No description provided for @editCin.
  ///
  /// In fr, this message translates to:
  /// **'Numéro CIN'**
  String get editCin;

  /// No description provided for @editCinHint.
  ///
  /// In fr, this message translates to:
  /// **'8 chiffres'**
  String get editCinHint;

  /// No description provided for @editLicenceNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de permis'**
  String get editLicenceNumber;

  /// No description provided for @editLicenceExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration du permis'**
  String get editLicenceExpiry;

  /// No description provided for @editLicenceExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce permis est expiré'**
  String get editLicenceExpired;

  /// No description provided for @editSectionAuctions.
  ///
  /// In fr, this message translates to:
  /// **'Enchères'**
  String get editSectionAuctions;

  /// No description provided for @editAlias.
  ///
  /// In fr, this message translates to:
  /// **'Pseudonyme public'**
  String get editAlias;

  /// No description provided for @editAliasHelper.
  ///
  /// In fr, this message translates to:
  /// **'Affiché aux autres participants des enchères'**
  String get editAliasHelper;

  /// No description provided for @editAliasField.
  ///
  /// In fr, this message translates to:
  /// **'Le pseudonyme'**
  String get editAliasField;

  /// No description provided for @editSaveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get editSaveChanges;

  /// No description provided for @editConfirmNewEmail.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre nouvelle adresse e-mail.'**
  String get editConfirmNewEmail;

  /// No description provided for @editSaved.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour.'**
  String get editSaved;

  /// No description provided for @commonOr.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get commonOr;

  /// No description provided for @googleContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get googleContinue;

  /// No description provided for @googleErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion Internet. Vérifiez votre réseau puis réessayez.'**
  String get googleErrorNetwork;

  /// No description provided for @googleErrorConfig.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Google n\'est pas encore configurée pour cette application.'**
  String get googleErrorConfig;

  /// No description provided for @googleErrorUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Google n\'est pas disponible sur cet appareil.'**
  String get googleErrorUnsupported;

  /// No description provided for @googleErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'La connexion Google a échoué. Réessayez.'**
  String get googleErrorUnknown;

  /// No description provided for @googleErrorNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte Google disponible sur ce téléphone. Ajoutez un compte dans les paramètres Android, puis réessayez.'**
  String get googleErrorNoAccount;

  /// No description provided for @googleErrorNotAllowed.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte Google n\'est pas autorisé pour l\'instant (application en phase de test).'**
  String get googleErrorNotAllowed;

  /// No description provided for @deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccount;

  /// No description provided for @deleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer votre compte ?'**
  String get deleteTitle;

  /// No description provided for @deleteIntro.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive. Seront supprimés :'**
  String get deleteIntro;

  /// No description provided for @deleteItemProfile.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil et vos informations personnelles'**
  String get deleteItemProfile;

  /// No description provided for @deleteItemPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Votre photo de profil'**
  String get deleteItemPhoto;

  /// No description provided for @deleteItemPrefs.
  ///
  /// In fr, this message translates to:
  /// **'Vos préférences et la session « Se souvenir de moi »'**
  String get deleteItemPrefs;

  /// No description provided for @deleteItemHistory.
  ///
  /// In fr, this message translates to:
  /// **'Votre historique (score de confiance, complétion du profil)'**
  String get deleteItemHistory;

  /// No description provided for @deleteBlocked.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Vous avez 1 réservation en cours ou à venir. Terminez-la ou annulez-la avant de supprimer votre compte.} other{Vous avez {count} réservations en cours ou à venir. Terminez-les ou annulez-les avant de supprimer votre compte.}}'**
  String deleteBlocked(int count);

  /// No description provided for @deleteSeeReservations.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes réservations'**
  String get deleteSeeReservations;

  /// No description provided for @deleteConfirmWord.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get deleteConfirmWord;

  /// No description provided for @deleteGoogleHint.
  ///
  /// In fr, this message translates to:
  /// **'Compte Google sans mot de passe : tapez {word} pour confirmer.'**
  String deleteGoogleHint(String word);

  /// No description provided for @deleteTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tapez {word}'**
  String deleteTypeLabel(String word);

  /// No description provided for @deleteWordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Tapez exactement {word}'**
  String deleteWordMismatch(String word);

  /// No description provided for @deleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deleteConfirm;

  /// No description provided for @deleteDone.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get deleteDone;

  /// No description provided for @deleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'La suppression a échoué. Réessayez.'**
  String get deleteFailed;

  /// No description provided for @remindersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get remindersTitle;

  /// No description provided for @remindersLicence.
  ///
  /// In fr, this message translates to:
  /// **'Expiration du permis'**
  String get remindersLicence;

  /// No description provided for @remindersLicenceSub.
  ///
  /// In fr, this message translates to:
  /// **'30 jours et 7 jours avant'**
  String get remindersLicenceSub;

  /// No description provided for @remindersReservation.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get remindersReservation;

  /// No description provided for @remindersReservationSub.
  ///
  /// In fr, this message translates to:
  /// **'La veille du départ et le jour du retour'**
  String get remindersReservationSub;

  /// No description provided for @remindersProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil incomplet'**
  String get remindersProfile;

  /// No description provided for @remindersProfileSub.
  ///
  /// In fr, this message translates to:
  /// **'2 jours après l\'inscription'**
  String get remindersProfileSub;

  /// No description provided for @remindersDenied.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont désactivées pour RentCar. L\'app fonctionne normalement, mais sans rappels.'**
  String get remindersDenied;

  /// No description provided for @remindersAllow.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les notifications'**
  String get remindersAllow;

  /// No description provided for @remindersUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Les rappels ne sont disponibles que sur Android.'**
  String get remindersUnsupported;

  /// No description provided for @remindersTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester une notification dans 10 s'**
  String get remindersTest;

  /// No description provided for @remindersTestScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Notification de test dans 10 secondes…'**
  String get remindersTestScheduled;

  /// No description provided for @notifChannelName.
  ///
  /// In fr, this message translates to:
  /// **'Rappels RentCar'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In fr, this message translates to:
  /// **'Permis, réservations et profil'**
  String get notifChannelDesc;

  /// No description provided for @notifLicenceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre permis expire bientôt'**
  String get notifLicenceTitle;

  /// No description provided for @notifLicence30Body.
  ///
  /// In fr, this message translates to:
  /// **'Votre permis de conduire expire le {date} (dans 30 jours). Pensez à le renouveler.'**
  String notifLicence30Body(String date);

  /// No description provided for @notifLicence7Body.
  ///
  /// In fr, this message translates to:
  /// **'Plus que 7 jours : votre permis expire le {date}. Mettez à jour votre profil après le renouvellement.'**
  String notifLicence7Body(String date);

  /// No description provided for @notifResaStartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre location commence demain'**
  String get notifResaStartTitle;

  /// No description provided for @notifResaStartBody.
  ///
  /// In fr, this message translates to:
  /// **'{car} vous attend demain à {time} à {city}. N\'oubliez pas votre permis et votre CIN.'**
  String notifResaStartBody(String car, String time, String city);

  /// No description provided for @notifResaReturnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retour du véhicule aujourd\'hui'**
  String get notifResaReturnTitle;

  /// No description provided for @notifResaReturnBody.
  ///
  /// In fr, this message translates to:
  /// **'Rendez {car} aujourd\'hui avant {time} à {city}.'**
  String notifResaReturnBody(String car, String time, String city);

  /// No description provided for @notifProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre profil'**
  String get notifProfileTitle;

  /// No description provided for @notifProfileBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil est complété à {percent} %. Ajoutez les informations manquantes pour réserver plus vite.'**
  String notifProfileBody(int percent);

  /// No description provided for @notifTestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Test RentCar'**
  String get notifTestTitle;

  /// No description provided for @notifTestBody.
  ///
  /// In fr, this message translates to:
  /// **'Les rappels fonctionnent. Touchez pour ouvrir votre profil.'**
  String get notifTestBody;

  /// No description provided for @complaintReport.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get complaintReport;

  /// No description provided for @complaintReportSub.
  ///
  /// In fr, this message translates to:
  /// **'Panne, propreté, facturation, enchère…'**
  String get complaintReportSub;

  /// No description provided for @complaintNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle réclamation'**
  String get complaintNewTitle;

  /// No description provided for @complaintEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la réclamation'**
  String get complaintEditTitle;

  /// No description provided for @complaintFormSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le problème : l\'agence vous répondra rapidement.'**
  String get complaintFormSubtitle;

  /// No description provided for @complaintCategoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get complaintCategoryLabel;

  /// No description provided for @complaintCategoryRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une catégorie.'**
  String get complaintCategoryRequired;

  /// No description provided for @complaintCatPanne.
  ///
  /// In fr, this message translates to:
  /// **'Panne'**
  String get complaintCatPanne;

  /// No description provided for @complaintCatProprete.
  ///
  /// In fr, this message translates to:
  /// **'Propreté'**
  String get complaintCatProprete;

  /// No description provided for @complaintCatRetardAgence.
  ///
  /// In fr, this message translates to:
  /// **'Retard agence'**
  String get complaintCatRetardAgence;

  /// No description provided for @complaintCatFacturation.
  ///
  /// In fr, this message translates to:
  /// **'Facturation'**
  String get complaintCatFacturation;

  /// No description provided for @complaintCatEnchere.
  ///
  /// In fr, this message translates to:
  /// **'Enchère'**
  String get complaintCatEnchere;

  /// No description provided for @complaintCatAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get complaintCatAutre;

  /// No description provided for @complaintStatusEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get complaintStatusEnAttente;

  /// No description provided for @complaintStatusEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get complaintStatusEnCours;

  /// No description provided for @complaintStatusResolue.
  ///
  /// In fr, this message translates to:
  /// **'Résolue'**
  String get complaintStatusResolue;

  /// No description provided for @complaintStatusRejetee.
  ///
  /// In fr, this message translates to:
  /// **'Rejetée'**
  String get complaintStatusRejetee;

  /// No description provided for @complaintPriorityBasse.
  ///
  /// In fr, this message translates to:
  /// **'Basse'**
  String get complaintPriorityBasse;

  /// No description provided for @complaintPriorityMoyenne.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get complaintPriorityMoyenne;

  /// No description provided for @complaintPriorityUrgente.
  ///
  /// In fr, this message translates to:
  /// **'Urgente'**
  String get complaintPriorityUrgente;

  /// No description provided for @complaintLinkLabel.
  ///
  /// In fr, this message translates to:
  /// **'Concerne'**
  String get complaintLinkLabel;

  /// No description provided for @complaintLinkNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get complaintLinkNone;

  /// No description provided for @complaintLinkReservation.
  ///
  /// In fr, this message translates to:
  /// **'Réservation'**
  String get complaintLinkReservation;

  /// No description provided for @complaintLinkAuction.
  ///
  /// In fr, this message translates to:
  /// **'Enchère'**
  String get complaintLinkAuction;

  /// No description provided for @complaintNoReservation.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez aucune réservation à lier. Choisissez « Aucune ».'**
  String get complaintNoReservation;

  /// No description provided for @complaintNoAuction.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez participé à aucune enchère. Choisissez « Aucune ».'**
  String get complaintNoAuction;

  /// No description provided for @complaintPickReservation.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la réservation concernée.'**
  String get complaintPickReservation;

  /// No description provided for @complaintPickAuction.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l\'enchère concernée.'**
  String get complaintPickAuction;

  /// No description provided for @complaintAutoFilled.
  ///
  /// In fr, this message translates to:
  /// **'Voiture : {car} · Agence : {agency}'**
  String complaintAutoFilled(String car, String agency);

  /// No description provided for @complaintTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get complaintTitleLabel;

  /// No description provided for @complaintTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Climatisation en panne'**
  String get complaintTitleHint;

  /// No description provided for @complaintTitleLength.
  ///
  /// In fr, this message translates to:
  /// **'Le titre doit faire entre 5 et 80 caractères.'**
  String get complaintTitleLength;

  /// No description provided for @complaintDescLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get complaintDescLabel;

  /// No description provided for @complaintDescHint.
  ///
  /// In fr, this message translates to:
  /// **'Que s\'est-il passé ? Où et quand ?'**
  String get complaintDescHint;

  /// No description provided for @complaintDescLength.
  ///
  /// In fr, this message translates to:
  /// **'La description doit faire entre 20 et 1000 caractères.'**
  String get complaintDescLength;

  /// No description provided for @complaintSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la réclamation'**
  String get complaintSubmit;

  /// No description provided for @complaintSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer la réclamation. Vérifiez puis réessayez.'**
  String get complaintSaveFailed;

  /// No description provided for @complaintSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation envoyée'**
  String get complaintSentTitle;

  /// No description provided for @complaintSentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Conservez cette référence : elle vous permet de suivre votre réclamation avec l\'agence.'**
  String get complaintSentMessage;

  /// No description provided for @complaintReferenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get complaintReferenceLabel;

  /// No description provided for @complaintDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get complaintDone;

  /// No description provided for @complaintUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation modifiée.'**
  String get complaintUpdated;

  /// No description provided for @complaintLoginRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour signaler un problème.'**
  String get complaintLoginRequired;

  /// No description provided for @complaintNotEditable.
  ///
  /// In fr, this message translates to:
  /// **'Cette réclamation est déjà prise en charge : elle ne peut plus être modifiée.'**
  String get complaintNotEditable;

  /// No description provided for @complaintNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation introuvable.'**
  String get complaintNotFound;

  /// No description provided for @myComplaintsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes réclamations'**
  String get myComplaintsTitle;

  /// No description provided for @myComplaintsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune réclamation} =1{1 réclamation} other{{count} réclamations}}'**
  String myComplaintsCount(int count);

  /// No description provided for @complaintsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get complaintsFilterAll;

  /// No description provided for @complaintsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par titre ou référence'**
  String get complaintsSearchHint;

  /// No description provided for @complaintsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réclamation'**
  String get complaintsEmptyTitle;

  /// No description provided for @complaintsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un souci avec une location ou une enchère ? Signalez-le : l\'agence vous répondra.'**
  String get complaintsEmptyMessage;

  /// No description provided for @complaintsNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réclamation ne correspond à votre recherche.'**
  String get complaintsNoMatch;

  /// No description provided for @complaintsClearFilters.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get complaintsClearFilters;

  /// No description provided for @complaintsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos réclamations.'**
  String get complaintsLoadError;

  /// No description provided for @complaintsRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get complaintsRetry;

  /// No description provided for @timeJustNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} min'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{il y a 1 heure} other{il y a {count} heures}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{hier} other{il y a {count} jours}}'**
  String timeDaysAgo(int count);

  /// No description provided for @complaintDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail de la réclamation'**
  String get complaintDetailsTitle;

  /// No description provided for @complaintFieldCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get complaintFieldCategory;

  /// No description provided for @complaintFieldPriority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get complaintFieldPriority;

  /// No description provided for @complaintFieldStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get complaintFieldStatus;

  /// No description provided for @complaintFieldCar.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get complaintFieldCar;

  /// No description provided for @complaintFieldAgency.
  ///
  /// In fr, this message translates to:
  /// **'Agence'**
  String get complaintFieldAgency;

  /// No description provided for @complaintFieldSent.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée le'**
  String get complaintFieldSent;

  /// No description provided for @complaintFieldUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour'**
  String get complaintFieldUpdated;

  /// No description provided for @complaintLinkedReservation.
  ///
  /// In fr, this message translates to:
  /// **'Réservation liée'**
  String get complaintLinkedReservation;

  /// No description provided for @complaintLinkedAuction.
  ///
  /// In fr, this message translates to:
  /// **'Enchère liée'**
  String get complaintLinkedAuction;

  /// No description provided for @complaintLinkedMissing.
  ///
  /// In fr, this message translates to:
  /// **'Élément lié introuvable (supprimé ?)'**
  String get complaintLinkedMissing;

  /// No description provided for @complaintPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get complaintPhotos;

  /// No description provided for @complaintLocation.
  ///
  /// In fr, this message translates to:
  /// **'Position signalée'**
  String get complaintLocation;

  /// No description provided for @complaintHistory.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get complaintHistory;

  /// No description provided for @complaintAgencyResponse.
  ///
  /// In fr, this message translates to:
  /// **'Réponse de l\'agence'**
  String get complaintAgencyResponse;

  /// No description provided for @complaintWaitingResponse.
  ///
  /// In fr, this message translates to:
  /// **'L\'agence n\'a pas encore répondu. Vous serez informé dès qu\'elle aura traité votre réclamation.'**
  String get complaintWaitingResponse;

  /// No description provided for @complaintEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get complaintEdit;

  /// No description provided for @complaintCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get complaintCancel;

  /// No description provided for @complaintCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette réclamation ?'**
  String get complaintCancelTitle;

  /// No description provided for @complaintCancelMessage.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera définitivement supprimée. Cette action est irréversible.'**
  String get complaintCancelMessage;

  /// No description provided for @complaintCancelConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get complaintCancelConfirm;

  /// No description provided for @complaintKeep.
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get complaintKeep;

  /// No description provided for @complaintCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation annulée.'**
  String get complaintCancelled;

  /// No description provided for @complaintCopied.
  ///
  /// In fr, this message translates to:
  /// **'Référence copiée.'**
  String get complaintCopied;

  /// No description provided for @complaintDemoSimulate.
  ///
  /// In fr, this message translates to:
  /// **'Simuler la réponse de l\'agence (démo)'**
  String get complaintDemoSimulate;

  /// No description provided for @complaintDemoNote.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo : il n\'y a pas encore de back office. Simulez ici le traitement par l\'agence.'**
  String get complaintDemoNote;

  /// No description provided for @complaintDemoTake.
  ///
  /// In fr, this message translates to:
  /// **'Prendre en charge'**
  String get complaintDemoTake;

  /// No description provided for @complaintDemoResolve.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre'**
  String get complaintDemoResolve;

  /// No description provided for @complaintDemoReject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get complaintDemoReject;

  /// No description provided for @complaintDemoDone.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau statut : {status}'**
  String complaintDemoDone(String status);

  /// No description provided for @complaintPhotosTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photos (preuves)'**
  String get complaintPhotosTitle;

  /// No description provided for @complaintPhotosHint.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à 4 photos : dégâts, saleté, ticket, compteur…'**
  String get complaintPhotosHint;

  /// No description provided for @complaintPhotoAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get complaintPhotoAdd;

  /// No description provided for @complaintPhotoRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get complaintPhotoRemove;

  /// No description provided for @complaintPhotoMax.
  ///
  /// In fr, this message translates to:
  /// **'4 photos maximum.'**
  String get complaintPhotoMax;

  /// No description provided for @complaintPhotoFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter cette photo. Réessayez.'**
  String get complaintPhotoFailed;

  /// No description provided for @complaintPhotoCounter.
  ///
  /// In fr, this message translates to:
  /// **'{index} / {total}'**
  String complaintPhotoCounter(int index, int total);

  /// No description provided for @complaintAttachLocation.
  ///
  /// In fr, this message translates to:
  /// **'Joindre ma position'**
  String get complaintAttachLocation;

  /// No description provided for @complaintAttachLocationSub.
  ///
  /// In fr, this message translates to:
  /// **'Aide l\'agence à vous retrouver (activé pour une panne).'**
  String get complaintAttachLocationSub;

  /// No description provided for @complaintLocationNoAddress.
  ///
  /// In fr, this message translates to:
  /// **'Position GPS jointe (adresse non trouvée)'**
  String get complaintLocationNoAddress;

  /// No description provided for @complaintLocationOff.
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible : la réclamation sera envoyée sans position.'**
  String get complaintLocationOff;

  /// No description provided for @complaintOpenMaps.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans Maps'**
  String get complaintOpenMaps;

  /// No description provided for @complaintMapsFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir Maps.'**
  String get complaintMapsFailed;

  /// No description provided for @urgentButton.
  ///
  /// In fr, this message translates to:
  /// **'Panne urgente'**
  String get urgentButton;

  /// No description provided for @urgentButtonSub.
  ///
  /// In fr, this message translates to:
  /// **'Assistance rapide : position et réservation en cours envoyées'**
  String get urgentButtonSub;

  /// No description provided for @urgentSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler une panne urgente'**
  String get urgentSheetTitle;

  /// No description provided for @urgentSheetIntro.
  ///
  /// In fr, this message translates to:
  /// **'Nous envoyons immédiatement à l\'agence :'**
  String get urgentSheetIntro;

  /// No description provided for @urgentWithReservation.
  ///
  /// In fr, this message translates to:
  /// **'Réservation en cours : {car} ({reference})'**
  String urgentWithReservation(String car, String reference);

  /// No description provided for @urgentNoReservation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation en cours : l\'alerte sera envoyée sans réservation liée.'**
  String get urgentNoReservation;

  /// No description provided for @urgentLocating.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de votre position…'**
  String get urgentLocating;

  /// No description provided for @urgentLocationOk.
  ///
  /// In fr, this message translates to:
  /// **'Position : {address}'**
  String urgentLocationOk(String address);

  /// No description provided for @urgentLocationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible : l\'alerte partira sans position.'**
  String get urgentLocationFailed;

  /// No description provided for @urgentSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'alerte'**
  String get urgentSend;

  /// No description provided for @urgentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Panne urgente — {car}'**
  String urgentTitle(String car);

  /// No description provided for @urgentTitleNoCar.
  ///
  /// In fr, this message translates to:
  /// **'Panne urgente'**
  String get urgentTitleNoCar;

  /// No description provided for @urgentDescription.
  ///
  /// In fr, this message translates to:
  /// **'Panne signalée avec le bouton d\'urgence de l\'application. J\'ai besoin d\'une assistance rapide.'**
  String get urgentDescription;

  /// No description provided for @urgentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'envoyer l\'alerte. Appelez directement l\'agence.'**
  String get urgentFailed;

  /// No description provided for @urgentSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Alerte envoyée'**
  String get urgentSentTitle;

  /// No description provided for @urgentSentMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'agence a reçu votre alerte de panne. Appelez-la si vous avez besoin d\'aide immédiatement.'**
  String get urgentSentMessage;

  /// No description provided for @urgentCallAgency.
  ///
  /// In fr, this message translates to:
  /// **'Appeler l\'agence'**
  String get urgentCallAgency;

  /// No description provided for @urgentCallFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer l\'appel. Composez le {number}.'**
  String urgentCallFailed(String number);

  /// No description provided for @urgentSafetyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre sécurité d\'abord'**
  String get urgentSafetyTitle;

  /// No description provided for @urgentTip1.
  ///
  /// In fr, this message translates to:
  /// **'Allumez les feux de détresse et garez-vous sur le bas-côté si possible.'**
  String get urgentTip1;

  /// No description provided for @urgentTip2.
  ///
  /// In fr, this message translates to:
  /// **'Enfilez le gilet de sécurité avant de sortir du véhicule.'**
  String get urgentTip2;

  /// No description provided for @urgentTip3.
  ///
  /// In fr, this message translates to:
  /// **'Placez le triangle de signalisation à environ 30 m derrière la voiture.'**
  String get urgentTip3;

  /// No description provided for @urgentTip4.
  ///
  /// In fr, this message translates to:
  /// **'Mettez-vous à l\'abri derrière la glissière de sécurité, loin de la circulation.'**
  String get urgentTip4;

  /// No description provided for @urgentTip5.
  ///
  /// In fr, this message translates to:
  /// **'Danger ou blessé : appelez le 190 (SAMU), le 197 (police) ou le 198 (protection civile).'**
  String get urgentTip5;

  /// No description provided for @urgentSeeComplaint.
  ///
  /// In fr, this message translates to:
  /// **'Voir la réclamation'**
  String get urgentSeeComplaint;

  /// No description provided for @complaintPriorityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get complaintPriorityLabel;

  /// No description provided for @aiAnalyze.
  ///
  /// In fr, this message translates to:
  /// **'Analyser avec l\'IA'**
  String get aiAnalyze;

  /// No description provided for @aiAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA en cours…'**
  String get aiAnalyzing;

  /// No description provided for @aiSuggestionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion IA'**
  String get aiSuggestionTitle;

  /// No description provided for @aiSuggestionCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie proposée'**
  String get aiSuggestionCategory;

  /// No description provided for @aiSuggestionPriority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité proposée'**
  String get aiSuggestionPriority;

  /// No description provided for @aiToneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ton détecté'**
  String get aiToneLabel;

  /// No description provided for @aiToneCalme.
  ///
  /// In fr, this message translates to:
  /// **'Calme'**
  String get aiToneCalme;

  /// No description provided for @aiToneMecontent.
  ///
  /// In fr, this message translates to:
  /// **'Mécontent'**
  String get aiToneMecontent;

  /// No description provided for @aiToneTresMecontent.
  ///
  /// In fr, this message translates to:
  /// **'Très mécontent'**
  String get aiToneTresMecontent;

  /// No description provided for @aiPriorityRaised.
  ///
  /// In fr, this message translates to:
  /// **'Priorité relevée d\'un niveau : client très mécontent.'**
  String get aiPriorityRaised;

  /// No description provided for @aiAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get aiAccept;

  /// No description provided for @aiKeep.
  ///
  /// In fr, this message translates to:
  /// **'Garder mon choix'**
  String get aiKeep;

  /// No description provided for @aiApplied.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion appliquée'**
  String get aiApplied;

  /// No description provided for @aiKept.
  ///
  /// In fr, this message translates to:
  /// **'Vous gardez votre choix'**
  String get aiKept;

  /// No description provided for @aiDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion automatique (Gemini) : vous gardez le dernier mot.'**
  String get aiDisclaimer;

  /// No description provided for @aiAnalysisTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA'**
  String get aiAnalysisTitle;

  /// No description provided for @aiSummaryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get aiSummaryLabel;

  /// No description provided for @aiImprove.
  ///
  /// In fr, this message translates to:
  /// **'Améliorer mon message'**
  String get aiImprove;

  /// No description provided for @aiImproving.
  ///
  /// In fr, this message translates to:
  /// **'Reformulation en cours…'**
  String get aiImproving;

  /// No description provided for @aiImproveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Message amélioré par l\'IA'**
  String get aiImproveTitle;

  /// No description provided for @aiImproveHint.
  ///
  /// In fr, this message translates to:
  /// **'Même contenu, formulé plus clairement. Vérifiez qu\'aucun détail n\'a changé.'**
  String get aiImproveHint;

  /// No description provided for @aiBefore.
  ///
  /// In fr, this message translates to:
  /// **'Avant'**
  String get aiBefore;

  /// No description provided for @aiAfter.
  ///
  /// In fr, this message translates to:
  /// **'Après'**
  String get aiAfter;

  /// No description provided for @aiUseImproved.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ce texte'**
  String get aiUseImproved;

  /// No description provided for @aiKeepMine.
  ///
  /// In fr, this message translates to:
  /// **'Garder mon texte'**
  String get aiKeepMine;

  /// No description provided for @aiImproveApplied.
  ///
  /// In fr, this message translates to:
  /// **'Message remplacé'**
  String get aiImproveApplied;

  /// No description provided for @aiImproveSame.
  ///
  /// In fr, this message translates to:
  /// **'Votre message est déjà clair.'**
  String get aiImproveSame;

  /// No description provided for @aiImproveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Reformulation indisponible pour le moment.'**
  String get aiImproveFailed;

  /// No description provided for @quickFixChecking.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de solutions rapides…'**
  String get quickFixChecking;

  /// No description provided for @quickFixTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avant d\'envoyer, avez-vous essayé ?'**
  String get quickFixTitle;

  /// No description provided for @quickFixSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Solutions rapides proposées par l\'IA :'**
  String get quickFixSubtitle;

  /// No description provided for @quickFixResolved.
  ///
  /// In fr, this message translates to:
  /// **'Problème résolu'**
  String get quickFixResolved;

  /// No description provided for @quickFixSendAnyway.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer quand même'**
  String get quickFixSendAnyway;

  /// No description provided for @quickFixResolvedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Tant mieux ! Aucune réclamation n\'a été envoyée.'**
  String get quickFixResolvedMsg;

  /// No description provided for @complaintMailSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi de la confirmation par e-mail…'**
  String get complaintMailSending;

  /// No description provided for @complaintMailSent.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation envoyée à {email}'**
  String complaintMailSent(String email);

  /// No description provided for @complaintMailStatusSent.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de suivi envoyé à {email}'**
  String complaintMailStatusSent(String email);

  /// No description provided for @complaintMailFailed.
  ///
  /// In fr, this message translates to:
  /// **'La confirmation par e-mail n\'a pas pu être envoyée.'**
  String get complaintMailFailed;

  /// No description provided for @complaintNotifChannel.
  ///
  /// In fr, this message translates to:
  /// **'Réclamations'**
  String get complaintNotifChannel;

  /// No description provided for @complaintNotifChannelDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suivi de vos réclamations : changements de statut et alertes urgentes.'**
  String get complaintNotifChannelDesc;

  /// No description provided for @complaintNotifStatusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation {reference}'**
  String complaintNotifStatusTitle(String reference);

  /// No description provided for @complaintNotifStatusBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre réclamation {reference} est maintenant {status}.'**
  String complaintNotifStatusBody(String reference, String status);

  /// No description provided for @complaintNotifUrgentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Alerte urgente envoyée'**
  String get complaintNotifUrgentTitle;

  /// No description provided for @complaintNotifUrgentBody.
  ///
  /// In fr, this message translates to:
  /// **'{reference} : l\'agence est prévenue et va vous recontacter. Restez en sécurité.'**
  String complaintNotifUrgentBody(String reference);

  /// No description provided for @complaintNotifOff.
  ///
  /// In fr, this message translates to:
  /// **'Notifications désactivées : vous ne serez pas prévenu quand une réclamation change de statut. Les mises à jour restent visibles ici.'**
  String get complaintNotifOff;

  /// No description provided for @complaintNotifEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get complaintNotifEnable;

  /// No description provided for @complaintUnreadLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get complaintUnreadLabel;

  /// No description provided for @complaintDemoDelayed.
  ///
  /// In fr, this message translates to:
  /// **'Réponse différée (10 s)'**
  String get complaintDemoDelayed;

  /// No description provided for @complaintDemoDelayedSub.
  ///
  /// In fr, this message translates to:
  /// **'Quittez l\'écran ou l\'application pour recevoir la notification.'**
  String get complaintDemoDelayedSub;

  /// No description provided for @complaintDemoScheduled.
  ///
  /// In fr, this message translates to:
  /// **'L\'agence répondra dans 10 s.'**
  String get complaintDemoScheduled;

  /// No description provided for @ratingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous satisfait de la résolution ?'**
  String get ratingTitle;

  /// No description provided for @ratingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre avis aide l\'agence à s\'améliorer.'**
  String get ratingSubtitle;

  /// No description provided for @ratingLabel1.
  ///
  /// In fr, this message translates to:
  /// **'Très insatisfait'**
  String get ratingLabel1;

  /// No description provided for @ratingLabel2.
  ///
  /// In fr, this message translates to:
  /// **'Insatisfait'**
  String get ratingLabel2;

  /// No description provided for @ratingLabel3.
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get ratingLabel3;

  /// No description provided for @ratingLabel4.
  ///
  /// In fr, this message translates to:
  /// **'Satisfait'**
  String get ratingLabel4;

  /// No description provided for @ratingLabel5.
  ///
  /// In fr, this message translates to:
  /// **'Très satisfait'**
  String get ratingLabel5;

  /// No description provided for @ratingStars.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 étoile} other{{count} étoiles}}'**
  String ratingStars(int count);

  /// No description provided for @ratingCommentHint.
  ///
  /// In fr, this message translates to:
  /// **'Un commentaire ? (facultatif)'**
  String get ratingCommentHint;

  /// No description provided for @ratingSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon avis'**
  String get ratingSubmit;

  /// No description provided for @ratingThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre avis'**
  String get ratingThanks;

  /// No description provided for @ratingYourComment.
  ///
  /// In fr, this message translates to:
  /// **'Votre commentaire'**
  String get ratingYourComment;

  /// No description provided for @ratingReopenPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Pas satisfait ? Rouvrez la réclamation : l\'agence la reprendra en charge.'**
  String get ratingReopenPrompt;

  /// No description provided for @ratingReopen.
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir la réclamation'**
  String get ratingReopen;

  /// No description provided for @ratingReopenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir la réclamation ?'**
  String get ratingReopenTitle;

  /// No description provided for @ratingReopenMessage.
  ///
  /// In fr, this message translates to:
  /// **'{reference} repassera « En attente » et l\'agence sera de nouveau chargée de votre demande.'**
  String ratingReopenMessage(String reference);

  /// No description provided for @ratingReopened.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation rouverte'**
  String get ratingReopened;

  /// No description provided for @ratingAverage.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get ratingAverage;

  /// No description provided for @ratingCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 avis} other{{count} avis}}'**
  String ratingCount(int count);

  /// No description provided for @trustAbusive.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 réclamation abusive} =1{1 réclamation abusive} other{{count} réclamations abusives}}'**
  String trustAbusive(int count);

  /// No description provided for @complaintStatsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes réclamations'**
  String get complaintStatsTitle;

  /// No description provided for @complaintStatsTotal.
  ///
  /// In fr, this message translates to:
  /// **'Envoyées'**
  String get complaintStatsTotal;

  /// No description provided for @complaintStatsResolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolues'**
  String get complaintStatsResolved;

  /// No description provided for @complaintStatsAvgGiven.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne donnée'**
  String get complaintStatsAvgGiven;

  /// No description provided for @complaintStatsNoRating.
  ///
  /// In fr, this message translates to:
  /// **'—'**
  String get complaintStatsNoRating;

  /// No description provided for @complaintRejectionWarning.
  ///
  /// In fr, this message translates to:
  /// **'{count} de vos réclamations ont été rejetées ces 30 derniers jours. Vérifiez votre demande avant de l\'envoyer : une réclamation rejetée comme abusive retire 10 points à votre score de confiance.'**
  String complaintRejectionWarning(int count);

  /// No description provided for @complaintRejectionWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get complaintRejectionWarningTitle;

  /// No description provided for @complaintDemoRejectAbusive.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter comme abusive (-10 confiance)'**
  String get complaintDemoRejectAbusive;

  /// No description provided for @complaintAbusiveBadge.
  ///
  /// In fr, this message translates to:
  /// **'Abusive'**
  String get complaintAbusiveBadge;

  /// No description provided for @assistantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Assistant RentCar'**
  String get assistantTitle;

  /// No description provided for @assistantSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Français · English · عربي · derja'**
  String get assistantSubtitle;

  /// No description provided for @assistantTyping.
  ///
  /// In fr, this message translates to:
  /// **'écrit…'**
  String get assistantTyping;

  /// No description provided for @assistantWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name} 👋 Je suis l\'assistant RentCar. Panne, réservation, réclamation, permis ou agence : comment puis-je vous aider ?'**
  String assistantWelcome(String name);

  /// No description provided for @assistantWelcomeGuest.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour 👋 Je suis l\'assistant RentCar. Panne, réservation, réclamation, permis ou agence : comment puis-je vous aider ?'**
  String get assistantWelcomeGuest;

  /// No description provided for @assistantHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez votre message…'**
  String get assistantHint;

  /// No description provided for @assistantSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get assistantSend;

  /// No description provided for @assistantChipBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Panne'**
  String get assistantChipBreakdown;

  /// No description provided for @assistantChipBreakdownMsg.
  ///
  /// In fr, this message translates to:
  /// **'Ma voiture est en panne, que dois-je faire ?'**
  String get assistantChipBreakdownMsg;

  /// No description provided for @assistantChipReservation.
  ///
  /// In fr, this message translates to:
  /// **'Ma réservation'**
  String get assistantChipReservation;

  /// No description provided for @assistantChipReservationMsg.
  ///
  /// In fr, this message translates to:
  /// **'Où en est ma réservation en cours ?'**
  String get assistantChipReservationMsg;

  /// No description provided for @assistantChipComplaint.
  ///
  /// In fr, this message translates to:
  /// **'Suivre une réclamation'**
  String get assistantChipComplaint;

  /// No description provided for @assistantChipComplaintMsg.
  ///
  /// In fr, this message translates to:
  /// **'Où en sont mes réclamations ?'**
  String get assistantChipComplaintMsg;

  /// No description provided for @assistantNewConversation.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle conversation'**
  String get assistantNewConversation;

  /// No description provided for @assistantNewConversationConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Effacer cette conversation et en commencer une nouvelle ?'**
  String get assistantNewConversationConfirm;

  /// No description provided for @assistantClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get assistantClear;

  /// No description provided for @assistantOffline.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet. Vérifiez votre réseau et réessayez, ou faites une réclamation : elle sera enregistrée dans l\'application.'**
  String get assistantOffline;

  /// No description provided for @assistantUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'assistant est momentanément indisponible. Réessayez dans un instant ou faites une réclamation classique.'**
  String get assistantUnavailable;

  /// No description provided for @assistantActionComplaint.
  ///
  /// In fr, this message translates to:
  /// **'Faire une réclamation'**
  String get assistantActionComplaint;

  /// No description provided for @assistantActionBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Panne urgente'**
  String get assistantActionBreakdown;

  /// No description provided for @assistantActionReservations.
  ///
  /// In fr, this message translates to:
  /// **'Mes réservations'**
  String get assistantActionReservations;

  /// No description provided for @assistantActionComplaints.
  ///
  /// In fr, this message translates to:
  /// **'Mes réclamations'**
  String get assistantActionComplaints;

  /// No description provided for @assistantDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Réponses générées par IA (Gemini) : vérifiez les informations importantes auprès de l\'agence.'**
  String get assistantDisclaimer;

  /// No description provided for @assistantDraftIntro.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai préparé ce récapitulatif. Vérifiez-le puis confirmez : rien n\'est envoyé sans votre accord.'**
  String get assistantDraftIntro;

  /// No description provided for @assistantDraftTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation proposée'**
  String get assistantDraftTitle;

  /// No description provided for @assistantDraftReservation.
  ///
  /// In fr, this message translates to:
  /// **'Réservation'**
  String get assistantDraftReservation;

  /// No description provided for @assistantDraftConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get assistantDraftConfirm;

  /// No description provided for @assistantDraftEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get assistantDraftEdit;

  /// No description provided for @assistantDraftConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée et envoyée'**
  String get assistantDraftConfirmed;

  /// No description provided for @assistantDraftEdited.
  ///
  /// In fr, this message translates to:
  /// **'Ouverte dans le formulaire'**
  String get assistantDraftEdited;

  /// No description provided for @assistantDraftNotice.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est créé tant que vous n\'avez pas confirmé.'**
  String get assistantDraftNotice;

  /// No description provided for @assistantComplaintCreated.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation {reference} créée ✓ Vous recevrez une confirmation par e-mail et une notification à chaque changement de statut.'**
  String assistantComplaintCreated(String reference);

  /// No description provided for @assistantActionViewComplaint.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail'**
  String get assistantActionViewComplaint;

  /// No description provided for @assistantActionCallAgency.
  ///
  /// In fr, this message translates to:
  /// **'Appeler l\'agence'**
  String get assistantActionCallAgency;

  /// No description provided for @assistantMic.
  ///
  /// In fr, this message translates to:
  /// **'Dicter un message'**
  String get assistantMic;

  /// No description provided for @assistantStopListening.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la dictée'**
  String get assistantStopListening;

  /// No description provided for @assistantListening.
  ///
  /// In fr, this message translates to:
  /// **'Je vous écoute…'**
  String get assistantListening;

  /// No description provided for @assistantVoiceLang.
  ///
  /// In fr, this message translates to:
  /// **'Langue de la dictée'**
  String get assistantVoiceLang;

  /// No description provided for @assistantVoiceFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get assistantVoiceFr;

  /// No description provided for @assistantVoiceAr.
  ///
  /// In fr, this message translates to:
  /// **'العربية (Tunisie)'**
  String get assistantVoiceAr;

  /// No description provided for @assistantMicDeniedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Micro refusé'**
  String get assistantMicDeniedTitle;

  /// No description provided for @assistantMicDenied.
  ///
  /// In fr, this message translates to:
  /// **'Pour dicter vos messages, autorisez le micro : Paramètres › Applications › RentCar › Autorisations › Micro. Vous pouvez toujours écrire votre message.'**
  String get assistantMicDenied;

  /// No description provided for @assistantVoiceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La reconnaissance vocale n\'est pas disponible sur cet appareil.'**
  String get assistantVoiceUnavailable;

  /// No description provided for @assistantVoiceNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai rien entendu, réessayez.'**
  String get assistantVoiceNoMatch;

  /// No description provided for @assistantVoiceError.
  ///
  /// In fr, this message translates to:
  /// **'La dictée a échoué. Vérifiez votre connexion et réessayez.'**
  String get assistantVoiceError;

  /// No description provided for @assistantFeedbackUp.
  ///
  /// In fr, this message translates to:
  /// **'Réponse utile'**
  String get assistantFeedbackUp;

  /// No description provided for @assistantFeedbackDown.
  ///
  /// In fr, this message translates to:
  /// **'Réponse pas utile'**
  String get assistantFeedbackDown;

  /// No description provided for @assistantQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité des réponses'**
  String get assistantQuality;

  /// No description provided for @assistantQualityStats.
  ///
  /// In fr, this message translates to:
  /// **'{up} 👍 · {down} 👎 — {percent} % de réponses jugées utiles'**
  String assistantQualityStats(int up, int down, int percent);

  /// No description provided for @assistantQualityEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis pour le moment. Utilisez 👍 / 👎 sous les réponses de l\'assistant.'**
  String get assistantQualityEmpty;

  /// No description provided for @assistantQualityNote.
  ///
  /// In fr, this message translates to:
  /// **'Avis enregistrés sur ce téléphone, conservés même après une nouvelle conversation.'**
  String get assistantQualityNote;

  /// No description provided for @aiQuotaReached.
  ///
  /// In fr, this message translates to:
  /// **'Assistant IA temporairement indisponible (quota atteint), réessayez plus tard.'**
  String get aiQuotaReached;

  /// No description provided for @registerAccountType.
  ///
  /// In fr, this message translates to:
  /// **'Type de compte'**
  String get registerAccountType;

  /// No description provided for @registerRoleUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get registerRoleUser;

  /// No description provided for @registerRoleCompany.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get registerRoleCompany;

  /// No description provided for @themeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get themeTitle;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get themeSystem;

  /// No description provided for @scanButton.
  ///
  /// In fr, this message translates to:
  /// **'Scanner mon permis'**
  String get scanButton;

  /// No description provided for @scanInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Lecture du permis…'**
  String get scanInProgress;

  /// No description provided for @scanTip.
  ///
  /// In fr, this message translates to:
  /// **'Photographiez le recto du permis à plat, bien éclairé, sans reflet.'**
  String get scanTip;

  /// No description provided for @scanCamera.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get scanCamera;

  /// No description provided for @scanGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get scanGallery;

  /// No description provided for @scanNothing.
  ///
  /// In fr, this message translates to:
  /// **'Aucune information lisible sur la photo. Saisissez le numéro et la date manuellement, ou réessayez avec une photo plus nette.'**
  String get scanNothing;

  /// No description provided for @scanOnlyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro trouvé. La date d\'expiration n\'a pas pu être lue : choisissez-la ci-dessous.'**
  String get scanOnlyNumber;

  /// No description provided for @scanOnlyExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration trouvée. Le numéro n\'a pas pu être lu : saisissez-le ci-dessous.'**
  String get scanOnlyExpiry;

  /// No description provided for @scanComplete.
  ///
  /// In fr, this message translates to:
  /// **'Numéro et date pré-remplis. Vérifiez-les avant d\'enregistrer.'**
  String get scanComplete;

  /// No description provided for @scanExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce permis a expiré le {date}. Vous ne pourrez pas réserver tant qu\'il n\'est pas renouvelé.'**
  String scanExpired(String date);

  /// No description provided for @scanFilledHelper.
  ///
  /// In fr, this message translates to:
  /// **'Rempli par le scan — vérifiez'**
  String get scanFilledHelper;

  /// No description provided for @scanCameraDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès à la caméra refusé. Autorisez-le dans les paramètres ou choisissez une photo de la galerie.'**
  String get scanCameraDenied;

  /// No description provided for @scanFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire cette image. Réessayez.'**
  String get scanFailed;

  /// No description provided for @validatorRequired.
  ///
  /// In fr, this message translates to:
  /// **'{field} est obligatoire'**
  String validatorRequired(String field);

  /// No description provided for @validatorFieldDefault.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ'**
  String get validatorFieldDefault;

  /// No description provided for @validatorNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire'**
  String get validatorNameRequired;

  /// No description provided for @validatorNameShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est trop court'**
  String get validatorNameShort;

  /// No description provided for @validatorNameLong.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est trop long'**
  String get validatorNameLong;

  /// No description provided for @validatorEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse e-mail est obligatoire'**
  String get validatorEmailRequired;

  /// No description provided for @validatorEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide (ex. nom@mail.tn)'**
  String get validatorEmailInvalid;

  /// No description provided for @validatorPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est obligatoire'**
  String get validatorPasswordRequired;

  /// No description provided for @validatorPasswordShort.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 6 caractères requis'**
  String get validatorPasswordShort;

  /// No description provided for @validatorPasswordLetter.
  ///
  /// In fr, this message translates to:
  /// **'Doit contenir au moins une lettre'**
  String get validatorPasswordLetter;

  /// No description provided for @validatorPasswordDigit.
  ///
  /// In fr, this message translates to:
  /// **'Doit contenir au moins un chiffre'**
  String get validatorPasswordDigit;

  /// No description provided for @validatorConfirmRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer'**
  String get validatorConfirmRequired;

  /// No description provided for @validatorPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get validatorPasswordMismatch;

  /// No description provided for @validatorPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de téléphone est obligatoire'**
  String get validatorPhoneRequired;

  /// No description provided for @validatorPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro tunisien invalide (8 chiffres, ex. 22 345 678)'**
  String get validatorPhoneInvalid;

  /// No description provided for @validatorCinRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro CIN est obligatoire'**
  String get validatorCinRequired;

  /// No description provided for @validatorCinInvalid.
  ///
  /// In fr, this message translates to:
  /// **'La CIN doit contenir 8 chiffres'**
  String get validatorCinInvalid;

  /// No description provided for @validatorLicenceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de permis est obligatoire'**
  String get validatorLicenceRequired;

  /// No description provided for @validatorLicenceInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de permis invalide'**
  String get validatorLicenceInvalid;

  /// No description provided for @validatorCardRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de carte est obligatoire'**
  String get validatorCardRequired;

  /// No description provided for @validatorCardInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro doit contenir 16 chiffres'**
  String get validatorCardInvalid;

  /// No description provided for @validatorExpiryRequired.
  ///
  /// In fr, this message translates to:
  /// **'La date d\'expiration est obligatoire'**
  String get validatorExpiryRequired;

  /// No description provided for @validatorExpiryFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format attendu MM/AA'**
  String get validatorExpiryFormat;

  /// No description provided for @validatorMonthInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Mois invalide'**
  String get validatorMonthInvalid;

  /// No description provided for @validatorCardExpired.
  ///
  /// In fr, this message translates to:
  /// **'Carte expirée'**
  String get validatorCardExpired;

  /// No description provided for @validatorCvvRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le CVV est obligatoire'**
  String get validatorCvvRequired;

  /// No description provided for @validatorCvvInvalid.
  ///
  /// In fr, this message translates to:
  /// **'CVV invalide'**
  String get validatorCvvInvalid;

  /// No description provided for @validatorAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le montant est obligatoire'**
  String get validatorAmountRequired;

  /// No description provided for @validatorAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get validatorAmountInvalid;

  /// No description provided for @validatorAmountPositive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être supérieur à 0'**
  String get validatorAmountPositive;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
