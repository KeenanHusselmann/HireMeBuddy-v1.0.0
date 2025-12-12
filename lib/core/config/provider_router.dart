import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/provider/screens/provider_splash_screen.dart';
import '../../features/provider/screens/provider_login_screen.dart';
import '../../features/provider/screens/provider_signup_screen.dart';
import '../../features/provider/screens/provider_registration_screen.dart';
import '../../features/provider/screens/provider_dashboard_screen.dart';
import '../../features/provider/screens/add_service_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

/// Helper class to refresh GoRouter when stream changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider App routing configuration
class ProviderAppRouter {
  ProviderAppRouter._();

  static final Provider<GoRouter> provider = Provider<GoRouter>((ref) {
    return GoRouter(
      initialLocation: '/provider-splash',
      debugLogDiagnostics: false, // Disable debug logs to reduce noise
      refreshListenable: GoRouterRefreshStream(ref.watch(currentUserProvider.stream)),
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);
        final isAuthenticated = authState.status == AuthStatus.authenticated;
        final isAuthRoute = state.matchedLocation == '/provider-login' || 
                           state.matchedLocation == '/provider-signup';
        final isSplash = state.matchedLocation == '/provider-splash';
        final isRegistration = state.matchedLocation == '/provider-registration';
        final isDashboard = state.matchedLocation == '/provider-dashboard';

        // Skip redirect on splash screen
        if (isSplash) return null;

        // Allow authenticated users to access registration page
        if (isAuthenticated && isRegistration) return null;
        
        // Allow navigation to dashboard (don't block it)
        if (isAuthenticated && isDashboard) return null;

        // Redirect to dashboard if authenticated and trying to access auth pages
        if (isAuthenticated && isAuthRoute) {
          return '/provider-dashboard';
        }

        // Redirect to login if not authenticated and trying to access protected pages
        if (!isAuthenticated && !isAuthRoute && !isSplash && !isRegistration) {
          return '/provider-login';
        }

        return null;
      },
      routes: [
        // Provider Splash Screen
        GoRoute(
          path: '/provider-splash',
          name: 'provider-splash',
          builder: (context, state) => const ProviderSplashScreen(),
        ),

        // Provider Authentication routes
        GoRoute(
          path: '/provider-login',
          name: 'provider-login',
          builder: (context, state) => const ProviderLoginScreen(),
        ),
        GoRoute(
          path: '/provider-signup',
          name: 'provider-signup',
          builder: (context, state) => const ProviderSignupScreen(),
        ),

        // Provider Dashboard
        GoRoute(
          path: '/provider-dashboard',
          name: 'provider-dashboard',
          builder: (context, state) => const ProviderDashboardScreen(),
        ),

        // Provider Registration
        GoRoute(
          path: '/provider-registration',
          name: 'provider-registration',
          builder: (context, state) => const ProviderRegistrationScreen(),
        ),

        // Add Service
        GoRoute(
          path: '/add-service',
          name: 'add-service',
          builder: (context, state) => const AddServiceScreen(),
        ),

        // Profile
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
      
      // Error page
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Page not found: ${state.matchedLocation}'),
        ),
      ),
    );
  });
}
