import '../../../core/repositories/user_repository.dart';
import '../../../core/entities/user_entity.dart';

/// Use Case para obtener usuarios maestros con paginación
class GetMasterUsersUseCase {
  final UserRepository repository;

  GetMasterUsersUseCase(this.repository);

  Future<List<UserEntity>> call({int page = 1, int limit = 10}) async {
    return await repository.getMasterUsers(page: page, limit: limit);
  }
}

