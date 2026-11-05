import 'package:flutter/material.dart';

/// Palet warna kohesif, premium, dan konsisten untuk SimpanNota
class AppColors {
  // Brand & Accent Colors
  static const Color primaryNavy = Color(0xFF0F172A); // Deep Slate Navy
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color accentBlue = Color(0xFF2563EB); // Modern Sapphire Blue
  static const Color primaryTeal = Color(0xFF0D9488); // Refined Teal Accent
  static const Color lightBlue = Color(0xFFEFF6FF); // Ice Blue background tint

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Clean off-white Slate 50
  static const Color surface = Colors.white; // Pure white for cards
  static const Color cardBorder = Color(0xFFE2E8F0); // Delicate Slate 200 border
  static const Color inputFill = Color(0xFFF1F5F9); // Slate 100 for input fields

  // Typography
  static const Color textDark = Color(0xFF0F172A); // Slate 900 - High contrast headline
  static const Color textBody = Color(0xFF334155); // Slate 700 - Readable body
  static const Color textGrey = Color(0xFF64748B); // Slate 500 - Secondary text
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400 - Subtle hint

  // Warranty Status Colors
  static const Color statusActive = Color(0xFF059669); // Emerald green
  static const Color statusActiveBg = Color(0xFFECFDF5);
  static const Color statusExpiring = Color(0xFFD97706); // Amber orange
  static const Color statusExpiringBg = Color(0xFFFFFBEB);
  static const Color statusExpired = Color(0xFFE11D48); // Rose red
  static const Color statusExpiredBg = Color(0xFFFFF1F2);

  // Shadows
  static const Color shadowColor = Color(0x0A0F172A);
  static const Color shadowColorMedium = Color(0x140F172A);
}
