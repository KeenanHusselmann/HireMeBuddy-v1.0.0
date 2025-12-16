import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/supabase_config.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'shared/services/notification_service.dart';

void main() async {
  // Set up global error handlers BEFORE initializing bindings
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Initialize bindings in the main zone
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (handle missing file gracefully)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found, using default configuration');
    // Initialize dotenv with empty map to prevent NotInitializedError
    dotenv.testLoad(fileInput: '');
  }

  // Initialize Supabase with real-time enabled
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );

  // Run app with async error handling
  runZonedGuarded(
    () => runApp(
      const ProviderScope(
        child: HireMeBuddyApp(),
      ),
    ),
    (error, stack) {
      debugPrint('Async Error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

class HireMeBuddyApp extends ConsumerWidget {
  const HireMeBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(AppRouter.provider);
    final themeMode = ref.watch(themeModeProvider);
    
    // Set up navigation callback for notifications (idempotent)
    NotificationService.setNavigateToMessagesCallback(() {
      router.go('/messages');
    });
    
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
