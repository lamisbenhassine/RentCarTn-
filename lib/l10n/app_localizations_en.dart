// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonEmail => 'Email address';

  @override
  String get commonEmailHint => 'name@example.tn';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonNewPassword => 'New password';

  @override
  String get commonConfirmPassword => 'Confirm password';

  @override
  String get commonPasswordHelper =>
      'At least 6 characters, letters and digits';

  @override
  String get commonPhone => 'Phone';

  @override
  String get commonFirstName => 'First name';

  @override
  String get commonLastName => 'Last name';

  @override
  String get commonLogin => 'Log in';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonCreateAccount => 'Create an account';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonOpenSettings => 'Open settings';

  @override
  String get commonSaveFailed => 'Could not save.';

  @override
  String get commonChangeFailed => 'Could not update.';

  @override
  String get commonNotProvided => 'Not provided';

  @override
  String get commonNotProvidedFem => 'Not provided';

  @override
  String get commonLocating => 'Locating…';

  @override
  String get commonAddressUnavailable => 'Address unavailable';

  @override
  String get commonPositionUnavailable => 'Location unavailable';

  @override
  String commonNearestAgency(String city, String km) {
    return 'Nearest agency: $city ($km km)';
  }

  @override
  String get commonEmailTaken => 'An account already exists with this email.';

  @override
  String get commonPhoneTaken => 'This phone number is already in use.';

  @override
  String get commonLanguage => 'Language';

  @override
  String get locationServiceDisabled =>
      'Location (GPS) is turned off on your device.';

  @override
  String get locationDenied => 'You denied access to your location.';

  @override
  String get locationDeniedForever =>
      'Location access is blocked. Allow it in the app settings.';

  @override
  String get locationTimeout =>
      'Location not found yet. Try again outdoors or choose your city.';

  @override
  String get locationUnknown => 'Unable to get your location.';

  @override
  String get authBrandTagline => 'Your mobility,\nour business.';

  @override
  String get authBrandDescription =>
      'Car rental, auctions and driving theory, all in one platform.';

  @override
  String get authStatCars => 'Vehicles';

  @override
  String get authStatCities => 'Cities';

  @override
  String get authStatRating => 'Average rating';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to manage your rentals and auctions.';

  @override
  String get loginNoAccountWithEmail => 'No account with this email';

  @override
  String get loginWrongPassword => 'Wrong password';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String loginRetryIn(int seconds) {
    return 'Try again in $seconds s';
  }

  @override
  String get loginNoAccountYet => 'No account yet?';

  @override
  String loginAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count attempts left',
      one: 'You have 1 attempt left',
    );
    return '$_temp0';
  }

  @override
  String get loginAccountNotFoundTitle => 'Account not found';

  @override
  String loginAccountNotFoundMessage(String attempts) {
    return 'No account is linked to this email address. Check the spelling or create an account. $attempts.';
  }

  @override
  String loginWrongPasswordMessage(String attempts) {
    return '$attempts before a 60-second lock. Forgot your password? Use the link above.';
  }

  @override
  String get loginLockedTitle => 'Login temporarily blocked';

  @override
  String loginLockedMessage(String time) {
    return 'Too many failed attempts. Try again in $time.';
  }

  @override
  String get loginVerifyEmailFirst =>
      'Verify your email address to access your account.';

  @override
  String loginWelcome(String name) {
    return 'Welcome $name!';
  }

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'A few details are all you need to book your first car.';

  @override
  String get registerStepIdentity => 'Identity';

  @override
  String get registerStepLocation => 'Location';

  @override
  String get registerStepSecurity => 'Security';

  @override
  String registerStepProgress(int current, int total, String title) {
    return 'Step $current of $total · $title';
  }

  @override
  String get registerUseLocationOrCity =>
      'Use your location or choose your city.';

  @override
  String get registerAcceptTermsRequired => 'You must accept the terms of use.';

  @override
  String get registerSuccess =>
      'Account created. Verify your email address to activate it.';

  @override
  String get registerFailed => 'Sign-up failed.';

  @override
  String get registerCreateMyAccount => 'Create my account';

  @override
  String get registerAlreadyRegistered => 'Already registered?';

  @override
  String get registerAgencyIntro =>
      'We pick the nearest RentCar agency for you.';

  @override
  String get registerUseMyLocation => 'Use my location';

  @override
  String get registerFarFromAgencies =>
      'You seem far from our agencies. Check the suggested city or choose it yourself.';

  @override
  String get registerChooseOtherCity => 'Choose another city';

  @override
  String get registerAgencyCity => 'Your agency city';

  @override
  String get registerPreferChooseCity => 'I\'d rather choose my city';

  @override
  String get registerAcceptTerms =>
      'I accept the general rental terms and the privacy policy.';

  @override
  String get registerSecurityNotice =>
      'Your account is stored on this device. The password is hashed (SHA-256) and never stored in plain text.';

  @override
  String get registerChooseCityBelow => 'Choose your city below.';

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthMedium => 'Fair';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthExcellent => 'Excellent';

  @override
  String get otpExpired => 'This code has expired. Request a new code.';

  @override
  String get otpTooManyAttempts =>
      'Too many wrong attempts. Request a new code.';

  @override
  String get otpIncomplete => 'Enter the 6 digits of the code.';

  @override
  String get otpRequestNew => 'Request a new code.';

  @override
  String otpWrongCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong code. You have $count attempts left.',
      one: 'Wrong code. You have 1 attempt left.',
    );
    return '$_temp0';
  }

  @override
  String get otpSendFailedNetwork =>
      'Couldn\'t send the email. Check your Internet connection and try again.';

  @override
  String otpSendFailedService(int code) {
    return 'The email service refused the request (error $code). Try again in a moment.';
  }

  @override
  String otpValidFor(String time) {
    return 'Valid for $time';
  }

  @override
  String otpAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts left',
      one: '1 attempt left',
    );
    return '$_temp0';
  }

  @override
  String get otpVerify => 'Verify code';

  @override
  String get otpSending => 'Sending…';

  @override
  String get otpResend => 'Resend code';

  @override
  String otpResendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get otpEmailNotSent => 'Email not sent';

  @override
  String get otpEmailSentTitle => 'Email sent';

  @override
  String otpEmailSentMessage(String destination) {
    return 'Check the inbox of $destination. The email may take a minute and land in spam.';
  }

  @override
  String get otpNewCodeSent => 'A new code has been sent.';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotSubtitle => 'Choose how to receive your verification code.';

  @override
  String get forgotCodeTitle => 'Enter the code';

  @override
  String forgotCodeSubtitleEmail(String destination) {
    return '6-digit code sent by email to $destination.';
  }

  @override
  String forgotCodeSubtitleSms(String destination) {
    return '6-digit code sent by SMS to $destination.';
  }

  @override
  String get forgotPasswordSubtitle =>
      'Choose a password you don\'t use anywhere else.';

  @override
  String get forgotSuccessTitle => 'Password changed';

  @override
  String get forgotSuccessSubtitle => 'You can now log in.';

  @override
  String get forgotChannelEmail => 'Email';

  @override
  String get forgotChannelSms => 'SMS';

  @override
  String get forgotAccountEmail => 'Account email address';

  @override
  String get forgotAccountPhone => 'Account phone number';

  @override
  String get forgotNoAccountEmail => 'No account is linked to this email.';

  @override
  String get forgotNoAccountPhone => 'No account is linked to this number.';

  @override
  String get forgotReceiveCode => 'Get the code';

  @override
  String get forgotSendingEmail => 'Sending the email…';

  @override
  String get forgotEmailNotice =>
      'A 6-digit code will be sent to the account\'s email address. Remember to check your spam folder.';

  @override
  String get forgotSmsNotice =>
      'Demo mode: no SMS is actually sent. The code will appear on the next screen.';

  @override
  String get forgotBackToLogin => 'Back to login';

  @override
  String get forgotSmsDemoTitle => 'SMS demo mode — your code';

  @override
  String get forgotSmsDemoFooter => '(In production, it would be sent by SMS.)';

  @override
  String get forgotChangeMethod => 'Change method';

  @override
  String get forgotSavePassword => 'Save password';

  @override
  String get forgotResetDone => 'Password reset';

  @override
  String get forgotResetDoneMessage =>
      'Your new password is securely saved. Use it to log in.';

  @override
  String forgotRedirectIn(int seconds) {
    return 'Redirecting to login in $seconds s…';
  }

  @override
  String get verifyTitle => 'Verify your email';

  @override
  String verifySubtitle(String email) {
    return 'Enter the 6-digit code sent to $email to activate your account.';
  }

  @override
  String get verifySendingCode => 'Sending the code…';

  @override
  String get verifyRetrySend => 'Try sending again';

  @override
  String get verifyChangeEmail => 'Change email address';

  @override
  String get verifySuccess => 'Email address verified. Welcome!';

  @override
  String get verifyNewEmailLabel => 'New email address';

  @override
  String get verifySameEmail => 'This is already your current address';

  @override
  String get verifySendCode => 'Send a code';

  @override
  String get profileTitle => 'My profile';

  @override
  String get profileLogoutTitle => 'Log out?';

  @override
  String get profileLogoutMessage =>
      'You will be taken back to the welcome screen. Demo session data (cart, auctions, progress) is kept until the app is closed.';

  @override
  String get profileStayLoggedIn => 'Stay logged in';

  @override
  String get profilePhotoRemoved => 'Photo removed.';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get profileGroupTrust => 'Trust and loyalty';

  @override
  String get profileGroupInfo => 'My information';

  @override
  String get profileGroupAccount => 'My account';

  @override
  String get profileGroupAuctions => 'Auctions';

  @override
  String get profileGroupLearning => 'Learning';

  @override
  String get profileGroupApp => 'App';

  @override
  String get profileEdit => 'Edit my profile';

  @override
  String get profileEditSubtitle => 'Photo, name, phone, licence, address';

  @override
  String get profileChangePassword => 'Change my password';

  @override
  String get profileChangePasswordSubtitle => 'Current then new password';

  @override
  String get profileReservations => 'My bookings';

  @override
  String profileRentalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rentals',
      one: '1 rental',
      zero: '0 rentals',
    );
    return '$_temp0';
  }

  @override
  String get profileCart => 'My cart';

  @override
  String get profileCartSubtitle => 'Vehicles waiting to be booked';

  @override
  String get profileMyAuctions => 'My auctions and bids';

  @override
  String profileMyAuctionsSubtitle(int ongoing, int won) {
    String _temp0 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won won',
      one: '1 won',
      zero: '0 won',
    );
    return '$ongoing ongoing · $_temp0';
  }

  @override
  String get profileMarketplace => 'Marketplace';

  @override
  String get profileMarketplaceSubtitle => 'Used vehicles at auction';

  @override
  String get profileFleet => 'Fleet management (demo)';

  @override
  String get profileFleetSubtitle => 'Sales dashboard';

  @override
  String get profileRoadCode => 'Driving theory';

  @override
  String profileProgress(int percent) {
    return 'Progress: $percent%';
  }

  @override
  String get profileQuizResults => 'My quiz results';

  @override
  String profileQuizCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quizzes taken',
      one: '1 quiz taken',
      zero: '0 quizzes taken',
    );
    return '$_temp0';
  }

  @override
  String get profileAbout => 'About';

  @override
  String get profileAboutSubtitle => 'RentCar Tunisia · demo version 1.0.0';

  @override
  String get profileAboutVersion => 'Demo 1.0.0';

  @override
  String get profileAboutText =>
      'Front-end app for car rental, used vehicle auctions and driving theory in Tunisia.\n\nAll data is simulated locally. No backend, no database, no real payment.';

  @override
  String get profileSupport => 'Support';

  @override
  String get profileSupportSubtitle =>
      'contact@rentcar.tn · +216 71 000 000 (fictitious)';

  @override
  String get profileSupportSnack =>
      'Fictitious contact details: no real service.';

  @override
  String get profileLogoutSubtitle => 'End the demo session';

  @override
  String profileAuctionAlias(String name) {
    return 'Auction alias: $name';
  }

  @override
  String get profileStatReservations => 'Bookings';

  @override
  String get profileStatAuctions => 'Auctions';

  @override
  String get profileStatCode => 'Theory';

  @override
  String get profileStatSpent => 'Spent';

  @override
  String get profileComplete => 'Profile complete ✓';

  @override
  String profileCompletion(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String profileCompletionMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
      one: '1 more',
    );
    return '$_temp0';
  }

  @override
  String get stepPhoto => 'Add a profile photo';

  @override
  String get stepPhone => 'Add your phone number';

  @override
  String get stepCin => 'Add your national ID (CIN) number';

  @override
  String get stepLicenceNumber => 'Add your driving licence';

  @override
  String get stepLicenceExpiry => 'Enter your licence expiry date';

  @override
  String get stepAddress => 'Add your address';

  @override
  String get stepPosition => 'Save your location';

  @override
  String get stepEmailVerified => 'Verify your email address';

  @override
  String get trustTitle => 'Trust score';

  @override
  String trustClient(String tier) {
    return '$tier customer';
  }

  @override
  String get tierBronze => 'Bronze';

  @override
  String get tierSilver => 'Silver';

  @override
  String get tierGold => 'Gold';

  @override
  String get trustGoldAdvantage => '10% off all your bookings';

  @override
  String trustToSilver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more completed rentals to reach Silver',
      one: '1 more completed rental to reach Silver',
    );
    return '$_temp0';
  }

  @override
  String trustToGold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more completed rentals to reach Gold (-10%)',
      one: '1 more completed rental to reach Gold (-10%)',
    );
    return '$_temp0';
  }

  @override
  String trustClean(int count) {
    return '$count without issues';
  }

  @override
  String trustLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count late returns',
      one: '1 late return',
      zero: '0 late returns',
    );
    return '$_temp0';
  }

  @override
  String trustComplaints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count complaints',
      one: '1 complaint',
      zero: '0 complaints',
    );
    return '$_temp0';
  }

  @override
  String get trustRules =>
      'Starts at 50 · +5 per rental without issues · -10 per late return · -15 per upheld complaint · -10 per abusive complaint.';

  @override
  String get profilePersonalInfo => 'Personal information';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileCin => 'National ID';

  @override
  String get profileBirth => 'Date of birth';

  @override
  String get profileAddress => 'Address';

  @override
  String get profileMemberSince => 'Member since';

  @override
  String get profileLicence => 'Driving licence';

  @override
  String get profileLicenceNumber => 'Number';

  @override
  String get profileLicenceExpiry => 'Expiry';

  @override
  String get licenceValid => 'Valid';

  @override
  String get licenceExpiringSoon => 'Expires soon';

  @override
  String get licenceExpired => 'Expired';

  @override
  String get profilePositionTitle => 'Location and agency';

  @override
  String get profileDefaultAgency => 'Default agency';

  @override
  String get profileCoordinates => 'Coordinates';

  @override
  String get profileUpdatePosition => 'Update my location';

  @override
  String get profileNewPosition => 'New location';

  @override
  String get profileUnchanged => 'unchanged';

  @override
  String get profileUseThisAddress => 'Also use this address';

  @override
  String profileDefaultAgencySet(String city) {
    return 'Default agency: $city.';
  }

  @override
  String get changePwdTitle => 'Change password';

  @override
  String get changePwdSubtitle =>
      'Enter your current password, then the new one.';

  @override
  String get changePwdCurrent => 'Current password';

  @override
  String get changePwdCurrentRequired => 'Current password is required';

  @override
  String get changePwdMustDiffer => 'Must be different from the current one';

  @override
  String get changePwdConfirm => 'Confirm new password';

  @override
  String get changePwdDone => 'Password changed.';

  @override
  String get changePwdWrongCurrent => 'Current password is incorrect.';

  @override
  String get avatarSheetTitle => 'Profile photo';

  @override
  String get avatarGallery => 'Photo gallery';

  @override
  String get avatarFiles => 'Files';

  @override
  String get avatarFilesSubtitle => 'Downloads, Drive…';

  @override
  String get avatarRemove => 'Remove photo';

  @override
  String get avatarOpenFailed => 'Couldn\'t open the image picker.';

  @override
  String get avatarUnreadable => 'Couldn\'t read the selected image.';

  @override
  String get avatarTooLarge => 'Image too large (1.5 MB max).';

  @override
  String get editSubtitle => 'Information used for your contracts';

  @override
  String get editPhotoSource => 'From your gallery or files';

  @override
  String get editAddPhoto => 'Add a photo';

  @override
  String get editChangePhoto => 'Change photo';

  @override
  String get editSectionIdentity => 'Identity';

  @override
  String get editBirthDate => 'Date of birth';

  @override
  String get editSectionContact => 'Contact details';

  @override
  String get editCity => 'City';

  @override
  String get editSectionDocuments => 'Driving documents';

  @override
  String get editCin => 'National ID (CIN) number';

  @override
  String get editCinHint => '8 digits';

  @override
  String get editLicenceNumber => 'Licence number';

  @override
  String get editLicenceExpiry => 'Licence expiry date';

  @override
  String get editLicenceExpired => 'This licence has expired';

  @override
  String get editSectionAuctions => 'Auctions';

  @override
  String get editAlias => 'Public alias';

  @override
  String get editAliasHelper => 'Shown to other auction participants';

  @override
  String get editAliasField => 'The alias';

  @override
  String get editSaveChanges => 'Save changes';

  @override
  String get editConfirmNewEmail => 'Confirm your new email address.';

  @override
  String get editSaved => 'Profile updated.';

  @override
  String get commonOr => 'or';

  @override
  String get googleContinue => 'Continue with Google';

  @override
  String get googleErrorNetwork =>
      'No Internet connection. Check your network and try again.';

  @override
  String get googleErrorConfig =>
      'Google sign-in is not configured for this app yet.';

  @override
  String get googleErrorUnsupported =>
      'Google sign-in isn\'t available on this device.';

  @override
  String get googleErrorUnknown => 'Google sign-in failed. Please try again.';

  @override
  String get googleErrorNoAccount =>
      'No Google account available on this phone. Add an account in Android settings, then try again.';

  @override
  String get googleErrorNotAllowed =>
      'This Google account isn\'t allowed yet (the app is in testing).';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get deleteTitle => 'Delete your account?';

  @override
  String get deleteIntro =>
      'This cannot be undone. The following will be deleted:';

  @override
  String get deleteItemProfile => 'Your profile and personal information';

  @override
  String get deleteItemPhoto => 'Your profile photo';

  @override
  String get deleteItemPrefs =>
      'Your preferences and the \"Remember me\" session';

  @override
  String get deleteItemHistory =>
      'Your history (trust score, profile completion)';

  @override
  String deleteBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You have $count ongoing or upcoming bookings. Complete or cancel them before deleting your account.',
      one: 'You have 1 ongoing or upcoming booking. Complete or cancel it before deleting your account.',
    );
    return '$_temp0';
  }

  @override
  String get deleteSeeReservations => 'See my bookings';

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String deleteGoogleHint(String word) {
    return 'Google account without a password: type $word to confirm.';
  }

  @override
  String deleteTypeLabel(String word) {
    return 'Type $word';
  }

  @override
  String deleteWordMismatch(String word) {
    return 'Type exactly $word';
  }

  @override
  String get deleteConfirm => 'Delete permanently';

  @override
  String get deleteDone => 'Account deleted';

  @override
  String get deleteFailed => 'Deletion failed. Please try again.';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersLicence => 'Licence expiry';

  @override
  String get remindersLicenceSub => '30 days and 7 days before';

  @override
  String get remindersReservation => 'Bookings';

  @override
  String get remindersReservationSub =>
      'The day before pick-up and on return day';

  @override
  String get remindersProfile => 'Incomplete profile';

  @override
  String get remindersProfileSub => '2 days after sign-up';

  @override
  String get remindersDenied =>
      'Notifications are turned off for RentCar. The app works normally, but without reminders.';

  @override
  String get remindersAllow => 'Allow notifications';

  @override
  String get remindersUnsupported => 'Reminders are only available on Android.';

  @override
  String get remindersTest => 'Test a notification in 10 s';

  @override
  String get remindersTestScheduled => 'Test notification in 10 seconds…';

  @override
  String get notifChannelName => 'RentCar reminders';

  @override
  String get notifChannelDesc => 'Licence, bookings and profile';

  @override
  String get notifLicenceTitle => 'Your licence expires soon';

  @override
  String notifLicence30Body(String date) {
    return 'Your driving licence expires on $date (in 30 days). Remember to renew it.';
  }

  @override
  String notifLicence7Body(String date) {
    return 'Only 7 days left: your licence expires on $date. Update your profile after renewing it.';
  }

  @override
  String get notifResaStartTitle => 'Your rental starts tomorrow';

  @override
  String notifResaStartBody(String car, String time, String city) {
    return '$car is waiting for you tomorrow at $time in $city. Don\'t forget your licence and ID.';
  }

  @override
  String get notifResaReturnTitle => 'Vehicle return today';

  @override
  String notifResaReturnBody(String car, String time, String city) {
    return 'Return $car today before $time in $city.';
  }

  @override
  String get notifProfileTitle => 'Complete your profile';

  @override
  String notifProfileBody(int percent) {
    return 'Your profile is $percent% complete. Add the missing details to book faster.';
  }

  @override
  String get notifTestTitle => 'RentCar test';

  @override
  String get notifTestBody => 'Reminders work. Tap to open your profile.';

  @override
  String get complaintReport => 'Report a problem';

  @override
  String get complaintReportSub => 'Breakdown, cleanliness, billing, auction…';

  @override
  String get complaintNewTitle => 'New complaint';

  @override
  String get complaintEditTitle => 'Edit complaint';

  @override
  String get complaintFormSubtitle =>
      'Describe the problem: the agency will get back to you quickly.';

  @override
  String get complaintCategoryLabel => 'Category';

  @override
  String get complaintCategoryRequired => 'Choose a category.';

  @override
  String get complaintCatPanne => 'Breakdown';

  @override
  String get complaintCatProprete => 'Cleanliness';

  @override
  String get complaintCatRetardAgence => 'Agency delay';

  @override
  String get complaintCatFacturation => 'Billing';

  @override
  String get complaintCatEnchere => 'Auction';

  @override
  String get complaintCatAutre => 'Other';

  @override
  String get complaintStatusEnAttente => 'Pending';

  @override
  String get complaintStatusEnCours => 'In progress';

  @override
  String get complaintStatusResolue => 'Resolved';

  @override
  String get complaintStatusRejetee => 'Rejected';

  @override
  String get complaintPriorityBasse => 'Low';

  @override
  String get complaintPriorityMoyenne => 'Medium';

  @override
  String get complaintPriorityUrgente => 'Urgent';

  @override
  String get complaintLinkLabel => 'Related to';

  @override
  String get complaintLinkNone => 'None';

  @override
  String get complaintLinkReservation => 'Booking';

  @override
  String get complaintLinkAuction => 'Auction';

  @override
  String get complaintNoReservation =>
      'You have no booking to link. Choose \"None\".';

  @override
  String get complaintNoAuction =>
      'You haven\'t taken part in any auction. Choose \"None\".';

  @override
  String get complaintPickReservation => 'Choose the booking concerned.';

  @override
  String get complaintPickAuction => 'Choose the auction concerned.';

  @override
  String complaintAutoFilled(String car, String agency) {
    return 'Car: $car · Agency: $agency';
  }

  @override
  String get complaintTitleLabel => 'Title';

  @override
  String get complaintTitleHint => 'E.g. Air conditioning not working';

  @override
  String get complaintTitleLength =>
      'The title must be 5 to 80 characters long.';

  @override
  String get complaintDescLabel => 'Description';

  @override
  String get complaintDescHint => 'What happened? Where and when?';

  @override
  String get complaintDescLength =>
      'The description must be 20 to 1000 characters long.';

  @override
  String get complaintSubmit => 'Send complaint';

  @override
  String get complaintSaveFailed =>
      'Couldn\'t save the complaint. Check and try again.';

  @override
  String get complaintSentTitle => 'Complaint sent';

  @override
  String get complaintSentMessage =>
      'Keep this reference: it lets you follow up on your complaint with the agency.';

  @override
  String get complaintReferenceLabel => 'Reference';

  @override
  String get complaintDone => 'Done';

  @override
  String get complaintUpdated => 'Complaint updated.';

  @override
  String get complaintLoginRequired => 'Log in to report a problem.';

  @override
  String get complaintNotEditable =>
      'This complaint is already being handled: it can no longer be edited.';

  @override
  String get complaintNotFound => 'Complaint not found.';

  @override
  String get myComplaintsTitle => 'My complaints';

  @override
  String myComplaintsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count complaints',
      one: '1 complaint',
      zero: 'No complaints',
    );
    return '$_temp0';
  }

  @override
  String get complaintsFilterAll => 'All';

  @override
  String get complaintsSearchHint => 'Search by title or reference';

  @override
  String get complaintsEmptyTitle => 'No complaints';

  @override
  String get complaintsEmptyMessage =>
      'A problem with a rental or an auction? Report it: the agency will get back to you.';

  @override
  String get complaintsNoMatch => 'No complaint matches your search.';

  @override
  String get complaintsClearFilters => 'Clear filters';

  @override
  String get complaintsLoadError => 'Couldn\'t load your complaints.';

  @override
  String get complaintsRetry => 'Retry';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get complaintDetailsTitle => 'Complaint details';

  @override
  String get complaintFieldCategory => 'Category';

  @override
  String get complaintFieldPriority => 'Priority';

  @override
  String get complaintFieldStatus => 'Status';

  @override
  String get complaintFieldCar => 'Car';

  @override
  String get complaintCarLabel => 'Vehicle concerned';

  @override
  String get complaintCarRequiredHint =>
      'Required for a breakdown or a cleanliness issue';

  @override
  String get complaintCarOptionalHint => 'Optional';

  @override
  String get complaintCarPick => 'Choose the vehicle';

  @override
  String get complaintCarRequired => 'Choose the vehicle concerned.';

  @override
  String get complaintCarFromReservation => 'Car from the linked booking';

  @override
  String get complaintCarSearch => 'Search: brand, model, city';

  @override
  String get complaintCarEmpty => 'No vehicle in the catalogue';

  @override
  String complaintCarNoMatch(String query) {
    return 'No vehicle matches \"$query\"';
  }

  @override
  String get complaintCarLoadError => 'Unable to load the vehicles.';

  @override
  String get complaintCarRetry => 'Retry';

  @override
  String get complaintCarRemoved => 'Vehicle removed from the catalogue';

  @override
  String get complaintCarOpen => 'View the vehicle page';

  @override
  String get assistantPickCar =>
      'Choose the vehicle concerned before sending the complaint.';

  @override
  String complaintEventBy(String name) {
    return 'by $name';
  }

  @override
  String complaintNotifResponseTitle(String reference) {
    return 'New reply · $reference';
  }

  @override
  String complaintNotifResponseBody(String reference) {
    return 'The agency replied to your complaint $reference.';
  }

  @override
  String get adminComplaintsTitle => 'Customer complaints';

  @override
  String adminComplaintsMenuSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting to be handled',
      one: '1 waiting to be handled',
      zero: 'None pending',
    );
    return '$_temp0';
  }

  @override
  String get adminStatAvgTime => 'Average handling time';

  @override
  String get adminStatAvgRating => 'Average satisfaction';

  @override
  String adminStatRating(String avg, int count) {
    return '$avg/5 · $count reviews';
  }

  @override
  String adminDurationDays(int days, int hours) {
    return '$days d $hours h';
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
  String get adminSearchHint => 'Reference, customer or vehicle';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterAllPriorities => 'All priorities';

  @override
  String get adminFilterAllCategories => 'All categories';

  @override
  String get adminEmptyTitle => 'No complaints';

  @override
  String get adminEmptyMessage => 'Customer complaints will appear here.';

  @override
  String get adminNoMatch => 'No complaint matches the filters.';

  @override
  String get adminClearFilters => 'Clear filters';

  @override
  String get adminRetry => 'Retry';

  @override
  String get adminDetailsTitle => 'Handling';

  @override
  String get adminClientSection => 'Customer';

  @override
  String get adminClientDeleted => 'Deleted account';

  @override
  String adminClientTrust(int score) {
    return 'Trust score: $score/100';
  }

  @override
  String adminClientRejected(int rejected, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      rejected,
      locale: localeName,
      other: '$rejected rejected complaints',
      one: '1 rejected complaint',
      zero: 'No rejected complaint',
    );
    return '$_temp0 out of $total';
  }

  @override
  String adminHandledBy(String name) {
    return 'Handled by $name';
  }

  @override
  String get adminActionsTitle => 'Actions';

  @override
  String get adminClosedNotice =>
      'Closed case: no action available. The customer can reopen it if unsatisfied.';

  @override
  String get adminTake => 'Take charge';

  @override
  String adminTakeConfirm(String reference) {
    return 'Take charge of $reference? The customer will be notified.';
  }

  @override
  String get adminRespond => 'Reply';

  @override
  String get adminResolve => 'Resolve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminRejectAbusive => 'Reject as abusive';

  @override
  String get adminRespondTitle => 'Reply to the customer';

  @override
  String get adminResolveTitle => 'Resolve the complaint';

  @override
  String get adminRejectTitle => 'Reject the complaint';

  @override
  String get adminMessageHint => 'Your message to the customer';

  @override
  String get adminMessageRequired =>
      'Write a message of at least 10 characters.';

  @override
  String get adminAbusiveWarning =>
      'The customer\'s trust score will drop by 10 points. This action is final.';

  @override
  String get adminAbusiveCheck => 'I confirm this complaint is abusive';

  @override
  String get adminSend => 'Send';

  @override
  String get adminConfirm => 'Confirm';

  @override
  String adminActionDone(String reference, String status) {
    return '$reference: $status';
  }

  @override
  String get adminResponseSent => 'Reply saved and sent to the customer.';

  @override
  String get adminActionFailed => 'Action failed. Please try again.';

  @override
  String get adminBanTitle => 'Ban this customer?';

  @override
  String adminBanMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rejected complaints',
      one: '1 rejected complaint',
    );
    return '$name now has $_temp0.';
  }

  @override
  String get adminBanLater => 'Later';

  @override
  String get adminBan => 'Ban';

  @override
  String get adminBanSoon => 'Banning will be available in the next step.';

  @override
  String durationMinSec(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get suspendedTitle => 'Account suspended';

  @override
  String suspendedUntil(String date) {
    return 'Your account is suspended until $date.';
  }

  @override
  String get suspendedPermanent => 'Your account is permanently suspended.';

  @override
  String get suspendedRemaining => 'Time remaining';

  @override
  String get suspendedReason => 'Reason';

  @override
  String get suspendedOver => 'Your suspension is over: you can sign in again.';

  @override
  String get suspendedContact => 'Contact support';

  @override
  String get suspendedCallAgency => 'Call the agency';

  @override
  String get suspendedBack => 'Back to sign in';

  @override
  String suspendedMailSubject(String email) {
    return 'Suspended account: $email';
  }

  @override
  String suspendedMailFailed(String email) {
    return 'No email app found. Write to $email.';
  }

  @override
  String get adminUsersTitle => 'Users';

  @override
  String adminUsersMenuSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suspended accounts',
      one: '1 suspended account',
      zero: 'No suspended account',
    );
    return '$_temp0';
  }

  @override
  String get adminUsersSearch => 'Name, email or phone';

  @override
  String get adminUsersFilterAll => 'All';

  @override
  String get adminUsersFilterBanned => 'Banned';

  @override
  String get adminUsersFilterActive => 'Active';

  @override
  String get adminUsersEmpty => 'No user matches.';

  @override
  String get adminRoleAdmin => 'Admin';

  @override
  String adminUserAbusive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abusive complaints',
      one: '1 abusive complaint',
      zero: 'No abusive complaint',
    );
    return '$_temp0';
  }

  @override
  String adminUserMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get adminUserBan => 'Ban';

  @override
  String get adminUserUnban => 'Unban';

  @override
  String adminUserUnbanConfirm(String name) {
    return 'Reactivate $name\'s account? They can sign in again immediately.';
  }

  @override
  String get adminUserIsAdmin => 'An administrator account cannot be banned.';

  @override
  String get adminUserIsSelf => 'You cannot ban yourself.';

  @override
  String banBadgeUntil(String date) {
    return 'Banned until $date';
  }

  @override
  String get banBadgePermanent => 'Permanently banned';

  @override
  String get banCurrentTitle => 'Current suspension';

  @override
  String banCurrentBy(String name) {
    return 'By $name';
  }

  @override
  String get banHistoryTitle => 'Ban history';

  @override
  String get banHistoryEmpty => 'No ban.';

  @override
  String get banHistoryActive => 'Active';

  @override
  String get banHistoryPermanent => 'Permanent';

  @override
  String banHistoryPeriod(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String banHistorySince(String start) {
    return 'Since $start';
  }

  @override
  String banHistoryLifted(String date, String name) {
    return 'Lifted on $date · $name';
  }

  @override
  String get banHistoryAuto => 'Automatic';

  @override
  String banHistoryComplaint(String reference) {
    return 'Complaint $reference';
  }

  @override
  String banDialogTitle(String name) {
    return 'Ban $name';
  }

  @override
  String get banDuration => 'Duration';

  @override
  String get ban24h => '24 h';

  @override
  String get ban3d => '3 days';

  @override
  String get ban7d => '7 days';

  @override
  String get ban30d => '30 days';

  @override
  String get banCustom => 'Custom';

  @override
  String get banPermanent => 'Permanent';

  @override
  String get banPickDate => 'Choose the end date and time';

  @override
  String banEnd(String date) {
    return 'Ends: $date';
  }

  @override
  String get banEndRequired => 'Choose an end date in the future.';

  @override
  String get banReasonLabel => 'Reason (required)';

  @override
  String get banReasonHint => 'Shown to the customer and sent by email';

  @override
  String get banReasonRequired => 'Enter the reason for the ban.';

  @override
  String banFalseComplaint(String reference) {
    return 'False complaint $reference';
  }

  @override
  String get banSummaryTitle => 'Summary';

  @override
  String banSummaryUntil(String name, String date, String duration) {
    return '$name will be suspended until $date ($duration).';
  }

  @override
  String banSummaryPermanent(String name) {
    return '$name will be permanently suspended.';
  }

  @override
  String banSummaryReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get banSummaryEffects =>
      'They will be signed out and unable to sign in (email or Google). An email will be sent to them.';

  @override
  String get banNext => 'Continue';

  @override
  String get banEdit => 'Edit';

  @override
  String get banConfirm => 'Confirm the ban';

  @override
  String banDone(String name) {
    return '$name is banned.';
  }

  @override
  String unbanDone(String name) {
    return '$name is reactivated.';
  }

  @override
  String get banMailSent => 'Email sent to the customer.';

  @override
  String get banMailFailed => 'The email to the customer could not be sent.';

  @override
  String get banFailed => 'Ban failed. Please try again.';

  @override
  String get navMenu => 'Menu';

  @override
  String get navMyActivity => 'My activity';

  @override
  String get navAdministration => 'Administration';

  @override
  String get complaintFieldAgency => 'Agency';

  @override
  String get complaintFieldSent => 'Sent on';

  @override
  String get complaintFieldUpdated => 'Updated';

  @override
  String get complaintLinkedReservation => 'Linked booking';

  @override
  String get complaintLinkedAuction => 'Linked auction';

  @override
  String get complaintLinkedMissing => 'Linked item not found (deleted?)';

  @override
  String get complaintPhotos => 'Photos';

  @override
  String get complaintLocation => 'Reported location';

  @override
  String get complaintHistory => 'Tracking';

  @override
  String get complaintAgencyResponse => 'Agency response';

  @override
  String get complaintWaitingResponse =>
      'The agency hasn\'t replied yet. You\'ll be informed as soon as your complaint has been handled.';

  @override
  String get complaintEdit => 'Edit';

  @override
  String get complaintCancel => 'Cancel';

  @override
  String get complaintCancelTitle => 'Cancel this complaint?';

  @override
  String get complaintCancelMessage =>
      'It will be permanently deleted. This cannot be undone.';

  @override
  String get complaintCancelConfirm => 'Yes, cancel';

  @override
  String get complaintKeep => 'Keep';

  @override
  String get complaintCancelled => 'Complaint cancelled.';

  @override
  String get complaintCopied => 'Reference copied.';

  @override
  String get complaintDemoSimulate => 'Simulate the agency\'s response (demo)';

  @override
  String get complaintDemoNote =>
      'Demo mode: there is no back office yet. Simulate the agency\'s handling here.';

  @override
  String get complaintDemoTake => 'Take charge';

  @override
  String get complaintDemoResolve => 'Resolve';

  @override
  String get complaintDemoReject => 'Reject';

  @override
  String complaintDemoDone(String status) {
    return 'New status: $status';
  }

  @override
  String get complaintPhotosTitle => 'Photos (evidence)';

  @override
  String get complaintPhotosHint =>
      'Up to 4 photos: damage, dirt, receipt, odometer…';

  @override
  String get complaintPhotoAdd => 'Add';

  @override
  String get complaintPhotoRemove => 'Remove photo';

  @override
  String get complaintPhotoMax => '4 photos maximum.';

  @override
  String get complaintPhotoFailed =>
      'Couldn\'t add this photo. Please try again.';

  @override
  String complaintPhotoCounter(int index, int total) {
    return '$index / $total';
  }

  @override
  String get complaintAttachLocation => 'Attach my location';

  @override
  String get complaintAttachLocationSub =>
      'Helps the agency find you (on for breakdowns).';

  @override
  String get complaintLocationNoAddress =>
      'GPS location attached (address not found)';

  @override
  String get complaintLocationOff =>
      'Location unavailable: the complaint will be sent without it.';

  @override
  String get complaintOpenMaps => 'Open in Maps';

  @override
  String get complaintMapsFailed => 'Couldn\'t open Maps.';

  @override
  String get urgentButton => 'Urgent breakdown';

  @override
  String get urgentButtonSub =>
      'Fast help: your location and ongoing booking are sent';

  @override
  String get urgentSheetTitle => 'Report an urgent breakdown';

  @override
  String get urgentSheetIntro => 'We immediately send the agency:';

  @override
  String urgentWithReservation(String car, String reference) {
    return 'Ongoing booking: $car ($reference)';
  }

  @override
  String get urgentNoReservation =>
      'No ongoing booking: the alert will be sent without a linked booking.';

  @override
  String get urgentLocating => 'Finding your location…';

  @override
  String urgentLocationOk(String address) {
    return 'Location: $address';
  }

  @override
  String get urgentLocationFailed =>
      'Location unavailable: the alert will be sent without it.';

  @override
  String get urgentSend => 'Send alert';

  @override
  String urgentTitle(String car) {
    return 'Urgent breakdown — $car';
  }

  @override
  String get urgentTitleNoCar => 'Urgent breakdown';

  @override
  String get urgentDescription =>
      'Breakdown reported with the app\'s emergency button. I need help quickly.';

  @override
  String get urgentFailed =>
      'Couldn\'t send the alert. Call the agency directly.';

  @override
  String get urgentSentTitle => 'Alert sent';

  @override
  String get urgentSentMessage =>
      'The agency has received your breakdown alert. Call them if you need help right away.';

  @override
  String get urgentCallAgency => 'Call the agency';

  @override
  String urgentCallFailed(String number) {
    return 'Couldn\'t start the call. Dial $number.';
  }

  @override
  String get urgentSafetyTitle => 'Your safety first';

  @override
  String get urgentTip1 =>
      'Turn on your hazard lights and pull over to the roadside if you can.';

  @override
  String get urgentTip2 =>
      'Put on the safety vest before getting out of the car.';

  @override
  String get urgentTip3 =>
      'Place the warning triangle about 30 m behind the car.';

  @override
  String get urgentTip4 =>
      'Wait in a safe place behind the guardrail, away from traffic.';

  @override
  String get urgentTip5 =>
      'Danger or injury: call 190 (ambulance), 197 (police) or 198 (civil protection).';

  @override
  String get urgentSeeComplaint => 'View complaint';

  @override
  String get complaintPriorityLabel => 'Priority';

  @override
  String get aiAnalyze => 'Analyse with AI';

  @override
  String get aiAnalyzing => 'AI analysis in progress…';

  @override
  String get aiSuggestionTitle => 'AI suggestion';

  @override
  String get aiSuggestionCategory => 'Suggested category';

  @override
  String get aiSuggestionPriority => 'Suggested priority';

  @override
  String get aiToneLabel => 'Detected tone';

  @override
  String get aiToneCalme => 'Calm';

  @override
  String get aiToneMecontent => 'Unhappy';

  @override
  String get aiToneTresMecontent => 'Very unhappy';

  @override
  String get aiPriorityRaised =>
      'Priority raised one level: very unhappy customer.';

  @override
  String get aiAccept => 'Accept';

  @override
  String get aiKeep => 'Keep my choice';

  @override
  String get aiApplied => 'Suggestion applied';

  @override
  String get aiKept => 'You kept your choice';

  @override
  String get aiDisclaimer =>
      'Automatic suggestion (Gemini): you have the final say.';

  @override
  String get aiAnalysisTitle => 'AI analysis';

  @override
  String get aiSummaryLabel => 'Summary';

  @override
  String get aiImprove => 'Improve my message';

  @override
  String get aiImproving => 'Rewriting…';

  @override
  String get aiImproveTitle => 'Message improved by AI';

  @override
  String get aiImproveHint =>
      'Same content, written more clearly. Check that no detail has changed.';

  @override
  String get aiBefore => 'Before';

  @override
  String get aiAfter => 'After';

  @override
  String get aiUseImproved => 'Use this text';

  @override
  String get aiKeepMine => 'Keep my text';

  @override
  String get aiImproveApplied => 'Message replaced';

  @override
  String get aiImproveSame => 'Your message is already clear.';

  @override
  String get aiImproveFailed => 'Rewriting is unavailable right now.';

  @override
  String get quickFixChecking => 'Looking for quick fixes…';

  @override
  String get quickFixTitle => 'Before sending, have you tried?';

  @override
  String get quickFixSubtitle => 'Quick fixes suggested by AI:';

  @override
  String get quickFixResolved => 'Problem solved';

  @override
  String get quickFixSendAnyway => 'Send anyway';

  @override
  String get quickFixResolvedMsg => 'Great! No complaint was sent.';

  @override
  String get complaintMailSending => 'Sending confirmation email…';

  @override
  String complaintMailSent(String email) {
    return 'Confirmation sent to $email';
  }

  @override
  String complaintMailStatusSent(String email) {
    return 'Update email sent to $email';
  }

  @override
  String get complaintMailFailed => 'The confirmation email could not be sent.';

  @override
  String get complaintNotifChannel => 'Complaints';

  @override
  String get complaintNotifChannelDesc =>
      'Follow your complaints: status changes and urgent alerts.';

  @override
  String complaintNotifStatusTitle(String reference) {
    return 'Complaint $reference';
  }

  @override
  String complaintNotifStatusBody(String reference, String status) {
    return 'Your complaint $reference is now $status.';
  }

  @override
  String get complaintNotifUrgentTitle => 'Urgent alert sent';

  @override
  String complaintNotifUrgentBody(String reference) {
    return '$reference: the agency has been notified and will contact you. Stay safe.';
  }

  @override
  String get complaintNotifOff =>
      'Notifications are off: you won\'t be alerted when a complaint changes status. Updates remain visible here.';

  @override
  String get complaintNotifEnable => 'Enable';

  @override
  String get complaintUnreadLabel => 'New';

  @override
  String get complaintDemoDelayed => 'Delayed response (10 s)';

  @override
  String get complaintDemoDelayedSub =>
      'Leave the screen or the app to receive the notification.';

  @override
  String get complaintDemoScheduled => 'The agency will respond in 10 s.';

  @override
  String get ratingTitle => 'Are you satisfied with the resolution?';

  @override
  String get ratingSubtitle => 'Your feedback helps the agency improve.';

  @override
  String get ratingLabel1 => 'Very dissatisfied';

  @override
  String get ratingLabel2 => 'Dissatisfied';

  @override
  String get ratingLabel3 => 'Okay';

  @override
  String get ratingLabel4 => 'Satisfied';

  @override
  String get ratingLabel5 => 'Very satisfied';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get ratingCommentHint => 'Any comment? (optional)';

  @override
  String get ratingSubmit => 'Send my feedback';

  @override
  String get ratingThanks => 'Thank you for your feedback';

  @override
  String get ratingYourComment => 'Your comment';

  @override
  String get ratingReopenPrompt =>
      'Not satisfied? Reopen the complaint: the agency will handle it again.';

  @override
  String get ratingReopen => 'Reopen the complaint';

  @override
  String get ratingReopenTitle => 'Reopen the complaint?';

  @override
  String ratingReopenMessage(String reference) {
    return '$reference will go back to \"Pending\" and the agency will handle your request again.';
  }

  @override
  String get ratingReopened => 'Complaint reopened';

  @override
  String get ratingAverage => 'Average rating';

  @override
  String ratingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String trustAbusive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abusive complaints',
      one: '1 abusive complaint',
      zero: '0 abusive complaints',
    );
    return '$_temp0';
  }

  @override
  String get complaintStatsTitle => 'My complaints';

  @override
  String get complaintStatsTotal => 'Sent';

  @override
  String get complaintStatsResolved => 'Resolved';

  @override
  String get complaintStatsAvgGiven => 'Average rating given';

  @override
  String get complaintStatsNoRating => '—';

  @override
  String complaintRejectionWarning(int count) {
    return '$count of your complaints were rejected in the last 30 days. Check your request before sending it: a complaint rejected as abusive removes 10 points from your trust score.';
  }

  @override
  String get complaintRejectionWarningTitle => 'Warning';

  @override
  String get complaintDemoRejectAbusive => 'Reject as abusive (-10 trust)';

  @override
  String get complaintAbusiveBadge => 'Abusive';

  @override
  String get assistantTitle => 'RentCar Assistant';

  @override
  String get assistantSubtitle => 'Français · English · عربي · derja';

  @override
  String get assistantTyping => 'typing…';

  @override
  String assistantWelcome(String name) {
    return 'Hi $name 👋 I\'m the RentCar assistant. Breakdown, booking, complaint, licence or agency: how can I help you?';
  }

  @override
  String get assistantWelcomeGuest =>
      'Hi 👋 I\'m the RentCar assistant. Breakdown, booking, complaint, licence or agency: how can I help you?';

  @override
  String get assistantHint => 'Type your message…';

  @override
  String get assistantSend => 'Send';

  @override
  String get assistantChipBreakdown => 'Breakdown';

  @override
  String get assistantChipBreakdownMsg =>
      'My car has broken down, what should I do?';

  @override
  String get assistantChipReservation => 'My booking';

  @override
  String get assistantChipReservationMsg =>
      'What is the status of my current booking?';

  @override
  String get assistantChipComplaint => 'Track a complaint';

  @override
  String get assistantChipComplaintMsg =>
      'What is the status of my complaints?';

  @override
  String get assistantNewConversation => 'New conversation';

  @override
  String get assistantNewConversationConfirm =>
      'Clear this conversation and start a new one?';

  @override
  String get assistantClear => 'Clear';

  @override
  String get assistantOffline =>
      'No internet connection. Check your network and try again, or file a complaint: it will be saved in the app.';

  @override
  String get assistantUnavailable =>
      'The assistant is temporarily unavailable. Try again in a moment or file a regular complaint.';

  @override
  String get assistantActionComplaint => 'File a complaint';

  @override
  String get assistantActionBreakdown => 'Urgent breakdown';

  @override
  String get assistantActionReservations => 'My bookings';

  @override
  String get assistantActionComplaints => 'My complaints';

  @override
  String get assistantDisclaimer =>
      'AI-generated answers (Gemini): check important information with the agency.';

  @override
  String get assistantDraftIntro =>
      'I\'ve prepared this summary. Check it and confirm: nothing is sent without your approval.';

  @override
  String get assistantDraftTitle => 'Proposed complaint';

  @override
  String get assistantDraftReservation => 'Booking';

  @override
  String get assistantDraftConfirm => 'Confirm';

  @override
  String get assistantDraftEdit => 'Edit';

  @override
  String get assistantDraftConfirmed => 'Confirmed and sent';

  @override
  String get assistantDraftEdited => 'Opened in the form';

  @override
  String get assistantDraftNotice => 'Nothing is created until you confirm.';

  @override
  String assistantComplaintCreated(String reference) {
    return 'Complaint $reference created ✓ You will receive a confirmation email and a notification at each status change.';
  }

  @override
  String get assistantActionViewComplaint => 'View details';

  @override
  String get assistantActionCallAgency => 'Call the agency';

  @override
  String get assistantMic => 'Dictate a message';

  @override
  String get assistantStopListening => 'Stop dictation';

  @override
  String get assistantListening => 'Listening…';

  @override
  String get assistantVoiceLang => 'Dictation language';

  @override
  String get assistantVoiceFr => 'Français';

  @override
  String get assistantVoiceAr => 'العربية (Tunisie)';

  @override
  String get assistantMicDeniedTitle => 'Microphone denied';

  @override
  String get assistantMicDenied =>
      'To dictate messages, allow the microphone: Settings › Apps › RentCar › Permissions › Microphone. You can still type your message.';

  @override
  String get assistantVoiceUnavailable =>
      'Speech recognition is not available on this device.';

  @override
  String get assistantVoiceNoMatch =>
      'I didn\'t hear anything, please try again.';

  @override
  String get assistantVoiceError =>
      'Dictation failed. Check your connection and try again.';

  @override
  String get assistantFeedbackUp => 'Helpful answer';

  @override
  String get assistantFeedbackDown => 'Not helpful';

  @override
  String get assistantQuality => 'Answer quality';

  @override
  String assistantQualityStats(int up, int down, int percent) {
    return '$up 👍 · $down 👎 — $percent% of answers rated helpful';
  }

  @override
  String get assistantQualityEmpty =>
      'No feedback yet. Use 👍 / 👎 under the assistant\'s answers.';

  @override
  String get assistantQualityNote =>
      'Feedback is stored on this phone and kept after a new conversation.';

  @override
  String get aiQuotaReached =>
      'AI assistant temporarily unavailable (quota reached), please try again later.';

  @override
  String get registerAccountType => 'Account type';

  @override
  String get registerRoleUser => 'Individual';

  @override
  String get registerRoleCompany => 'Company';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'Auto';

  @override
  String get scanButton => 'Scan my licence';

  @override
  String get scanInProgress => 'Reading the licence…';

  @override
  String get scanTip =>
      'Photograph the front of the licence flat, in good light, without glare.';

  @override
  String get scanCamera => 'Take a photo';

  @override
  String get scanGallery => 'Choose from gallery';

  @override
  String get scanNothing =>
      'No readable information on the photo. Enter the number and date manually, or try again with a sharper photo.';

  @override
  String get scanOnlyNumber =>
      'Number found. The expiry date couldn\'t be read: pick it below.';

  @override
  String get scanOnlyExpiry =>
      'Expiry date found. The number couldn\'t be read: enter it below.';

  @override
  String get scanComplete =>
      'Number and date filled in. Check them before saving.';

  @override
  String scanExpired(String date) {
    return 'This licence expired on $date. You won\'t be able to book until it is renewed.';
  }

  @override
  String get scanFilledHelper => 'Filled in by the scan — please check';

  @override
  String get scanCameraDenied =>
      'Camera access denied. Allow it in settings or choose a photo from the gallery.';

  @override
  String get scanFailed => 'Couldn\'t read this image. Please try again.';

  @override
  String validatorRequired(String field) {
    return '$field is required';
  }

  @override
  String get validatorFieldDefault => 'This field';

  @override
  String get validatorNameRequired => 'Name is required';

  @override
  String get validatorNameShort => 'Name is too short';

  @override
  String get validatorNameLong => 'Name is too long';

  @override
  String get validatorEmailRequired => 'Email address is required';

  @override
  String get validatorEmailInvalid =>
      'Invalid email address (e.g. name@mail.tn)';

  @override
  String get validatorPasswordRequired => 'Password is required';

  @override
  String get validatorPasswordShort => 'At least 6 characters required';

  @override
  String get validatorPasswordLetter => 'Must contain at least one letter';

  @override
  String get validatorPasswordDigit => 'Must contain at least one digit';

  @override
  String get validatorConfirmRequired => 'Please confirm';

  @override
  String get validatorPasswordMismatch => 'Passwords don\'t match';

  @override
  String get validatorPhoneRequired => 'Phone number is required';

  @override
  String get validatorPhoneInvalid =>
      'Invalid Tunisian number (8 digits, e.g. 22 345 678)';

  @override
  String get validatorCinRequired => 'National ID number is required';

  @override
  String get validatorCinInvalid => 'National ID must contain 8 digits';

  @override
  String get validatorLicenceRequired => 'Licence number is required';

  @override
  String get validatorLicenceInvalid => 'Invalid licence number';

  @override
  String get validatorCardRequired => 'Card number is required';

  @override
  String get validatorCardInvalid => 'The number must contain 16 digits';

  @override
  String get validatorExpiryRequired => 'Expiry date is required';

  @override
  String get validatorExpiryFormat => 'Expected format MM/YY';

  @override
  String get validatorMonthInvalid => 'Invalid month';

  @override
  String get validatorCardExpired => 'Card expired';

  @override
  String get validatorCvvRequired => 'CVV is required';

  @override
  String get validatorCvvInvalid => 'Invalid CVV';

  @override
  String get validatorAmountRequired => 'Amount is required';

  @override
  String get validatorAmountInvalid => 'Invalid amount';

  @override
  String get validatorAmountPositive => 'Amount must be greater than 0';
}
