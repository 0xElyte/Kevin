import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SciFi_Theme design tokens and ThemeData for Project Kevin.
///
/// This theme enforces a black and red sci-fi aesthetic with futuristic
/// typography (Orbitron for headings, Exo 2 for body text) and is always
/// displayed in dark mode regardless of system settings.
class SciFiTheme {
  // Color tokens
  static const Color colorBackground = Color(0xFF000000);
  static const Color colorSurface = Color(0xFF0D0D0D);
  static const Color colorAccent = Color(0xFFCC0000);
  static const Color colorAccentDim = Color(0xFF660000);
  static const Color colorTextPrimary = Color(0xFFFFFFFF);
  static const Color colorTextSecondary = Color(0xFF888888);
  static const Color colorBorderUser = Color(0xFFCC0000);
  static const Color colorBorderKevin = Color(0xFF333333);

  // Layout tokens
  static const double borderRadius = 8.0;
  static const EdgeInsets bubblePadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );

  /// Returns the complete ThemeData for the SciFi theme.
  ///
  /// This theme is always dark and uses Orbitron for headings and Exo 2
  /// for body text via Google Fonts.
  static ThemeData get themeData {
    final TextTheme textTheme = TextTheme(
      // Headings use Orbitron
      displayLarge: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.orbitron(
        color: colorTextPrimary,
        fontWeight: FontWeight.w500,
      ),
      // Body text uses Exo 2
      bodyLarge: GoogleFonts.exo2(color: colorTextPrimary),
      bodyMedium: GoogleFonts.exo2(color: colorTextPrimary),
      bodySmall: GoogleFonts.exo2(color: colorTextSecondary),
      labelLarge: GoogleFonts.exo2(
        color: colorTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.exo2(
        color: colorTextPrimary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.exo2(
        color: colorTextSecondary,
        fontWeight: FontWeight.w500,
      ),
    );

    return ThemeData(
      // Force dark theme regardless of system setting
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: colorAccent,
        secondary: colorAccentDim,
        surface: colorSurface,
        error: colorAccent,
        onPrimary: colorTextPrimary,
        onSecondary: colorTextPrimary,
        onSurface: colorTextPrimary,
        onError: colorTextPrimary,
      ),

      // Scaffold background
      scaffoldBackgroundColor: colorBackground,

      // Typography
      textTheme: textTheme,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorBackground,
        foregroundColor: colorTextPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.orbitron(
          color: colorTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: colorSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: colorAccent, width: 1),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: colorAccent, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: colorAccentDim, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: colorAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: colorAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: colorAccent, width: 2),
        ),
        labelStyle: GoogleFonts.exo2(color: colorTextSecondary),
        hintStyle: GoogleFonts.exo2(color: colorTextSecondary),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorAccent,
          foregroundColor: colorTextPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.exo2(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorAccent,
          textStyle: GoogleFonts.exo2(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorAccent,
          side: const BorderSide(color: colorAccent, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.exo2(fontWeight: FontWeight.w600),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: colorAccent),

      // Divider theme
      dividerTheme: const DividerThemeData(color: colorAccentDim, thickness: 1),
    );
  }
}
