import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/auction_provider.dart';
import 'state/auth_provider.dart';
import 'state/car_provider.dart';
import 'state/cart_provider.dart';
import 'state/learning_provider.dart';
import 'state/reservation_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Le français est la langue principale : les formats de date en dépendent.
  await initializeDateFormatting('fr_FR', null);
  runApp(const RentCarApp());
}

class RentCarApp extends StatelessWidget {
  const RentCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CarProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => AuctionProvider()),
        ChangeNotifierProvider(create: (_) => LearningProvider()),
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

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RentCar Tunisia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Limite l'impact du réglage système de taille de police.
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child!,
        );
      },
    );
  }
}
