import '../../../core/repositories/user_repository.dart';
import '../../../core/entities/user_entity.dart';

/// Use Case para crear un nuevo usuario
class CreateUserUseCase {
  final UserRepository repository;

  CreateUserUseCase(this.repository);

  Future<UserEntity> call(UserEntity user, String password) async {
    return await repository.createUser(user, password);
  }
}

