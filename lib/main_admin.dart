import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/supabase_config.dart';
import 'features/admin/screens/admin_login_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

void main() async {
  // Initialize bindings first
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env file not found, using empty configuration');
    dotenv.testLoad(fileInput: '');
  }

  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Run admin app
  runApp(
    const ProviderScope(
      child: AdminApp(),
    ),
  );
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  String _initialLocation = '/admin-login';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Check if there's an active Supabase session
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // Verify user is an admin
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .maybeSingle();
        
        // CRITICAL: If user is NOT an admin, sign them out
        if (profile != null && profile['role'] == 'admin') {
          if (mounted) {
            setState(() {
              _initialLocation = '/admin-dashboard';
            });
          }
          return;
        } else {
          // User has wrong role, sign them out
          debugPrint('⚠️ User has role=${profile?['role']}, signing out from ADMIN app');
          await Supabase.instance.client.auth.signOut();
        }
      } catch (e) {
        debugPrint('Error checking admin profile: $e');
        await Supabase.instance.client.auth.signOut();
      }
    }
    
    // No valid session, clear preferences and go to login
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_logged_in');
    await prefs.remove('admin_email');
    
    if (mounted) {
      setState(() {
        _initialLocation = '/admin-login';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: _initialLocation,
      routes: [
        GoRoute(
          path: '/admin-login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'HireMeBuddy - Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C3E50),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
      ),
      routerConfig: router,
    );
  }
}
