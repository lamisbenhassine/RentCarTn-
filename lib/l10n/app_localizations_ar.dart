// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonEmail => 'البريد الإلكتروني';

  @override
  String get commonEmailHint => 'name@example.tn';

  @override
  String get commonPassword => 'كلمة المرور';

  @override
  String get commonNewPassword => 'كلمة المرور الجديدة';

  @override
  String get commonConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get commonPasswordHelper => '6 أحرف على الأقل، حروف وأرقام';

  @override
  String get commonPhone => 'الهاتف';

  @override
  String get commonFirstName => 'الاسم';

  @override
  String get commonLastName => 'اللقب';

  @override
  String get commonLogin => 'تسجيل الدخول';

  @override
  String get commonLogout => 'تسجيل الخروج';

  @override
  String get commonCreateAccount => 'إنشاء حساب';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonOpenSettings => 'فتح الإعدادات';

  @override
  String get commonSaveFailed => 'تعذّر الحفظ.';

  @override
  String get commonChangeFailed => 'تعذّر التعديل.';

  @override
  String get commonNotProvided => 'غير مُدخل';

  @override
  String get commonNotProvidedFem => 'غير مُدخلة';

  @override
  String get commonLocating => 'جارٍ تحديد الموقع…';

  @override
  String get commonAddressUnavailable => 'العنوان غير متوفر';

  @override
  String get commonPositionUnavailable => 'الموقع غير متوفر';

  @override
  String commonNearestAgency(String city, String km) {
    return 'أقرب وكالة: $city ($km كم)';
  }

  @override
  String get commonEmailTaken => 'يوجد حساب بهذا البريد الإلكتروني بالفعل.';

  @override
  String get commonPhoneTaken => 'رقم الهاتف هذا مستخدم بالفعل.';

  @override
  String get commonLanguage => 'اللغة';

  @override
  String get locationServiceDisabled =>
      'خدمة تحديد الموقع (GPS) معطّلة على جهازك.';

  @override
  String get locationDenied => 'لقد رفضت الوصول إلى موقعك.';

  @override
  String get locationDeniedForever =>
      'الوصول إلى الموقع محظور. اسمح به من إعدادات التطبيق.';

  @override
  String get locationTimeout =>
      'تعذّر العثور على الموقع حاليًا. حاول مجددًا في الخارج أو اختر مدينتك.';

  @override
  String get locationUnknown => 'تعذّر الحصول على موقعك.';

  @override
  String get authBrandTagline => 'تنقّلك،\nمهنتنا.';

  @override
  String get authBrandDescription =>
      'تأجير السيارات والمزادات وتعلّم قانون الطرقات في منصة واحدة.';

  @override
  String get authStatCars => 'سيارة';

  @override
  String get authStatCities => 'مدينة';

  @override
  String get authStatRating => 'متوسط التقييم';

  @override
  String get loginTitle => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لإدارة حجوزاتك ومزاداتك.';

  @override
  String get loginNoAccountWithEmail => 'لا يوجد حساب بهذا البريد الإلكتروني';

  @override
  String get loginWrongPassword => 'كلمة المرور غير صحيحة';

  @override
  String get loginRememberMe => 'تذكّرني';

  @override
  String get loginForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String loginRetryIn(int seconds) {
    return 'أعد المحاولة بعد $seconds ث';
  }

  @override
  String get loginNoAccountYet => 'ليس لديك حساب؟';

  @override
  String loginAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تبقّت لك $count محاولة',
      few: 'تبقّت لك $count محاولات',
      two: 'تبقّت لك محاولتان',
      one: 'تبقّت لك محاولة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get loginAccountNotFoundTitle => 'الحساب غير موجود';

  @override
  String loginAccountNotFoundMessage(String attempts) {
    return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني. تحقّق من الكتابة أو أنشئ حسابًا. $attempts.';
  }

  @override
  String loginWrongPasswordMessage(String attempts) {
    return '$attempts قبل حظر لمدة 60 ثانية. نسيت كلمة المرور؟ استخدم الرابط أعلاه.';
  }

  @override
  String get loginLockedTitle => 'تسجيل الدخول محظور مؤقتًا';

  @override
  String loginLockedMessage(String time) {
    return 'محاولات فاشلة كثيرة. أعد المحاولة بعد $time.';
  }

  @override
  String get loginVerifyEmailFirst =>
      'تحقّق من بريدك الإلكتروني للوصول إلى حسابك.';

  @override
  String loginWelcome(String name) {
    return 'مرحبًا $name!';
  }

  @override
  String get registerTitle => 'أنشئ حسابك';

  @override
  String get registerSubtitle => 'بعض المعلومات تكفي لحجز سيارتك الأولى.';

  @override
  String get registerStepIdentity => 'الهوية';

  @override
  String get registerStepLocation => 'الموقع';

  @override
  String get registerStepSecurity => 'الأمان';

  @override
  String registerStepProgress(int current, int total, String title) {
    return 'الخطوة $current من $total · $title';
  }

  @override
  String get registerUseLocationOrCity => 'استخدم موقعك أو اختر مدينتك.';

  @override
  String get registerAcceptTermsRequired => 'يجب الموافقة على شروط الاستخدام.';

  @override
  String get registerSuccess =>
      'تم إنشاء الحساب. تحقّق من بريدك الإلكتروني لتفعيله.';

  @override
  String get registerFailed => 'تعذّر التسجيل.';

  @override
  String get registerCreateMyAccount => 'إنشاء حسابي';

  @override
  String get registerAlreadyRegistered => 'لديك حساب بالفعل؟';

  @override
  String get registerAgencyIntro => 'نختار لك أقرب وكالة RentCar.';

  @override
  String get registerUseMyLocation => 'استخدام موقعي';

  @override
  String get registerFarFromAgencies =>
      'يبدو أنك بعيد عن وكالاتنا. تحقّق من المدينة المقترحة أو اخترها يدويًا.';

  @override
  String get registerChooseOtherCity => 'اختيار مدينة أخرى';

  @override
  String get registerAgencyCity => 'مدينة وكالتك';

  @override
  String get registerPreferChooseCity => 'أفضّل اختيار مدينتي';

  @override
  String get registerAcceptTerms =>
      'أوافق على الشروط العامة للتأجير وسياسة الخصوصية.';

  @override
  String get registerSecurityNotice =>
      'يُحفظ حسابك على هذا الجهاز. كلمة المرور مشفّرة (SHA-256) ولا تُخزَّن أبدًا كنص واضح.';

  @override
  String get registerChooseCityBelow => 'اختر مدينتك أدناه.';

  @override
  String get strengthWeak => 'ضعيفة';

  @override
  String get strengthMedium => 'متوسطة';

  @override
  String get strengthGood => 'جيدة';

  @override
  String get strengthExcellent => 'ممتازة';

  @override
  String get otpExpired => 'انتهت صلاحية هذا الرمز. اطلب رمزًا جديدًا.';

  @override
  String get otpTooManyAttempts => 'محاولات خاطئة كثيرة. اطلب رمزًا جديدًا.';

  @override
  String get otpIncomplete => 'أدخل أرقام الرمز الستة.';

  @override
  String get otpRequestNew => 'اطلب رمزًا جديدًا.';

  @override
  String otpWrongCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رمز غير صحيح. تبقّت لك $count محاولة.',
      few: 'رمز غير صحيح. تبقّت لك $count محاولات.',
      two: 'رمز غير صحيح. تبقّت لك محاولتان.',
      one: 'رمز غير صحيح. تبقّت لك محاولة واحدة.',
    );
    return '$_temp0';
  }

  @override
  String get otpSendFailedNetwork =>
      'تعذّر إرسال البريد الإلكتروني. تحقّق من اتصالك بالإنترنت ثم أعد المحاولة.';

  @override
  String otpSendFailedService(int code) {
    return 'رفضت خدمة الإرسال الطلب (خطأ $code). أعد المحاولة بعد قليل.';
  }

  @override
  String otpValidFor(String time) {
    return 'صالح لمدة $time';
  }

  @override
  String otpAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محاولة متبقية',
      few: '$count محاولات متبقية',
      two: 'محاولتان متبقيتان',
      one: 'محاولة واحدة متبقية',
    );
    return '$_temp0';
  }

  @override
  String get otpVerify => 'تحقّق من الرمز';

  @override
  String get otpSending => 'جارٍ الإرسال…';

  @override
  String get otpResend => 'إعادة إرسال الرمز';

  @override
  String otpResendIn(int seconds) {
    return 'إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get otpEmailNotSent => 'لم يُرسل البريد الإلكتروني';

  @override
  String get otpEmailSentTitle => 'تم إرسال البريد الإلكتروني';

  @override
  String otpEmailSentMessage(String destination) {
    return 'افتح صندوق الوارد لـ $destination. قد يستغرق البريد دقيقة وقد يصل إلى الرسائل غير المرغوب فيها.';
  }

  @override
  String get otpNewCodeSent => 'تم إرسال رمز جديد.';

  @override
  String get forgotTitle => 'نسيت كلمة المرور';

  @override
  String get forgotSubtitle => 'اختر طريقة استلام رمز التحقق.';

  @override
  String get forgotCodeTitle => 'أدخل الرمز';

  @override
  String forgotCodeSubtitleEmail(String destination) {
    return 'رمز من 6 أرقام أُرسل بالبريد الإلكتروني إلى $destination.';
  }

  @override
  String forgotCodeSubtitleSms(String destination) {
    return 'رمز من 6 أرقام أُرسل برسالة نصية إلى $destination.';
  }

  @override
  String get forgotPasswordSubtitle =>
      'اختر كلمة مرور لا تستخدمها في مكان آخر.';

  @override
  String get forgotSuccessTitle => 'تم تغيير كلمة المرور';

  @override
  String get forgotSuccessSubtitle => 'يمكنك الآن تسجيل الدخول.';

  @override
  String get forgotChannelEmail => 'البريد';

  @override
  String get forgotChannelSms => 'رسالة نصية';

  @override
  String get forgotAccountEmail => 'البريد الإلكتروني للحساب';

  @override
  String get forgotAccountPhone => 'هاتف الحساب';

  @override
  String get forgotNoAccountEmail =>
      'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';

  @override
  String get forgotNoAccountPhone => 'لا يوجد حساب مرتبط بهذا الرقم.';

  @override
  String get forgotReceiveCode => 'استلام الرمز';

  @override
  String get forgotSendingEmail => 'جارٍ إرسال البريد الإلكتروني…';

  @override
  String get forgotEmailNotice =>
      'سيُرسل رمز من 6 أرقام إلى البريد الإلكتروني للحساب. لا تنسَ التحقق من مجلد الرسائل غير المرغوب فيها.';

  @override
  String get forgotSmsNotice =>
      'وضع تجريبي: لا تُرسل أي رسالة نصية فعليًا. سيظهر الرمز في الشاشة التالية.';

  @override
  String get forgotBackToLogin => 'العودة إلى تسجيل الدخول';

  @override
  String get forgotSmsDemoTitle => 'وضع الرسائل التجريبي — رمزك';

  @override
  String get forgotSmsDemoFooter => '(في النسخة النهائية، سيُرسل برسالة نصية.)';

  @override
  String get forgotChangeMethod => 'تغيير الطريقة';

  @override
  String get forgotSavePassword => 'حفظ كلمة المرور';

  @override
  String get forgotResetDone => 'تمت إعادة تعيين كلمة المرور';

  @override
  String get forgotResetDoneMessage =>
      'تم حفظ كلمة مرورك الجديدة بأمان. استخدمها لتسجيل الدخول.';

  @override
  String forgotRedirectIn(int seconds) {
    return 'التوجيه إلى تسجيل الدخول بعد $seconds ث…';
  }

  @override
  String get verifyTitle => 'تحقّق من بريدك الإلكتروني';

  @override
  String verifySubtitle(String email) {
    return 'أدخل الرمز المكوّن من 6 أرقام المُرسل إلى $email لتفعيل حسابك.';
  }

  @override
  String get verifySendingCode => 'جارٍ إرسال الرمز…';

  @override
  String get verifyRetrySend => 'إعادة محاولة الإرسال';

  @override
  String get verifyChangeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get verifySuccess => 'تم التحقق من البريد الإلكتروني. مرحبًا بك!';

  @override
  String get verifyNewEmailLabel => 'البريد الإلكتروني الجديد';

  @override
  String get verifySameEmail => 'هذا هو عنوانك الحالي بالفعل';

  @override
  String get verifySendCode => 'إرسال رمز';

  @override
  String get profileTitle => 'ملفي الشخصي';

  @override
  String get profileLogoutTitle => 'تسجيل الخروج؟';

  @override
  String get profileLogoutMessage =>
      'ستعود إلى شاشة الترحيب. تُحفظ بيانات الجلسة التجريبية (السلة، المزادات، التقدّم) حتى إغلاق التطبيق.';

  @override
  String get profileStayLoggedIn => 'البقاء متصلًا';

  @override
  String get profilePhotoRemoved => 'تم حذف الصورة.';

  @override
  String get profilePhotoUpdated => 'تم تحديث صورة الملف الشخصي.';

  @override
  String get profileGroupTrust => 'الثقة والولاء';

  @override
  String get profileGroupInfo => 'معلوماتي';

  @override
  String get profileGroupAccount => 'حسابي';

  @override
  String get profileGroupAuctions => 'المزادات';

  @override
  String get profileGroupLearning => 'التعلّم';

  @override
  String get profileGroupApp => 'التطبيق';

  @override
  String get profileEdit => 'تعديل ملفي الشخصي';

  @override
  String get profileEditSubtitle => 'الصورة، الاسم، الهاتف، الرخصة، العنوان';

  @override
  String get profileChangePassword => 'تغيير كلمة المرور';

  @override
  String get profileChangePasswordSubtitle => 'كلمة المرور الحالية ثم الجديدة';

  @override
  String get profileReservations => 'حجوزاتي';

  @override
  String profileRentalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عملية كراء',
      few: '$count عمليات كراء',
      two: 'كراءان',
      one: 'كراء واحد',
      zero: 'لا يوجد كراء',
    );
    return '$_temp0';
  }

  @override
  String get profileCart => 'سلّتي';

  @override
  String get profileCartSubtitle => 'سيارات في انتظار الحجز';

  @override
  String get profileMyAuctions => 'مزاداتي وعروضي';

  @override
  String profileMyAuctionsSubtitle(int ongoing, int won) {
    String _temp0 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won فوزًا',
      few: '$won انتصارات',
      two: 'فوزان',
      one: 'فوز واحد',
      zero: 'لا فوز',
    );
    return '$ongoing جارية · $_temp0';
  }

  @override
  String get profileMarketplace => 'السوق';

  @override
  String get profileMarketplaceSubtitle => 'سيارات مستعملة في المزاد';

  @override
  String get profileFleet => 'إدارة الأسطول (تجريبي)';

  @override
  String get profileFleetSubtitle => 'لوحة متابعة المبيعات';

  @override
  String get profileRoadCode => 'قانون الطرقات';

  @override
  String profileProgress(int percent) {
    return 'التقدّم: $percent٪';
  }

  @override
  String get profileQuizResults => 'نتائج اختباراتي';

  @override
  String profileQuizCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اختبارًا منجزًا',
      few: '$count اختبارات منجزة',
      two: 'اختباران منجزان',
      one: 'اختبار واحد منجز',
      zero: 'لا اختبارات منجزة',
    );
    return '$_temp0';
  }

  @override
  String get profileAbout => 'حول التطبيق';

  @override
  String get profileAboutSubtitle => 'RentCar Tunisia · النسخة التجريبية 1.0.0';

  @override
  String get profileAboutVersion => 'تجريبي 1.0.0';

  @override
  String get profileAboutText =>
      'تطبيق واجهة لتأجير السيارات ومزادات السيارات المستعملة وتعلّم قانون الطرقات في تونس.\n\nكل البيانات محاكاة محليًا. لا خادم، لا قاعدة بيانات، ولا دفع حقيقي.';

  @override
  String get profileSupport => 'المساعدة';

  @override
  String get profileSupportSubtitle =>
      'contact@rentcar.tn · ‎+216 71 000 000 (وهمي)';

  @override
  String get profileSupportSnack => 'بيانات اتصال وهمية: لا توجد خدمة حقيقية.';

  @override
  String get profileLogoutSubtitle => 'إنهاء الجلسة التجريبية';

  @override
  String profileAuctionAlias(String name) {
    return 'اسم المزادات: $name';
  }

  @override
  String get profileStatReservations => 'الحجوزات';

  @override
  String get profileStatAuctions => 'المزادات';

  @override
  String get profileStatCode => 'القانون';

  @override
  String get profileStatSpent => 'المصروف';

  @override
  String get profileComplete => 'الملف مكتمل ✓';

  @override
  String profileCompletion(int percent) {
    return 'اكتمل الملف بنسبة $percent٪';
  }

  @override
  String profileCompletionMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count عنصرًا',
      few: 'بقيت $count عناصر',
      two: 'بقي عنصران',
      one: 'بقي عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String get stepPhoto => 'أضف صورة للملف الشخصي';

  @override
  String get stepPhone => 'أضف رقم هاتفك';

  @override
  String get stepCin => 'أضف رقم بطاقة التعريف الوطنية';

  @override
  String get stepLicenceNumber => 'أضف رخصة السياقة';

  @override
  String get stepLicenceExpiry => 'أدخل تاريخ انتهاء الرخصة';

  @override
  String get stepAddress => 'أضف عنوانك';

  @override
  String get stepPosition => 'سجّل موقعك';

  @override
  String get stepEmailVerified => 'تحقّق من بريدك الإلكتروني';

  @override
  String get trustTitle => 'مؤشر الثقة';

  @override
  String trustClient(String tier) {
    return 'عميل $tier';
  }

  @override
  String get tierBronze => 'برونزي';

  @override
  String get tierSilver => 'فضي';

  @override
  String get tierGold => 'ذهبي';

  @override
  String get trustGoldAdvantage => 'خصم 10٪ على كل حجوزاتك';

  @override
  String trustToSilver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count عملية كراء منتهية للوصول إلى المستوى الفضي',
      few: 'بقيت $count عمليات كراء منتهية للوصول إلى المستوى الفضي',
      two: 'بقي كراءان منتهيان للوصول إلى المستوى الفضي',
      one: 'بقي كراء واحد منتهٍ للوصول إلى المستوى الفضي',
    );
    return '$_temp0';
  }

  @override
  String trustToGold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'بقيت $count عملية كراء منتهية للوصول إلى المستوى الذهبي (خصم 10٪)',
      few: 'بقيت $count عمليات كراء منتهية للوصول إلى المستوى الذهبي (خصم 10٪)',
      two: 'بقي كراءان منتهيان للوصول إلى المستوى الذهبي (خصم 10٪)',
      one: 'بقي كراء واحد منتهٍ للوصول إلى المستوى الذهبي (خصم 10٪)',
    );
    return '$_temp0';
  }

  @override
  String trustClean(int count) {
    return '$count دون مشاكل';
  }

  @override
  String trustLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تأخيرًا',
      few: '$count تأخيرات',
      two: 'تأخيران',
      one: 'تأخير واحد',
      zero: 'لا تأخير',
    );
    return '$_temp0';
  }

  @override
  String trustComplaints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شكوى',
      few: '$count شكاوى',
      two: 'شكويان',
      one: 'شكوى واحدة',
      zero: 'لا شكاوى',
    );
    return '$_temp0';
  }

  @override
  String get trustRules =>
      'البداية 50 · ‎+5 لكل كراء دون مشاكل · ‎-10 لكل تأخير · ‎-15 لكل شكوى مُثبتة · ‎-10 لكل شكوى تعسفية.';

  @override
  String get profilePersonalInfo => 'المعلومات الشخصية';

  @override
  String get profileFullName => 'الاسم الكامل';

  @override
  String get profileEmail => 'البريد الإلكتروني';

  @override
  String get profileCin => 'بطاقة التعريف';

  @override
  String get profileBirth => 'تاريخ الميلاد';

  @override
  String get profileAddress => 'العنوان';

  @override
  String get profileMemberSince => 'عضو منذ';

  @override
  String get profileLicence => 'رخصة السياقة';

  @override
  String get profileLicenceNumber => 'الرقم';

  @override
  String get profileLicenceExpiry => 'تاريخ الانتهاء';

  @override
  String get licenceValid => 'صالحة';

  @override
  String get licenceExpiringSoon => 'تنتهي قريبًا';

  @override
  String get licenceExpired => 'منتهية';

  @override
  String get profilePositionTitle => 'الموقع والوكالة';

  @override
  String get profileDefaultAgency => 'الوكالة الافتراضية';

  @override
  String get profileCoordinates => 'الإحداثيات';

  @override
  String get profileUpdatePosition => 'تحديث موقعي';

  @override
  String get profileNewPosition => 'موقع جديد';

  @override
  String get profileUnchanged => 'دون تغيير';

  @override
  String get profileUseThisAddress => 'استخدام هذا العنوان أيضًا';

  @override
  String profileDefaultAgencySet(String city) {
    return 'الوكالة الافتراضية: $city.';
  }

  @override
  String get changePwdTitle => 'تغيير كلمة المرور';

  @override
  String get changePwdSubtitle => 'أدخل كلمة المرور الحالية ثم الجديدة.';

  @override
  String get changePwdCurrent => 'كلمة المرور الحالية';

  @override
  String get changePwdCurrentRequired => 'كلمة المرور الحالية مطلوبة';

  @override
  String get changePwdMustDiffer => 'يجب أن تختلف عن كلمة المرور الحالية';

  @override
  String get changePwdConfirm => 'تأكيد كلمة المرور الجديدة';

  @override
  String get changePwdDone => 'تم تغيير كلمة المرور.';

  @override
  String get changePwdWrongCurrent => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get avatarSheetTitle => 'صورة الملف الشخصي';

  @override
  String get avatarGallery => 'معرض الصور';

  @override
  String get avatarFiles => 'الملفات';

  @override
  String get avatarFilesSubtitle => 'التنزيلات، Drive…';

  @override
  String get avatarRemove => 'حذف الصورة';

  @override
  String get avatarOpenFailed => 'تعذّر فتح اختيار الصور.';

  @override
  String get avatarUnreadable => 'تعذّر قراءة الصورة المختارة.';

  @override
  String get avatarTooLarge => 'الصورة كبيرة جدًا (1.5 ميغابايت كحد أقصى).';

  @override
  String get editSubtitle => 'معلومات تُستخدم في عقودك';

  @override
  String get editPhotoSource => 'من المعرض أو من ملفاتك';

  @override
  String get editAddPhoto => 'إضافة صورة';

  @override
  String get editChangePhoto => 'تغيير الصورة';

  @override
  String get editSectionIdentity => 'الهوية';

  @override
  String get editBirthDate => 'تاريخ الميلاد';

  @override
  String get editSectionContact => 'معلومات الاتصال';

  @override
  String get editCity => 'المدينة';

  @override
  String get editSectionDocuments => 'وثائق السياقة';

  @override
  String get editCin => 'رقم بطاقة التعريف الوطنية';

  @override
  String get editCinHint => '8 أرقام';

  @override
  String get editLicenceNumber => 'رقم الرخصة';

  @override
  String get editLicenceExpiry => 'تاريخ انتهاء الرخصة';

  @override
  String get editLicenceExpired => 'هذه الرخصة منتهية الصلاحية';

  @override
  String get editSectionAuctions => 'المزادات';

  @override
  String get editAlias => 'الاسم العلني';

  @override
  String get editAliasHelper => 'يظهر لباقي المشاركين في المزادات';

  @override
  String get editAliasField => 'الاسم العلني';

  @override
  String get editSaveChanges => 'حفظ التعديلات';

  @override
  String get editConfirmNewEmail => 'أكّد بريدك الإلكتروني الجديد.';

  @override
  String get editSaved => 'تم تحديث الملف الشخصي.';

  @override
  String get commonOr => 'أو';

  @override
  String get googleContinue => 'المتابعة باستخدام Google';

  @override
  String get googleErrorNetwork =>
      'لا يوجد اتصال بالإنترنت. تحقّق من شبكتك ثم أعد المحاولة.';

  @override
  String get googleErrorConfig =>
      'تسجيل الدخول عبر Google غير مُهيّأ بعد لهذا التطبيق.';

  @override
  String get googleErrorUnsupported =>
      'تسجيل الدخول عبر Google غير متاح على هذا الجهاز.';

  @override
  String get googleErrorUnknown => 'فشل تسجيل الدخول عبر Google. أعد المحاولة.';

  @override
  String get googleErrorNoAccount =>
      'لا يوجد حساب Google متاح على هذا الهاتف. أضف حسابًا من إعدادات Android ثم أعد المحاولة.';

  @override
  String get googleErrorNotAllowed =>
      'حساب Google هذا غير مسموح به حاليًا (التطبيق في مرحلة الاختبار).';

  @override
  String get deleteAccount => 'حذف حسابي';

  @override
  String get deleteTitle => 'حذف حسابك؟';

  @override
  String get deleteIntro => 'هذا الإجراء نهائي. سيتم حذف:';

  @override
  String get deleteItemProfile => 'ملفك الشخصي ومعلوماتك الشخصية';

  @override
  String get deleteItemPhoto => 'صورة ملفك الشخصي';

  @override
  String get deleteItemPrefs => 'تفضيلاتك وجلسة «تذكّرني»';

  @override
  String get deleteItemHistory => 'سجلّك (مؤشر الثقة، اكتمال الملف)';

  @override
  String deleteBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'لديك $count حجزًا جاريًا أو قادمًا. أنهِها أو ألغِها قبل حذف حسابك.',
      few: 'لديك $count حجوزات جارية أو قادمة. أنهِها أو ألغِها قبل حذف حسابك.',
      two: 'لديك حجزان جاريان أو قادمان. أنهِهما أو ألغِهما قبل حذف حسابك.',
      one: 'لديك حجز جارٍ أو قادم. أنهِه أو ألغِه قبل حذف حسابك.',
    );
    return '$_temp0';
  }

  @override
  String get deleteSeeReservations => 'عرض حجوزاتي';

  @override
  String get deleteConfirmWord => 'حذف';

  @override
  String deleteGoogleHint(String word) {
    return 'حساب Google دون كلمة مرور: اكتب $word للتأكيد.';
  }

  @override
  String deleteTypeLabel(String word) {
    return 'اكتب $word';
  }

  @override
  String deleteWordMismatch(String word) {
    return 'اكتب $word بالضبط';
  }

  @override
  String get deleteConfirm => 'حذف نهائي';

  @override
  String get deleteDone => 'تم حذف الحساب';

  @override
  String get deleteFailed => 'فشل الحذف. أعد المحاولة.';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String get remindersLicence => 'انتهاء الرخصة';

  @override
  String get remindersLicenceSub => 'قبل 30 يومًا و7 أيام';

  @override
  String get remindersReservation => 'الحجوزات';

  @override
  String get remindersReservationSub => 'قبل يوم من الاستلام ويوم الإرجاع';

  @override
  String get remindersProfile => 'ملف غير مكتمل';

  @override
  String get remindersProfileSub => 'بعد يومين من التسجيل';

  @override
  String get remindersDenied =>
      'الإشعارات معطّلة لتطبيق RentCar. يعمل التطبيق بشكل عادي لكن دون تذكيرات.';

  @override
  String get remindersAllow => 'السماح بالإشعارات';

  @override
  String get remindersUnsupported => 'التذكيرات متاحة على Android فقط.';

  @override
  String get remindersTest => 'تجربة إشعار بعد 10 ث';

  @override
  String get remindersTestScheduled => 'إشعار تجريبي بعد 10 ثوانٍ…';

  @override
  String get notifChannelName => 'تذكيرات RentCar';

  @override
  String get notifChannelDesc => 'الرخصة والحجوزات والملف الشخصي';

  @override
  String get notifLicenceTitle => 'رخصتك تنتهي قريبًا';

  @override
  String notifLicence30Body(String date) {
    return 'تنتهي رخصة السياقة في $date (بعد 30 يومًا). لا تنسَ تجديدها.';
  }

  @override
  String notifLicence7Body(String date) {
    return 'بقيت 7 أيام: تنتهي رخصتك في $date. حدّث ملفك بعد التجديد.';
  }

  @override
  String get notifResaStartTitle => 'يبدأ كراؤك غدًا';

  @override
  String notifResaStartBody(String car, String time, String city) {
    return '$car في انتظارك غدًا على الساعة $time في $city. لا تنسَ رخصتك وبطاقة تعريفك.';
  }

  @override
  String get notifResaReturnTitle => 'إرجاع السيارة اليوم';

  @override
  String notifResaReturnBody(String car, String time, String city) {
    return 'أرجع $car اليوم قبل الساعة $time في $city.';
  }

  @override
  String get notifProfileTitle => 'أكمل ملفك الشخصي';

  @override
  String notifProfileBody(int percent) {
    return 'اكتمل ملفك بنسبة $percent٪. أضف المعلومات الناقصة للحجز بسرعة أكبر.';
  }

  @override
  String get notifTestTitle => 'تجربة RentCar';

  @override
  String get notifTestBody => 'التذكيرات تعمل. المس لفتح ملفك الشخصي.';

  @override
  String get complaintReport => 'الإبلاغ عن مشكلة';

  @override
  String get complaintReportSub => 'عطل، نظافة، فوترة، مزاد…';

  @override
  String get complaintNewTitle => 'شكوى جديدة';

  @override
  String get complaintEditTitle => 'تعديل الشكوى';

  @override
  String get complaintFormSubtitle => 'صِف المشكلة: ستردّ عليك الوكالة بسرعة.';

  @override
  String get complaintCategoryLabel => 'الصنف';

  @override
  String get complaintCategoryRequired => 'اختر صنفًا.';

  @override
  String get complaintCatPanne => 'عطل';

  @override
  String get complaintCatProprete => 'النظافة';

  @override
  String get complaintCatRetardAgence => 'تأخر الوكالة';

  @override
  String get complaintCatFacturation => 'الفوترة';

  @override
  String get complaintCatEnchere => 'مزاد';

  @override
  String get complaintCatAutre => 'أخرى';

  @override
  String get complaintStatusEnAttente => 'قيد الانتظار';

  @override
  String get complaintStatusEnCours => 'قيد المعالجة';

  @override
  String get complaintStatusResolue => 'تمت المعالجة';

  @override
  String get complaintStatusRejetee => 'مرفوضة';

  @override
  String get complaintPriorityBasse => 'منخفضة';

  @override
  String get complaintPriorityMoyenne => 'متوسطة';

  @override
  String get complaintPriorityUrgente => 'عاجلة';

  @override
  String get complaintLinkLabel => 'تتعلق بـ';

  @override
  String get complaintLinkNone => 'لا شيء';

  @override
  String get complaintLinkReservation => 'حجز';

  @override
  String get complaintLinkAuction => 'مزاد';

  @override
  String get complaintNoReservation => 'ليس لديك أي حجز لربطه. اختر «لا شيء».';

  @override
  String get complaintNoAuction => 'لم تشارك في أي مزاد. اختر «لا شيء».';

  @override
  String get complaintPickReservation => 'اختر الحجز المعني.';

  @override
  String get complaintPickAuction => 'اختر المزاد المعني.';

  @override
  String complaintAutoFilled(String car, String agency) {
    return 'السيارة: $car · الوكالة: $agency';
  }

  @override
  String get complaintTitleLabel => 'العنوان';

  @override
  String get complaintTitleHint => 'مثال: المكيّف لا يعمل';

  @override
  String get complaintTitleLength => 'يجب أن يتراوح العنوان بين 5 و80 حرفًا.';

  @override
  String get complaintDescLabel => 'الوصف';

  @override
  String get complaintDescHint => 'ماذا حدث؟ أين ومتى؟';

  @override
  String get complaintDescLength => 'يجب أن يتراوح الوصف بين 20 و1000 حرف.';

  @override
  String get complaintSubmit => 'إرسال الشكوى';

  @override
  String get complaintSaveFailed => 'تعذّر حفظ الشكوى. تحقّق ثم أعد المحاولة.';

  @override
  String get complaintSentTitle => 'تم إرسال الشكوى';

  @override
  String get complaintSentMessage =>
      'احتفظ بهذا المرجع: يتيح لك متابعة شكواك مع الوكالة.';

  @override
  String get complaintReferenceLabel => 'المرجع';

  @override
  String get complaintDone => 'تم';

  @override
  String get complaintUpdated => 'تم تعديل الشكوى.';

  @override
  String get complaintLoginRequired => 'سجّل الدخول للإبلاغ عن مشكلة.';

  @override
  String get complaintNotEditable =>
      'هذه الشكوى قيد المعالجة بالفعل: لم يعد من الممكن تعديلها.';

  @override
  String get complaintNotFound => 'الشكوى غير موجودة.';

  @override
  String get myComplaintsTitle => 'شكاواي';

  @override
  String myComplaintsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شكوى',
      few: '$count شكاوى',
      two: 'شكويان',
      one: 'شكوى واحدة',
      zero: 'لا توجد شكاوى',
    );
    return '$_temp0';
  }

  @override
  String get complaintsFilterAll => 'الكل';

  @override
  String get complaintsSearchHint => 'ابحث بالعنوان أو المرجع';

  @override
  String get complaintsEmptyTitle => 'لا توجد شكاوى';

  @override
  String get complaintsEmptyMessage =>
      'هل واجهت مشكلة في كراء أو مزاد؟ أبلغ عنها وستردّ عليك الوكالة.';

  @override
  String get complaintsNoMatch => 'لا توجد شكوى تطابق بحثك.';

  @override
  String get complaintsClearFilters => 'مسح الفلاتر';

  @override
  String get complaintsLoadError => 'تعذّر تحميل شكاواك.';

  @override
  String get complaintsRetry => 'إعادة المحاولة';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'أمس',
    );
    return '$_temp0';
  }

  @override
  String get complaintDetailsTitle => 'تفاصيل الشكوى';

  @override
  String get complaintFieldCategory => 'الصنف';

  @override
  String get complaintFieldPriority => 'الأولوية';

  @override
  String get complaintFieldStatus => 'الحالة';

  @override
  String get complaintFieldCar => 'السيارة';

  @override
  String get complaintFieldAgency => 'الوكالة';

  @override
  String get complaintFieldSent => 'أُرسلت في';

  @override
  String get complaintFieldUpdated => 'آخر تحديث';

  @override
  String get complaintLinkedReservation => 'الحجز المرتبط';

  @override
  String get complaintLinkedAuction => 'المزاد المرتبط';

  @override
  String get complaintLinkedMissing => 'العنصر المرتبط غير موجود (محذوف؟)';

  @override
  String get complaintPhotos => 'الصور';

  @override
  String get complaintLocation => 'الموقع المُبلَّغ عنه';

  @override
  String get complaintHistory => 'المتابعة';

  @override
  String get complaintAgencyResponse => 'ردّ الوكالة';

  @override
  String get complaintWaitingResponse =>
      'لم تردّ الوكالة بعد. سيتم إعلامك فور معالجة شكواك.';

  @override
  String get complaintEdit => 'تعديل';

  @override
  String get complaintCancel => 'إلغاء';

  @override
  String get complaintCancelTitle => 'إلغاء هذه الشكوى؟';

  @override
  String get complaintCancelMessage =>
      'سيتم حذفها نهائيًا. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get complaintCancelConfirm => 'نعم، ألغِ';

  @override
  String get complaintKeep => 'الاحتفاظ بها';

  @override
  String get complaintCancelled => 'تم إلغاء الشكوى.';

  @override
  String get complaintCopied => 'تم نسخ المرجع.';

  @override
  String get complaintDemoSimulate => 'محاكاة ردّ الوكالة (تجريبي)';

  @override
  String get complaintDemoNote =>
      'وضع تجريبي: لا توجد واجهة إدارة بعد. حاكِ هنا معالجة الوكالة.';

  @override
  String get complaintDemoTake => 'التكفّل بها';

  @override
  String get complaintDemoResolve => 'معالجة';

  @override
  String get complaintDemoReject => 'رفض';

  @override
  String complaintDemoDone(String status) {
    return 'الحالة الجديدة: $status';
  }

  @override
  String get complaintPhotosTitle => 'الصور (أدلة)';

  @override
  String get complaintPhotosHint => 'حتى 4 صور: أضرار، أوساخ، وصل، عدّاد…';

  @override
  String get complaintPhotoAdd => 'إضافة';

  @override
  String get complaintPhotoRemove => 'إزالة الصورة';

  @override
  String get complaintPhotoMax => '4 صور كحد أقصى.';

  @override
  String get complaintPhotoFailed => 'تعذّرت إضافة هذه الصورة. أعد المحاولة.';

  @override
  String complaintPhotoCounter(int index, int total) {
    return '$index / $total';
  }

  @override
  String get complaintAttachLocation => 'إرفاق موقعي';

  @override
  String get complaintAttachLocationSub =>
      'يساعد الوكالة على إيجادك (مفعّل عند العطل).';

  @override
  String get complaintLocationNoAddress =>
      'تم إرفاق موقع GPS (لم يُعثر على العنوان)';

  @override
  String get complaintLocationOff =>
      'الموقع غير متوفر: ستُرسل الشكوى دون موقع.';

  @override
  String get complaintOpenMaps => 'فتح في الخرائط';

  @override
  String get complaintMapsFailed => 'تعذّر فتح الخرائط.';

  @override
  String get urgentButton => 'عطل عاجل';

  @override
  String get urgentButtonSub => 'مساعدة سريعة: يُرسل موقعك والحجز الجاري';

  @override
  String get urgentSheetTitle => 'الإبلاغ عن عطل عاجل';

  @override
  String get urgentSheetIntro => 'نرسل فورًا إلى الوكالة:';

  @override
  String urgentWithReservation(String car, String reference) {
    return 'الحجز الجاري: $car ($reference)';
  }

  @override
  String get urgentNoReservation =>
      'لا يوجد حجز جارٍ: سيُرسل التنبيه دون حجز مرتبط.';

  @override
  String get urgentLocating => 'جارٍ البحث عن موقعك…';

  @override
  String urgentLocationOk(String address) {
    return 'الموقع: $address';
  }

  @override
  String get urgentLocationFailed =>
      'الموقع غير متوفر: سيُرسل التنبيه دون موقع.';

  @override
  String get urgentSend => 'إرسال التنبيه';

  @override
  String urgentTitle(String car) {
    return 'عطل عاجل — $car';
  }

  @override
  String get urgentTitleNoCar => 'عطل عاجل';

  @override
  String get urgentDescription =>
      'تم الإبلاغ عن العطل بزر الطوارئ في التطبيق. أحتاج إلى مساعدة سريعة.';

  @override
  String get urgentFailed => 'تعذّر إرسال التنبيه. اتصل بالوكالة مباشرة.';

  @override
  String get urgentSentTitle => 'تم إرسال التنبيه';

  @override
  String get urgentSentMessage =>
      'استلمت الوكالة تنبيه العطل. اتصل بها إذا احتجت إلى مساعدة فورية.';

  @override
  String get urgentCallAgency => 'الاتصال بالوكالة';

  @override
  String urgentCallFailed(String number) {
    return 'تعذّر بدء الاتصال. اطلب الرقم $number.';
  }

  @override
  String get urgentSafetyTitle => 'سلامتك أولًا';

  @override
  String get urgentTip1 => 'شغّل أضواء التنبيه وتوقّف على جانب الطريق إن أمكن.';

  @override
  String get urgentTip2 => 'ارتدِ السترة العاكسة قبل النزول من السيارة.';

  @override
  String get urgentTip3 =>
      'ضع مثلث التنبيه على بُعد 30 مترًا تقريبًا خلف السيارة.';

  @override
  String get urgentTip4 => 'احتمِ خلف الحاجز الواقي بعيدًا عن حركة المرور.';

  @override
  String get urgentTip5 =>
      'خطر أو إصابة: اتصل بالرقم 190 (الإسعاف) أو 197 (الشرطة) أو 198 (الحماية المدنية).';

  @override
  String get urgentSeeComplaint => 'عرض الشكوى';

  @override
  String get complaintPriorityLabel => 'الأولوية';

  @override
  String get aiAnalyze => 'التحليل بالذكاء الاصطناعي';

  @override
  String get aiAnalyzing => 'جارٍ التحليل بالذكاء الاصطناعي…';

  @override
  String get aiSuggestionTitle => 'اقتراح الذكاء الاصطناعي';

  @override
  String get aiSuggestionCategory => 'الصنف المقترح';

  @override
  String get aiSuggestionPriority => 'الأولوية المقترحة';

  @override
  String get aiToneLabel => 'النبرة المكتشفة';

  @override
  String get aiToneCalme => 'هادئ';

  @override
  String get aiToneMecontent => 'غير راضٍ';

  @override
  String get aiToneTresMecontent => 'غير راضٍ جدًا';

  @override
  String get aiPriorityRaised => 'تم رفع الأولوية درجة: عميل غير راضٍ جدًا.';

  @override
  String get aiAccept => 'قبول';

  @override
  String get aiKeep => 'الإبقاء على اختياري';

  @override
  String get aiApplied => 'تم تطبيق الاقتراح';

  @override
  String get aiKept => 'احتفظت باختيارك';

  @override
  String get aiDisclaimer => 'اقتراح آلي (Gemini): القرار الأخير لك.';

  @override
  String get aiAnalysisTitle => 'تحليل الذكاء الاصطناعي';

  @override
  String get aiSummaryLabel => 'الملخص';

  @override
  String get aiImprove => 'تحسين رسالتي';

  @override
  String get aiImproving => 'جارٍ إعادة الصياغة…';

  @override
  String get aiImproveTitle => 'رسالة محسّنة بالذكاء الاصطناعي';

  @override
  String get aiImproveHint =>
      'نفس المحتوى بصياغة أوضح. تأكد من عدم تغيّر أي تفصيل.';

  @override
  String get aiBefore => 'قبل';

  @override
  String get aiAfter => 'بعد';

  @override
  String get aiUseImproved => 'استخدام هذا النص';

  @override
  String get aiKeepMine => 'الإبقاء على نصي';

  @override
  String get aiImproveApplied => 'تم استبدال الرسالة';

  @override
  String get aiImproveSame => 'رسالتك واضحة بالفعل.';

  @override
  String get aiImproveFailed => 'إعادة الصياغة غير متاحة حاليًا.';

  @override
  String get quickFixChecking => 'جارٍ البحث عن حلول سريعة…';

  @override
  String get quickFixTitle => 'قبل الإرسال، هل جربت؟';

  @override
  String get quickFixSubtitle => 'حلول سريعة يقترحها الذكاء الاصطناعي:';

  @override
  String get quickFixResolved => 'تم حل المشكلة';

  @override
  String get quickFixSendAnyway => 'الإرسال على أي حال';

  @override
  String get quickFixResolvedMsg => 'رائع! لم يتم إرسال أي شكوى.';

  @override
  String get complaintMailSending => 'جارٍ إرسال التأكيد بالبريد الإلكتروني…';

  @override
  String complaintMailSent(String email) {
    return 'تم إرسال التأكيد إلى $email';
  }

  @override
  String complaintMailStatusSent(String email) {
    return 'تم إرسال بريد المتابعة إلى $email';
  }

  @override
  String get complaintMailFailed => 'تعذّر إرسال التأكيد بالبريد الإلكتروني.';

  @override
  String get complaintNotifChannel => 'الشكاوى';

  @override
  String get complaintNotifChannelDesc =>
      'متابعة شكاواك: تغييرات الحالة والتنبيهات العاجلة.';

  @override
  String complaintNotifStatusTitle(String reference) {
    return 'الشكوى $reference';
  }

  @override
  String complaintNotifStatusBody(String reference, String status) {
    return 'شكواك $reference أصبحت الآن: $status.';
  }

  @override
  String get complaintNotifUrgentTitle => 'تم إرسال تنبيه عاجل';

  @override
  String complaintNotifUrgentBody(String reference) {
    return '$reference: تم إبلاغ الوكالة وستتصل بك. ابقَ في أمان.';
  }

  @override
  String get complaintNotifOff =>
      'الإشعارات معطلة: لن يتم تنبيهك عند تغيّر حالة الشكوى. تبقى التحديثات ظاهرة هنا.';

  @override
  String get complaintNotifEnable => 'تفعيل';

  @override
  String get complaintUnreadLabel => 'جديد';

  @override
  String get complaintDemoDelayed => 'رد مؤجل (10 ث)';

  @override
  String get complaintDemoDelayedSub => 'غادر الشاشة أو التطبيق لتلقي الإشعار.';

  @override
  String get complaintDemoScheduled => 'ستردّ الوكالة خلال 10 ثوانٍ.';

  @override
  String get ratingTitle => 'هل أنت راضٍ عن الحل؟';

  @override
  String get ratingSubtitle => 'رأيك يساعد الوكالة على التحسن.';

  @override
  String get ratingLabel1 => 'غير راضٍ إطلاقًا';

  @override
  String get ratingLabel2 => 'غير راضٍ';

  @override
  String get ratingLabel3 => 'مقبول';

  @override
  String get ratingLabel4 => 'راضٍ';

  @override
  String get ratingLabel5 => 'راضٍ جدًا';

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجمة',
      few: '$count نجوم',
      two: 'نجمتان',
      one: 'نجمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get ratingCommentHint => 'تعليق؟ (اختياري)';

  @override
  String get ratingSubmit => 'إرسال رأيي';

  @override
  String get ratingThanks => 'شكرًا على رأيك';

  @override
  String get ratingYourComment => 'تعليقك';

  @override
  String get ratingReopenPrompt =>
      'غير راضٍ؟ أعد فتح الشكوى: ستتكفل بها الوكالة من جديد.';

  @override
  String get ratingReopen => 'إعادة فتح الشكوى';

  @override
  String get ratingReopenTitle => 'إعادة فتح الشكوى؟';

  @override
  String ratingReopenMessage(String reference) {
    return 'ستعود $reference إلى «قيد الانتظار» وستتكفل الوكالة بطلبك من جديد.';
  }

  @override
  String get ratingReopened => 'تمت إعادة فتح الشكوى';

  @override
  String get ratingAverage => 'متوسط التقييم';

  @override
  String ratingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تقييم',
      few: '$count تقييمات',
      two: 'تقييمان',
      one: 'تقييم واحد',
    );
    return '$_temp0';
  }

  @override
  String trustAbusive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شكوى تعسفية',
      few: '$count شكاوى تعسفية',
      two: 'شكويان تعسفيتان',
      one: 'شكوى تعسفية واحدة',
      zero: 'لا شكاوى تعسفية',
    );
    return '$_temp0';
  }

  @override
  String get complaintStatsTitle => 'شكاواي';

  @override
  String get complaintStatsTotal => 'المرسلة';

  @override
  String get complaintStatsResolved => 'المعالجة';

  @override
  String get complaintStatsAvgGiven => 'متوسط التقييم المقدَّم';

  @override
  String get complaintStatsNoRating => '—';

  @override
  String complaintRejectionWarning(int count) {
    return 'تم رفض $count من شكاواك خلال آخر 30 يومًا. تحقق من طلبك قبل إرساله: الشكوى المرفوضة كتعسفية تخصم 10 نقاط من درجة الثقة.';
  }

  @override
  String get complaintRejectionWarningTitle => 'تنبيه';

  @override
  String get complaintDemoRejectAbusive => 'رفض كشكوى تعسفية (‎-10 ثقة)';

  @override
  String get complaintAbusiveBadge => 'تعسفية';

  @override
  String get assistantTitle => 'مساعد RentCar';

  @override
  String get assistantSubtitle => 'Français · English · عربي · derja';

  @override
  String get assistantTyping => 'يكتب…';

  @override
  String assistantWelcome(String name) {
    return 'مرحبًا $name 👋 أنا مساعد RentCar. عطل، حجز، شكوى، رخصة أو وكالة: كيف يمكنني مساعدتك؟';
  }

  @override
  String get assistantWelcomeGuest =>
      'مرحبًا 👋 أنا مساعد RentCar. عطل، حجز، شكوى، رخصة أو وكالة: كيف يمكنني مساعدتك؟';

  @override
  String get assistantHint => 'اكتب رسالتك…';

  @override
  String get assistantSend => 'إرسال';

  @override
  String get assistantChipBreakdown => 'عطل';

  @override
  String get assistantChipBreakdownMsg => 'سيارتي معطلة، ماذا أفعل؟';

  @override
  String get assistantChipReservation => 'حجزي';

  @override
  String get assistantChipReservationMsg => 'ما حالة حجزي الحالي؟';

  @override
  String get assistantChipComplaint => 'متابعة شكوى';

  @override
  String get assistantChipComplaintMsg => 'ما حالة شكاواي؟';

  @override
  String get assistantNewConversation => 'محادثة جديدة';

  @override
  String get assistantNewConversationConfirm =>
      'مسح هذه المحادثة وبدء محادثة جديدة؟';

  @override
  String get assistantClear => 'مسح';

  @override
  String get assistantOffline =>
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وأعد المحاولة، أو قدّم شكوى: سيتم حفظها في التطبيق.';

  @override
  String get assistantUnavailable =>
      'المساعد غير متاح مؤقتًا. أعد المحاولة بعد قليل أو قدّم شكوى عادية.';

  @override
  String get assistantActionComplaint => 'تقديم شكوى';

  @override
  String get assistantActionBreakdown => 'عطل عاجل';

  @override
  String get assistantActionReservations => 'حجوزاتي';

  @override
  String get assistantActionComplaints => 'شكاواي';

  @override
  String get assistantDisclaimer =>
      'إجابات مولّدة بالذكاء الاصطناعي (Gemini): تحقق من المعلومات المهمة لدى الوكالة.';

  @override
  String get assistantDraftIntro =>
      'أعددت هذا الملخص. راجعه ثم أكّد: لا يُرسل شيء دون موافقتك.';

  @override
  String get assistantDraftTitle => 'شكوى مقترحة';

  @override
  String get assistantDraftReservation => 'الحجز';

  @override
  String get assistantDraftConfirm => 'تأكيد';

  @override
  String get assistantDraftEdit => 'تعديل';

  @override
  String get assistantDraftConfirmed => 'تم التأكيد والإرسال';

  @override
  String get assistantDraftEdited => 'فُتحت في الاستمارة';

  @override
  String get assistantDraftNotice => 'لا يتم إنشاء أي شيء قبل تأكيدك.';

  @override
  String assistantComplaintCreated(String reference) {
    return 'تم إنشاء الشكوى $reference ✓ ستصلك رسالة تأكيد بالبريد وإشعار عند كل تغيير في الحالة.';
  }

  @override
  String get assistantActionViewComplaint => 'عرض التفاصيل';

  @override
  String get assistantActionCallAgency => 'الاتصال بالوكالة';

  @override
  String get assistantMic => 'إملاء رسالة';

  @override
  String get assistantStopListening => 'إيقاف الإملاء';

  @override
  String get assistantListening => 'أنا أستمع إليك…';

  @override
  String get assistantVoiceLang => 'لغة الإملاء';

  @override
  String get assistantVoiceFr => 'Français';

  @override
  String get assistantVoiceAr => 'العربية (تونس)';

  @override
  String get assistantMicDeniedTitle => 'تم رفض الميكروفون';

  @override
  String get assistantMicDenied =>
      'لإملاء رسائلك، اسمح باستخدام الميكروفون: الإعدادات › التطبيقات › RentCar › الأذونات › الميكروفون. يمكنك دائمًا كتابة رسالتك.';

  @override
  String get assistantVoiceUnavailable =>
      'التعرّف على الصوت غير متوفر على هذا الجهاز.';

  @override
  String get assistantVoiceNoMatch => 'لم أسمع شيئًا، أعد المحاولة.';

  @override
  String get assistantVoiceError =>
      'فشل الإملاء. تحقق من الاتصال وأعد المحاولة.';

  @override
  String get assistantFeedbackUp => 'إجابة مفيدة';

  @override
  String get assistantFeedbackDown => 'إجابة غير مفيدة';

  @override
  String get assistantQuality => 'جودة الإجابات';

  @override
  String assistantQualityStats(int up, int down, int percent) {
    return '$up 👍 · $down 👎 — $percent٪ من الإجابات اعتُبرت مفيدة';
  }

  @override
  String get assistantQualityEmpty =>
      'لا توجد تقييمات بعد. استخدم 👍 / 👎 تحت إجابات المساعد.';

  @override
  String get assistantQualityNote =>
      'التقييمات محفوظة على هذا الهاتف حتى بعد محادثة جديدة.';

  @override
  String get aiQuotaReached =>
      'المساعد الذكي غير متاح مؤقتًا (تم بلوغ الحصة)، أعد المحاولة لاحقًا.';

  @override
  String get registerAccountType => 'نوع الحساب';

  @override
  String get registerRoleUser => 'مستخدم';

  @override
  String get registerRoleCompany => 'شركة';

  @override
  String get themeTitle => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get scanButton => 'مسح رخصتي ضوئيًا';

  @override
  String get scanInProgress => 'جارٍ قراءة الرخصة…';

  @override
  String get scanTip =>
      'صوّر وجه الرخصة وهي مسطّحة، في إضاءة جيدة ودون انعكاس.';

  @override
  String get scanCamera => 'التقاط صورة';

  @override
  String get scanGallery => 'الاختيار من المعرض';

  @override
  String get scanNothing =>
      'لا توجد معلومات مقروءة في الصورة. أدخل الرقم والتاريخ يدويًا، أو أعد المحاولة بصورة أوضح.';

  @override
  String get scanOnlyNumber =>
      'تم العثور على الرقم. تعذّرت قراءة تاريخ الانتهاء: اختره أدناه.';

  @override
  String get scanOnlyExpiry =>
      'تم العثور على تاريخ الانتهاء. تعذّرت قراءة الرقم: أدخله أدناه.';

  @override
  String get scanComplete => 'تم ملء الرقم والتاريخ. تحقّق منهما قبل الحفظ.';

  @override
  String scanExpired(String date) {
    return 'انتهت صلاحية هذه الرخصة في $date. لن تتمكن من الحجز قبل تجديدها.';
  }

  @override
  String get scanFilledHelper => 'تم الملء عبر المسح — تحقّق';

  @override
  String get scanCameraDenied =>
      'تم رفض الوصول إلى الكاميرا. اسمح به من الإعدادات أو اختر صورة من المعرض.';

  @override
  String get scanFailed => 'تعذّرت قراءة هذه الصورة. أعد المحاولة.';

  @override
  String validatorRequired(String field) {
    return '$field مطلوب';
  }

  @override
  String get validatorFieldDefault => 'هذا الحقل';

  @override
  String get validatorNameRequired => 'الاسم مطلوب';

  @override
  String get validatorNameShort => 'الاسم قصير جدًا';

  @override
  String get validatorNameLong => 'الاسم طويل جدًا';

  @override
  String get validatorEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get validatorEmailInvalid =>
      'بريد إلكتروني غير صالح (مثال: name@mail.tn)';

  @override
  String get validatorPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get validatorPasswordShort => '6 أحرف على الأقل';

  @override
  String get validatorPasswordLetter => 'يجب أن تحتوي على حرف واحد على الأقل';

  @override
  String get validatorPasswordDigit => 'يجب أن تحتوي على رقم واحد على الأقل';

  @override
  String get validatorConfirmRequired => 'يرجى التأكيد';

  @override
  String get validatorPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get validatorPhoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get validatorPhoneInvalid =>
      'رقم تونسي غير صالح (8 أرقام، مثال: 22 345 678)';

  @override
  String get validatorCinRequired => 'رقم بطاقة التعريف مطلوب';

  @override
  String get validatorCinInvalid => 'يجب أن تحتوي بطاقة التعريف على 8 أرقام';

  @override
  String get validatorLicenceRequired => 'رقم الرخصة مطلوب';

  @override
  String get validatorLicenceInvalid => 'رقم رخصة غير صالح';

  @override
  String get validatorCardRequired => 'رقم البطاقة مطلوب';

  @override
  String get validatorCardInvalid => 'يجب أن يحتوي الرقم على 16 رقمًا';

  @override
  String get validatorExpiryRequired => 'تاريخ الانتهاء مطلوب';

  @override
  String get validatorExpiryFormat => 'الصيغة المطلوبة MM/YY';

  @override
  String get validatorMonthInvalid => 'شهر غير صالح';

  @override
  String get validatorCardExpired => 'البطاقة منتهية الصلاحية';

  @override
  String get validatorCvvRequired => 'رمز CVV مطلوب';

  @override
  String get validatorCvvInvalid => 'رمز CVV غير صالح';

  @override
  String get validatorAmountRequired => 'المبلغ مطلوب';

  @override
  String get validatorAmountInvalid => 'مبلغ غير صالح';

  @override
  String get validatorAmountPositive => 'يجب أن يكون المبلغ أكبر من 0';
}
