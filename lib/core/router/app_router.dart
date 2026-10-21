import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/reservation.dart';
import '../../features/auctions/auction_details_screen.dart';
import '../../features/auctions/auction_result_screen.dart';
import '../../features/auctions/auctions_screen.dart';
import '../../features/auctions/fleet_management_screen.dart';
import '../../features/auctions/my_auctions_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/booking/checkout_screen.dart';
import '../../features/booking/confirmation_screen.dart';
import '../../features/booking/contract_screen.dart';
import '../../features/booking/receipt_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/catalog/car_details_screen.dart';
import '../../features/catalog/car_form_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/catalog/manage_cars_screen.dart';
import '../../features/home/home_screen.dart';
import '../../data/models/learning.dart';
import '../../features/learning/exam_form_screen.dart';
import '../../features/learning/learning_dashboard_screen.dart';
import '../../features/learning/manage_exams_screen.dart';
import '../../features/learning/manage_signs_screen.dart';
import '../../features/learning/quiz_screen.dart';
import '../../features/learning/rules_screen.dart';
import '../../features/learning/sign_form_screen.dart';
import '../../features/learning/signs_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reservations/my_reservations_screen.dart';
import '../../features/reservations/reservation_details_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../state/auth_provider.dart';

/// Chemins centralisés pour éviter les chaînes dispersées dans les écrans.
class Routes {
  Routes._();

  static const onboarding = '/bienvenue';
  static const login = '/connexion';
  static const register = '/inscription';
  static const forgotPassword = '/mot-de-passe-oublie';

  static const home = '/accueil';
  static const catalog = '/catalogue';
  static const manageCars = '/catalogue/gerer';
  static const auctions = '/encheres';
  static const learning = '/code-de-la-route';
  static const profile = '/profil';

  static const editProfile = '/profil/modifier';
  static const cart = '/panier';
  static const checkout = '/paiement';
  static const confirmation = '/confirmation';
  static const reservations = '/mes-reservations';
  static const myAuctions = '/mes-encheres';
  static const fleet = '/gestion-flotte';
  static const signs = '/code-de-la-route/panneaux';
  static const manageSigns = '/code-de-la-route/panneaux/gerer';
  static const manageExams = '/code-de-la-route/examens/gerer';
  static const rules = '/code-de-la-route/regles';

  static String car(String id) => '/voiture/$id';
  static String auction(String id) => '/enchere/$id';
  static String auctionResult(String id) => '/enchere/$id/resultat';
  static String quiz(String id) => '/code-de-la-route/quiz/$id';
  static String reservation(String id) => '/mes-reservations/$id';
  static String contract(String id) => '/contrat/$id';
  static String receipt(String id) => '/recu/$id';

  /// Formulaire create (`id` null) ou update.
  static String signForm({String? id, SignCategory? category}) {
    if (id != null) {
      return '/code-de-la-route/panneaux/$id/modifier';
    }
    final q = category == null ? '' : '?categorie=${category.name}';
    return '/code-de-la-route/panneaux/nouveau$q';
  }

  static String examForm({String? id}) {
    if (id != null) return '/code-de-la-route/examens/$id/modifier';
    return '/code-de-la-route/examens/nouveau';
  }

  static String carForm({String? id}) {
    if (id != null) return '/catalogue/$id/modifier';
    return '/catalogue/nouveau';
  }
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.onboarding,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final path = state.matchedLocation;
      const publicPaths = {
        Routes.onboarding,
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
      };
      final isPublic = publicPaths.contains(path);

      if (!loggedIn && !isPublic) return Routes.onboarding;
      if (loggedIn && isPublic) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Routes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),

      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) =>
            MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: Routes.catalog,
            pageBuilder: (_, state) => NoTransitionPage(
              child: CatalogScreen(
                initialCategory: state.uri.queryParameters['categorie'],
                initialQuery: state.uri.queryParameters['q'],
              ),
            ),
          ),
          GoRoute(
            path: Routes.auctions,
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: AuctionsScreen()),
          ),
          GoRoute(
            path: Routes.learning,
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: LearningDashboardScreen()),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      GoRoute(
        path: Routes.manageCars,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ManageCarsScreen(),
      ),
      GoRoute(
        path: '/catalogue/nouveau',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CarFormScreen(),
      ),
      GoRoute(
        path: '/catalogue/:id/modifier',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => CarFormScreen(
          carId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/voiture/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            CarDetailsScreen(carId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.cart,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CartScreen(),
      ),
      GoRoute(
        path: Routes.checkout,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: Routes.confirmation,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ConfirmationScreen(
          reservations: (state.extra as List<Reservation>?) ?? const [],
        ),
      ),
      GoRoute(
        path: Routes.reservations,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const MyReservationsScreen(),
      ),
      GoRoute(
        path: '/mes-reservations/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ReservationDetailsScreen(reservationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/contrat/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ContractScreen(reservationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/recu/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ReceiptScreen(reservationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.editProfile,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.signs,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SignsScreen(),
      ),
      GoRoute(
        path: Routes.manageSigns,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ManageSignsScreen(),
      ),
      GoRoute(
        path: '/code-de-la-route/panneaux/nouveau',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final raw = state.uri.queryParameters['categorie'];
          SignCategory? category;
          if (raw != null) {
            for (final c in SignCategory.values) {
              if (c.name == raw) {
                category = c;
                break;
              }
            }
          }
          return SignFormScreen(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/code-de-la-route/panneaux/:id/modifier',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => SignFormScreen(
          signId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: Routes.manageExams,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ManageExamsScreen(),
      ),
      GoRoute(
        path: '/code-de-la-route/examens/nouveau',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ExamFormScreen(),
      ),
      GoRoute(
        path: '/code-de-la-route/examens/:id/modifier',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ExamFormScreen(
          examId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: Routes.rules,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const RulesScreen(),
      ),
      GoRoute(
        path: '/code-de-la-route/quiz/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => QuizScreen(quizId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/enchere/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            AuctionDetailsScreen(auctionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/enchere/:id/resultat',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            AuctionResultScreen(auctionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.myAuctions,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const MyAuctionsScreen(),
      ),
      GoRoute(
        path: Routes.fleet,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const FleetManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(
      location: state.uri.toString(),
    ),
  );
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                "La page « $location » n'existe pas.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go(Routes.home),
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
