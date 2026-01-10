import '../../../core/repositories/user_repository.dart';
import '../../../core/entities/user_entity.dart';

/// Use Case para login
class LoginUseCase {
  final UserRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity?> call(String email, String password) async {
    // En producción, aquí se validaría la contraseña
    final user = await repository.getUserByEmail(email);
    if (user != null) {
      // Simular validación de contraseña
      // En producción, esto se haría con hash y comparación segura
      return user;
    }
    return null;
  }
}

