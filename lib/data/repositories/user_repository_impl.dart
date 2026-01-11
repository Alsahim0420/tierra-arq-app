import '../../core/datasources/user_datasource.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/entities/user_entity.dart';
import '../../core/models/auth_response.dart';

/// Implementación concreta del repository de usuarios
class UserRepositoryImpl implements UserRepository {
  final UserDataSource dataSource;

  UserRepositoryImpl(this.dataSource);

  @override
  Future<AuthResponse> login(String email, String password) async {
    return await dataSource.login(email, password);
  }

  @override
  Future<List<UserEntity>> getUsers() async {
    return await dataSource.getUsers();
  }

  @override
  Future<List<UserEntity>> getMasterUsers({int page = 1, int limit = 10}) async {
    return await dataSource.getMasterUsers(page: page, limit: limit);
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    return await dataSource.getUserById(id);
  }

  @override
  Future<UserEntity?> getUserByEmail(String email) async {
    return await dataSource.getUserByEmail(email);
  }

  @override
  Future<UserEntity> createUser(UserEntity user, String password) async {
    return await dataSource.createUser(user, password);
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    return await dataSource.updateUser(user);
  }

  @override
  Future<void> deleteUser(String id) async {
    return await dataSource.deleteUser(id);
  }
}
