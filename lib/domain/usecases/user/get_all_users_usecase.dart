import '../../../core/repositories/user_repository.dart';
import '../../../core/entities/user_entity.dart';

/// Use Case para obtener todos los usuarios
class GetAllUsersUseCase {
  final UserRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<List<UserEntity>> call() async {
    return await repository.getUsers();
  }
}

