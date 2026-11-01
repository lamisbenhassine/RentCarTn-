import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/models/profile_completion.dart';
import 'data/services/notification_service.dart';
import 'features/complaints/complaint_notifications.dart';
import 'l10n/app_localizations.dart';
import 'state/auction_provider.dart';
import 'state/auth_provider.dart';
import 'state/complaint_provider.dart';
import 'state/car_provider.dart';
import 'state/cart_provider.dart';
import 'state/chat_provider.dart';
import 'state/exam_provider.dart';
import 'state/learning_provider.dart';
import 'state/load_state.dart';
import 'state/locale_provider.dart';
import 'state/reminder_provider.dart';
import 'state/reservation_provider.dart';
import 'state/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Formats de date pour toutes les langues (fr, en, ar).
  await initializeDateFormatting();

  // Langue enregistrée, sinon celle du téléphone (fr / en / ar), sinon fr.
  final locale = LocaleProvider();
  await locale.load();

  // Thème enregistré (Clair / Sombre / Automatique).
  final theme = ThemeProvider();
  await theme.load();

  // Notifications locales (Android) : fuseau Africa/Tunis + réglages.
  await NotificationService.instance.init();
  final reminders = ReminderProvider();
  await reminders.load();

  // Configuration sqflite : ouvre (ou crée) le fichier local sur mobile.
  // Sur web, AppDatabase est un stub — aucun impact.
  if (AppDatabase.instance.isSupported) {
    await AppDatabase.instance.database;
  }

  // « Se souvenir de moi » : reconnecte le compte mémorisé avant le premier
  // écran, pour que le routeur ouvre directement l'accueil.
  final auth = AuthProvider();
  await auth.restoreSession();

  runApp(
    RentCarApp(auth: auth, locale: locale, theme: theme, reminders: reminders),
  );
}

class RentCarApp extends StatelessWidget {
  const RentCarApp({
    super.key,
    this.auth,
    this.locale,
    this.theme,
    this.reminders,
  });

  /// Réglages des rappels déjà chargés.
  final ReminderProvider? reminders;

  /// Session déjà restaurée (sinon une session vide est créée).
  final AuthProvider? auth;

  /// Langue déjà chargée (sinon français).
  final LocaleProvider? locale;

