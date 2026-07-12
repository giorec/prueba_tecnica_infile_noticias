import 'package:flutter/material.dart';

/// Paleta de colores corporativa de Infile.
///
/// REGLA DE USO:
/// - [white] domina todos los fondos (spec: predominante en blanco).
/// - [infileBlue] exclusivamente para botones primarios, acentos y AppBar icons.
/// - [darkGray] para tipografía principal e iconografía.
/// - Nunca usar colores genéricos (rojo, verde, azul puro) fuera de este sistema.
abstract final class AppColors {
  // ── Fondo principal ─────────────────────────────────────────────────────────
  /// Blanco puro — fondo dominante en todas las pantallas.
  static const Color white = Color(0xFFFFFFFF);

  /// Gris muy claro — superficies secundarias, cards, inputs.
  static const Color surface = Color(0xFFF5F7FA);

  /// Gris claro para bordes y dividers.
  static const Color border = Color(0xFFE2E8F0);

  // ── Corporativo Infile ──────────────────────────────────────────────────────
  /// Azul institucional Infile — botones primarios, acentos, links activos.
  static const Color infileBlue = Color(0xFF003DA5);

  /// Azul Infile con opacidad — estados hover, splash en buttons.
  static const Color infileBlueDark = Color(0xFF002880);

  /// Azul Infile claro — chips de categoría, badges, fondos de íconos.
  static const Color infileBlueLight = Color(0xFFE8EFFE);

  // ── Tipografía / Iconos ─────────────────────────────────────────────────────
  /// Gris oscuro corporativo — texto principal, iconos.
  static const Color darkGray = Color(0xFF333333);

  /// Gris medio — texto secundario, subtítulos, hints.
  static const Color mediumGray = Color(0xFF64748B);

  /// Gris claro — texto deshabilitado, placeholders.
  static const Color lightGray = Color(0xFF94A3B8);

  // ── Estados de feedback ─────────────────────────────────────────────────────
  /// Verde para mensajes de éxito.
  static const Color success = Color(0xFF10B981);

  /// Rojo para errores y validaciones.
  static const Color error = Color(0xFFEF4444);

  /// Ámbar para advertencias.
  static const Color warning = Color(0xFFF59E0B);

  // ── Shimmer (skeleton loading) ──────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
