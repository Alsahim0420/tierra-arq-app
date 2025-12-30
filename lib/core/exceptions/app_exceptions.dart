/// Excepciones personalizadas para la aplicación

/// Excepción base para errores de la aplicación
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Excepción para errores de red/conexión
class NetworkException extends AppException {
  const NetworkException([String? message])
      : super(
          message ?? 'Error de conexión. Verifica tu conexión a internet.',
          code: 'NETWORK_ERROR',
        );
}

/// Excepción para errores de autenticación
class AuthenticationException extends AppException {
  const AuthenticationException([String? message])
      : super(
          message ?? 'Credenciales incorrectas. Verifica tu email y contraseña.',
          code: 'AUTH_ERROR',
        );
}

/// Excepción para errores del servidor
class ServerException extends AppException {
  final int? statusCode;

  const ServerException([String? message, this.statusCode])
      : super(
          message ?? 'Error del servidor. Intenta más tarde.',
          code: 'SERVER_ERROR',
        );
}

/// Excepción para errores de validación
class ValidationException extends AppException {
  const ValidationException([String? message])
      : super(
          message ?? 'Datos inválidos. Verifica la información ingresada.',
          code: 'VALIDATION_ERROR',
        );
}

/// Excepción para errores desconocidos
class UnknownException extends AppException {
  const UnknownException([String? message])
      : super(
          message ?? 'Ocurrió un error inesperado. Intenta nuevamente.',
          code: 'UNKNOWN_ERROR',
        );
}