  /// Thème déjà chargé (sinon Automatique).
  final ThemeProvider? theme;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locale ?? LocaleProvider()),
        ChangeNotifierProvider(create: (_) => theme ?? ThemeProvider()),
        ChangeNotifierProvider(create: (_) => reminders ?? ReminderProvider()),
        ChangeNotifierProvider(create: (_) => auth ?? AuthProvider()),
        ChangeNotifierProvider(create: (_) => CarProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => AuctionProvider()),
        ChangeNotifierProvider(create: (_) => LearningProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> with WidgetsBindingObserver {
  late final GoRouter _router;

  // --- Rappels : reprogrammés quand l'utilisateur, ses réservations, les
  // réglages ou la langue changent ; tout annulé à la déconnexion. ---
  late final AuthProvider _auth;
  late final ReservationProvider _reservations;
  late final ReminderProvider _reminders;
  late final LocaleProvider _locale;
  Timer? _reminderDebounce;
  String? _reminderSignature;

  void _scheduleReminderSync() {
    _reminderDebounce?.cancel();
    _reminderDebounce = Timer(
      const Duration(milliseconds: 400),
      _syncReminders,
    );
  }

  Future<void> _syncReminders() async {
    final user = _auth.user;
    if (user != null && _reservations.state == LoadState.initial) {
      _reservations.load(); // déclenchera une nouvelle synchro une fois chargé
    }
    final signature = [
      user?.id,
      user?.licenceExpiry,
      user?.memberSince,
      user?.completion.percent,
      _reminders.signature,
      _locale.locale.languageCode,
      for (final r in _reservations.reservations)
        '${r.id}:${r.status.name}:${r.range.start}:${r.range.end}',
    ].join('|');
    if (signature == _reminderSignature) return;
    _reminderSignature = signature;
    await _reminders.sync(
      user: user,
      reservations: _reservations.reservations,
      l: lookupAppLocalizations(_locale.locale),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // L'utilisateur a pu autoriser / bloquer les notifications dans Android.
    if (state == AppLifecycleState.resumed) _reminders.refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reminderDebounce?.cancel();
    for (final n in [_auth, _reservations, _reminders, _locale]) {
      n.removeListener(_scheduleReminderSync);
    }
    _auth.removeListener(_syncComplaints);
    super.dispose();
  }

  // --- Réclamations : chargées pour l'utilisateur connecté, vidées à la
  // déconnexion (ou à la suppression du compte). ---
  late final ComplaintProvider _complaints;
  late final ChatProvider _chat;

  /// Réclamations + historique de l'assistant suivent le compte connecté.
  void _syncComplaints() {
    _complaints.loadFor(_auth.user?.id);
    _chat.loadFor(_auth.user?.id);
  }

  // Construits une seule fois (pas à chaque rebuild).
  static final ThemeData _lightTheme = AppTheme.light;
  static final ThemeData _darkTheme = AppTheme.dark;

  /// Écrans adaptés au mode sombre (module User). Les autres écrans
  /// utilisent encore des couleurs claires en dur : ils restent en clair,
  /// sans modifier leur code.
  static const List<String> _darkReadyPaths = [
    Routes.login,
    Routes.register,
    Routes.forgotPassword,
    Routes.verifyEmail,
    Routes.profile, // + /profil/modifier
    Routes.complaints, // + /reclamations/nouvelle, /reclamations/:id/…
    Routes.assistant,
  ];

  bool _isDarkReady(String path) =>
      _darkReadyPaths.any((p) => path == p || path.startsWith('$p/'));

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = buildRouter(auth);

    // Rappels.
    _auth = auth;
    _reservations = context.read<ReservationProvider>();
    _reminders = context.read<ReminderProvider>();
    _locale = context.read<LocaleProvider>();
    for (final n in [_auth, _reservations, _reminders, _locale]) {
      n.addListener(_scheduleReminderSync);
    }
    WidgetsBinding.instance.addObserver(this);
    _scheduleReminderSync();

    // Réclamations de l'utilisateur connecté.
    _complaints = context.read<ComplaintProvider>();
    _chat = context.read<ChatProvider>();
    // Notifications : statut changé, alerte urgente créée (langue courante).
    _complaints.alerts = ComplaintNotifications(
      l10n: () => lookupAppLocalizations(_locale.locale),
      onPermissionChanged: _reminders.refreshPermission,
    );
    _auth.addListener(_syncComplaints);
    // Après la première image : pas de notifyListeners pendant le build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncComplaints();
    });

    // Clic sur une notification → écran concerné (payload = route).
    NotificationService.instance.onOpenRoute = (route) => _router.go(route);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // App lancée depuis une notification alors qu'elle était fermée.
      final route = await NotificationService.instance.launchRoute();
      if (route != null && mounted) _router.go(route);
    });

    // Session restaurée : le pseudo d'enchères doit suivre le compte.
    final user = auth.user;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuctionProvider>().setUsername(
          user.publicUsername,
          userId: user.id,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RentCar Tunisia',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: context.watch<ThemeProvider>().mode,
      routerConfig: _router,
      // fr / en / ar. L'arabe passe en RTL tout seul : la Directionality
      // vient de GlobalWidgetsLocalizations (inclus dans les delegates).
      locale: context.watch<LocaleProvider>().locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        // Limite l'impact du réglage système de taille de police.
        final scale = MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);
        // Thème sombre seulement sur les écrans adaptés : on suit la route
        // courante. Le widget Theme est toujours présent (seules ses données
        // changent) pour ne jamais recréer le Navigator.
        return ListenableBuilder(
          listenable: _router.routerDelegate,
          builder: (context, _) {
            final appTheme = Theme.of(context);
            final path = _router.routerDelegate.currentConfiguration.uri.path;
            final useAppTheme =
                appTheme.brightness == Brightness.light || _isDarkReady(path);
            return Theme(
              data: useAppTheme ? appTheme : _lightTheme,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scale),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}
