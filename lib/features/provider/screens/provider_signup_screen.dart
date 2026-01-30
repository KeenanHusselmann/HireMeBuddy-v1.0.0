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

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection('1. Service Provider Agreement', 
                        'By registering as a service provider on HireMeBuddy, you agree to provide professional services to clients through our platform.'),
                      _buildTermsSection('2. Professional Conduct',
                        'You agree to maintain professional standards and deliver quality services to all clients.'),
                      _buildTermsSection('3. Verification',
                        'All identification documents and service photos will be verified by our team before your profile is activated.'),
                      _buildTermsSection('4. Payment Terms',
                        'Platform fees apply to all transactions. Payments will be processed according to our payment schedule.'),
                      _buildTermsSection('5. Cancellation Policy',
                        'Cancellations must be made according to our cancellation policy. Late cancellations may result in penalties.'),
                      _buildTermsSection('6. Account Termination',
                        'We reserve the right to suspend or terminate accounts that violate our terms of service.'),
                      _buildTermsSection('7. Liability',
                        'Service providers are responsible for their own actions and services provided through the platform. HireMeBuddy is not liable for disputes between providers and clients.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
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
          body: SafeArea(
            child: Container(
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
                        padding: const EdgeInsets.only(bottom: 100),
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
                              cursorColor: Colors.deepOrange.shade600,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                floatingLabelStyle: TextStyle(color: Colors.deepOrange.shade600),
                                prefixIcon: Icon(Icons.person_outline, color: Colors.deepOrange.shade600),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
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
                              cursorColor: Colors.deepOrange.shade600,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                floatingLabelStyle: TextStyle(color: Colors.deepOrange.shade600),
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
                              cursorColor: Colors.deepOrange.shade600,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                floatingLabelStyle: TextStyle(color: Colors.deepOrange.shade600),
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.deepOrange.shade600),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
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
                              cursorColor: Colors.deepOrange.shade600,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                floatingLabelStyle: TextStyle(color: Colors.deepOrange.shade600),
                                prefixIcon: Icon(Icons.phone_outlined, color: Colors.deepOrange.shade600),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
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
                              cursorColor: Colors.deepOrange.shade600,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                floatingLabelStyle: TextStyle(color: Colors.deepOrange.shade600),
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
                              cursorColor: Colors.deepOrange.shade600,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                floatingLabelStyle: TextStyle(color: Colors.deepOrange.shade600),
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
                                  child: GestureDetector(
                                    onTap: () {
                                      _showTermsAndConditions();
                                    },
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'I agree to ',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        children: [
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: TextStyle(
                                              color: Colors.deepOrange.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
        ),
        // Loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.orange.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepOrange.shade50,
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.deepOrange,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Creating your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Setting up your profile...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
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