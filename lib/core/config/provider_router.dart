import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../features/provider/screens/provider_splash_screen.dart';
import '../../features/provider/screens/provider_login_screen.dart';
import '../../features/provider/screens/provider_signup_screen.dart';
import '../../features/provider/screens/provider_registration_screen.dart';
import '../../features/provider/screens/add_service_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/terms_and_conditions_screen.dart';
import '../../features/auth/screens/privacy_policy_screen.dart';
import '../../shared/widgets/provider_bottom_nav.dart';

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
      redirect: (context, state) async {
        final authState = ref.read(authStateProvider);
        final isAuthenticated = authState.status == AuthStatus.authenticated;
        final isAuthRoute = state.matchedLocation == '/provider-login' || 
                           state.matchedLocation == '/provider-signup' ||
                           state.matchedLocation == '/forgot-password' ||
                           state.matchedLocation == '/reset-password';
        final isSplash = state.matchedLocation == '/provider-splash';
        final isRegistration = state.matchedLocation == '/provider-registration';
        final isDashboard = state.matchedLocation == '/provider-dashboard';

        // Skip redirect on splash screen
        if (isSplash) return null;

        // IMMEDIATE REDIRECT: If not authenticated, go to login (don't do DB lookups)
        if (!isAuthenticated && !isAuthRoute && !isSplash) {
          return '/provider-login';
        }

        // CRITICAL: Validate user role for PROVIDER app (only when authenticated)
        if (isAuthenticated) {
          try {
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              final profile = await Supabase.instance.client
                  .from('profiles')
                  .select('role')
                  .eq('id', session.user.id)
                  .maybeSingle();
              
              // If user is NOT a provider, sign them out and redirect to login
              if (profile != null && profile['role'] != 'provider') {
                debugPrint('⚠️ User has role=${profile['role']}, signing out from PROVIDER app');
                await Supabase.instance.client.auth.signOut();
                return '/provider-login';
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error checking user role: $e');
          }
        }

        // Allow authenticated users to access registration page
        if (isAuthenticated && isRegistration) return null;
        
        // Allow navigation to dashboard (don't block it)
        if (isAuthenticated && isDashboard) return null;

        // Redirect to dashboard if authenticated and trying to access auth pages
        if (isAuthenticated && isAuthRoute) {
          return '/provider-dashboard';
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
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),

        // Provider Dashboard
        GoRoute(
          path: '/provider-dashboard',
          name: 'provider-dashboard',
          builder: (context, state) => const ProviderBottomNav(),
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

        // Terms and Conditions
        GoRoute(
          path: '/terms-and-conditions',
          name: 'terms-and-conditions',
          builder: (context, state) => const TermsAndConditionsScreen(),
        ),

        // Privacy Policy
        GoRoute(
          path: '/privacy-policy',
          name: 'privacy-policy',
          builder: (context, state) => const PrivacyPolicyScreen(),
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
