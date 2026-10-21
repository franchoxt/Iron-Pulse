import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Electric Cyan / Sky Blue)
  static const Color primaryBlue = Color(0xFF13A4EC);
  static const Color primaryCyan = Color(0xFF13A4EC);
  static const Color primaryNeon = Color(0xFF13A4EC); // Compatibility alias
  static const Color cyanGlow = Color(0x6613A4EC);
  static const Color neonGlow = Color(0x6613A4EC);
  static const Color cyanTint = Color(0xFF0F2231);
  static const Color neonTint = Color(0xFF0F2231);
  static const Color cyanBorder = Color(0xFF1B3D57);
  static const Color neonBorder = Color(0xFF1B3D57);

  // Dark Backgrounds
  static const Color background = Color(0xFF0A0D12);
  static const Color backgroundDarker = Color(0xFF07090D);
  static const Color cardBg = Color(0xFF121620);
  static const Color cardBgLight = Color(0xFF171D2A);
  static const Color inputBg = Color(0xFF151A22);
  static const Color buttonDark = Color(0xFF161C26);

  // Borders
  static const Color borderSubtle = Color(0xFF212836);
  static const Color borderLight = Color(0xFF2B3446);
  static const Color borderNeon = Color(0xFF13A4EC);

  // Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFE2E8F0);
  static const Color textGray = Color(0xFF8A96A6);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFFFFFFFF);

  // Status & Tag Accents
  static const Color accentGreen = Color(0xFF4EDEA3);
  static const Color accentGreenTint = Color(0x264EDEA3);
  static const Color accentGreenBorder = Color(0x4D4EDEA3);

  static const Color accentAmber = Color(0xFFFFB95F);
  static const Color accentAmberTint = Color(0x26FFB95F);
  static const Color accentAmberBorder = Color(0x4DFFB95F);

  static const Color accentPurple = Color(0xFFA855F7);
  static const Color accentPurpleTint = Color(0x28A855F7);
  static const Color accentPurpleBorder = Color(0x66A855F7);

  // Surface tokens from HTML / Material 3 Dark
  static const Color surfaceContainerLowest = Color(0xFF0B0E13);
  static const Color surfaceContainerLow = Color(0xFF191C21);
  static const Color surfaceContainer = Color(0xFF1D2025);
  static const Color surfaceContainerHigh = Color(0xFF272A30);
  static const Color surfaceContainerHighest = Color(0xFF32353A);
  static const Color onSurface = Color(0xFFE1E2E9);
  static const Color onSurfaceVariant = Color(0xFFBDC8D1);
  static const Color outline = Color(0xFF88929B);
  static const Color outlineVariant = Color(0xFF3E4850);
  static const Color primaryLight = Color(0xFF81CFFF);
  static const Color primaryContainer = Color(0xFF00A3E0);
  static const Color secondary = Color(0xFF4EDEA3);
  static const Color tertiary = Color(0xFFFFB95F);
}

class AppTypography {
  static const List<String> fontFamilies = [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontFamilyFallback: fontFamilies,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryNeon,
        surface: AppColors.cardBg,
        onPrimary: AppColors.textDark,
        onSurface: AppColors.textWhite,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.style(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        headlineLarge: AppTypography.style(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: AppTypography.style(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: AppTypography.style(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: AppTypography.style(
          color: AppColors.textLight,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: AppTypography.style(
          color: AppColors.textGray,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: AppTypography.style(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
