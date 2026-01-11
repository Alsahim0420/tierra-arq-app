import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection/injection_container.dart' as di;
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/obra/obra_bloc.dart';
import '../bloc/tarea/tarea_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';
import '../bloc/user/user_bloc.dart';
import '../screens/auth/auth_wrapper.dart';

class TierraApp extends StatelessWidget {
  const TierraApp({super.key});

  // Colores principales
  static const primary = Color(0xFFD5B189);
  static const secondary = Color(0xFF9E7A55);

  // Colores para tema oscuro
  static const dark = Color(0xFF0E0E0E);
  static const card = Color(0xFF1B1B1B);
  static const muted = Color(0xFF8D8D8D);

  // Colores para tema claro
  static const lightBackground = Color(0xFFF5F5F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightMuted = Color(0xFF757575);

  // Método para obtener el color del AppBar según el tema
  static Color getAppBarColor(bool isDark) {
    return isDark ? card : primary;
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: card,
      ),
      scaffoldBackgroundColor: dark,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      dividerColor: muted.withValues(alpha: 0.2),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightCard,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: Colors.black87,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      cardTheme: const CardThemeData(
        color: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      dividerColor: lightMuted.withValues(alpha: 0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.getIt<ThemeBloc>()..add(const LoadTheme()),
        ),
        BlocProvider(
          create: (_) => di.getIt<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider(create: (_) => di.getIt<ObraBloc>()),
        BlocProvider(create: (_) => di.getIt<TareaBloc>()),
        BlocProvider(create: (_) => di.getIt<UserBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TIERRA Control de Obras',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeState.theme == AppTheme.light
                ? ThemeMode.light
                : ThemeMode.dark,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
