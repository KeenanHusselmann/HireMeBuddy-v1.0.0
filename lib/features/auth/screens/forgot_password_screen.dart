import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/auth_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('client_reset_email');
      final codeSent = prefs.getBool('client_reset_code_sent') ?? false;
      
      if (savedEmail != null && codeSent) {
        if (mounted) {
          setState(() {
            _emailController.text = savedEmail;
            _codeSent = true;
          });
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('client_reset_email', _emailController.text);
      await prefs.setBool('client_reset_code_sent', _codeSent);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('client_reset_email');
      await prefs.remove('client_reset_code_sent');
    } catch (e) {
      // Silent fail
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload state when app comes back to foreground
      _loadSavedState();
    }
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      await authService.resetPassword(email);
      
      if (mounted) {
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
        await _saveState(); // Save state for when user switches apps
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyCodeAndReset() async {
    final email = _emailController.text.trim();
    final code = _otpController.text.trim();
    
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification code');
      return;
    }

    // Just validate the code format before navigating
    if (code.length != 6 || !RegExp(r'^\d+$').hasMatch(code)) {
      setState(() => _errorMessage = 'Invalid code format. Please enter 6 digits.');
      return;
    }

    // Save email and code to SharedPreferences before navigating
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('client_reset_email_temp', email);
    await prefs.setString('client_reset_code_temp', code);

    // Navigate to reset password screen
    if (mounted) {
      context.push('/reset-password');
    }
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? Colors.green : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.lock_reset,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                _codeSent ? 'Enter Verification Code' : 'Forgot Password?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to ${_emailController.text}'
                    : 'Enter your email address and we\'ll send you a verification code to reset your password.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              if (!_codeSent) ...[
                // Email input
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
              ] else ...[
                // OTP input
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    hintText: 'Enter 6-digit code',
                    prefixIcon: const Icon(Icons.verified_user),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !_isLoading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_codeSent ? _verifyCodeAndReset : _sendResetCode),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_codeSent ? 'Verify Code' : 'Send Code'),
              ),
              
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _sendResetCode,
                  child: const Text('Resend Code'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
