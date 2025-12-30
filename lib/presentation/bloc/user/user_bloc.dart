import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/user/get_user_usecase.dart';
import '../../../domain/usecases/user/get_all_users_usecase.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase getUserUseCase;
  final GetAllUsersUseCase getAllUsersUseCase;

  UserBloc(this.getUserUseCase, this.getAllUsersUseCase)
      : super(const UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<LoadAllUsers>(_onLoadAllUsers);
  }

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final user = await getUserUseCase(event.userId);
      if (user != null) {
        emit(UserLoaded(user));
      } else {
        emit(const UserError('Usuario no encontrado'));
      }
    } catch (e) {
      emit(UserError('Error al cargar usuario: $e'));
    }
  }

  Future<void> _onLoadAllUsers(
    LoadAllUsers event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      final users = await getAllUsersUseCase();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UserError('Error al cargar usuarios: $e'));
    }
  }
}

