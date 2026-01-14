/// Enhanced input validators for production-grade validation
/// 
/// This file provides comprehensive validation for all user inputs
/// to ensure data integrity and security across the application.

class EmailValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates email format with strict RFC compliance
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final email = value.trim();
    
    // Length check (max 254 characters per RFC 5321)
    if (email.length > 254) {
      return 'Email too long (max 254 characters)';
    }
    
    // Regex validation
    if (!_emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }
    
    // Additional checks
    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Email cannot start or end with a dot';
    }
    
    if (email.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }
    
    return null;
  }
}

class PasswordValidator {
  /// Validates password strength with enhanced security requirements
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    // Minimum length
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    // Maximum length (prevent DoS)
    if (value.length > 128) {
      return 'Password too long (max 128 characters)';
    }
    
    // Must contain uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Must contain lowercase
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Must contain number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Must contain special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
}

class PhoneValidator {
  static final RegExp _phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  
  /// Validates phone number (E.164 format)
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    final phone = value.trim().replaceAll(RegExp(r'[\s-()]'), '');
    
    if (!_phoneRegex.hasMatch(phone)) {
      return 'Invalid phone number format';
    }
    
    if (phone.length < 7 || phone.length > 15) {
      return 'Phone number must be 7-15 digits';
    }
    
    return null;
  }
}

class NumericValidator {
  /// Validates positive numbers with optional decimal
  static String? validatePositive(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value.trim());
    
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (number < 0) {
      return '$fieldName must be positive';
    }
    
    if (number > 1000000) {
      return '$fieldName exceeds maximum value';
    }
    
    return null;
  }
  
  /// Validates integers within a range
  static String? validateInteger(String? value, {
    String fieldName = 'Value',
    int min = 0,
    int max = 1000000,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = int.tryParse(value.trim());
    
    if (number == null) {
      return '$fieldName must be a whole number';
    }
    
    if (number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (number > max) {
      return '$fieldName cannot exceed $max';
    }
    
    return null;
  }
}

class TextValidator {
  /// Validates text with length constraints and pattern matching
  static String? validate(
    String? value, {
    String fieldName = 'Field',
    int minLength = 1,
    int maxLength = 500,
    bool allowSpecialChars = true,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    
    final text = value.trim();
    
    if (text.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    if (text.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    
    // Check for SQL injection patterns
    final sqlPatterns = [
      r'(\bor\b|\band\b).*[=<>]',
      r'union.*select',
      r'drop\s+table',
      r'insert\s+into',
      r'--',
      r'/\*',
      r'\*/',
    ];
    
    for (final pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        return '$fieldName contains invalid characters';
      }
    }
    
    // Check for XSS patterns
    final xssPatterns = [
      r'<script',
      r'javascript:',
      r'onerror=',
      r'onclick=',
    ];
    
    for (final pattern in xssPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        return '$fieldName contains invalid characters';
      }
    }
    
    if (!allowSpecialChars) {
      if (text.contains(RegExp(r'[^a-zA-Z0-9\s]'))) {
        return '$fieldName can only contain letters, numbers, and spaces';
      }
    }
    
    return null;
  }
}

class UrlValidator {
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );
  
  /// Validates URL format
  static String? validate(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'URL is required' : null;
    }
    
    if (!_urlRegex.hasMatch(value.trim())) {
      return 'Invalid URL format';
    }
    
    return null;
  }
}

class RateValidator {
  /// Validates hourly rate (0-10000 range)
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Hourly rate is required';
    }
    
    final rate = double.tryParse(value.trim());
    
    if (rate == null) {
      return 'Hourly rate must be a valid number';
    }
    
    if (rate < 0) {
      return 'Hourly rate cannot be negative';
    }
    
    if (rate > 10000) {
      return 'Hourly rate cannot exceed 10,000';
    }
    
    // Check for unreasonable precision
    final decimalPlaces = value.split('.').length > 1 
        ? value.split('.')[1].length 
        : 0;
    
    if (decimalPlaces > 2) {
      return 'Hourly rate can have at most 2 decimal places';
    }
    
    return null;
  }
}

class BioValidator {
  /// Validates bio/description text
  static String? validate(String? value) {
    return TextValidator.validate(
      value,
      fieldName: 'Bio',
      minLength: 10,
      maxLength: 500,
      allowSpecialChars: true,
      required: true,
    );
  }
}

class NameValidator {
  /// Validates first/last names
  static String? validate(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final name = value.trim();
    
    if (name.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (name.length > 50) {
      return '$fieldName cannot exceed 50 characters';
    }
    
    // Allow letters, spaces, hyphens, apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
}
