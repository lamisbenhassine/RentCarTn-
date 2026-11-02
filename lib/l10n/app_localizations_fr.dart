// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonEmail => 'Adresse e-mail';

  @override
  String get commonEmailHint => 'nom@exemple.tn';

  @override
  String get commonPassword => 'Mot de passe';

  @override
  String get commonNewPassword => 'Nouveau mot de passe';

  @override
  String get commonConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get commonPasswordHelper =>
      '6 caractères minimum, lettres et chiffres';

  @override
  String get commonPhone => 'Téléphone';

  @override
  String get commonFirstName => 'Prénom';

  @override
  String get commonLastName => 'Nom';

  @override
  String get commonLogin => 'Se connecter';

  @override
  String get commonLogout => 'Se déconnecter';

  @override
  String get commonCreateAccount => 'Créer un compte';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonOpenSettings => 'Ouvrir les paramètres';

  @override
  String get commonSaveFailed => 'Enregistrement impossible.';

  @override
  String get commonChangeFailed => 'Modification impossible.';

  @override
  String get commonNotProvided => 'Non renseigné';

  @override
  String get commonNotProvidedFem => 'Non renseignée';

  @override
  String get commonLocating => 'Localisation en cours…';

  @override
  String get commonAddressUnavailable => 'Adresse indisponible';

  @override
  String get commonPositionUnavailable => 'Position indisponible';

  @override
  String commonNearestAgency(String city, String km) {
    return 'Agence la plus proche : $city ($km km)';
  }

  @override
  String get commonEmailTaken => 'Un compte existe déjà avec cet e-mail.';

  @override
  String get commonPhoneTaken => 'Ce numéro de téléphone est déjà utilisé.';

  @override
  String get commonLanguage => 'Langue';

  @override
  String get locationServiceDisabled =>
      'La localisation (GPS) est désactivée sur votre appareil.';

  @override
  String get locationDenied => 'Vous avez refusé l\'accès à votre position.';

  @override
  String get locationDeniedForever =>
      'L\'accès à la position est bloqué. Autorisez-le dans les paramètres de l\'application.';

  @override
  String get locationTimeout =>
      'Position introuvable pour l\'instant. Réessayez à l\'extérieur ou choisissez votre ville.';

  @override
  String get locationUnknown => 'Impossible de récupérer votre position.';

  @override
  String get authBrandTagline => 'Votre mobilité,\nnotre métier.';

  @override
  String get authBrandDescription =>
      'Location, enchères et apprentissage du code de la route réunis dans une seule plateforme.';

  @override
  String get authStatCars => 'Véhicules';

  @override
  String get authStatCities => 'Villes';

  @override
  String get authStatRating => 'Note moyenne';

  @override
  String get loginTitle => 'Content de vous revoir';

  @override
  String get loginSubtitle =>
      'Connectez-vous pour gérer vos locations et vos enchères.';

  @override
  String get loginNoAccountWithEmail => 'Aucun compte avec cet e-mail';

  @override
  String get loginWrongPassword => 'Mot de passe incorrect';

  @override
  String get loginRememberMe => 'Se souvenir de moi';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String loginRetryIn(int seconds) {
    return 'Réessayer dans $seconds s';
  }

  @override
  String get loginNoAccountYet => 'Pas encore de compte ?';

  @override
  String loginAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il vous reste $count tentatives',
      one: 'Il vous reste 1 tentative',
    );
    return '$_temp0';
  }

  @override
  String get loginAccountNotFoundTitle => 'Compte introuvable';

  @override
  String loginAccountNotFoundMessage(String attempts) {
    return 'Aucun compte n\'est associé à cette adresse e-mail. Vérifiez l\'orthographe ou créez un compte. $attempts.';
  }

  @override
  String loginWrongPasswordMessage(String attempts) {
    return '$attempts avant un blocage de 60 secondes. Mot de passe oublié ? Utilisez le lien ci-dessus.';
  }

  @override
  String get loginLockedTitle => 'Connexion temporairement bloquée';

  @override
  String loginLockedMessage(String time) {
    return 'Trop de tentatives échouées. Réessayez dans $time.';
  }

  @override
  String get loginVerifyEmailFirst =>
      'Vérifiez votre adresse e-mail pour accéder à votre compte.';

  @override
  String loginWelcome(String name) {
    return 'Bienvenue $name !';
  }

  @override
  String get registerTitle => 'Créer votre compte';

  @override
  String get registerSubtitle =>
      'Quelques informations suffisent pour réserver votre première voiture.';

  @override
  String get registerStepIdentity => 'Identité';

  @override
  String get registerStepLocation => 'Localisation';

  @override
  String get registerStepSecurity => 'Sécurité';

  @override
  String registerStepProgress(int current, int total, String title) {
    return 'Étape $current sur $total · $title';
  }

  @override
  String get registerUseLocationOrCity =>
      'Utilisez votre position ou choisissez votre ville.';

  @override
  String get registerAcceptTermsRequired =>
      'Vous devez accepter les conditions d\'utilisation.';

  @override
  String get registerSuccess =>
      'Compte créé. Vérifiez votre adresse e-mail pour l\'activer.';

  @override
  String get registerFailed => 'Inscription impossible.';

  @override
  String get registerCreateMyAccount => 'Créer mon compte';

  @override
  String get registerAlreadyRegistered => 'Déjà inscrit ?';

  @override
  String get registerAgencyIntro =>
      'Nous choisissons pour vous l\'agence RentCar la plus proche.';

  @override
  String get registerUseMyLocation => 'Utiliser ma position';

  @override
  String get registerFarFromAgencies =>
      'Vous semblez loin de nos agences. Vérifiez la ville proposée ou choisissez-la manuellement.';

  @override
  String get registerChooseOtherCity => 'Choisir une autre ville';

  @override
  String get registerAgencyCity => 'Ville de votre agence';

  @override
  String get registerPreferChooseCity => 'Je préfère choisir ma ville';

  @override
  String get registerAcceptTerms =>
      'J\'accepte les conditions générales de location et la politique de confidentialité.';

  @override
  String get registerSecurityNotice =>
      'Votre compte est enregistré sur cet appareil. Le mot de passe est chiffré (SHA-256) et jamais stocké en clair.';

  @override
  String get registerChooseCityBelow => 'Choisissez votre ville ci-dessous.';

  @override
  String get strengthWeak => 'Faible';

  @override
  String get strengthMedium => 'Moyen';

  @override
  String get strengthGood => 'Bon';

  @override
  String get strengthExcellent => 'Excellent';

  @override
  String get otpExpired => 'Ce code a expiré. Demandez un nouveau code.';

  @override
  String get otpTooManyAttempts =>
      'Trop d\'essais incorrects. Demandez un nouveau code.';

  @override
  String get otpIncomplete => 'Saisissez les 6 chiffres du code.';

  @override
  String get otpRequestNew => 'Demandez un nouveau code.';

  @override
  String otpWrongCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Code incorrect. Il vous reste $count essais.',
      one: 'Code incorrect. Il vous reste 1 essai.',
    );
    return '$_temp0';
  }

  @override
  String get otpSendFailedNetwork =>
      'Impossible d\'envoyer l\'e-mail. Vérifiez votre connexion Internet puis réessayez.';

  @override
  String otpSendFailedService(int code) {
    return 'Le service d\'envoi a refusé la demande (erreur $code). Réessayez dans un instant.';
  }

  @override
  String otpValidFor(String time) {
    return 'Valable encore $time';
  }

  @override
  String otpAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count essais restants',
      one: '1 essai restant',
    );
    return '$_temp0';
  }

  @override
  String get otpVerify => 'Vérifier le code';

  @override
  String get otpSending => 'Envoi…';

  @override
  String get otpResend => 'Renvoyer le code';

  @override
  String otpResendIn(int seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get otpEmailNotSent => 'E-mail non envoyé';

  @override
  String get otpEmailSentTitle => 'E-mail envoyé';

  @override
  String otpEmailSentMessage(String destination) {
    return 'Consultez la boîte de réception de $destination. L\'e-mail peut prendre une minute et arriver dans les spams.';
  }

  @override
  String get otpNewCodeSent => 'Un nouveau code a été envoyé.';

  @override
  String get forgotTitle => 'Mot de passe oublié';

  @override
  String get forgotSubtitle =>
      'Choisissez comment recevoir votre code de vérification.';

  @override
  String get forgotCodeTitle => 'Saisissez le code';

  @override
  String forgotCodeSubtitleEmail(String destination) {
    return 'Code à 6 chiffres envoyé par e-mail à $destination.';
  }

  @override
  String forgotCodeSubtitleSms(String destination) {
    return 'Code à 6 chiffres envoyé par SMS à $destination.';
  }

  @override
  String get forgotPasswordSubtitle =>
      'Choisissez un mot de passe que vous n\'utilisez pas ailleurs.';

  @override
  String get forgotSuccessTitle => 'Mot de passe modifié';

  @override
  String get forgotSuccessSubtitle => 'Vous pouvez maintenant vous connecter.';

  @override
  String get forgotChannelEmail => 'E-mail';

  @override
  String get forgotChannelSms => 'SMS';

  @override
  String get forgotAccountEmail => 'Adresse e-mail du compte';

  @override
  String get forgotAccountPhone => 'Téléphone du compte';

  @override
  String get forgotNoAccountEmail =>
      'Aucun compte n\'est associé à cet e-mail.';

  @override
  String get forgotNoAccountPhone => 'Aucun compte n\'est associé à ce numéro.';

  @override
  String get forgotReceiveCode => 'Recevoir le code';

  @override
  String get forgotSendingEmail => 'Envoi de l\'e-mail en cours…';

  @override
  String get forgotEmailNotice =>
      'Un code à 6 chiffres sera envoyé à l\'adresse e-mail du compte. Pensez à vérifier le dossier Spam.';

  @override
  String get forgotSmsNotice =>
      'Mode démo : aucun SMS n\'est réellement envoyé. Le code s\'affichera à l\'écran suivant.';

  @override
  String get forgotBackToLogin => 'Retour à la connexion';

  @override
  String get forgotSmsDemoTitle => 'Mode démo SMS — votre code';

  @override
  String get forgotSmsDemoFooter =>
      '(En production, il serait envoyé par SMS.)';

  @override
  String get forgotChangeMethod => 'Changer de méthode';

  @override
  String get forgotSavePassword => 'Enregistrer le mot de passe';

  @override
  String get forgotResetDone => 'Mot de passe réinitialisé';

  @override
  String get forgotResetDoneMessage =>
      'Votre nouveau mot de passe est enregistré de façon sécurisée. Utilisez-le pour vous connecter.';

  @override
  String forgotRedirectIn(int seconds) {
    return 'Redirection vers la connexion dans $seconds s…';
  }

  @override
  String get verifyTitle => 'Vérifiez votre e-mail';

  @override
  String verifySubtitle(String email) {
    return 'Saisissez le code à 6 chiffres envoyé à $email pour activer votre compte.';
  }

  @override
  String get verifySendingCode => 'Envoi du code en cours…';

  @override
  String get verifyRetrySend => 'Réessayer l\'envoi';

  @override
  String get verifyChangeEmail => 'Modifier l\'adresse e-mail';

  @override
  String get verifySuccess => 'Adresse e-mail vérifiée. Bienvenue !';

  @override
  String get verifyNewEmailLabel => 'Nouvelle adresse e-mail';

  @override
  String get verifySameEmail => 'C\'est déjà votre adresse actuelle';

  @override
  String get verifySendCode => 'Envoyer un code';

  @override
  String get profileTitle => 'Mon profil';

  @override
  String get profileLogoutTitle => 'Se déconnecter ?';

  @override
  String get profileLogoutMessage =>
      'Vous serez redirigé vers l\'écran d\'accueil. Les données de la session de démonstration (panier, enchères, progression) seront conservées jusqu\'à la fermeture de l\'application.';

  @override
  String get profileStayLoggedIn => 'Rester connecté';

  @override
  String get profilePhotoRemoved => 'Photo supprimée.';

  @override
  String get profilePhotoUpdated => 'Photo de profil mise à jour.';

  @override
  String get profileGroupTrust => 'Confiance et fidélité';

  @override
  String get profileGroupInfo => 'Mes informations';

  @override
  String get profileGroupAccount => 'Mon compte';

  @override
  String get profileGroupAuctions => 'Enchères';

  @override
  String get profileGroupLearning => 'Apprentissage';

  @override
  String get profileGroupApp => 'Application';

  @override
  String get profileEdit => 'Modifier mon profil';

  @override
  String get profileEditSubtitle => 'Photo, nom, téléphone, permis, adresse';

  @override
  String get profileChangePassword => 'Changer mon mot de passe';

  @override
  String get profileChangePasswordSubtitle =>
      'Ancien puis nouveau mot de passe';

  @override
  String get profileReservations => 'Mes réservations';

  @override
  String profileRentalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count locations',
      one: '1 location',
      zero: '0 location',
    );
    return '$_temp0';
  }

  @override
  String get profileCart => 'Mon panier';

  @override
  String get profileCartSubtitle => 'Véhicules en attente de réservation';

  @override
  String get profileMyAuctions => 'Mes enchères et offres';

  @override
  String profileMyAuctionsSubtitle(int ongoing, int won) {
    String _temp0 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won gagnées',
      one: '1 gagnée',
      zero: '0 gagnée',
    );
    return '$ongoing en cours · $_temp0';
  }

  @override
  String get profileMarketplace => 'Place de marché';

  @override
  String get profileMarketplaceSubtitle => 'Véhicules d\'occasion aux enchères';

  @override
  String get profileFleet => 'Gestion de flotte (démo)';

  @override
  String get profileFleetSubtitle => 'Tableau de bord des ventes';

  @override
  String get profileRoadCode => 'Code de la route';

  @override
  String profileProgress(int percent) {
    return 'Progression : $percent %';
  }

  @override
  String get profileQuizResults => 'Mes résultats de quiz';

  @override
  String profileQuizCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quiz réalisés',
      one: '1 quiz réalisé',
      zero: '0 quiz réalisé',
    );
    return '$_temp0';
  }

  @override
  String get profileAbout => 'À propos';

  @override
  String get profileAboutSubtitle => 'RentCar Tunisia · version démo 1.0.0';

  @override
  String get profileAboutVersion => 'Démo 1.0.0';

  @override
  String get profileAboutText =>
      'Application frontend de location de voitures, de ventes aux enchères de véhicules d\'occasion et d\'apprentissage du code de la route en Tunisie.\n\nToutes les données sont simulées localement. Aucun backend, aucune base de données, aucun paiement réel.';

  @override
  String get profileSupport => 'Assistance';

  @override
  String get profileSupportSubtitle =>
      'contact@rentcar.tn · +216 71 000 000 (fictif)';

  @override
  String get profileSupportSnack =>
      'Coordonnées fictives : aucun service réel.';

  @override
  String get profileLogoutSubtitle => 'Fermer la session de démonstration';

  @override
  String profileAuctionAlias(String name) {
    return 'Pseudo enchères : $name';
  }

  @override
  String get profileStatReservations => 'Réservations';

  @override
  String get profileStatAuctions => 'Enchères';

  @override
  String get profileStatCode => 'Code';

  @override
  String get profileStatSpent => 'Dépensé';

  @override
  String get profileComplete => 'Profil complet ✓';

  @override
  String profileCompletion(int percent) {
    return 'Profil complété à $percent %';
  }

  @override
  String profileCompletionMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'encore $count autres',
      one: 'encore 1 autre',
    );
    return '$_temp0';
  }

  @override
  String get stepPhoto => 'Ajoutez une photo de profil';

  @override
  String get stepPhone => 'Ajoutez votre numéro de téléphone';

  @override
  String get stepCin => 'Ajoutez votre numéro de CIN';

  @override
  String get stepLicenceNumber => 'Ajoutez votre permis de conduire';

  @override
  String get stepLicenceExpiry => 'Indiquez la date d\'expiration du permis';

  @override
  String get stepAddress => 'Ajoutez votre adresse';

  @override
  String get stepPosition => 'Enregistrez votre position';

  @override
  String get stepEmailVerified => 'Vérifiez votre adresse e-mail';

  @override
  String get trustTitle => 'Score de confiance';

  @override
  String trustClient(String tier) {
    return 'Client $tier';
  }

  @override
  String get tierBronze => 'Bronze';

  @override
  String get tierSilver => 'Silver';

  @override
  String get tierGold => 'Gold';

  @override
  String get trustGoldAdvantage => '-10 % sur toutes vos réservations';

  @override
  String trustToSilver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count locations terminées pour passer Silver',
      one: 'Encore 1 location terminée pour passer Silver',
    );
    return '$_temp0';
  }

  @override
  String trustToGold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count locations terminées pour passer Gold (-10 %)',
      one: 'Encore 1 location terminée pour passer Gold (-10 %)',
    );
    return '$_temp0';
  }

  @override
  String trustClean(int count) {
    return '$count sans problème';
  }

  @override
  String trustLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count retards',
      one: '1 retard',
      zero: '0 retard',
    );
    return '$_temp0';
  }

  @override
  String trustComplaints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réclamations',
      one: '1 réclamation',
      zero: '0 réclamation',
    );
    return '$_temp0';
  }

  @override
  String get trustRules =>
      'Départ à 50 · +5 par location sans problème · -10 par retard · -15 par réclamation justifiée · -10 par réclamation abusive.';

  @override
  String get profilePersonalInfo => 'Informations personnelles';

  @override
  String get profileFullName => 'Nom complet';

  @override
  String get profileEmail => 'E-mail';

  @override
  String get profileCin => 'CIN';

  @override
  String get profileBirth => 'Naissance';

  @override
  String get profileAddress => 'Adresse';

  @override
  String get profileMemberSince => 'Membre depuis';

  @override
  String get profileLicence => 'Permis de conduire';

  @override
  String get profileLicenceNumber => 'Numéro';

  @override
  String get profileLicenceExpiry => 'Expiration';

  @override
  String get licenceValid => 'Valide';

  @override
  String get licenceExpiringSoon => 'Expire bientôt';

  @override
  String get licenceExpired => 'Expiré';

  @override
  String get profilePositionTitle => 'Position et agence';

  @override
  String get profileDefaultAgency => 'Agence par défaut';

  @override
  String get profileCoordinates => 'Coordonnées';

  @override
  String get profileUpdatePosition => 'Mettre à jour ma position';

  @override
  String get profileNewPosition => 'Nouvelle position';

  @override
  String get profileUnchanged => 'inchangée';

  @override
  String get profileUseThisAddress => 'Utiliser aussi cette adresse';

  @override
  String profileDefaultAgencySet(String city) {
    return 'Agence par défaut : $city.';
  }

  @override
  String get changePwdTitle => 'Changer le mot de passe';

  @override
  String get changePwdSubtitle =>
      'Saisissez votre mot de passe actuel puis le nouveau.';

  @override
  String get changePwdCurrent => 'Mot de passe actuel';

  @override
  String get changePwdCurrentRequired =>
      'Le mot de passe actuel est obligatoire';

  @override
  String get changePwdMustDiffer => 'Doit être différent de l\'actuel';

  @override
  String get changePwdConfirm => 'Confirmer le nouveau mot de passe';

  @override
  String get changePwdDone => 'Mot de passe modifié.';

  @override
  String get changePwdWrongCurrent => 'Mot de passe actuel incorrect.';

  @override
  String get avatarSheetTitle => 'Photo de profil';

  @override
  String get avatarGallery => 'Galerie photos';

  @override
  String get avatarFiles => 'Fichiers';

  @override
  String get avatarFilesSubtitle => 'Téléchargements, Drive…';

  @override
  String get avatarRemove => 'Supprimer la photo';

  @override
  String get avatarOpenFailed => 'Impossible d\'ouvrir la sélection d\'image.';

  @override
  String get avatarUnreadable => 'Impossible de lire l\'image choisie.';

  @override
  String get avatarTooLarge => 'Image trop lourde (1,5 Mo maximum).';

  @override
  String get editSubtitle => 'Informations utilisées pour vos contrats';

  @override
  String get editPhotoSource => 'Depuis la galerie ou vos fichiers';

  @override
  String get editAddPhoto => 'Ajouter une photo';

  @override
  String get editChangePhoto => 'Changer la photo';

  @override
  String get editSectionIdentity => 'Identité';

  @override
  String get editBirthDate => 'Date de naissance';

  @override
  String get editSectionContact => 'Coordonnées';

  @override
  String get editCity => 'Ville';

  @override
  String get editSectionDocuments => 'Documents de conduite';

  @override
  String get editCin => 'Numéro CIN';

  @override
  String get editCinHint => '8 chiffres';

  @override
  String get editLicenceNumber => 'Numéro de permis';

  @override
  String get editLicenceExpiry => 'Date d\'expiration du permis';

  @override
  String get editLicenceExpired => 'Ce permis est expiré';

  @override
  String get editSectionAuctions => 'Enchères';

  @override
  String get editAlias => 'Pseudonyme public';

  @override
  String get editAliasHelper => 'Affiché aux autres participants des enchères';

  @override
  String get editAliasField => 'Le pseudonyme';

  @override
  String get editSaveChanges => 'Enregistrer les modifications';

  @override
  String get editConfirmNewEmail => 'Confirmez votre nouvelle adresse e-mail.';

  @override
  String get editSaved => 'Profil mis à jour.';

  @override
  String get commonOr => 'ou';

  @override
  String get googleContinue => 'Continuer avec Google';

  @override
  String get googleErrorNetwork =>
      'Pas de connexion Internet. Vérifiez votre réseau puis réessayez.';

  @override
  String get googleErrorConfig =>
      'La connexion Google n\'est pas encore configurée pour cette application.';

  @override
  String get googleErrorUnsupported =>
      'La connexion Google n\'est pas disponible sur cet appareil.';

  @override
  String get googleErrorUnknown => 'La connexion Google a échoué. Réessayez.';

  @override
  String get googleErrorNoAccount =>
      'Aucun compte Google disponible sur ce téléphone. Ajoutez un compte dans les paramètres Android, puis réessayez.';

  @override
  String get googleErrorNotAllowed =>
      'Ce compte Google n\'est pas autorisé pour l\'instant (application en phase de test).';

  @override
  String get deleteAccount => 'Supprimer mon compte';

  @override
  String get deleteTitle => 'Supprimer votre compte ?';

  @override
  String get deleteIntro => 'Cette action est définitive. Seront supprimés :';

  @override
  String get deleteItemProfile =>
      'Votre profil et vos informations personnelles';

  @override
  String get deleteItemPhoto => 'Votre photo de profil';

  @override
  String get deleteItemPrefs =>
      'Vos préférences et la session « Se souvenir de moi »';

  @override
  String get deleteItemHistory =>
      'Votre historique (score de confiance, complétion du profil)';

  @override
  String deleteBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vous avez $count réservations en cours ou à venir. Terminez-les ou annulez-les avant de supprimer votre compte.',
      one: 'Vous avez 1 réservation en cours ou à venir. Terminez-la ou annulez-la avant de supprimer votre compte.',
    );
    return '$_temp0';
  }

  @override
  String get deleteSeeReservations => 'Voir mes réservations';

  @override
  String get deleteConfirmWord => 'SUPPRIMER';

  @override
  String deleteGoogleHint(String word) {
    return 'Compte Google sans mot de passe : tapez $word pour confirmer.';
  }

  @override
  String deleteTypeLabel(String word) {
    return 'Tapez $word';
  }

  @override
  String deleteWordMismatch(String word) {
    return 'Tapez exactement $word';
  }

  @override
  String get deleteConfirm => 'Supprimer définitivement';

  @override
  String get deleteDone => 'Compte supprimé';

  @override
  String get deleteFailed => 'La suppression a échoué. Réessayez.';

  @override
  String get remindersTitle => 'Rappels';

  @override
  String get remindersLicence => 'Expiration du permis';

  @override
  String get remindersLicenceSub => '30 jours et 7 jours avant';

  @override
  String get remindersReservation => 'Réservations';

  @override
  String get remindersReservationSub =>
      'La veille du départ et le jour du retour';

  @override
  String get remindersProfile => 'Profil incomplet';

  @override
  String get remindersProfileSub => '2 jours après l\'inscription';

  @override
  String get remindersDenied =>
      'Les notifications sont désactivées pour RentCar. L\'app fonctionne normalement, mais sans rappels.';

  @override
  String get remindersAllow => 'Autoriser les notifications';

  @override
  String get remindersUnsupported =>
      'Les rappels ne sont disponibles que sur Android.';

  @override
  String get remindersTest => 'Tester une notification dans 10 s';

  @override
  String get remindersTestScheduled => 'Notification de test dans 10 secondes…';

  @override
  String get notifChannelName => 'Rappels RentCar';

  @override
  String get notifChannelDesc => 'Permis, réservations et profil';

  @override
  String get notifLicenceTitle => 'Votre permis expire bientôt';

  @override
  String notifLicence30Body(String date) {
    return 'Votre permis de conduire expire le $date (dans 30 jours). Pensez à le renouveler.';
  }

  @override
  String notifLicence7Body(String date) {
    return 'Plus que 7 jours : votre permis expire le $date. Mettez à jour votre profil après le renouvellement.';
  }

  @override
  String get notifResaStartTitle => 'Votre location commence demain';

  @override
  String notifResaStartBody(String car, String time, String city) {
    return '$car vous attend demain à $time à $city. N\'oubliez pas votre permis et votre CIN.';
  }

  @override
  String get notifResaReturnTitle => 'Retour du véhicule aujourd\'hui';

  @override
  String notifResaReturnBody(String car, String time, String city) {
    return 'Rendez $car aujourd\'hui avant $time à $city.';
  }

  @override
  String get notifProfileTitle => 'Complétez votre profil';

  @override
  String notifProfileBody(int percent) {
    return 'Votre profil est complété à $percent %. Ajoutez les informations manquantes pour réserver plus vite.';
  }

  @override
  String get notifTestTitle => 'Test RentCar';

  @override
  String get notifTestBody =>
      'Les rappels fonctionnent. Touchez pour ouvrir votre profil.';

  @override
  String get complaintReport => 'Signaler un problème';

  @override
  String get complaintReportSub => 'Panne, propreté, facturation, enchère…';

  @override
  String get complaintNewTitle => 'Nouvelle réclamation';

  @override
  String get complaintEditTitle => 'Modifier la réclamation';

  @override
  String get complaintFormSubtitle =>
      'Décrivez le problème : l\'agence vous répondra rapidement.';

  @override
  String get complaintCategoryLabel => 'Catégorie';

  @override
  String get complaintCategoryRequired => 'Choisissez une catégorie.';

  @override
  String get complaintCatPanne => 'Panne';

  @override
  String get complaintCatProprete => 'Propreté';

  @override
  String get complaintCatRetardAgence => 'Retard agence';

  @override
  String get complaintCatFacturation => 'Facturation';

  @override
  String get complaintCatEnchere => 'Enchère';

  @override
  String get complaintCatAutre => 'Autre';

  @override
  String get complaintStatusEnAttente => 'En attente';

  @override
  String get complaintStatusEnCours => 'En cours';

  @override
  String get complaintStatusResolue => 'Résolue';

  @override
  String get complaintStatusRejetee => 'Rejetée';

  @override
  String get complaintPriorityBasse => 'Basse';

  @override
  String get complaintPriorityMoyenne => 'Moyenne';

  @override
  String get complaintPriorityUrgente => 'Urgente';

  @override
  String get complaintLinkLabel => 'Concerne';

  @override
  String get complaintLinkNone => 'Aucune';

  @override
  String get complaintLinkReservation => 'Réservation';

  @override
  String get complaintLinkAuction => 'Enchère';

  @override
  String get complaintNoReservation =>
      'Vous n\'avez aucune réservation à lier. Choisissez « Aucune ».';

  @override
  String get complaintNoAuction =>
      'Vous n\'avez participé à aucune enchère. Choisissez « Aucune ».';

  @override
  String get complaintPickReservation => 'Choisissez la réservation concernée.';

  @override
  String get complaintPickAuction => 'Choisissez l\'enchère concernée.';

  @override
  String complaintAutoFilled(String car, String agency) {
    return 'Voiture : $car · Agence : $agency';
  }

  @override
  String get complaintTitleLabel => 'Titre';

  @override
  String get complaintTitleHint => 'Ex. Climatisation en panne';

  @override
  String get complaintTitleLength =>
      'Le titre doit faire entre 5 et 80 caractères.';

  @override
  String get complaintDescLabel => 'Description';

  @override
  String get complaintDescHint => 'Que s\'est-il passé ? Où et quand ?';

  @override
  String get complaintDescLength =>
      'La description doit faire entre 20 et 1000 caractères.';

  @override
  String get complaintSubmit => 'Envoyer la réclamation';

  @override
  String get complaintSaveFailed =>
      'Impossible d\'enregistrer la réclamation. Vérifiez puis réessayez.';

  @override
  String get complaintSentTitle => 'Réclamation envoyée';

  @override
  String get complaintSentMessage =>
      'Conservez cette référence : elle vous permet de suivre votre réclamation avec l\'agence.';

  @override
  String get complaintReferenceLabel => 'Référence';

  @override
  String get complaintDone => 'Terminé';

  @override
  String get complaintUpdated => 'Réclamation modifiée.';

  @override
  String get complaintLoginRequired =>
      'Connectez-vous pour signaler un problème.';

  @override
  String get complaintNotEditable =>
      'Cette réclamation est déjà prise en charge : elle ne peut plus être modifiée.';

  @override
  String get complaintNotFound => 'Réclamation introuvable.';

  @override
  String get myComplaintsTitle => 'Mes réclamations';

  @override
  String myComplaintsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réclamations',
      one: '1 réclamation',
      zero: 'Aucune réclamation',
    );
    return '$_temp0';
  }

  @override
  String get complaintsFilterAll => 'Toutes';

  @override
  String get complaintsSearchHint => 'Rechercher par titre ou référence';

  @override
  String get complaintsEmptyTitle => 'Aucune réclamation';

  @override
  String get complaintsEmptyMessage =>
      'Un souci avec une location ou une enchère ? Signalez-le : l\'agence vous répondra.';

  @override
  String get complaintsNoMatch =>
      'Aucune réclamation ne correspond à votre recherche.';

  @override
  String get complaintsClearFilters => 'Effacer les filtres';

  @override
  String get complaintsLoadError => 'Impossible de charger vos réclamations.';

  @override
  String get complaintsRetry => 'Réessayer';

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'hier',
    );
    return '$_temp0';
  }

  @override
  String get complaintDetailsTitle => 'Détail de la réclamation';

  @override
  String get complaintFieldCategory => 'Catégorie';

  @override
  String get complaintFieldPriority => 'Priorité';

  @override
  String get complaintFieldStatus => 'Statut';

  @override
  String get complaintFieldCar => 'Voiture';

  @override
  String get complaintCarLabel => 'Véhicule concerné';

  @override
  String get complaintCarRequiredHint =>
      'Obligatoire pour une panne ou un problème de propreté';

  @override
  String get complaintCarOptionalHint => 'Facultatif';

  @override
  String get complaintCarPick => 'Choisir le véhicule';

  @override
  String get complaintCarRequired => 'Choisissez le véhicule concerné.';

  @override
  String get complaintCarFromReservation => 'Voiture de la réservation liée';

  @override
  String get complaintCarSearch => 'Rechercher : marque, modèle, ville';

  @override
  String get complaintCarEmpty => 'Aucun véhicule dans le catalogue';

  @override
  String complaintCarNoMatch(String query) {
    return 'Aucun véhicule ne correspond à « $query »';
  }

  @override
  String get complaintCarLoadError => 'Impossible de charger les véhicules.';

  @override
  String get complaintCarRetry => 'Réessayer';

  @override
  String get complaintCarRemoved => 'Véhicule retiré du catalogue';

  @override
  String get complaintCarOpen => 'Voir la fiche du véhicule';

  @override
  String get assistantPickCar =>
      'Choisissez le véhicule concerné avant d\'envoyer la réclamation.';

  @override
  String complaintEventBy(String name) {
    return 'par $name';
  }

  @override
  String complaintNotifResponseTitle(String reference) {
    return 'Nouvelle réponse · $reference';
  }

  @override
  String complaintNotifResponseBody(String reference) {
    return 'L\'agence a répondu à votre réclamation $reference.';
  }

  @override
  String get adminComplaintsTitle => 'Réclamations clients';

  @override
  String adminComplaintsMenuSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en attente de traitement',
      one: '1 en attente de traitement',
      zero: 'Aucune en attente',
    );
    return '$_temp0';
  }

  @override
  String get adminStatAvgTime => 'Temps moyen de traitement';

  @override
  String get adminStatAvgRating => 'Satisfaction moyenne';

  @override
  String adminStatRating(String avg, int count) {
    return '$avg/5 · $count avis';
  }

  @override
  String adminDurationDays(int days, int hours) {
    return '$days j $hours h';
  }

  @override
  String adminDurationHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String adminDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get adminSearchHint => 'Référence, client ou véhicule';

  @override
  String get adminFilterAll => 'Toutes';

  @override
  String get adminFilterAllPriorities => 'Toutes priorités';

  @override
  String get adminFilterAllCategories => 'Toutes catégories';

  @override
  String get adminEmptyTitle => 'Aucune réclamation';

  @override
  String get adminEmptyMessage =>
      'Les réclamations des clients apparaîtront ici.';

  @override
  String get adminNoMatch => 'Aucune réclamation ne correspond aux filtres.';

  @override
  String get adminClearFilters => 'Effacer les filtres';

  @override
  String get adminRetry => 'Réessayer';

  @override
  String get adminDetailsTitle => 'Traitement';

  @override
  String get adminClientSection => 'Client';

  @override
  String get adminClientDeleted => 'Compte supprimé';

  @override
  String adminClientTrust(int score) {
    return 'Score de confiance : $score/100';
  }

  @override
  String adminClientRejected(int rejected, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      rejected,
      locale: localeName,
      other: '$rejected réclamations rejetées',
      one: '1 réclamation rejetée',
      zero: 'Aucune réclamation rejetée',
    );
    return '$_temp0 sur $total';
  }

  @override
  String adminHandledBy(String name) {
    return 'Pris en charge par $name';
  }

  @override
  String get adminActionsTitle => 'Actions';

  @override
  String get adminClosedNotice =>
      'Dossier clos : aucune action possible. Le client peut le rouvrir s\'il n\'est pas satisfait.';

  @override
  String get adminTake => 'Prendre en charge';

  @override
  String adminTakeConfirm(String reference) {
    return 'Prendre en charge $reference ? Le client sera prévenu.';
  }

  @override
  String get adminRespond => 'Répondre';

  @override
  String get adminResolve => 'Résoudre';

  @override
  String get adminReject => 'Rejeter';

  @override
  String get adminRejectAbusive => 'Rejeter comme abusive';

  @override
  String get adminRespondTitle => 'Répondre au client';

  @override
  String get adminResolveTitle => 'Résoudre la réclamation';

  @override
  String get adminRejectTitle => 'Rejeter la réclamation';

  @override
  String get adminMessageHint => 'Votre message au client';

  @override
  String get adminMessageRequired =>
      'Écrivez un message d\'au moins 10 caractères.';

  @override
  String get adminAbusiveWarning =>
      'Le score de confiance du client baissera de 10 points. Cette action est définitive.';

  @override
  String get adminAbusiveCheck =>
      'Je confirme que cette réclamation est abusive';

  @override
  String get adminSend => 'Envoyer';

  @override
  String get adminConfirm => 'Confirmer';

  @override
  String adminActionDone(String reference, String status) {
    return '$reference : $status';
  }

  @override
  String get adminResponseSent => 'Réponse enregistrée et envoyée au client.';

  @override
  String get adminActionFailed => 'Action impossible. Réessayez.';

  @override
  String get adminBanTitle => 'Bannir ce client ?';

  @override
  String adminBanMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réclamations rejetées',
      one: '1 réclamation rejetée',
    );
    return '$name a maintenant $_temp0.';
  }

  @override
  String get adminBanLater => 'Plus tard';

  @override
  String get adminBan => 'Bannir';

  @override
  String get adminBanSoon =>
      'Le bannissement sera disponible à la prochaine étape.';

  @override
  String durationMinSec(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get suspendedTitle => 'Compte suspendu';

  @override
  String suspendedUntil(String date) {
    return 'Votre compte est suspendu jusqu\'au $date.';
  }

  @override
  String get suspendedPermanent => 'Votre compte est suspendu définitivement.';

  @override
  String get suspendedRemaining => 'Temps restant';

  @override
  String get suspendedReason => 'Motif';

  @override
  String get suspendedOver =>
      'Votre suspension est terminée : vous pouvez vous reconnecter.';

  @override
  String get suspendedContact => 'Contacter le support';

  @override
  String get suspendedCallAgency => 'Appeler l\'agence';

  @override
  String get suspendedBack => 'Retour à la connexion';

  @override
  String suspendedMailSubject(String email) {
    return 'Compte suspendu : $email';
  }

  @override
  String suspendedMailFailed(String email) {
    return 'Aucune application e-mail. Écrivez à $email.';
  }

  @override
  String get adminUsersTitle => 'Utilisateurs';

  @override
  String adminUsersMenuSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comptes suspendus',
      one: '1 compte suspendu',
      zero: 'Aucun compte suspendu',
    );
    return '$_temp0';
  }

  @override
  String get adminUsersSearch => 'Nom, e-mail ou téléphone';

  @override
  String get adminUsersFilterAll => 'Tous';

  @override
  String get adminUsersFilterBanned => 'Bannis';

  @override
  String get adminUsersFilterActive => 'Actifs';

  @override
  String get adminUsersEmpty => 'Aucun utilisateur ne correspond.';

  @override
  String get adminRoleAdmin => 'Admin';

  @override
  String adminUserAbusive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réclamations abusives',
      one: '1 réclamation abusive',
      zero: 'Aucune réclamation abusive',
    );
    return '$_temp0';
  }

  @override
  String adminUserMemberSince(String date) {
    return 'Membre depuis le $date';
  }

  @override
  String get adminUserBan => 'Bannir';

  @override
  String get adminUserUnban => 'Débannir';

  @override
  String adminUserUnbanConfirm(String name) {
    return 'Réactiver le compte de $name ? Il pourra se reconnecter immédiatement.';
  }

  @override
  String get adminUserIsAdmin =>
      'Un compte administrateur ne peut pas être banni.';

  @override
  String get adminUserIsSelf => 'Vous ne pouvez pas vous bannir vous-même.';

  @override
  String banBadgeUntil(String date) {
    return 'Banni jusqu\'au $date';
  }

  @override
  String get banBadgePermanent => 'Banni définitivement';

  @override
  String get banCurrentTitle => 'Suspension en cours';

  @override
  String banCurrentBy(String name) {
    return 'Par $name';
  }

  @override
  String get banHistoryTitle => 'Historique des bannissements';

  @override
  String get banHistoryEmpty => 'Aucun bannissement.';

  @override
  String get banHistoryActive => 'En cours';

  @override
  String get banHistoryPermanent => 'Définitif';

  @override
  String banHistoryPeriod(String start, String end) {
    return 'Du $start au $end';
  }

  @override
  String banHistorySince(String start) {
    return 'Depuis le $start';
  }

  @override
  String banHistoryLifted(String date, String name) {
    return 'Levé le $date · $name';
  }

  @override
  String get banHistoryAuto => 'Automatique';

  @override
  String banHistoryComplaint(String reference) {
    return 'Réclamation $reference';
  }

  @override
  String banDialogTitle(String name) {
    return 'Bannir $name';
  }

  @override
  String get banDuration => 'Durée';

  @override
  String get ban24h => '24 h';

  @override
  String get ban3d => '3 jours';

  @override
  String get ban7d => '7 jours';

  @override
  String get ban30d => '30 jours';

  @override
  String get banCustom => 'Personnalisée';

  @override
  String get banPermanent => 'Définitif';

  @override
  String get banPickDate => 'Choisir la date et l\'heure de fin';

  @override
  String banEnd(String date) {
    return 'Fin : $date';
  }

  @override
  String get banEndRequired => 'Choisissez une date de fin dans le futur.';

  @override
  String get banReasonLabel => 'Motif (obligatoire)';

  @override
  String get banReasonHint => 'Affiché au client et envoyé par e-mail';

  @override
  String get banReasonRequired => 'Indiquez le motif du bannissement.';

  @override
  String banFalseComplaint(String reference) {
    return 'Fausse réclamation $reference';
  }

  @override
  String get banSummaryTitle => 'Récapitulatif';

  @override
  String banSummaryUntil(String name, String date, String duration) {
    return '$name sera suspendu jusqu\'au $date ($duration).';
  }

  @override
  String banSummaryPermanent(String name) {
    return '$name sera suspendu définitivement.';
  }

  @override
  String banSummaryReason(String reason) {
    return 'Motif : $reason';
  }

  @override
  String get banSummaryEffects =>
      'Il sera déconnecté et ne pourra plus se connecter (e-mail ou Google). Un e-mail lui sera envoyé.';

  @override
  String get banNext => 'Continuer';

  @override
  String get banEdit => 'Modifier';

  @override
  String get banConfirm => 'Confirmer le bannissement';

  @override
  String banDone(String name) {
    return '$name est banni.';
  }

  @override
  String unbanDone(String name) {
    return '$name est réactivé.';
  }

  @override
  String get banMailSent => 'E-mail envoyé au client.';

  @override
  String get banMailFailed => 'L\'e-mail au client n\'a pas pu être envoyé.';

  @override
  String get banFailed => 'Bannissement impossible. Réessayez.';

  @override
  String get navMenu => 'Menu';

  @override
  String get navMyActivity => 'Mon activité';

  @override
  String get navAdministration => 'Administration';

  @override
  String get complaintFieldAgency => 'Agence';

  @override
  String get complaintFieldSent => 'Envoyée le';

  @override
  String get complaintFieldUpdated => 'Mise à jour';

  @override
  String get complaintLinkedReservation => 'Réservation liée';

  @override
  String get complaintLinkedAuction => 'Enchère liée';

  @override
  String get complaintLinkedMissing => 'Élément lié introuvable (supprimé ?)';

  @override
  String get complaintPhotos => 'Photos';

  @override
  String get complaintLocation => 'Position signalée';

  @override
  String get complaintHistory => 'Suivi';

  @override
  String get complaintAgencyResponse => 'Réponse de l\'agence';

  @override
  String get complaintWaitingResponse =>
      'L\'agence n\'a pas encore répondu. Vous serez informé dès qu\'elle aura traité votre réclamation.';

  @override
  String get complaintEdit => 'Modifier';

  @override
  String get complaintCancel => 'Annuler';

  @override
  String get complaintCancelTitle => 'Annuler cette réclamation ?';

  @override
  String get complaintCancelMessage =>
      'Elle sera définitivement supprimée. Cette action est irréversible.';

  @override
  String get complaintCancelConfirm => 'Oui, annuler';

  @override
  String get complaintKeep => 'Garder';

  @override
  String get complaintCancelled => 'Réclamation annulée.';

  @override
  String get complaintCopied => 'Référence copiée.';

  @override
  String get complaintDemoSimulate => 'Simuler la réponse de l\'agence (démo)';

  @override
  String get complaintDemoNote =>
      'Mode démo : il n\'y a pas encore de back office. Simulez ici le traitement par l\'agence.';

  @override
  String get complaintDemoTake => 'Prendre en charge';

  @override
  String get complaintDemoResolve => 'Résoudre';

  @override
  String get complaintDemoReject => 'Rejeter';

  @override
  String complaintDemoDone(String status) {
    return 'Nouveau statut : $status';
  }

  @override
  String get complaintPhotosTitle => 'Photos (preuves)';

  @override
  String get complaintPhotosHint =>
      'Jusqu\'à 4 photos : dégâts, saleté, ticket, compteur…';

  @override
  String get complaintPhotoAdd => 'Ajouter';

  @override
  String get complaintPhotoRemove => 'Retirer la photo';

  @override
  String get complaintPhotoMax => '4 photos maximum.';

  @override
  String get complaintPhotoFailed =>
      'Impossible d\'ajouter cette photo. Réessayez.';

  @override
  String complaintPhotoCounter(int index, int total) {
    return '$index / $total';
  }

  @override
  String get complaintAttachLocation => 'Joindre ma position';

  @override
  String get complaintAttachLocationSub =>
      'Aide l\'agence à vous retrouver (activé pour une panne).';

  @override
  String get complaintLocationNoAddress =>
      'Position GPS jointe (adresse non trouvée)';

  @override
  String get complaintLocationOff =>
      'Position indisponible : la réclamation sera envoyée sans position.';

  @override
  String get complaintOpenMaps => 'Ouvrir dans Maps';

  @override
  String get complaintMapsFailed => 'Impossible d\'ouvrir Maps.';

  @override
  String get urgentButton => 'Panne urgente';

  @override
  String get urgentButtonSub =>
      'Assistance rapide : position et réservation en cours envoyées';

  @override
  String get urgentSheetTitle => 'Signaler une panne urgente';

  @override
  String get urgentSheetIntro => 'Nous envoyons immédiatement à l\'agence :';

  @override
  String urgentWithReservation(String car, String reference) {
    return 'Réservation en cours : $car ($reference)';
  }

  @override
  String get urgentNoReservation =>
      'Aucune réservation en cours : l\'alerte sera envoyée sans réservation liée.';

  @override
  String get urgentLocating => 'Recherche de votre position…';

  @override
  String urgentLocationOk(String address) {
    return 'Position : $address';
  }

  @override
  String get urgentLocationFailed =>
      'Position indisponible : l\'alerte partira sans position.';

  @override
  String get urgentSend => 'Envoyer l\'alerte';

  @override
  String urgentTitle(String car) {
    return 'Panne urgente — $car';
  }

  @override
  String get urgentTitleNoCar => 'Panne urgente';

  @override
  String get urgentDescription =>
      'Panne signalée avec le bouton d\'urgence de l\'application. J\'ai besoin d\'une assistance rapide.';

  @override
  String get urgentFailed =>
      'Impossible d\'envoyer l\'alerte. Appelez directement l\'agence.';

  @override
  String get urgentSentTitle => 'Alerte envoyée';

  @override
  String get urgentSentMessage =>
      'L\'agence a reçu votre alerte de panne. Appelez-la si vous avez besoin d\'aide immédiatement.';

  @override
  String get urgentCallAgency => 'Appeler l\'agence';

  @override
  String urgentCallFailed(String number) {
    return 'Impossible de lancer l\'appel. Composez le $number.';
  }

  @override
  String get urgentSafetyTitle => 'Votre sécurité d\'abord';

  @override
  String get urgentTip1 =>
      'Allumez les feux de détresse et garez-vous sur le bas-côté si possible.';

  @override
  String get urgentTip2 =>
      'Enfilez le gilet de sécurité avant de sortir du véhicule.';

  @override
  String get urgentTip3 =>
      'Placez le triangle de signalisation à environ 30 m derrière la voiture.';

  @override
  String get urgentTip4 =>
      'Mettez-vous à l\'abri derrière la glissière de sécurité, loin de la circulation.';

  @override
  String get urgentTip5 =>
      'Danger ou blessé : appelez le 190 (SAMU), le 197 (police) ou le 198 (protection civile).';

  @override
  String get urgentSeeComplaint => 'Voir la réclamation';

  @override
  String get complaintPriorityLabel => 'Priorité';

  @override
  String get aiAnalyze => 'Analyser avec l\'IA';

  @override
  String get aiAnalyzing => 'Analyse IA en cours…';

  @override
  String get aiSuggestionTitle => 'Suggestion IA';

  @override
  String get aiSuggestionCategory => 'Catégorie proposée';

  @override
  String get aiSuggestionPriority => 'Priorité proposée';

  @override
  String get aiToneLabel => 'Ton détecté';

  @override
  String get aiToneCalme => 'Calme';

  @override
  String get aiToneMecontent => 'Mécontent';

  @override
  String get aiToneTresMecontent => 'Très mécontent';

  @override
  String get aiPriorityRaised =>
      'Priorité relevée d\'un niveau : client très mécontent.';

  @override
  String get aiAccept => 'Accepter';

  @override
  String get aiKeep => 'Garder mon choix';

  @override
  String get aiApplied => 'Suggestion appliquée';

  @override
  String get aiKept => 'Vous gardez votre choix';

  @override
  String get aiDisclaimer =>
      'Suggestion automatique (Gemini) : vous gardez le dernier mot.';

  @override
  String get aiAnalysisTitle => 'Analyse IA';

  @override
  String get aiSummaryLabel => 'Résumé';

  @override
  String get aiImprove => 'Améliorer mon message';

  @override
  String get aiImproving => 'Reformulation en cours…';

  @override
  String get aiImproveTitle => 'Message amélioré par l\'IA';

  @override
  String get aiImproveHint =>
      'Même contenu, formulé plus clairement. Vérifiez qu\'aucun détail n\'a changé.';

  @override
  String get aiBefore => 'Avant';

  @override
  String get aiAfter => 'Après';

  @override
  String get aiUseImproved => 'Utiliser ce texte';

  @override
  String get aiKeepMine => 'Garder mon texte';

  @override
  String get aiImproveApplied => 'Message remplacé';

  @override
  String get aiImproveSame => 'Votre message est déjà clair.';

  @override
  String get aiImproveFailed => 'Reformulation indisponible pour le moment.';

  @override
  String get quickFixChecking => 'Recherche de solutions rapides…';

  @override
  String get quickFixTitle => 'Avant d\'envoyer, avez-vous essayé ?';

  @override
  String get quickFixSubtitle => 'Solutions rapides proposées par l\'IA :';

  @override
  String get quickFixResolved => 'Problème résolu';

  @override
  String get quickFixSendAnyway => 'Envoyer quand même';

  @override
  String get quickFixResolvedMsg =>
      'Tant mieux ! Aucune réclamation n\'a été envoyée.';

  @override
  String get complaintMailSending => 'Envoi de la confirmation par e-mail…';

  @override
  String complaintMailSent(String email) {
    return 'Confirmation envoyée à $email';
  }

  @override
  String complaintMailStatusSent(String email) {
    return 'E-mail de suivi envoyé à $email';
  }

  @override
  String get complaintMailFailed =>
      'La confirmation par e-mail n\'a pas pu être envoyée.';

  @override
  String get complaintNotifChannel => 'Réclamations';

  @override
  String get complaintNotifChannelDesc =>
      'Suivi de vos réclamations : changements de statut et alertes urgentes.';

  @override
  String complaintNotifStatusTitle(String reference) {
    return 'Réclamation $reference';
  }

  @override
  String complaintNotifStatusBody(String reference, String status) {
    return 'Votre réclamation $reference est maintenant $status.';
  }

  @override
  String get complaintNotifUrgentTitle => 'Alerte urgente envoyée';

  @override
  String complaintNotifUrgentBody(String reference) {
    return '$reference : l\'agence est prévenue et va vous recontacter. Restez en sécurité.';
  }

  @override
  String get complaintNotifOff =>
      'Notifications désactivées : vous ne serez pas prévenu quand une réclamation change de statut. Les mises à jour restent visibles ici.';

  @override
  String get complaintNotifEnable => 'Activer';

  @override
  String get complaintUnreadLabel => 'Nouveau';

  @override
  String get complaintDemoDelayed => 'Réponse différée (10 s)';

  @override
  String get complaintDemoDelayedSub =>
      'Quittez l\'écran ou l\'application pour recevoir la notification.';

  @override
  String get complaintDemoScheduled => 'L\'agence répondra dans 10 s.';

  @override
  String get ratingTitle => 'Êtes-vous satisfait de la résolution ?';

  @override
  String get ratingSubtitle => 'Votre avis aide l\'agence à s\'améliorer.';

  @override
  String get ratingLabel1 => 'Très insatisfait';

  @override
  String get ratingLabel2 => 'Insatisfait';

  @override
  String get ratingLabel3 => 'Correct';

  @override
  String get ratingLabel4 => 'Satisfait';

  @override
  String get ratingLabel5 => 'Très satisfait';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étoiles',
      one: '1 étoile',
    );
    return '$_temp0';
  }

  @override
  String get ratingCommentHint => 'Un commentaire ? (facultatif)';

  @override
  String get ratingSubmit => 'Envoyer mon avis';

  @override
  String get ratingThanks => 'Merci pour votre avis';

  @override
  String get ratingYourComment => 'Votre commentaire';

  @override
  String get ratingReopenPrompt =>
      'Pas satisfait ? Rouvrez la réclamation : l\'agence la reprendra en charge.';

  @override
  String get ratingReopen => 'Rouvrir la réclamation';

  @override
  String get ratingReopenTitle => 'Rouvrir la réclamation ?';

  @override
  String ratingReopenMessage(String reference) {
    return '$reference repassera « En attente » et l\'agence sera de nouveau chargée de votre demande.';
  }

  @override
  String get ratingReopened => 'Réclamation rouverte';

  @override
  String get ratingAverage => 'Note moyenne';

  @override
  String ratingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
    );
    return '$_temp0';
  }

  @override
  String trustAbusive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réclamations abusives',
      one: '1 réclamation abusive',
      zero: '0 réclamation abusive',
    );
    return '$_temp0';
  }

  @override
  String get complaintStatsTitle => 'Mes réclamations';

  @override
  String get complaintStatsTotal => 'Envoyées';

  @override
  String get complaintStatsResolved => 'Résolues';

  @override
  String get complaintStatsAvgGiven => 'Note moyenne donnée';

  @override
  String get complaintStatsNoRating => '—';

  @override
  String complaintRejectionWarning(int count) {
    return '$count de vos réclamations ont été rejetées ces 30 derniers jours. Vérifiez votre demande avant de l\'envoyer : une réclamation rejetée comme abusive retire 10 points à votre score de confiance.';
  }

  @override
  String get complaintRejectionWarningTitle => 'Attention';

  @override
  String get complaintDemoRejectAbusive =>
      'Rejeter comme abusive (-10 confiance)';

  @override
  String get complaintAbusiveBadge => 'Abusive';

  @override
  String get assistantTitle => 'Assistant RentCar';

  @override
  String get assistantSubtitle => 'Français · English · عربي · derja';

  @override
  String get assistantTyping => 'écrit…';

  @override
  String assistantWelcome(String name) {
    return 'Bonjour $name 👋 Je suis l\'assistant RentCar. Panne, réservation, réclamation, permis ou agence : comment puis-je vous aider ?';
  }

  @override
  String get assistantWelcomeGuest =>
      'Bonjour 👋 Je suis l\'assistant RentCar. Panne, réservation, réclamation, permis ou agence : comment puis-je vous aider ?';

  @override
  String get assistantHint => 'Écrivez votre message…';

  @override
  String get assistantSend => 'Envoyer';

  @override
  String get assistantChipBreakdown => 'Panne';

  @override
  String get assistantChipBreakdownMsg =>
      'Ma voiture est en panne, que dois-je faire ?';

  @override
  String get assistantChipReservation => 'Ma réservation';

  @override
  String get assistantChipReservationMsg =>
      'Où en est ma réservation en cours ?';

  @override
  String get assistantChipComplaint => 'Suivre une réclamation';

  @override
  String get assistantChipComplaintMsg => 'Où en sont mes réclamations ?';

  @override
  String get assistantNewConversation => 'Nouvelle conversation';

  @override
  String get assistantNewConversationConfirm =>
      'Effacer cette conversation et en commencer une nouvelle ?';

  @override
  String get assistantClear => 'Effacer';

  @override
  String get assistantOffline =>
      'Pas de connexion internet. Vérifiez votre réseau et réessayez, ou faites une réclamation : elle sera enregistrée dans l\'application.';

  @override
  String get assistantUnavailable =>
      'L\'assistant est momentanément indisponible. Réessayez dans un instant ou faites une réclamation classique.';

  @override
  String get assistantActionComplaint => 'Faire une réclamation';

  @override
  String get assistantActionBreakdown => 'Panne urgente';

  @override
  String get assistantActionReservations => 'Mes réservations';

  @override
  String get assistantActionComplaints => 'Mes réclamations';

  @override
  String get assistantDisclaimer =>
      'Réponses générées par IA (Gemini) : vérifiez les informations importantes auprès de l\'agence.';

  @override
  String get assistantDraftIntro =>
      'J\'ai préparé ce récapitulatif. Vérifiez-le puis confirmez : rien n\'est envoyé sans votre accord.';

  @override
  String get assistantDraftTitle => 'Réclamation proposée';

  @override
  String get assistantDraftReservation => 'Réservation';

  @override
  String get assistantDraftConfirm => 'Confirmer';

  @override
  String get assistantDraftEdit => 'Modifier';

  @override
  String get assistantDraftConfirmed => 'Confirmée et envoyée';

  @override
  String get assistantDraftEdited => 'Ouverte dans le formulaire';

  @override
  String get assistantDraftNotice =>
      'Rien n\'est créé tant que vous n\'avez pas confirmé.';

  @override
  String assistantComplaintCreated(String reference) {
    return 'Réclamation $reference créée ✓ Vous recevrez une confirmation par e-mail et une notification à chaque changement de statut.';
  }

  @override
  String get assistantActionViewComplaint => 'Voir le détail';

  @override
  String get assistantActionCallAgency => 'Appeler l\'agence';

  @override
  String get assistantMic => 'Dicter un message';

  @override
  String get assistantStopListening => 'Arrêter la dictée';

  @override
  String get assistantListening => 'Je vous écoute…';

  @override
  String get assistantVoiceLang => 'Langue de la dictée';

  @override
  String get assistantVoiceFr => 'Français';

  @override
  String get assistantVoiceAr => 'العربية (Tunisie)';

  @override
  String get assistantMicDeniedTitle => 'Micro refusé';

  @override
  String get assistantMicDenied =>
      'Pour dicter vos messages, autorisez le micro : Paramètres › Applications › RentCar › Autorisations › Micro. Vous pouvez toujours écrire votre message.';

  @override
  String get assistantVoiceUnavailable =>
      'La reconnaissance vocale n\'est pas disponible sur cet appareil.';

  @override
  String get assistantVoiceNoMatch => 'Je n\'ai rien entendu, réessayez.';

  @override
  String get assistantVoiceError =>
      'La dictée a échoué. Vérifiez votre connexion et réessayez.';

  @override
  String get assistantFeedbackUp => 'Réponse utile';

  @override
  String get assistantFeedbackDown => 'Réponse pas utile';

  @override
  String get assistantQuality => 'Qualité des réponses';

  @override
  String assistantQualityStats(int up, int down, int percent) {
    return '$up 👍 · $down 👎 — $percent % de réponses jugées utiles';
  }

  @override
  String get assistantQualityEmpty =>
      'Aucun avis pour le moment. Utilisez 👍 / 👎 sous les réponses de l\'assistant.';

  @override
  String get assistantQualityNote =>
      'Avis enregistrés sur ce téléphone, conservés même après une nouvelle conversation.';

  @override
  String get aiQuotaReached =>
      'Assistant IA temporairement indisponible (quota atteint), réessayez plus tard.';

  @override
  String get registerAccountType => 'Type de compte';

  @override
  String get registerRoleUser => 'Utilisateur';

  @override
  String get registerRoleCompany => 'Entreprise';

  @override
  String get themeTitle => 'Thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Auto';

  @override
  String get scanButton => 'Scanner mon permis';

  @override
  String get scanInProgress => 'Lecture du permis…';

  @override
  String get scanTip =>
      'Photographiez le recto du permis à plat, bien éclairé, sans reflet.';

  @override
  String get scanCamera => 'Prendre une photo';

  @override
  String get scanGallery => 'Choisir dans la galerie';

  @override
  String get scanNothing =>
      'Aucune information lisible sur la photo. Saisissez le numéro et la date manuellement, ou réessayez avec une photo plus nette.';

  @override
  String get scanOnlyNumber =>
      'Numéro trouvé. La date d\'expiration n\'a pas pu être lue : choisissez-la ci-dessous.';

  @override
  String get scanOnlyExpiry =>
      'Date d\'expiration trouvée. Le numéro n\'a pas pu être lu : saisissez-le ci-dessous.';

  @override
  String get scanComplete =>
      'Numéro et date pré-remplis. Vérifiez-les avant d\'enregistrer.';

  @override
  String scanExpired(String date) {
    return 'Ce permis a expiré le $date. Vous ne pourrez pas réserver tant qu\'il n\'est pas renouvelé.';
  }

  @override
  String get scanFilledHelper => 'Rempli par le scan — vérifiez';

  @override
  String get scanCameraDenied =>
      'Accès à la caméra refusé. Autorisez-le dans les paramètres ou choisissez une photo de la galerie.';

  @override
  String get scanFailed => 'Impossible de lire cette image. Réessayez.';

  @override
  String validatorRequired(String field) {
    return '$field est obligatoire';
  }

  @override
  String get validatorFieldDefault => 'Ce champ';

  @override
  String get validatorNameRequired => 'Le nom est obligatoire';

  @override
  String get validatorNameShort => 'Le nom est trop court';

  @override
  String get validatorNameLong => 'Le nom est trop long';

  @override
  String get validatorEmailRequired => 'L\'adresse e-mail est obligatoire';

  @override
  String get validatorEmailInvalid =>
      'Adresse e-mail invalide (ex. nom@mail.tn)';

  @override
  String get validatorPasswordRequired => 'Le mot de passe est obligatoire';

  @override
  String get validatorPasswordShort => 'Au moins 6 caractères requis';

  @override
  String get validatorPasswordLetter => 'Doit contenir au moins une lettre';

  @override
  String get validatorPasswordDigit => 'Doit contenir au moins un chiffre';

  @override
  String get validatorConfirmRequired => 'Veuillez confirmer';

  @override
  String get validatorPasswordMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get validatorPhoneRequired => 'Le numéro de téléphone est obligatoire';

  @override
  String get validatorPhoneInvalid =>
      'Numéro tunisien invalide (8 chiffres, ex. 22 345 678)';

  @override
  String get validatorCinRequired => 'Le numéro CIN est obligatoire';

  @override
  String get validatorCinInvalid => 'La CIN doit contenir 8 chiffres';

  @override
  String get validatorLicenceRequired => 'Le numéro de permis est obligatoire';

  @override
  String get validatorLicenceInvalid => 'Numéro de permis invalide';

  @override
  String get validatorCardRequired => 'Le numéro de carte est obligatoire';

  @override
  String get validatorCardInvalid => 'Le numéro doit contenir 16 chiffres';

  @override
  String get validatorExpiryRequired => 'La date d\'expiration est obligatoire';

  @override
  String get validatorExpiryFormat => 'Format attendu MM/AA';

  @override
  String get validatorMonthInvalid => 'Mois invalide';

  @override
  String get validatorCardExpired => 'Carte expirée';

  @override
  String get validatorCvvRequired => 'Le CVV est obligatoire';

  @override
  String get validatorCvvInvalid => 'CVV invalide';

  @override
  String get validatorAmountRequired => 'Le montant est obligatoire';

  @override
  String get validatorAmountInvalid => 'Montant invalide';

  @override
  String get validatorAmountPositive => 'Le montant doit être supérieur à 0';
}
