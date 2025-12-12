import 'package:flutter/material.dart';

/// App color constants based on HireMeBuddy's brand
/// Extracted from the React app's Tailwind configuration
class AppColors {
  AppColors._();

  // Primary Teal Colors
  static const Color primaryTeal = Color(0xFF008B80); // hsl(180, 100%, 35%)
  static const Color primaryTealHover = Color(0xFF007366); // hsl(180, 100%, 30%)
  static const Color primaryTealLight = Color(0xFFCCF0EC); // hsl(180, 50%, 90%)

  // Background Colors (Light Mode)
  static const Color backgroundLight = Color(0xFFFAFAFA); // hsl(0, 0%, 98%)
  static const Color cardLight = Color(0xFFFFFFFF); // hsl(0, 0%, 100%)
  static const Color mutedLight = Color(0xFFEFF5F4); // hsl(180, 10%, 94%)

  // Background Colors (Dark Mode)
  static const Color backgroundDark = Color(0xFF0D1716); // hsl(180, 15%, 8%)
  static const Color cardDark = Color(0xFF111D1C); // hsl(180, 15%, 10%)
  static const Color mutedDark = Color(0xFF1A2726); // hsl(180, 15%, 15%)

  // Text Colors
  static const Color foregroundLight = Color(0xFF222E2D); // hsl(180, 8%, 15%)
  static const Color foregroundDark = Color(0xFFF5F5F5);
  static const Color mutedForeground = Color(0xFF6B8280); // hsl(180, 5%, 45%)

  // Accent Colors
  static const Color accentTeal = Color(0xFF00B8A9); // hsl(180, 90%, 40%)
  static const Color accentTealDark = Color(0xFF00D9C7); // hsl(180, 80%, 55%)

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
