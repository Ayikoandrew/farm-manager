import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/animal.dart';
import 'routes.dart';

late final AppCoordinator coordinator;

const String _hasSeenLandingKey = 'has_seen_landing_page';

void initRouter() {
  coordinator = AppCoordinator();
}

Future<bool> hasSeenLandingPage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_hasSeenLandingKey) ?? false;
}

/// Mark that user has seen the landing page
Future<void> markLandingPageSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_hasSeenLandingKey, true);
}

// Base class for all routes with URI support
abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context);
}

// Landing Page Route - /welcome
class LandingRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/welcome');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    // Mark as seen when landing page is shown
    markLandingPageSeen();
    return const LandingPage();
  }
}

// Dashboard Route - /
class DashboardRoute extends AppRoute {
  final bool showCreateFarmDialog;

  DashboardRoute({this.showCreateFarmDialog = false});

  @override
  Uri toUri() =>
      Uri.parse('/${showCreateFarmDialog ? "?create_farm=true" : ""}');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return AuthWrapper(
      child: DashboardScreen(showCreateFarmDialog: showCreateFarmDialog),
    );
  }
}

// Animals List Route - /animals
class AnimalsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/animals');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: AnimalsScreen());
  }
}

// Animal Detail Route - /animals/:id
class AnimalDetailRoute extends AppRoute {
  final Animal animal;

  AnimalDetailRoute({required this.animal});

  @override
  Uri toUri() => Uri.parse('/animals/${animal.id}');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return AuthWrapper(child: AnimalDetailScreen(animal: animal));
  }
}

// Feeding Route - /feeding
class FeedingRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/feeding');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: FeedingScreen());
  }
}

// Weight Route - /weight
class WeightRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/weight');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: WeightScreen());
  }
}

// Breeding Route - /breeding
class BreedingRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/breeding');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: BreedingScreen());
  }
}

// Health Route - /health
class HealthRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/health');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: HealthScreen());
  }
}

// Financial Route - /financial
class FinancialRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/financial');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: FinancialScreen());
  }
}

// Budget Route - /budget
class BudgetRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/budget');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: BudgetScreen());
  }
}

// ML Analytics Route - /ml
class MLRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/ml');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: MLAnalyticsScreen());
  }
}

// Reports Route - /reports
class ReportsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/reports');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: ReportsScreen());
  }
}

// Assistant Route - /assistant
class AssistantRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/assistant');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: AssistantScreen());
  }
}

// Notifications Route - /notifications
class NotificationsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/notifications');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: NotificationsScreen());
  }
}

// Documentation Route - /docs (web only, no auth required)
class DocumentationRoute extends AppRoute {
  final String? section;

  DocumentationRoute({this.section});

  @override
  Uri toUri() =>
      Uri.parse('/docs${section != null ? "?section=$section" : ""}');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return DocumentationScreen(initialSection: section);
  }
}

// Auth Routes
// Login Route - /login
class LoginRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/login');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const LoginScreen();
  }
}

// Register Route - /register
class RegisterRoute extends AppRoute {
  final bool hasInviteCode;

  RegisterRoute({this.hasInviteCode = false});

  @override
  Uri toUri() => Uri.parse('/register${hasInviteCode ? "?invite=true" : ""}');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return RegisterScreen(hasInviteCode: hasInviteCode);
  }
}

// Forgot Password Route - /forgot-password
class ForgotPasswordRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/forgot-password');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const ForgotPasswordScreen();
  }
}

// Profile Route - /profile
class ProfileRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/profile');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: ProfileScreen());
  }
}

// Settings Route - /settings
class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: SettingsScreen());
  }
}

// Wallet Route - /payments/wallet
class WalletRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/payments/wallet');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: WalletScreen());
  }
}

// Send Money Route - /payments/send
class SendMoneyRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/payments/send');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: SendMoneyScreen());
  }
}

// Receive Money Route - /payments/receive
class ReceiveMoneyRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/payments/receive');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: ReceiveMoneyScreen());
  }
}

// Payment History Route - /payments/history
class PaymentHistoryRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/payments/history');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return const AuthWrapper(child: PaymentHistoryScreen());
  }
}

// Not Found Route - 404
class NotFoundRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/404');

  @override
  Widget build(Coordinator<AppRoute> coord, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.replace(DashboardRoute()),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// App Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    final segments = uri.pathSegments;
    final queryParams = uri.queryParameters;

    return switch (segments) {
      [] => DashboardRoute(
        showCreateFarmDialog: queryParams['create_farm'] == 'true',
      ),
      ['welcome'] => LandingRoute(),
      ['login'] => LoginRoute(),
      ['register'] => RegisterRoute(
        hasInviteCode: queryParams['invite'] == 'true',
      ),
      ['forgot-password'] => ForgotPasswordRoute(),
      ['profile'] => ProfileRoute(),
      ['settings'] => SettingsRoute(),
      ['animals'] => AnimalsRoute(),
      ['animals', _] => AnimalsRoute(), // Fallback to list for deep links
      ['feeding'] => FeedingRoute(),
      ['weight'] => WeightRoute(),
      ['breeding'] => BreedingRoute(),
      ['health'] => HealthRoute(),
      ['financial'] => FinancialRoute(),
      ['budget'] => BudgetRoute(),
      ['ml'] => MLRoute(),
      ['reports'] => ReportsRoute(),
      ['assistant'] => AssistantRoute(),
      ['docs'] => DocumentationRoute(section: queryParams['section']),
      ['payments', 'wallet'] => WalletRoute(),
      ['payments', 'send'] => SendMoneyRoute(),
      ['payments', 'receive'] => ReceiveMoneyRoute(),
      ['payments', 'history'] => PaymentHistoryRoute(),
      _ => NotFoundRoute(),
    };
  }
}
