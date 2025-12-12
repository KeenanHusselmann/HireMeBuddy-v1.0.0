import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for the Supabase client instance
/// 
/// This provider gives you access to the initialized Supabase client
/// throughout your application. Usage:
/// `dart
/// final supabase = ref.watch(supabaseClientProvider);
/// final data = await supabase.from('profiles').select();
/// `
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the current authenticated user
/// 
/// Returns null if no user is authenticated.
/// This provider automatically updates when auth state changes.
final currentUserProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange.map((state) => state.session?.user);
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
