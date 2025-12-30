import 'dart:convert';
import '../../core/datasources/user_datasource.dart';
import '../../core/entities/user_entity.dart';
import '../../core/models/auth_response.dart';
import '../../core/services/http_service.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Implementación concreta del datasource de usuarios
class UserDataSourceImpl implements UserDataSource {
  final HttpService _httpService;
  final TokenStorageService _tokenStorage;
  final List<UserEntity> _users = [];

  UserDataSourceImpl({
    required HttpService httpService,
    required TokenStorageService tokenStorage,
  }) : _httpService = httpService,
       _tokenStorage = tokenStorage;

  @override
  Future<List<UserEntity>> getUsers() async {
    return List.from(_users);
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _httpService.post(
        '/user/login',
        body: {'email': email, 'password': password},
        requiresAuth: false, // El login no requiere autenticación
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final authResponse = AuthResponse.fromJson(data);

          // Guardar tokens
          await _tokenStorage.saveToken(
            authResponse.token,
            refreshToken: authResponse.refreshToken,
          );
          // Guardar datos del usuario
          await _tokenStorage.saveUserData(authResponse.user);

          return authResponse;
        } catch (_) {
          throw const ServerException('Error al procesar la respuesta del servidor');
        }
      } else if (response.statusCode == 401) {
        // Credenciales incorrectas
        String errorMessage = 'Credenciales incorrectas';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        throw AuthenticationException(errorMessage);
      } else if (response.statusCode == 400) {
        // Error de validación
        String errorMessage = 'Datos inválidos';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        throw ValidationException(errorMessage);
      } else if (response.statusCode >= 500) {
        // Error del servidor
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        // Otros errores
        String errorMessage = 'Error al iniciar sesión';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        throw ServerException(errorMessage, response.statusCode);
      }
    } on AppException {
      // Re-lanzar excepciones de la aplicación (ya manejadas por HttpService)
      rethrow;
    } catch (e) {
      // Error desconocido
      throw UnknownException('Error inesperado: ${e.toString()}');
    }
  }

  /// Convertir datos del usuario de la API a UserEntity
  UserEntity _mapUserFromApi(Map<String, dynamic> userData) {
    return UserEntity(
      id: userData['id']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
      name: userData['name']?.toString() ?? '',
      lastname: userData['lastname']?.toString() ?? '',
      role: userData['type']?.toString() ?? userData['role']?.toString() ?? '',
      phone: userData['phone'] != null
          ? int.tryParse(userData['phone'].toString())
          : null,
      city: userData['city']?.toString() ?? '',
      dni: userData['dni'] != null
          ? int.tryParse(userData['dni'].toString())
          : null,
    );
  }

  @override
  Future<UserEntity?> getUserByEmail(String email) async {
    try {
      // Primero intentar desde la API
      final response = await _httpService.get('/user/email/$email');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _mapUserFromApi(data);
      }
      // Fallback a mock data
      return _users.firstWhere((user) => user.email == email);
    } catch (e) {
      // Fallback a mock data
      try {
        return _users.firstWhere((user) => user.email == email);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    _users.add(user);
    return user;
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    _users.removeWhere((user) => user.id == id);
  }
}
