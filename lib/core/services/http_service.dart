import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'token_storage_service.dart';
import '../exceptions/app_exceptions.dart';

/// Tipos de petición HTTP disponibles
enum HttpMethod { get, post, put, delete, patch }

class HttpService {
  final TokenStorageService _tokenStorage;
  final String _baseUrl;

  HttpService({required TokenStorageService tokenStorage, String? baseUrl})
    : _tokenStorage = tokenStorage,
      _baseUrl = baseUrl ?? 'https://tierra-platform-backend.vercel.app/api';

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
          response = await _executeRequest(method, url, requestHeaders, body);
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
    final headers = <String, String>{};
    
    // Solo agregar Content-Type: application/json si no se especifica en additionalHeaders
    // o si no está vacío (para permitir descargas binarias sin Content-Type)
    if (additionalHeaders == null || 
        !additionalHeaders.containsKey('Content-Type') ||
        (additionalHeaders['Content-Type']?.isNotEmpty ?? true)) {
      headers['Content-Type'] = 'application/json';
    }
    
    // Agregar headers adicionales (pueden sobrescribir Content-Type)
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
      // Si Content-Type está vacío, removerlo
      if (headers['Content-Type']?.isEmpty ?? false) {
        headers.remove('Content-Type');
      }
    }

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
        return await http.put(Uri.parse(url), headers: headers, body: bodyJson);
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
  }) => request(
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
  }) => request(
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
  }) => request(
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
  }) => request(
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
  }) => request(
    HttpMethod.patch,
    endpoint,
    body: body,
    requiresAuth: requiresAuth,
    headers: headers,
  );

  /// POST request con multipart/form-data (para subida de archivos)
  Future<http.Response> postMultipart(
    String endpoint, {
    required File file,
    String fieldName = 'documento',
    bool requiresAuth = true,
    Map<String, String>? additionalFields,
  }) async {
    try {
      // Construir URL completa
      final url = _buildUrl(endpoint);

      // Crear request multipart
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Agregar headers de autenticación si es necesario
      if (requiresAuth) {
        final token = await _getValidToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Agregar campos adicionales si existen
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Agregar el archivo
      final fileBytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      developer.log(
        '📤 [HttpService] Subiendo archivo:',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📤 [HttpService] Nombre: $fileName',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📤 [HttpService] Extensión: $fileExtension',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📤 [HttpService] Tamaño: ${fileBytes.length} bytes (${(fileBytes.length / 1024).toStringAsFixed(2)} KB)',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📤 [HttpService] Field name: $fieldName',
        name: 'TareaStateFlow',
      );

      // Determinar Content-Type basado en la extensión
      String? contentType;
      switch (fileExtension) {
        case 'xlsx':
          contentType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        case 'csv':
          contentType = 'text/csv';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      developer.log(
        '📤 [HttpService] Content-Type: $contentType',
        name: 'TareaStateFlow',
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: fileName,

          contentType: http.MediaType.parse(contentType),
        ),
      );

      developer.log('📤 [HttpService] URL: $url', name: 'TareaStateFlow');
      developer.log(
        '📤 [HttpService] Headers: ${request.headers}',
        name: 'TareaStateFlow',
      );

      // Enviar request
      developer.log(
        '📤 [HttpService] Enviando petición multipart...',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📤 [HttpService] Total de archivos: ${request.files.length}',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📤 [HttpService] Total de campos: ${request.fields.length}',
        name: 'TareaStateFlow',
      );

      final streamedResponse = await request.send().timeout(
        const Duration(
          minutes: 5,
        ), // Timeout de 5 minutos para archivos grandes
        onTimeout: () {
          developer.log(
            '  [HttpService] Timeout al enviar petición multipart',
            name: 'TareaStateFlow',
          );
          throw TimeoutException(
            'La petición tardó demasiado. El archivo puede ser muy grande.',
          );
        },
      );
      developer.log(
        '📤 [HttpService] StreamedResponse recibido, statusCode: ${streamedResponse.statusCode}',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📤 [HttpService] StreamedResponse headers: ${streamedResponse.headers}',
        name: 'TareaStateFlow',
      );

      final response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(minutes: 2), // Timeout para leer la respuesta
        onTimeout: () {
          developer.log(
            '  [HttpService] Timeout al leer respuesta',
            name: 'TareaStateFlow',
          );
          throw TimeoutException('La respuesta tardó demasiado en llegar.');
        },
      );
      developer.log(
        '📤 [HttpService] Response convertido, statusCode: ${response.statusCode}',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📤 [HttpService] Response body length: ${response.body.length} bytes',
        name: 'TareaStateFlow',
      );

      // Si el token expiró, intentar refrescar y reintentar
      if (response.statusCode == 401 && requiresAuth) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          // Recrear request con nuevo token
          final retryRequest = http.MultipartRequest('POST', Uri.parse(url));
          retryRequest.headers['Authorization'] = 'Bearer $newToken';
          if (additionalFields != null) {
            retryRequest.fields.addAll(additionalFields);
          }
          retryRequest.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              fileBytes,
              filename: file.path.split('/').last,
            ),
          );
          final retryStreamedResponse = await retryRequest.send();
          return await http.Response.fromStream(retryStreamedResponse);
        }
      }

      return response;
    } on AppException {
      rethrow;
    } on http.ClientException catch (e) {
      developer.log(
        '  [HttpService] ClientException: $e',
        name: 'TareaStateFlow',
      );
      throw const NetworkException('Error de conexión. Verifica tu internet.');
    } catch (e, stackTrace) {
      developer.log(
        '  [HttpService] Exception inesperada: $e',
        name: 'TareaStateFlow',
      );
      developer.log(
        '  [HttpService] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException('Error inesperado: ${e.toString()}');
    }
  }
}
