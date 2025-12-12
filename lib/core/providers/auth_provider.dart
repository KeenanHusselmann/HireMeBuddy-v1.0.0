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

// User Profile Provider
// This provider automatically refreshes when the current user changes
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Watch the currentUserProvider to automatically refresh when user changes
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  
  if (user == null) return null;
  
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserProfile(user.id);
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
    required String fullName,
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
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
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
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
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
}
