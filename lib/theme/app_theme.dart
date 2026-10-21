import 'package:flutter/material.dart';

/// IRON PULSE - Guía de Estilo y Sistema de Diseño
/// Basado en: .agents/rules/guias-de-estilo-y-reglas-de-diseno.md
class AppColors {
  // 1. Colores Principales
  /// Azul Primario (Acción): #3B82F6 (Blue-500)
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryCyan = Color(0xFF3B82F6);
  static const Color primaryNeon = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF60A5FA); // Blue-400
  static const Color primaryContainer = Color(0xFF2563EB); // Blue-600
  static const Color blueGlow = Color(0x663B82F6);
  static const Color neonGlow = Color(0x663B82F6);
  static const Color blueTint = Color(0xFF1E3A8A);
  static const Color neonTint = Color(0xFF1E3A8A);

  // 2. Fondos de Aplicación
  /// Fondo Dark: #0F172A (Slate-900)
  static const Color background = Color(0xFF0F172A);
  static const Color backgroundDarker = Color(0xFF020617); // Slate-950
  /// Fondo Light: #F8FAFC (Slate-50)
  static const Color backgroundLight = Color(0xFFF8FAFC);

  // Tarjetas y Superficies
  /// Tarjetas Dark: #1E293B (Slate-800)
  static const Color cardBg = Color(0xFF1E293B);
  static const Color cardBgLight = Color(0xFF334155); // Slate-700
  static const Color inputBg = Color(0xFF1E293B);
  static const Color buttonDark = Color(0xFF334155);

  // Surface tokens Material 3 Dark (Slate Palette)
  static const Color surfaceContainerLowest = Color(0xFF020617);
  static const Color surfaceContainerLow = Color(0xFF0F172A);
  static const Color surfaceContainer = Color(0xFF1E293B);
  static const Color surfaceContainerHigh = Color(0xFF334155);
  static const Color surfaceContainerHighest = Color(0xFF475569);
  static const Color onSurface = Color(0xFFF8FAFC);
  static const Color onSurfaceVariant = Color(0xFF94A3B8);
  static const Color outline = Color(0xFF334155);
  static const Color outlineVariant = Color(0xFF475569);

  // 3. Colores de Estado
  /// Éxito / Confirmado: #22C55E (Green-500)
  static const Color successGreen = Color(0xFF22C55E);
  static const Color secondary = Color(0xFF22C55E);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentGreenTint = Color(0x2622C55E);
  static const Color accentGreenBorder = Color(0x4D22C55E);

  /// Alerta / Espera: #F59E0B (Amber-500)
  static const Color alertAmber = Color(0xFFF59E0B);
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentAmberTint = Color(0x26F59E0B);
  static const Color accentAmberBorder = Color(0x4DF59E0B);

  /// Error / Cancelado: #EF4444 (Red-500)
  static const Color errorRed = Color(0xFFEF4444);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentRedTint = Color(0x26EF4444);
  static const Color accentRedBorder = Color(0x4DEF4444);

  // 4. Intensidades (Glosario de la Guía)
  /// Low: Chip Verde (#22C55E)
  static const Color intensityLow = Color(0xFF22C55E);
  /// Medium: Chip Azul/Naranja (#3B82F6 / #F59E0B)
  static const Color intensityMedium = Color(0xFF3B82F6);
  /// High: Chip Púrpura/Rojo (#7C3AED / #EF4444)
  static const Color intensityHigh = Color(0xFF7C3AED);

  // 5. Texto
  /// Primario Dark: #F8FAFC (Slate-50) / Light: #1E293B (Slate-800)
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textLight = Color(0xFFF1F5F9); // Slate-100
  static const Color textDark = Color(0xFF1E293B);  // Slate-800
  /// Secundario: #64748B (Slate-500)
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textGray = Color(0xFF94A3B8);   // Slate-400
  static const Color textMuted = Color(0xFF64748B);  // Slate-500

  // 6. Navegación
  static const Color navActive = Color(0xFF3B82F6);
  static const Color navInactive = Color(0xFF94A3B8); // Slate-400

  // Bordes
  static const Color borderSubtle = Color(0xFF334155); // Slate-700
  static const Color borderLight = Color(0xFF475569);  // Slate-600
  static const Color borderNeon = Color(0xFF3B82F6);
  static const Color cyanBorder = Color(0xFF1D4ED8);
  static const Color neonBorder = Color(0xFF1D4ED8);
}

/// Medidas y bordes de la Guía de Estilo
class AppDimensions {
  /// Bordes de tarjetas: rounded-3xl (~24px)
  static const double radiusCard = 24.0;
  static final BorderRadius cardBorderRadius = BorderRadius.circular(24.0);

  /// Bordes de botones: rounded-2xl (~16px)
  static const double radiusButton = 16.0;
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(16.0);

  /// Bordes de chips y secundarios: rounded-full
  static final BorderRadius chipBorderRadius = BorderRadius.circular(999.0);

  /// Altura mínima de botones táctiles: 48px
  static const double minButtonHeight = 48.0;

  // Escala de espaciado en múltiplos de 4 (4, 8, 12, 16, 24, 32)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Márgenes laterales de pantalla
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets screenPaddingLarge = EdgeInsets.symmetric(horizontal: 24.0);
}

class AppTypography {
  static const List<String> fontFamilies = [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'SF Pro',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing = -0.02,
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
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        surface: AppColors.cardBg,
        onPrimary: Colors.white,
        onSurface: AppColors.textWhite,
        error: AppColors.errorRed,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.style(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w800,
          fontSize: 32,
        ),
        headlineLarge: AppTypography.style(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
        headlineMedium: AppTypography.style(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: AppTypography.style(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: AppTypography.style(
          color: AppColors.textLight,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: AppTypography.style(
          color: AppColors.textGray,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        bodySmall: AppTypography.style(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
    );
  }
}
