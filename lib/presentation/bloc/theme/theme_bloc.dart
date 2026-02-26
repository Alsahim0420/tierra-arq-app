import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/theme_service.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeService _themeService;

  ThemeBloc(this._themeService) : super(const ThemeState(AppTheme.system)) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
  }

  static AppTheme _themeFromString(String value) {
    switch (value) {
      case 'light':
        return AppTheme.light;
      case 'dark':
        return AppTheme.dark;
      default:
        return AppTheme.system;
    }
  }

  static String _themeToString(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'light';
      case AppTheme.dark:
        return 'dark';
      case AppTheme.system:
        return 'system';
    }
  }

  Future<void> _onLoadTheme(
    LoadTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final themeString = await _themeService.getTheme();
      emit(ThemeState(_themeFromString(themeString)));
    } catch (e) {
      emit(const ThemeState(AppTheme.system));
    }
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      await _themeService.setTheme(_themeToString(event.theme));
      emit(ThemeState(event.theme));
    } catch (e) {
      // Si hay error, mantener el estado actual
    }
  }
}

