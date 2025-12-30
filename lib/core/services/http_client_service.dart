import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'token_storage_service.dart';

/// Servicio HTTP con interceptor para manejar tokens y refresh automático
class HttpClientService {
  final TokenStorageService _tokenStorage;
  final String baseUrl;

  HttpClientService({
    required TokenStorageService tokenStorage,
    this.baseUrl = 'https://tierra-platform-backend.vercel.app/api',
  }) : _tokenStorage = tokenStorage;

  /// Verificar si el token está expirado
  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  /// Obtener fecha de expiración del token
  DateTime? _getTokenExpiration(String token) {
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      return null;
    }
  }

  /// Refrescar el token automáticamente
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/user/refresh'),
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
    } catch (e) {
      return null;
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

  /// Realizar petición GET
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final token = await _getValidToken();
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
    );

    // Si el token expiró durante la petición, intentar refrescar y reintentar
    if (response.statusCode == 401) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        return await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: requestHeaders,
        );
      }
    }

    return response;
  }

  /// Realizar petición POST
  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
  }) async {
    final token = requiresAuth ? await _getValidToken() : null;
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );

    // Si el token expiró durante la petición, intentar refrescar y reintentar
    if (response.statusCode == 401 && requiresAuth) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        return await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return response;
  }

  /// Realizar petición PUT
  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await _getValidToken();
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 401) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        return await http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return response;
  }

  /// Realizar petición DELETE
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final token = await _getValidToken();
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
    );

    if (response.statusCode == 401) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        requestHeaders['Authorization'] = 'Bearer $newToken';
        return await http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: requestHeaders,
        );
      }
    }

    return response;
  }
}
