import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration using environment variables
/// 
/// Configuration is loaded from .env file for security.
/// Never commit credentials directly to source control.
class SupabaseConfig {
  // Private constructor to prevent instantiation
  SupabaseConfig._();

  /// Supabase project URL (loaded from environment)
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? 'https://vjpaolkqlumpyuxxmmvr.supabase.co';

  /// Supabase anon/public API key (loaded from environment)
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5MTY3ODEsImV4cCI6MjA2ODQ5Mjc4MX0.irmIx87eljdUN5zdu3IH5aQbUxAgGbjS8d4ENgBg2Tc';

  /// Supabase project ID (extracted from URL)
  static String get projectId {
    final url = supabaseUrl;
    final match = RegExp(r'https://([^.]+)\.').firstMatch(url);
    return match?.group(1) ?? '';
  }
  
  /// Helper method to throw error for missing environment variables
  static String _throwMissingEnv(String key) {
    throw Exception(
      'Missing environment variable: $key. '
      'Please ensure .env file exists and contains $key'
    );
  }
}
