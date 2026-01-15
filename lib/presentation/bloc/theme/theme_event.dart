import 'package:equatable/equatable.dart';
import 'theme_state.dart';

class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class LoadTheme extends ThemeEvent {
  const LoadTheme();
}

class ChangeTheme extends ThemeEvent {
  const ChangeTheme(this.theme);

  final AppTheme theme;

  @override
  List<Object> get props => [theme];
}

