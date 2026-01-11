import '../entities/user_entity.dart';
import '../models/auth_response.dart';

/// Datasource abstracto para usuarios
abstract class UserDataSource {
  Future<AuthResponse> login(String email, String password);
  Future<List<UserEntity>> getUsers();
  Future<List<UserEntity>> getMasterUsers({int page = 1, int limit = 10});
  Future<UserEntity?> getUserById(String id);
  Future<UserEntity?> getUserByEmail(String email);
  Future<UserEntity> createUser(UserEntity user, String password);
  Future<UserEntity> updateUser(UserEntity user);
  Future<void> deleteUser(String id);
}
