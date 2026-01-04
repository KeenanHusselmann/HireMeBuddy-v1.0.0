import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Supabase configuration using environment variables
/// 
/// Configuration is loaded from:
/// - Hardcoded values for web builds (anon key is safe to expose)
/// - .env file for mobile/desktop builds
class SupabaseConfig {
  // Private constructor to prevent instantiation
  SupabaseConfig._();

  // Web deployment constants (anon key is public and safe to expose)
  static const String _webSupabaseUrl = 'https://vjpaolkqlumpyuxxmmvr.supabase.co';
  static const String _webSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5MTY3ODEsImV4cCI6MjA2ODQ5Mjc4MX0.irmIx87eljdUN5zdu3IH5aQbUxAgGbjS8d4ENgBg2Tc';

  /// Supabase project URL (from web constants or .env)
  static String get supabaseUrl {
    if (kIsWeb) {
      return _webSupabaseUrl;
    }
    return dotenv.env['SUPABASE_URL'] ?? _throwMissingEnv('SUPABASE_URL');
  }

  /// Supabase anon/public API key (from web constants or .env)
  static String get supabaseAnonKey {
    if (kIsWeb) {
      return _webSupabaseAnonKey;
    }
    return dotenv.env['SUPABASE_ANON_KEY'] ?? _throwMissingEnv('SUPABASE_ANON_KEY');
  }

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
