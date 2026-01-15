import '../../core/repositories/user_repository.dart';
import '../../core/entities/user_entity.dart';
import '../../core/models/auth_response.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/mappers/user_mapper.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Use case para iniciar sesión
class LoginUseCase {
  final UserRepository _repository;

  LoginUseCase(this._repository);

  Future<AuthResponse> call(String email, String password) async {
    return await _repository.login(email, password);
  }
}

/// Use case para cerrar sesión
class LogoutUseCase {
  final TokenStorageService _tokenStorage;

  LogoutUseCase(this._tokenStorage);

  Future<void> call() async {
    await _tokenStorage.clearAll();
  }
}

/// Use case para obtener el usuario actual desde el token
class GetCurrentUserUseCase {
  final TokenStorageService _tokenStorage;
  final UserRepository _repository;

  GetCurrentUserUseCase(this._tokenStorage, this._repository);

  Future<UserEntity?> call() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) return null;

      // Verificar si el token es válido
      if (JwtDecoder.isExpired(token)) {
        await _tokenStorage.clearAll();
        return null;
      }

      // Primero intentar obtener el usuario desde los datos guardados (UserModel)
      final userModel = await _tokenStorage.getUserData();
      if (userModel != null) {
        return UserMapper.toEntity(userModel);
      }

      // Si no hay datos guardados, intentar desde el token
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId =
          decodedToken['id']?.toString() ??
          decodedToken['userId']?.toString() ??
          decodedToken['sub']?.toString();

      if (userId != null) {
        // Obtener el usuario desde el repository
        return await _repository.getUserById(userId);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
