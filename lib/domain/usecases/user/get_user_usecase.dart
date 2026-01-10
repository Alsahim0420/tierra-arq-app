import '../../../core/repositories/user_repository.dart';
import '../../../core/entities/user_entity.dart';

/// Use Case para obtener usuario por ID
class GetUserUseCase {
  final UserRepository repository;

  GetUserUseCase(this.repository);

  Future<UserEntity?> call(String id) async {
    return await repository.getUserById(id);
  }
}

