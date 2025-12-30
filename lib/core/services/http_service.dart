import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'token_storage_service.dart';
import '../exceptions/app_exceptions.dart';

/// Tipos de petición HTTP disponibles
enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch,
}

/// Servicio HTTP global limpio y fácil de usar
/// 
/// Uso:
/// ```dart
/// final response = await httpService.request(
///   HttpMethod.post,
///   '/user/login',
///   body: {'email': email, 'password': password},
///   requiresAuth: false,
/// );
/// ```
class HttpService {
  final TokenStorageService _tokenStorage;
  final String _baseUrl;

  HttpService({
    required TokenStorageService tokenStorage,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
        _baseUrl = baseUrl ?? 'https://tierra-platform-backend.vercel.app/api';

  /// Método principal para realizar peticiones HTTP
  /// 
  /// [method] - Tipo de petición (GET, POST, PUT, DELETE, PATCH)
  /// [endpoint] - Endpoint de la API (ej: '/user/login')
  /// [body] - Cuerpo de la petición (opcional)
  /// [requiresAuth] - Si requiere autenticación (default: true)
  /// [headers] - Headers adicionales (opcional)
  /// 
  /// Retorna la respuesta HTTP
  Future<http.Response> request(
    HttpMethod method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    try {
      // Construir URL completa
      final url = _buildUrl(endpoint);

      // Obtener headers con autenticación si es necesario
      final requestHeaders = await _buildHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: headers,
      );

      // Realizar petición según el método
      http.Response response = await _executeRequest(
        method,
        url,
        requestHeaders,
        body,
      );

      // Si el token expiró, intentar refrescar y reintentar
      if (response.statusCode == 401 && requiresAuth) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          requestHeaders['Authorization'] = 'Bearer $newToken';
          response = await _executeRequest(
            method,
            url,
            requestHeaders,
            body,
          );
        }
      }

      return response;
    } on AppException {
      rethrow;
    } on http.ClientException {
      throw const NetworkException('Error de conexión. Verifica tu internet.');
    } catch (e) {
      throw UnknownException('Error inesperado: ${e.toString()}');
    }
  }

  /// Construir URL completa
  String _buildUrl(String endpoint) {
    // Asegurar que el endpoint empiece con '/'
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$_baseUrl$cleanEndpoint';
  }

  /// Construir headers de la petición
  Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    if (requiresAuth) {
      final token = await _getValidToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Ejecutar la petición HTTP según el método
  Future<http.Response> _executeRequest(
    HttpMethod method,
    String url,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    final bodyJson = body != null ? jsonEncode(body) : null;

    switch (method) {
      case HttpMethod.get:
        return await http.get(Uri.parse(url), headers: headers);
      case HttpMethod.post:
        return await http.post(
          Uri.parse(url),
          headers: headers,
          body: bodyJson,
        );
      case HttpMethod.put:
        return await http.put(
          Uri.parse(url),
          headers: headers,
          body: bodyJson,
        );
      case HttpMethod.delete:
        return await http.delete(Uri.parse(url), headers: headers);
      case HttpMethod.patch:
        return await http.patch(
          Uri.parse(url),
          headers: headers,
          body: bodyJson,
        );
    }
  }

  /// Obtener token válido (refresca si es necesario)
  Future<String?> _getValidToken() async {
    var token = await _tokenStorage.getToken();
    if (token == null) return null;

    // Verificar si el token está por expirar (menos de 5 minutos)
    final expiration = _getTokenExpiration(token);
    if (expiration != null) {
      final now = DateTime.now();
      final timeUntilExpiration = expiration.difference(now);

      // Si falta menos de 5 minutos, refrescar
      if (timeUntilExpiration.inMinutes < 5) {
        token = await _refreshToken();
      }
    }

    // Si está expirado, intentar refrescar
    if (token != null && _isTokenExpired(token)) {
      token = await _refreshToken();
    }

    return token;
  }

  /// Verificar si el token está expirado
  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  /// Obtener fecha de expiración del token
  DateTime? _getTokenExpiration(String token) {
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (_) {
      return null;
    }
  }

  /// Refrescar el token automáticamente
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/user/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = data['token'] as String;
        await _tokenStorage.saveToken(newToken);
        if (data.containsKey('refreshToken')) {
          await _tokenStorage.saveRefreshToken(data['refreshToken'] as String);
        }
        return newToken;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ========== MÉTODOS CONVENIENCIA ==========

  /// GET request
  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) =>
      request(
        HttpMethod.get,
        endpoint,
        requiresAuth: requiresAuth,
        headers: headers,
      );

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) =>
      request(
        HttpMethod.post,
        endpoint,
        body: body,
        requiresAuth: requiresAuth,
        headers: headers,
      );

  /// PUT request
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) =>
      request(
        HttpMethod.put,
        endpoint,
        body: body,
        requiresAuth: requiresAuth,
        headers: headers,
      );

  /// DELETE request
  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) =>
      request(
        HttpMethod.delete,
        endpoint,
        requiresAuth: requiresAuth,
        headers: headers,
      );

  /// PATCH request
  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) =>
      request(
        HttpMethod.patch,
        endpoint,
        body: body,
        requiresAuth: requiresAuth,
        headers: headers,
      );
}

