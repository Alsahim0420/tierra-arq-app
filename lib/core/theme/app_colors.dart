import 'package:flutter/material.dart';

/// Colores centralizados de la aplicación.
/// Cambiar los valores aquí actualiza la paleta en toda la app.
/// Soporta modo claro y oscuro mediante [AppColorsLight] y [AppColorsDark].
abstract class AppColors {
  AppColors._();

  // ─── Paleta brand (naranja) ─────────────────────────────────────────────
  static const Color primary = Color(0xFFE86C00);
  static const Color primaryContainer = Color(0xFFFFB74D);
  static const Color onPrimary = Color(0xFF2D1B00);
  static const Color secondary = Color(0xFFD84315);
  static const Color secondaryContainer = Color(0xFFFF8A65);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ─── Semánticos (error, success, etc.) ─────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  static const Color outline = Color(0xFF795548);
  static const Color outlineVariant = Color(0xFFBCAAA4);

  /// Color del AppBar según tema actual. Usar con [Theme.of(context).brightness].
  static Color appBarColor(bool isDark) =>
      isDark ? AppColorsDark.card : primary;

  /// Fondo del scaffold según tema actual.
  static Color scaffoldBackgroundColor(bool isDark) =>
      isDark ? AppColorsDark.scaffoldBackground : AppColorsLight.scaffoldBackground;

  /// Color de superficie/card según tema actual.
  static Color cardColor(bool isDark) =>
      isDark ? AppColorsDark.card : AppColorsLight.card;
}

/// Colores para modo claro. Usar en [ThemeData.light] / [ColorScheme.light].
class AppColorsLight {
  AppColorsLight._();

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F1B18);
  static const Color onSurfaceVariant = Color(0xFF757575);
  static const Color surfaceContainerHighest = Color(0xFFF5F5F5);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color muted = Color(0xFF757575);
}

/// Colores para modo oscuro. Usar en [ThemeData.dark] / [ColorScheme.dark].
class AppColorsDark {
  AppColorsDark._();

  static const Color surface = Color(0xFF1B1B1B);
  static const Color onSurface = Color(0xFFE8E1DC);
  static const Color onSurfaceVariant = Color(0xFF8D8D8D);
  static const Color surfaceContainerHighest = Color(0xFF2D2D2D);
  static const Color scaffoldBackground = Color(0xFF0E0E0E);
  static const Color card = Color(0xFF1B1B1B);
  static const Color divider = Color(0xFF3D3D3D);
  static const Color muted = Color(0xFF8D8D8D);
}
