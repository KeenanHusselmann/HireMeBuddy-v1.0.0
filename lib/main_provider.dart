import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/supabase_config.dart';
import 'core/config/provider_router.dart';

void main() async {
  // Initialize bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (handle missing file gracefully)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found, using default configuration');
    // Initialize dotenv with empty map to prevent NotInitializedError
    dotenv.testLoad(fileInput: '');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Run app with async error handling
  runZonedGuarded(
    () => runApp(const ProviderScope(child: ProviderApp())),
    (error, stack) {
      debugPrint('Async Error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

class ProviderApp extends ConsumerWidget {
  const ProviderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(ProviderAppRouter.provider);

    return MaterialApp.router(
      title: 'HireMeBuddy Provider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        primaryColor: Colors.deepOrange.shade600,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          primary: Colors.deepOrange.shade600,
          secondary: Colors.orange.shade500,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepOrange.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
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
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
