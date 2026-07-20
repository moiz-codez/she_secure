import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const bgBase = Color(0xFF0B0B0F);
  static const bgElevated = Color(0xFF17171D);
  static const bgElevated2 = Color(0xFF202028);

  // Accent
  static const accentAlert = Color(0xFFFF3B5C);
  static const accentAlertPressed = Color(0xFFE62E4D);
  static const accentBrand = Color(0xFF7C5CFC);
  static const accentSafe = Color(0xFF2ED573);
  static const accentWarning = Color(0xFFFFB020);

  // Text
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF9B9BA8);
  static const textDisabled = Color(0xFF55555F);

  // Border
  static const borderSubtle = Color(0xFF2A2A33);

  // Gradient
  static const gradientHeroColors = [accentAlert, accentBrand];
}
