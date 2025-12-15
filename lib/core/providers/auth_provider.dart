import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/services/auth_service.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current User Provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
});

// User Profile Provider - Real-time updates
// This provider automatically refreshes when the profile changes in the database
final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  
  if (user == null) {
    yield null;
    return;
  }
  
  final supabase = Supabase.instance.client;
  
  // Stream the profile for real-time updates
  await for (final profiles in supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)) {
    
    if (profiles.isEmpty) {
      yield null;
    } else {
      yield UserProfile.fromJson(profiles.first);
    }
  }
});

// Auth State Provider (for UI convenience)
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authServiceProvider));
});

// Auth State Model
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// Auth State Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService)
      : super(AuthState(status: AuthStatus.initial)) {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((authState) {
      if (authState.session?.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: authState.session!.user,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  // Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String role = 'client', // Default role is client
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      print('AuthStateNotifier: Starting signup for $email with role: $role');
      
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        role: role,
      );

      print('AuthStateNotifier: Signup response - User ID: ${response.user?.id}');
      print('AuthStateNotifier: Signup response - Session: ${response.session != null}');

      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        print('AuthStateNotifier: Signup successful');
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sign up failed - no user returned',
        );
        print('AuthStateNotifier: Signup failed - no user');
        return false;
      }
    } catch (e) {
      print('AuthStateNotifier: Signup error - $e');
      final errorMessage = _parseAuthError(e);
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      );
      return false;
    }
  }

  // Sign In
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      print('AuthStateNotifier: Attempting sign in for $email');
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      print('AuthStateNotifier: Response user = ${response.user?.id}');
      print('AuthStateNotifier: Response session = ${response.session?.accessToken != null}');

      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        print('AuthStateNotifier: Sign in successful');
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sign in failed',
        );
        print('AuthStateNotifier: Sign in failed - no user');
        return false;
      }
    } catch (e) {
      print('AuthStateNotifier: Sign in error = $e');
      final errorMessage = _parseAuthError(e);
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMessage,
      );
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  // Parse authentication errors into user-friendly messages
  String _parseAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid login credentials') || 
        errorString.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    } else if (errorString.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    } else if (errorString.contains('user already registered')) {
      return 'An account with this email already exists.';
    } else if (errorString.contains('invalid email')) {
      return 'Please enter a valid email address.';
    } else if (errorString.contains('password') && errorString.contains('short')) {
      return 'Password must be at least 6 characters long.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (errorString.contains('phone number is required')) {
      return 'Phone number is required for registration.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    } else {
      // Generic fallback
      return 'An error occurred. Please try again.';
    }
  }
}
