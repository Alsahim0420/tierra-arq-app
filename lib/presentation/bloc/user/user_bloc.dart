import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/user/get_user_usecase.dart';
import '../../../domain/usecases/user/get_all_users_usecase.dart';
import '../../../domain/usecases/user/create_user_usecase.dart';
import '../../../core/entities/user_entity.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase getUserUseCase;
  final GetAllUsersUseCase getAllUsersUseCase;
  final CreateUserUseCase createUserUseCase;

  UserBloc(
    this.getUserUseCase,
    this.getAllUsersUseCase,
    this.createUserUseCase,
  ) : super(const UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<LoadAllUsers>(_onLoadAllUsers);
    on<CreateUser>(_onCreateUser);
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

  Future<void> _onCreateUser(
    CreateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    try {
      // Crear UserEntity con role "master" por defecto (se enviará como "type" al API)
      // El id se generará en el servidor, así que usamos un valor temporal
      final user = UserEntity(
        id: '', // Se asignará desde el servidor
        email: event.email,
        name: event.name,
        lastname: event.lastname,
        role: 'master', // Siempre "master" según requisito
        phone: event.phone,
        city: event.city,
        dni: event.dni,
      );

      final createdUser = await createUserUseCase(user, event.password);
      emit(UserCreated(createdUser));
    } catch (e) {
      emit(UserError('Error al crear usuario: ${e.toString()}'));
    }
  }
}

