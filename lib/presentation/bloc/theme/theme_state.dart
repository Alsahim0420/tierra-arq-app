import 'package:equatable/equatable.dart';

enum AppTheme { light, dark, system }

class ThemeState extends Equatable {
  const ThemeState(this.theme);

  final AppTheme theme;

  @override
  List<Object> get props => [theme];
}

