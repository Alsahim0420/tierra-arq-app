import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/datasources/obra_datasource.dart';
import '../../core/entities/obra_entity.dart';
import '../../core/entities/user_entity.dart';
import '../../core/entities/tarea_entity.dart';
import '../../core/services/http_service.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Implementación concreta del datasource de obras
class ObraDataSourceImpl implements ObraDataSource {
  final HttpService _httpService;
  final TokenStorageService _tokenStorage;

  ObraDataSourceImpl({
    required HttpService httpService,
    required TokenStorageService tokenStorage,
  }) : _httpService = httpService,
       _tokenStorage = tokenStorage;

  /// Obtiene todas las obras del usuario logueado
  ///
  /// Endpoint: GET /master/responsable/{userId}
  /// Obtiene automáticamente el ID del usuario desde el token JWT
  /// Retorna lista de todas las obras del usuario responsable
  @override
  Future<List<ObraEntity>> getObras() async {
    try {
      // Obtener el ID del usuario desde el token
      final userId = await _getUserIdFromToken();
      if (userId.isEmpty) {
        throw const ServerException(
          'No se pudo obtener el ID del usuario desde el token',
        );
      }

      final response = await _httpService.get('/master/responsable/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La respuesta tiene estructura: {"status":"success","data":{"user":{...},"obras":[...]}}
        if (data.containsKey('data') && data['data'] is Map) {
          final dataObj = data['data'] as Map<String, dynamic>;
          if (dataObj.containsKey('obras') && dataObj['obras'] is List) {
            final obrasList = dataObj['obras'] as List;
            return obrasList
                .map((item) => _mapObraFromApi(item as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ServerException('Error al obtener obras', response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al obtener obras: ${e.toString()}');
    }
  }

  /// Obtiene todas las obras de un responsable específico
  ///
  /// Endpoint: GET /master/responsable/{userId}
  /// Requiere autenticación Bearer token
  ///
  /// [userId] - ID del usuario responsable (usuario logueado)
  /// Si userId está vacío o es null, se obtiene automáticamente del token
  /// Retorna lista de obras asignadas a ese responsable
  @override
  Future<List<ObraEntity>> getObrasByResponsable(String userId) async {
    try {
      // Si no se proporciona userId, obtenerlo del token
      String finalUserId = userId;
      if (finalUserId.isEmpty) {
        finalUserId = await _getUserIdFromToken();
        if (finalUserId.isEmpty) {
          throw const ServerException(
            'No se pudo obtener el ID del usuario desde el token',
          );
        }
      }

      final response = await _httpService.get(
        '/master/responsable/$finalUserId',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La respuesta tiene estructura: {"status":"success","data":{"user":{...},"obras":[...]}}
        if (data.containsKey('data') && data['data'] is Map) {
          final dataObj = data['data'] as Map<String, dynamic>;
          if (dataObj.containsKey('obras') && dataObj['obras'] is List) {
            final obrasList = dataObj['obras'] as List;
            return obrasList
                .map((item) => _mapObraFromApi(item as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw ServerException('Error al obtener obras', response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al obtener obras: ${e.toString()}');
    }
  }

  /// Obtiene el ID del usuario desde el token JWT
  Future<String> _getUserIdFromToken() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return '';
      }

      // Decodificar el token JWT
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // Extraer el ID del usuario del token
      final userId =
          decodedToken['id']?.toString() ??
          decodedToken['userId']?.toString() ??
          decodedToken['sub']?.toString() ??
          '';

      return userId;
    } catch (e) {
      return '';
    }
  }

  /// Mapear respuesta del API a ObraEntity
  ObraEntity _mapObraFromApi(Map<String, dynamic> data) {
    // Mapear responsable de forma segura
    Map<String, dynamic> responsableData = {};
    if (data['responsable'] != null) {
      if (data['responsable'] is Map) {
        responsableData = data['responsable'] as Map<String, dynamic>;
      } else if (data['responsable'] is String) {
        // Si viene como String (ID), crear un objeto básico
        responsableData = {'id': data['responsable']};
      }
    }

    // Mapear tareas de forma segura
    List<dynamic> tareasList = [];
    if (data['tareas'] != null && data['tareas'] is List) {
      tareasList = data['tareas'] as List<dynamic>;
    }

    return ObraEntity(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      costo: (data['costo'] ?? data['cost'] ?? 0.0).toDouble(),
      responsable: _mapUserFromApi(responsableData),
      tareas: _mapTareasFromApi(tareasList),
    );
  }

  /// Mapear usuario desde API
  UserEntity _mapUserFromApi(Map<String, dynamic> data) {
    return UserEntity(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      lastname: data['lastname']?.toString() ?? '',
      role: data['type']?.toString() ?? data['role']?.toString() ?? '',
      phone: data['phone'] != null
          ? int.tryParse(data['phone'].toString())
          : null,
      city: data['city']?.toString() ?? '',
      dni: data['dni'] != null ? int.tryParse(data['dni'].toString()) : null,
    );
  }

  /// Mapear tareas desde API
  List<TareaEntity> _mapTareasFromApi(List<dynamic> data) {
    return data
        .map((item) {
          if (item is! Map<String, dynamic>) return null;
          final tareaData = item;

          // Mapear assignedTo de forma segura
          UserEntity? assignedTo;
          if (tareaData['assignedTo'] != null) {
            if (tareaData['assignedTo'] is Map) {
              assignedTo = _mapUserFromApi(
                tareaData['assignedTo'] as Map<String, dynamic>,
              );
            } else if (tareaData['assignedTo'] is String) {
              // Si viene como String (ID), crear un objeto básico
              assignedTo = _mapUserFromApi({'id': tareaData['assignedTo']});
            }
          }

          // Mapear evidences de forma segura
          List<String> evidences = [];
          if (tareaData['evidences'] != null &&
              tareaData['evidences'] is List) {
            evidences = (tareaData['evidences'] as List)
                .map((e) => e.toString())
                .toList();
          }

          return TareaEntity(
            id:
                tareaData['_id']?.toString() ??
                tareaData['id']?.toString() ??
                '',
            name:
                tareaData['title']?.toString() ??
                tareaData['name']?.toString() ??
                '',
            description: tareaData['description']?.toString() ?? '',
            state:
                tareaData['status']?.toString() ??
                tareaData['state']?.toString() ??
                'pendiente',
            duration: tareaData['duration'] != null
                ? int.tryParse(tareaData['duration'].toString()) ?? 0
                : 0,
            evidences: evidences,
            assignedTo: assignedTo,
          );
        })
        .whereType<TareaEntity>()
        .toList();
  }

  @override
  Future<ObraEntity> createObra(ObraEntity obra) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de creación no implementado');
  }

  @override
  Future<ObraEntity> updateObra(ObraEntity obra) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de actualización no implementado');
  }

  @override
  Future<void> deleteObra(String id) async {
    // TODO: Implementar cuando esté disponible el endpoint
    throw const ServerException('Endpoint de eliminación no implementado');
  }
}
