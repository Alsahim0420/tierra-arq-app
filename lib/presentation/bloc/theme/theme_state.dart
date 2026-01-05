import 'package:equatable/equatable.dart';

enum AppTheme { dark, light }

class ThemeState extends Equatable {
  const ThemeState(this.theme);

  final AppTheme theme;

  @override
  List<Object> get props => [theme];
}

