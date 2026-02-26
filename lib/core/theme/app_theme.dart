import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Configuración centralizada de [ThemeData] para la aplicación.
/// Usa [ColorScheme] y colores de [AppColors] / [AppColorsLight] / [AppColorsDark].
abstract class AppThemeData {
  AppThemeData._();

  static const _cardRadius = 18.0;

  static ColorScheme get _lightColorScheme => ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondary,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColorsLight.surface,
        onSurface: AppColorsLight.onSurface,
        onSurfaceVariant: AppColorsLight.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      );

  static ColorScheme get _darkColorScheme => ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondary,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.onSurface,
        onSurfaceVariant: AppColorsDark.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        scaffoldBackgroundColor: AppColorsLight.scaffoldBackground,
        textTheme: _textTheme(AppColorsLight.onSurface),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColorsLight.onSurface,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColorsLight.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: AppColorsLight.muted.withValues(alpha: 0.2),
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        scaffoldBackgroundColor: AppColorsDark.scaffoldBackground,
        textTheme: _textTheme(AppColorsDark.onSurface),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColorsDark.onSurface,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColorsDark.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: AppColorsDark.muted.withValues(alpha: 0.2),
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static TextTheme _textTheme(Color onSurface) => TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      );
}
