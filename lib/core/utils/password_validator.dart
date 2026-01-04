/// Password validation utility with strong security requirements
class PasswordValidator {
  // Private constructor to prevent instantiation
  PasswordValidator._();

  /// Minimum password length
  static const int minLength = 8;

  /// Validates password strength
  /// Returns null if valid, error message if invalid
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }

    return null; // Password is valid
  }

  /// Returns a list of password requirements for display
  static List<String> getRequirements() {
    return [
      'At least $minLength characters long',
      'Contains uppercase letter (A-Z)',
      'Contains lowercase letter (a-z)',
      'Contains number (0-9)',
      'Contains special character (!@#\$%^&*...)',
    ];
  }

  /// Returns a user-friendly helper text
  static String getHelperText() {
    return 'Password must be at least $minLength characters and include uppercase, lowercase, number, and special character.';
  }

  /// Validates password confirmation match
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
