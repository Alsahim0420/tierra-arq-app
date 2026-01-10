import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/mappers/user_mapper.dart';
import '../../../core/exceptions/app_exceptions.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  UserEntity? _currentUser;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  UserEntity? get currentUser => _currentUser;

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authResponse = await loginUseCase(event.email, event.password);

      // Convertir el usuario de la respuesta (UserModel) a UserEntity usando el mapper
      final user = UserMapper.toEntity(authResponse.user);
      _currentUser = user;
      emit(AuthAuthenticated(user));
    } on AppException catch (e) {
      // Usar el mensaje de la excepción personalizada
      emit(AuthError(e.message));
    } catch (e) {
      // Error desconocido
      emit(AuthError('Error inesperado. Intenta nuevamente.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await logoutUseCase();
    _currentUser = null;
    emit(const AuthUnauthenticated());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        _currentUser = user;
        emit(AuthAuthenticated(user));
      } else {
        _currentUser = null;
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      _currentUser = null;
      emit(const AuthUnauthenticated());
    }
  }
}
