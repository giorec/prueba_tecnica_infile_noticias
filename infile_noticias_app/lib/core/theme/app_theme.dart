import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Tema global de la aplicación Infile Noticias.
///
/// Principios de diseño:
/// - Fondo predominantemente blanco (#FFFFFF).
/// - Azul institucional (#003DA5) para elementos de acción primaria.
/// - Tipografía Inter (Google Fonts) — moderna y corporativa.
/// - Minimalismo con acentos estratégicos en azul.
final class AppTheme {
  AppTheme._();

  // ── Tipografía base ──────────────────────────────────────────────────────────
  static TextTheme get _textTheme => GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
            letterSpacing: -0.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.darkGray,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.darkGray,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.mediumGray,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );

  /// Tema claro principal (fondo blanco, acentos azul Infile).
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.infileBlue,
          primary: AppColors.infileBlue,
          onPrimary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.darkGray,
          error: AppColors.error,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.white,
        textTheme: _textTheme,
        primaryTextTheme: _textTheme,

        // ── AppBar: blanca con sombra sutil ─────────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.darkGray,
          elevation: 0,
          shadowColor: AppColors.border,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
          iconTheme: const IconThemeData(color: AppColors.darkGray),
        ),

        // ── ElevatedButton: azul Infile, esquinas redondeadas ───────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.infileBlue,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.lightGray,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ).copyWith(
            // Animación sutil de opacidad en press
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.white.withValues(alpha: 0.15);
              }
              return null;
            }),
          ),
        ),

        // ── TextButton: azul Infile, sin fondo ──────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.infileBlue,
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── OutlinedButton ─────────────────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.infileBlue,
            side: const BorderSide(color: AppColors.infileBlue, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),

        // ── Input / TextField ───────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.infileBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          hintStyle: GoogleFonts.inter(
            color: AppColors.lightGray,
            fontSize: 15,
          ),
          labelStyle: GoogleFonts.inter(
            color: AppColors.mediumGray,
            fontSize: 15,
          ),
          floatingLabelStyle: GoogleFonts.inter(
            color: AppColors.infileBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          errorStyle: GoogleFonts.inter(
            color: AppColors.error,
            fontSize: 12,
          ),
        ),

        // ── Card ────────────────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Divisores ──────────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 0,
        ),
      );
}
