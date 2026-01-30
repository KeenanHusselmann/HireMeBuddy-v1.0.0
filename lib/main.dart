import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'core/config/supabase_config.dart';
import 'core/config/app_router.dart';
import 'core/config/provider_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/push_notification_service.dart';

// Detect which app flavor is running from compile-time constant
const String appFlavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'client');

void main() async {
  // Set up global error handlers BEFORE initializing bindings
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Initialize bindings in the main zone
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🚀 Launching $appFlavor app...');
  
  // Load environment variables (handle missing file gracefully)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found, using default configuration');
    // Initialize dotenv with empty map to prevent NotInitializedError
    dotenv.testLoad(fileInput: '');
  }

  // Initialize Firebase (for FCM, analytics, etc.)
  await Firebase.initializeApp();

  // Initialize Supabase FIRST (before push notifications need it)
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );

  // Initialize push + local notifications AFTER Supabase
  await NotificationService().initialize();
  await PushNotificationService().init();

  // Run app with appropriate flavor
  runApp(
    ProviderScope(
      child: appFlavor == 'provider' 
        ? const HireMeBuddyProviderApp() 
        : const HireMeBuddyApp(),
    ),
  );
}

class HireMeBuddyApp extends ConsumerStatefulWidget {
  const HireMeBuddyApp({super.key});

  @override
  ConsumerState<HireMeBuddyApp> createState() => _HireMeBuddyAppState();
}

class _HireMeBuddyAppState extends ConsumerState<HireMeBuddyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check for password recovery session on app start
    _checkForRecoverySession();

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle initial link when app is launched from deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }

    // Also listen to auth state changes for password recovery
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('Auth event: $event');
      if (event == AuthChangeEvent.passwordRecovery) {
        final router = ref.read(AppRouter.provider);
        router.go('/reset-password');
      }
    });
  }

  Future<void> _checkForRecoverySession() async {
    // Wait for Supabase to fully initialize
    await Future.delayed(const Duration(seconds: 2));
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      // Check if this is a recovery session
      final recoveryToken = user.userMetadata?['recovery_token'];
      final recoverySentAt = session.user.recoverySentAt;
      
      debugPrint('Session found: user=${user.email}, recoveryToken=$recoveryToken, recoverySentAt=$recoverySentAt');
      
      if (recoveryToken != null || recoverySentAt != null) {
        debugPrint('Recovery session detected! Navigating to reset password');
        final router = ref.read(AppRouter.provider);
        router.go('/reset-password');
      }
    } else {
      debugPrint('No session found on app start');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');
    
    // Check if it's a password reset link
    if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
      final router = ref.read(AppRouter.provider);
      router.go('/reset-password');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.provider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'HireMeBuddy',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Routing configuration
      routerConfig: router,
    );
  }
}

// Provider App (same as HireMeBuddyApp but uses ProviderAppRouter)
class HireMeBuddyProviderApp extends ConsumerStatefulWidget {
  const HireMeBuddyProviderApp({super.key});

  @override
  ConsumerState<HireMeBuddyProviderApp> createState() => _HireMeBuddyProviderAppState();
}

class _HireMeBuddyProviderAppState extends ConsumerState<HireMeBuddyProviderApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check for password recovery session on app start
    _checkForRecoverySession();

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle initial link when app is launched from deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }

    // Also listen to auth state changes for password recovery
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('Auth event: $event');
      if (event == AuthChangeEvent.passwordRecovery) {
        final router = ref.read(ProviderAppRouter.provider);
        router.go('/reset-password');
      }
    });
  }

  Future<void> _checkForRecoverySession() async {
    // Wait for Supabase to fully initialize
    await Future.delayed(const Duration(seconds: 2));
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      final recoveryToken = user.userMetadata?['recovery_token'];
      final recoverySentAt = session.user.recoverySentAt;
      
      debugPrint('Session found: user=${user.email}, recoveryToken=$recoveryToken, recoverySentAt=$recoverySentAt');
      
      if (recoveryToken != null || recoverySentAt != null) {
        debugPrint('Recovery session detected! Navigating to reset password');
        final router = ref.read(ProviderAppRouter.provider);
        router.go('/reset-password');
      }
    } else {
      debugPrint('No session found on app start');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');
    
    // Check if it's a password reset link
    if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
      final router = ref.read(ProviderAppRouter.provider);
      router.go('/reset-password');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(ProviderAppRouter.provider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'HireMeBuddy Provider',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Routing configuration
      routerConfig: router,
    );
  }
}
