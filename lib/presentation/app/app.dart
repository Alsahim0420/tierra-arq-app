// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection/injection_container.dart' as di;
import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/obra/obra_bloc.dart';
import '../bloc/tarea/tarea_bloc.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';
import '../bloc/user/user_bloc.dart';
import '../screens/auth/auth_wrapper.dart';

class TierraApp extends StatelessWidget {
  const TierraApp({super.key});

  static ThemeMode _themeModeFromAppTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
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
        BlocProvider(create: (_) => di.getIt<DashboardBloc>()),
        BlocProvider(create: (_) => di.getIt<UserBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Obrit',
            theme: AppThemeData.lightTheme,
            darkTheme: AppThemeData.darkTheme,
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
