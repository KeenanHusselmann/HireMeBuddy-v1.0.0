import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/password_validator.dart';

class ProviderSignupScreen extends ConsumerStatefulWidget {
  const ProviderSignupScreen({super.key});

  @override
  ConsumerState<ProviderSignupScreen> createState() => _ProviderSignupScreenState();
}

class _ProviderSignupScreenState extends ConsumerState<ProviderSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  // Password requirement states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRequirements);
    _confirmPasswordController.addListener(_checkPasswordMatch);
  }

  void _validatePasswordRequirements() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
    _checkPasswordMatch();
  }

  void _checkPasswordMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordRequirements);
    _confirmPasswordController.removeListener(_checkPasswordMatch);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agree to Terms required', style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
      return;
    }

    final success = await ref.read(authStateProvider.notifier).signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      role: 'provider', // Set role as provider
    );

    if (success && mounted) {
      // Invalidate the user profile cache to force refresh with new data
      ref.invalidate(userProfileProvider);
      
      // Small delay to ensure auth state is fully updated
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Complete your provider profile.', style: TextStyle(fontSize: 13)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
        // Go directly to registration to enforce provider_profiles creation
        context.go('/provider-registration');
      }
    } else if (mounted) {
      final errorMessage = ref.read(authStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Signup failed', style: const TextStyle(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepOrange.shade700,
                  Colors.orange.shade500,
                ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 50),
                            const Text(
                              'JOIN AS PROVIDER',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start earning with your skills',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Signup Form Card
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // First Name
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                prefixIcon: Icon(Icons.person_outline, color: Colors.deepOrange.shade600),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepOrange.shade600, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'First name required' : null,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 12),

                            // Last Name
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                prefixIcon: Icon(Icons.person_outline, color: Colors.deepOrange.shade600),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepOrange.shade600, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Last name required' : null,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 12),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.deepOrange.shade600),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepOrange.shade600, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (!value.contains('@')) return 'Invalid email';
                                return null;
                              },
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 12),

                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone_outlined, color: Colors.deepOrange.shade600),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepOrange.shade600, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Required' : null,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.deepOrange.shade600),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _passwordsMatch ? Colors.green : Colors.grey,
                                    width: _passwordsMatch ? 2 : 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _passwordsMatch ? Colors.green : Colors.grey,
                                    width: _passwordsMatch ? 2 : 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _passwordsMatch ? Colors.green : Colors.deepOrange.shade600,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                              validator: PasswordValidator.validate,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 12),

                            // Password Requirements Card
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Password Requirements:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildRequirement('At least 8 characters', _hasMinLength),
                                    _buildRequirement('One uppercase letter (A-Z)', _hasUppercase),
                                    _buildRequirement('One lowercase letter (a-z)', _hasLowercase),
                                    _buildRequirement('One number (0-9)', _hasDigit),
                                    _buildRequirement('One special character (!@#\$%^&*)', _hasSpecialChar),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.deepOrange.shade600),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _confirmPasswordController.text.isEmpty
                                        ? Colors.grey
                                        : (_passwordsMatch ? Colors.green : Colors.red),
                                    width: _confirmPasswordController.text.isEmpty ? 1 : 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _confirmPasswordController.text.isEmpty
                                        ? Colors.grey
                                        : (_passwordsMatch ? Colors.green : Colors.red),
                                    width: _confirmPasswordController.text.isEmpty ? 1 : 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _confirmPasswordController.text.isEmpty
                                        ? Colors.deepOrange.shade600
                                        : (_passwordsMatch ? Colors.green : Colors.red),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              ),
                              validator: (value) => PasswordValidator.validateConfirmPassword(
                                value,
                                _passwordController.text,
                              ),
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 16),

                            // Terms Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: isLoading
                                      ? null
                                      : (value) => setState(() => _agreedToTerms = value ?? false),
                                  activeColor: Colors.deepOrange.shade600,
                                ),
                                Expanded(
                                  child: Text(
                                    'I agree to Terms & Conditions',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Signup Button
                            ElevatedButton(
                              onPressed: isLoading ? null : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'CREATE ACCOUNT',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),

                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already a provider? ', style: TextStyle(fontSize: 13)),
                                TextButton(
                                  onPressed: isLoading ? null : () => context.go('/provider-login'),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.deepOrange.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Creating your account...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we set up your profile',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to build each requirement row
  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: isMet ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? Colors.green.shade700 : Colors.grey.shade600,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }}