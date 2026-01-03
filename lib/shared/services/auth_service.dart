import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/user_profile.dart';
import '../../core/utils/logger.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _logger = AppLogger();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Check if user is logged in
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');
      
      // Supabase automatically sends verification email on signup
      // This forces a resend of the verification email
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
      _logger.info('Email verification sent to: ${user.email}');
    } catch (e) {
      _logger.error('Error sending email verification', e);
      rethrow;
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');
      
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
      _logger.info('Verification email resent to: ${user.email}');
    } catch (e) {
      _logger.error('Error resending verification email', e);
      rethrow;
    }
  }

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  // Request password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'hiremebuddy://reset-password',
      );
      _logger.info('Password reset email sent to: $email');
    } catch (e) {
      _logger.error('Error sending password reset email', e);
      rethrow;
    }
  }

  // Update password (after reset)
  Future<void> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (response.user == null) {
        throw Exception('Failed to update password');
      }
      _logger.info('Password updated successfully');
    } catch (e) {
      _logger.error('Error updating password', e);
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String role = 'client', // Default role is client
  }) async {
    print('AuthService: Starting Supabase signup for $email with role: $role');
    
    // Determine full name from firstName and lastName if not provided
    final String nameToUse = fullName ?? '${firstName ?? ''} ${lastName ?? ''}'.trim();
    
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': nameToUse,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'role': role,
        },
        emailRedirectTo: null,
      );

      print('AuthService: Supabase signup response - User: ${response.user?.id}, Session: ${response.session != null}');
      print('AuthService: User metadata: ${response.user?.userMetadata}');

      // Create or update profile in profiles table ONLY if signup succeeded
      if (response.user != null && response.session != null) {
        print('AuthService: ========================================');
        print('AuthService: CREATING PROFILE IN profiles TABLE');
        print('AuthService: User ID: ${response.user!.id}');
        print('AuthService: Full Name: $nameToUse');
        print('AuthService: First Name: $firstName');
        print('AuthService: Last Name: $lastName');
        print('AuthService: Phone: $phoneNumber');
        print('AuthService: Role: $role');
        print('AuthService: ========================================');
        
        try {
          // Create profile directly - don't wait for trigger since migrations may not be executed
          int retries = 5;
          Exception? lastError;
          
          for (int i = 0; i < retries; i++) {
            try {
              print('AuthService: Attempt ${i + 1}/$retries to create profile...');
              
              // Use upsert to handle both new profiles and updates
              final profileData = {
                'id': response.user!.id,
                'user_id': response.user!.id,  // Required by database
                'full_name': nameToUse,
                'first_name': firstName,
                'last_name': lastName,
                'email': email,  // Store email in profiles table
                'role': role,
              };
              
              // Add phone number if provided
              if (phoneNumber != null && phoneNumber.isNotEmpty) {
                profileData['phone'] = phoneNumber;  // Fixed: use 'phone' instead of 'contact_number'
              }
              
              print('AuthService: Profile data to insert: $profileData');
              
              final insertResult = await _supabase.from('profiles').upsert(
                profileData,
                onConflict: 'id',
              ).select();
              
              print('AuthService: ✅✅✅ INSERT RESULT: $insertResult');
              print('AuthService: ✅ Profile created/updated successfully');
              print('AuthService: Profile data - ID: ${response.user!.id}, Name: $nameToUse, Role: $role');
              
              // Verify the profile was created
              final verify = await _supabase
                  .from('profiles')
                  .select('id, full_name, first_name, last_name, role')
                  .eq('id', response.user!.id)
                  .maybeSingle();
              
              if (verify != null) {
                print('AuthService: ✅ Profile verified in database: ${verify['full_name']} (${verify['role']})');
              } else {
                print('AuthService: ⚠️ Profile created but verification failed');
              }
              
              lastError = null;
              break;
            } catch (e) {
              lastError = e is Exception ? e : Exception(e.toString());
              print('AuthService: ❌ Profile operation attempt ${i + 1}/$retries failed: $e');
              
              if (i < retries - 1) {
                // Wait before retry with exponential backoff
                await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
              }
            }
          }
          
          // If all retries failed, this is a critical error
          if (lastError != null) {
            print('AuthService: CRITICAL - Profile creation failed after $retries attempts');
            print('AuthService: User authenticated but profile not created. Manual intervention may be needed.');
            // Note: We still don't rethrow to allow signup to complete
            // The provider_service.dart defensive check will handle missing profiles
          }
        } catch (e) {
          print('AuthService: Unexpected error in profile creation: $e');
          print('AuthService: Error type: ${e.runtimeType}');
        }
      } else {
        print('AuthService: Signup succeeded but no session created (email confirmation might be required)');
      }

      return response;
    } catch (e) {
      print('AuthService: Signup failed at Supabase level: $e');
      print('AuthService: Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      print('AuthService: Fetching profile for user: $userId');
      
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        print('AuthService: ⚠️ Profile not found for user: $userId');
        return null;
      }

      print('AuthService: ✅ Profile found - Name: ${response['full_name']}, Role: ${response['role']}');
      return UserProfile.fromJson(response);
    } catch (e) {
      print('AuthService: ❌ Error fetching profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phoneNumber != null) updates['phone'] = phoneNumber;
    if (profileImageUrl != null) updates['profile_photo_url'] = profileImageUrl;

    await _supabase.from('profiles').update(updates).eq('id', userId);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
