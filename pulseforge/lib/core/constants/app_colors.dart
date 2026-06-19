import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceLight = Color(0xFF1E1E1E);
  static const card = Color(0xFF181818);

  static const primaryBlue = Color(0xFF00D4FF);
  static const primaryPurple = Color(0xFF8B5CF6);
  static const accentCyan = Color(0xFF06B6D4);
  static const accentViolet = Color(0xFFA855F7);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple],
  );

  static const glassBorder = Color(0x33FFFFFF);
  static const glassFill = Color(0x1AFFFFFF);
}
