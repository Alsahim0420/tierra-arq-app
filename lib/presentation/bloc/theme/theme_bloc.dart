import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/theme_service.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeService _themeService;

  ThemeBloc(this._themeService) : super(const ThemeState(AppTheme.dark)) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
  }

  Future<void> _onLoadTheme(
    LoadTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final themeString = await _themeService.getTheme();
      final theme = themeString == 'light' ? AppTheme.light : AppTheme.dark;
      emit(ThemeState(theme));
    } catch (e) {
      emit(const ThemeState(AppTheme.dark));
    }
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final themeString = event.theme == AppTheme.light ? 'light' : 'dark';
      await _themeService.setTheme(themeString);
      emit(ThemeState(event.theme));
    } catch (e) {
      // Si hay error, mantener el estado actual
    }
  }
}

