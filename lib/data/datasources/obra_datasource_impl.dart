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

  /// Obtiene todas las obras activas (pendiente y en_proceso) del usuario logueado
  ///
  /// Endpoint: GET /master/obra?estado=activas&page=1&limit=10
  /// El backend filtra automáticamente obras con estado "pendiente" y "en_proceso"
  /// Retorna lista paginada de obras activas (solo la primera página por defecto)
  @override
  Future<List<ObraEntity>> getObras() async {
    try {
      // Usar el nuevo endpoint con parámetros de paginación y filtro de estado
      // Por defecto, obtener página 1 con límite de 10 obras
      // El backend filtra automáticamente obras activas (pendiente y en_proceso)
      final response = await _httpService.get(
        '/master/obra?estado=activas&page=1&limit=10',
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La nueva respuesta tiene estructura paginada:
        // {"status":"success","data":{"docs":[...],"totalDocs":7,"limit":10,"page":1,...}}
        if (data.containsKey('data') && data['data'] is Map) {
          final dataObj = data['data'] as Map<String, dynamic>;
          
          // Buscar la lista de obras en 'docs' (estructura paginada)
          if (dataObj.containsKey('docs') && dataObj['docs'] is List) {
            final obrasList = dataObj['docs'] as List;
            return obrasList
                .map((item) => _mapObraFromApi(item as Map<String, dynamic>))
                .toList();
          }
          
          // Fallback: si viene la estructura antigua con 'obras' directamente
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

  /// Obtiene todas las obras finalizadas del usuario logueado
  ///
  /// Endpoint: GET /master/obra?estado=finalizadas&sort=updatedAt:desc&page={page}&limit={limit}
  /// El backend filtra automáticamente obras con estado "finalizado"
  /// Retorna lista paginada de obras finalizadas, ordenadas por fecha de actualización descendente
  @override
  Future<List<ObraEntity>> getObrasFinalizadas({int page = 1, int limit = 10}) async {
    try {
      // Usar el endpoint con parámetros de paginación, filtro de estado y ordenamiento
      final response = await _httpService.get(
        '/master/obra?estado=finalizadas&sort=updatedAt:desc&page=$page&limit=$limit',
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La respuesta tiene estructura paginada:
        // {"status":"success","data":{"docs":[...],"totalDocs":1,"limit":10,"page":1,...}}
        if (data.containsKey('data') && data['data'] is Map) {
          final dataObj = data['data'] as Map<String, dynamic>;
          
          // Buscar la lista de obras en 'docs' (estructura paginada)
          if (dataObj.containsKey('docs') && dataObj['docs'] is List) {
            final obrasList = dataObj['docs'] as List;
            return obrasList
                .map((item) => _mapObraFromApi(item as Map<String, dynamic>))
                .toList();
          }
          
          // Fallback: si viene la estructura antigua con 'obras' directamente
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
        throw ServerException('Error al obtener obras finalizadas', response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al obtener obras finalizadas: ${e.toString()}');
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
      costoEstimado: data['costoEstimado'] ?? data['costo_estimado'] ?? data['estimatedCost'] != null
          ? (data['costoEstimado'] ?? data['costo_estimado'] ?? data['estimatedCost']).toDouble()
          : null,
      responsable: _mapUserFromApi(responsableData),
      tareas: _mapTareasFromApi(tareasList),
      estado: data['estado']?.toString() ?? 'pendiente',
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

  /// Normalizar el estado de la tarea desde la API
  String _normalizeTareaState(String state) {
    final normalized = state.toLowerCase().trim();
    if (normalized == 'en_proceso' || normalized == 'en_progreso') {
      return 'en progreso';
    }
    if (normalized == 'pendiente' || normalized == 'pending') {
      return 'pendiente';
    }
    if (normalized == 'finalizado' ||
        normalized == 'finalizada' ||
        normalized == 'completada' ||
        normalized == 'completado' ||
        normalized == 'completed') {
      return 'finalizado';
    }
    // Si no coincide, devolver el valor normalizado tal cual
    return normalized;
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

          // Mapear obra_tarea_id si existe
          final obraTareaId = tareaData['obra_tarea_id']?.toString();

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
            state: _normalizeTareaState(
                tareaData['status']?.toString() ??
                tareaData['state']?.toString() ??
                'pendiente'),
            duration: tareaData['duration'] != null
                ? int.tryParse(tareaData['duration'].toString()) ?? 0
                : 0,
            evidences: evidences,
            assignedTo: assignedTo,
            observation: tareaData['observation']?.toString(),
            obraTareaId: obraTareaId,
          );
        })
        .whereType<TareaEntity>()
        .toList();
  }

  @override
  Future<ObraEntity> createObra(ObraEntity obra) async {
    try {
      // Construir el body según el formato del endpoint
      // Incluye el array de IDs de tareas si existen
      final body = <String, dynamic>{
        'title': obra.title,
        'description': obra.description,
        'location': obra.location,
        'city': obra.city,
        'responsable': obra.responsable.id, // Solo enviar el ID del responsable
        'costo': obra.costo,
        if (obra.costoEstimado != null) 'costoEstimado': obra.costoEstimado,
      };

      // Si hay tareas asociadas, extraer solo los IDs y agregarlos al body
      if (obra.tareas.isNotEmpty) {
        final tareaIds = obra.tareas
            .where((tarea) => tarea.id.isNotEmpty) // Solo IDs válidos
            .map((tarea) => tarea.id)
            .toList();
        
        if (tareaIds.isNotEmpty) {
          body['tareas'] = tareaIds;
        }
      }

      final response = await _httpService.post(
        '/master/obra',
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // La respuesta puede venir en diferentes formatos
        Map<String, dynamic> obraData;
        if (data.containsKey('data')) {
          if (data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            if (dataObj.containsKey('obra')) {
              obraData = dataObj['obra'] as Map<String, dynamic>;
            } else {
              obraData = dataObj;
            }
          } else {
            obraData = {};
          }
        } else if (data.containsKey('obra')) {
          obraData = data['obra'] as Map<String, dynamic>;
        } else {
          obraData = data;
        }

        final createdObra = _mapObraFromApi(obraData);
        return createdObra;
      } else if (response.statusCode == 400) {
        String errorMessage = 'Datos inválidos';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        throw ValidationException(errorMessage);
      } else if (response.statusCode == 409) {
        String errorMessage = 'Ya existe una obra con estos datos';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        throw ValidationException(errorMessage);
      } else if (response.statusCode == 401) {
        throw AuthenticationException('No autorizado');
      } else if (response.statusCode >= 500) {
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al crear obra';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        throw ServerException(errorMessage, response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al crear obra: ${e.toString()}');
    }
  }

  @override
  Future<ObraEntity> updateObra(ObraEntity obra) async {
    // Método no implementado - no se usa en la aplicación actual
    // Retornar la misma obra sin cambios para evitar errores
    return obra;
  }
  
  @override
  Future<void> deleteObra(String id) async {
    // Método no implementado - no se usa en la aplicación actual
    // No hacer nada para evitar errores
    return;
  }
}
