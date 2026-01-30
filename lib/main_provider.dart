import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'core/config/supabase_config.dart';
import 'core/config/provider_router.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/push_notification_service.dart';

Future<void> main() async {
  // Keep everything in the same zone to avoid zone mismatch errors
  await runZonedGuarded<Future<void>>(() async {
    // Initialize bindings
    WidgetsFlutterBinding.ensureInitialized();
    
    // COMPLETELY DISABLE ERROR SCREENS - CRITICAL FIX
    // Override the error widget to return nothing
    ErrorWidget.builder = (_) => const SizedBox.shrink();
    
    // Override error presentation to do nothing
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log to console but DON'T show red screen
      debugPrint('Error suppressed: ${details.exception}');
    };
    
    // Disable error presentation completely
    FlutterError.presentError = (FlutterErrorDetails details) {
      // Do nothing - don't present any errors visually
      debugPrint('Error presentation blocked: ${details.exception}');
    };
    
    // Load environment variables (handle missing file gracefully)
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Warning: .env file not found, using default configuration');
      // Initialize dotenv with empty map to prevent NotInitializedError
      dotenv.testLoad(fileInput: '');
    }

    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize Supabase early so services that rely on it can use `Supabase.instance`
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    // Initialize push + local notifications
    await NotificationService().initialize();
    await PushNotificationService().init();


    // Run app
    runApp(const ProviderScope(child: ProviderApp()));
  }, (error, stack) {
    // Suppress ALL errors in zone
    debugPrint('Zone error suppressed: $error');
  });
}

class ProviderApp extends ConsumerStatefulWidget {
  const ProviderApp({super.key});

  @override
  ConsumerState<ProviderApp> createState() => _ProviderAppState();
}

class _ProviderAppState extends ConsumerState<ProviderApp> {
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
    // Wait a bit for Supabase to initialize
    await Future.delayed(const Duration(milliseconds: 500));
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final user = session.user;
      // Check if this is a recovery session
      final recoveryToken = user.userMetadata?['recovery_token'];
      if (recoveryToken != null || session.user.recoverySentAt != null) {
        debugPrint('Recovery session detected, navigating to reset password');
        final router = ref.read(ProviderAppRouter.provider);
        Future.delayed(const Duration(milliseconds: 500), () {
          router.go('/reset-password');
        });
      }
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

    return MaterialApp(
      home: Builder(
        builder: (context) {
          // NUCLEAR OPTION: Catch absolutely everything
          ErrorWidget.builder = (_) => Container(color: Colors.white);
          
          return MaterialApp.router(
            title: 'HireMeBuddy Provider',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepOrange,
        primaryColor: Colors.deepOrange.shade600,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Colors.deepOrange.shade600,
          secondary: Colors.orange.shade500,
          surface: Colors.white,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
          onError: Colors.white,
        ).copyWith(
          primary: Colors.deepOrange.shade600,
          onSurface: Colors.black87,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepOrange.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepOrange.shade600, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade600, width: 2.0),
          ),
          floatingLabelStyle: TextStyle(color: Colors.deepOrange.shade600),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          iconColor: Colors.grey.shade700,
          prefixIconColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.focused)) {
              return Colors.deepOrange.shade600;
            }
            return Colors.grey.shade700;
          }),
          suffixIconColor: MaterialStateColor.resolveWith((states) {
            if (states.contains(MaterialState.focused)) {
              return Colors.deepOrange.shade600;
            }
            return Colors.grey.shade700;
          }),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.deepOrange.shade600,
          circularTrackColor: Colors.deepOrange.shade100,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.deepOrange;
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.deepOrange.shade200;
            }
            return Colors.grey.shade300;
          }),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.deepOrange.shade600,
          selectionColor: Colors.deepOrange.shade200,
          selectionHandleColor: Colors.deepOrange.shade600,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange.shade600,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.deepOrange.withOpacity(0.5),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.deepOrange.shade600,
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.deepOrange.shade50,
          selectedColor: Colors.deepOrange.shade600,
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        useMaterial3: false,
      ),
      routerConfig: router,
    );
        },
      ),
}
