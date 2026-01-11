import '../../../core/entities/user_entity.dart';

/// Utilidades para verificar roles de usuario
class UserRoleUtils {
  /// Verifica si el usuario es administrador
  static bool isAdmin(UserEntity user) {
    return user.role.toLowerCase() == 'admin' || user.role.toLowerCase() == 'administrador';
  }

  /// Verifica si el usuario es maestro
  static bool isMaster(UserEntity user) {
    return user.role.toLowerCase() == 'master' || user.role.toLowerCase() == 'maestro';
  }

  /// Obtiene el nombre de visualización del rol
  static String getRoleDisplayName(UserEntity user) {
    if (isAdmin(user)) {
      return 'Administrador';
    } else if (isMaster(user)) {
      return 'Maestro';
    }
    return user.role; // Retornar el rol original si no coincide
  }
}

