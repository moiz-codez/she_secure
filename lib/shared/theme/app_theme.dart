import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppColorsThemeExtension extends ThemeExtension<AppColorsThemeExtension> {
  const AppColorsThemeExtension({
    required this.bgBase,
    required this.bgElevated,
    required this.bgElevated2,
    required this.accentAlert,
    required this.accentAlertPressed,
    required this.accentBrand,
    required this.accentSafe,
    required this.accentWarning,
    required this.borderSubtle,
  });

  final Color bgBase;
  final Color bgElevated;
  final Color bgElevated2;
  final Color accentAlert;
  final Color accentAlertPressed;
  final Color accentBrand;
  final Color accentSafe;
  final Color accentWarning;
  final Color borderSubtle;

  static const instance = AppColorsThemeExtension(
    bgBase: AppColors.bgBase,
    bgElevated: AppColors.bgElevated,
    bgElevated2: AppColors.bgElevated2,
    accentAlert: AppColors.accentAlert,
    accentAlertPressed: AppColors.accentAlertPressed,
    accentBrand: AppColors.accentBrand,
    accentSafe: AppColors.accentSafe,
    accentWarning: AppColors.accentWarning,
    borderSubtle: AppColors.borderSubtle,
  );

  @override
  AppColorsThemeExtension copyWith({
    Color? bgBase,
    Color? bgElevated,
    Color? bgElevated2,
    Color? accentAlert,
    Color? accentAlertPressed,
    Color? accentBrand,
    Color? accentSafe,
    Color? accentWarning,
    Color? borderSubtle,
  }) {
    return AppColorsThemeExtension(
      bgBase: bgBase ?? this.bgBase,
      bgElevated: bgElevated ?? this.bgElevated,
      bgElevated2: bgElevated2 ?? this.bgElevated2,
      accentAlert: accentAlert ?? this.accentAlert,
      accentAlertPressed: accentAlertPressed ?? this.accentAlertPressed,
      accentBrand: accentBrand ?? this.accentBrand,
      accentSafe: accentSafe ?? this.accentSafe,
      accentWarning: accentWarning ?? this.accentWarning,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  AppColorsThemeExtension lerp(
    covariant ThemeExtension<AppColorsThemeExtension>? other,
    double t,
  ) {
    if (other is! AppColorsThemeExtension) return this;
    return AppColorsThemeExtension(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      bgElevated2: Color.lerp(bgElevated2, other.bgElevated2, t)!,
      accentAlert: Color.lerp(accentAlert, other.accentAlert, t)!,
      accentAlertPressed: Color.lerp(accentAlertPressed, other.accentAlertPressed, t)!,
      accentBrand: Color.lerp(accentBrand, other.accentBrand, t)!,
      accentSafe: Color.lerp(accentSafe, other.accentSafe, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}

abstract final class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgBase,
        primary: AppColors.accentBrand,
        secondary: AppColors.accentBrand,
        error: AppColors.accentAlert,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingMedium,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        titleLarge: AppTextStyles.sectionLabel,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelSmall: AppTextStyles.caption,
        labelMedium: AppTextStyles.buttonLabel,
      ),
      extensions: const [AppColorsThemeExtension.instance],
    );
  }
}

/// Extension on BuildContext for convenient access to app colors.
extension AppColorsExtension on BuildContext {
  AppColorsThemeExtension get appColors =>
      Theme.of(this).extension<AppColorsThemeExtension>()!;
}