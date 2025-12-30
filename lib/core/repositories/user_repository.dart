import '../entities/user_entity.dart';
import '../models/auth_response.dart';

/// Repository abstracto para usuarios
abstract class UserRepository {
  Future<AuthResponse> login(String email, String password);
  Future<List<UserEntity>> getUsers();
  Future<UserEntity?> getUserById(String id);
  Future<UserEntity?> getUserByEmail(String email);
  Future<UserEntity> createUser(UserEntity user);
  Future<UserEntity> updateUser(UserEntity user);
  Future<void> deleteUser(String id);
}
