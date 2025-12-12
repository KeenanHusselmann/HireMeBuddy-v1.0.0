import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/services/screens/home_screen.dart';
import '../../features/services/screens/service_list_screen.dart';
import '../../features/services/screens/provider_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/provider/screens/provider_splash_screen.dart';
import '../../features/provider/screens/provider_login_screen.dart';
import '../../features/provider/screens/provider_signup_screen.dart';
import '../../features/provider/screens/provider_registration_screen.dart';
import '../../features/provider/screens/provider_dashboard_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_login_screen.dart';

// Provider Detail Loader widget
class ProviderDetailLoader extends StatelessWidget {
  final String providerId;

  const ProviderDetailLoader({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading...')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProviderData(providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(child: Text('Provider not found'));
          }
          
          return ProviderDetailScreen(provider: snapshot.data!);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchProviderData(String providerId) async {
    final supabase = Supabase.instance.client;
    
    final response = await supabase
        .from('provider_profiles')
        .select('''
          *,
          profiles!inner(
            id,
            full_name,
            avatar_url,
            contact_number
          )
        ''')
        .eq('id', providerId)
        .single();
    
    return response;
  }
}

/// App routing configuration using GoRouter
/// 
/// This handles all navigation within the app including
/// authenticated and unauthenticated routes
class AppRouter {
  AppRouter._();

  static final Provider<GoRouter> provider = Provider<GoRouter>((ref) {
    final authState = ref.watch(authStateProvider);
    
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final isAuthenticated = authState.status == AuthStatus.authenticated;
        final isAuthRoute = state.matchedLocation == '/login' || 
                           state.matchedLocation == '/signup';
        final isSplash = state.matchedLocation == '/';

        // Skip redirect on splash screen
        if (isSplash) return null;

        // Redirect to home if authenticated and trying to access auth pages
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        // Redirect to login if not authenticated and trying to access protected pages
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Home/Landing
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),

        // Authentication routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),

        // Services
        GoRoute(
          path: '/services',
          name: 'services',
          builder: (context, state) => const ServiceListScreen(),
        ),

        // Provider Detail
        GoRoute(
          path: '/provider-detail/:providerId',
          name: 'provider-detail',
          builder: (context, state) {
            final providerId = state.pathParameters['providerId']!;
            final providerData = state.extra as Map<String, dynamic>?;
            
            if (providerData != null) {
              // If provider data is passed, use it directly
              return ProviderDetailScreen(provider: providerData);
            } else {
              // Otherwise, show a loading screen and fetch the provider data
              return ProviderDetailLoader(providerId: providerId);
            }
          },
        ),

        // Profile
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // Provider routes
        GoRoute(
          path: '/provider-splash',
          name: 'provider-splash',
          builder: (context, state) => const ProviderSplashScreen(),
        ),
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
          path: '/provider-registration',
          name: 'provider-registration',
          builder: (context, state) => const ProviderRegistrationScreen(),
        ),
        GoRoute(
          path: '/provider-dashboard',
          name: 'provider-dashboard',
          builder: (context, state) => const ProviderDashboardScreen(),
        ),

        // Admin routes
        GoRoute(
          path: '/admin-login',
          name: 'admin-login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/admin-dashboard',
          name: 'admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
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
