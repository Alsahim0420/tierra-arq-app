import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/datasources/obra_datasource.dart';
import '../../core/entities/obra_entity.dart';
import '../../core/entities/user_entity.dart';
import '../../core/entities/tarea_entity.dart';
import '../../core/entities/reporte_pdf_entity.dart';
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

  @override
  Future<List<ObraEntity>> getObras() async {
    try {
      // Obtener el tipo de usuario
      final userType = await _getUserTypeFromToken();

      // Si el usuario es 'master', obtener solo sus obras como responsable
      if (userType == 'master') {
        final userId = await _getUserIdFromToken();
        if (userId.isEmpty) {
          return [];
        }
        return await getObrasByResponsable(userId);
      }

      final response = await _httpService.get(
        '/master/obra?estado=activas&page=1&limit=10',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

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

  @override
  Future<List<ObraEntity>> getObrasFinalizadas({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Obtener el tipo de usuario
      final userType = await _getUserTypeFromToken();

      // Si el usuario es 'master', obtener sus obras y filtrar las finalizadas
      if (userType == 'master') {
        final userId = await _getUserIdFromToken();
        if (userId.isEmpty) {
          return [];
        }

        // Obtener todas las obras del responsable y filtrar las finalizadas
        final todasLasObras = await getObrasByResponsable(userId);
        final obrasFinalizadas = todasLasObras
            .where((obra) => obra.estado.toLowerCase() == 'finalizado')
            .toList();

        return obrasFinalizadas;
      }

      // Si el usuario es 'admin' o tipo desconocido, obtener todas las obras finalizadas

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
        throw ServerException(
          'Error al obtener obras finalizadas',
          response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        'Error al obtener obras finalizadas: ${e.toString()}',
      );
    }
  }

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

  /// Obtiene el tipo de usuario (admin o master) desde el token o almacenamiento
  Future<String> _getUserTypeFromToken() async {
    try {
      // Primero intentar obtener desde TokenStorageService (más confiable)
      final userModel = await _tokenStorage.getUserData();
      if (userModel != null && userModel.type.isNotEmpty) {
        return userModel.type.toLowerCase();
      }

      // Si no está en UserModel, intentar desde el token JWT
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        return ''; // Retornar vacío si no hay token
      }

      // Decodificar el token JWT
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // Extraer el tipo de usuario del token
      final userType =
          decodedToken['type']?.toString() ??
          decodedToken['role']?.toString() ??
          '';

      if (userType.isNotEmpty) {
        return userType.toLowerCase();
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  /// Mapear respuesta del API a ObraEntity
  ObraEntity _mapObraFromApi(Map<String, dynamic> data) {
    Map<String, dynamic> responsableData = {};
    if (data['responsable'] != null) {
      if (data['responsable'] is Map) {
        responsableData = data['responsable'] as Map<String, dynamic>;
      } else if (data['responsable'] is String) {
        responsableData = {'id': data['responsable']};
      }
    }

    List<dynamic> tareasList = [];
    if (data['tareas'] != null && data['tareas'] is List) {
      tareasList = data['tareas'] as List<dynamic>;
    }

    UserEntity responsable = _mapUserFromApi(responsableData);
    List<TareaEntity> tareas = _mapTareasFromApi(tareasList);

    // Mapear costoEstimado de forma segura
    final costoEstimadoValue =
        data['costoEstimado'] ??
        data['costo_estimado'] ??
        data['estimatedCost'];
    final double? costoEstimado = costoEstimadoValue != null
        ? (costoEstimadoValue as num).toDouble()
        : null;

    // Mapear costoFinal de forma segura
    final costoFinalValue =
        data['costoFinal'] ?? data['costo_final'] ?? data['finalCost'];
    double? costoFinal;
    if (costoFinalValue != null) {
      if (costoFinalValue is num) {
        costoFinal = costoFinalValue.toDouble();
      } else if (costoFinalValue is String) {
        costoFinal = double.tryParse(costoFinalValue);
      }
    }

    // Mapear fechas de forma segura
    DateTime? fechaInicio;
    if (data['fecha_inicio'] != null) {
      try {
        fechaInicio = DateTime.parse(data['fecha_inicio'].toString());
      } catch (_) {
        fechaInicio = null;
      }
    }

    DateTime? fechaFin;
    if (data['fecha_fin'] != null) {
      try {
        fechaFin = DateTime.parse(data['fecha_fin'].toString());
      } catch (_) {
        fechaFin = null;
      }
    }

    DateTime? fechaEntrega;
    if (data['fecha_entrega'] != null) {
      try {
        fechaEntrega = DateTime.parse(data['fecha_entrega'].toString());
      } catch (_) {
        fechaEntrega = null;
      }
    }

    final obra = ObraEntity(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      departamento: data['departamento']?.toString(),
      costo: (data['costo'] ?? data['cost'] ?? 0.0).toDouble(),
      costoEstimado: costoEstimado,
      costoFinal: costoFinal,
      responsable: responsable,
      tareas: tareas,
      estado: data['estado']?.toString() ?? 'pendiente',
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      fechaEntrega: fechaEntrega,
    );
    return obra;
  }

  /// Mapear usuario desde API
  UserEntity _mapUserFromApi(Map<String, dynamic> data) {
    int? phone;
    if (data['phone'] != null) {
      if (data['phone'] is int) {
        phone = data['phone'] as int;
      } else {
        phone = int.tryParse(data['phone'].toString());
      }
    }

    int? dni;
    if (data['dni'] != null) {
      if (data['dni'] is int) {
        dni = data['dni'] as int;
      } else {
        dni = int.tryParse(data['dni'].toString());
      }
    }

    return UserEntity(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      lastname: data['lastname']?.toString() ?? '',
      role: data['type']?.toString() ?? data['role']?.toString() ?? '',
      phone: phone,
      city: data['city']?.toString() ?? '',
      dni: dni,
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
    if (normalized == 'estancado' ||
        normalized == 'estancada' ||
        normalized == 'stalled') {
      return 'estancado';
    }
    // Si no coincide, devolver el valor normalizado tal cual
    return normalized;
  }

  /// Mapear tareas desde API
  List<TareaEntity> _mapTareasFromApi(List<dynamic> data) {
    return data
        .asMap()
        .entries
        .map((entry) {
          final item = entry.value;

          if (item is! Map<String, dynamic>) {
            return null;
          }
          final tareaData = item;

          UserEntity? assignedTo;
          if (tareaData['assignedTo'] != null) {
            if (tareaData['assignedTo'] is Map) {
              assignedTo = _mapUserFromApi(
                tareaData['assignedTo'] as Map<String, dynamic>,
              );
            } else if (tareaData['assignedTo'] is String) {
              assignedTo = _mapUserFromApi({'id': tareaData['assignedTo']});
            }
          }

          List<String> evidences = [];
          if (tareaData['evidences'] != null &&
              tareaData['evidences'] is List) {
            evidences = (tareaData['evidences'] as List)
                .map((e) => e.toString())
                .toList();
          }

          final obraTareaId = tareaData['obra_tarea_id']?.toString();
          final tareaId =
              tareaData['_id']?.toString() ?? tareaData['id']?.toString() ?? '';
          final tareaName =
              tareaData['title']?.toString() ??
              tareaData['name']?.toString() ??
              '';
          final tareaDescription = tareaData['description']?.toString() ?? '';
          final tareaStateRaw =
              tareaData['status']?.toString() ??
              tareaData['state']?.toString() ??
              'pendiente';
          final tareaState = _normalizeTareaState(tareaStateRaw);

          int duration = 0;
          if (tareaData['duration'] != null) {
            if (tareaData['duration'] is int) {
              duration = tareaData['duration'] as int;
            } else {
              duration = int.tryParse(tareaData['duration'].toString()) ?? 0;
            }
          }

          final tareaObservation = tareaData['observation']?.toString();

          // Mapear costo si existe
          double? costo;
          if (tareaData['costo'] != null) {
            final costoValue = tareaData['costo'];
            if (costoValue is num) {
              costo = costoValue.toDouble();
            } else if (costoValue is String) {
              costo = double.tryParse(costoValue);
            }
          }

          return TareaEntity(
            id: tareaId,
            name: tareaName,
            description: tareaDescription,
            state: tareaState,
            duration: duration,
            evidences: evidences,
            assignedTo: assignedTo,
            observation: tareaObservation,
            obraTareaId: obraTareaId,
            costo: costo,
          );
        })
        .whereType<TareaEntity>()
        .toList();
  }

  @override
  Future<ObraEntity> createObra(ObraEntity obra) async {
    try {
      final body = <String, dynamic>{
        'title': obra.title,
        'description': obra.description,
        'location': obra.location,
        'city': obra.city,
        if (obra.departamento != null) 'departamento': obra.departamento,
        'responsable': obra.responsable.id, // Solo enviar el ID del responsable
        'costo': obra.costo,
        if (obra.costoEstimado != null) 'costoEstimado': obra.costoEstimado,
        if (obra.fechaInicio != null)
          'fecha_inicio': obra.fechaInicio!.toIso8601String(),
        if (obra.fechaEntrega != null)
          'fechaEntrega': obra.fechaEntrega!.toIso8601String(),
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

      final response = await _httpService.post('/master/obra', body: body);

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
  Future<ObraEntity> processDocument(File file) async {
    try {
      developer.log(
        '📄 [ProcessDocument] Iniciando procesamiento de documento',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📄 [ProcessDocument] Llamando a postMultipart...',
        name: 'TareaStateFlow',
      );

      final response = await _httpService.postMultipart(
        '/master/documento/procesar',
        file: file,
        fieldName: 'documento',
      );

      developer.log(
        '📄 [ProcessDocument] postMultipart completado',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📄 [ProcessDocument] Response status: ${response.statusCode}',
        name: 'TareaStateFlow',
      );
      developer.log(
        '📄 [ProcessDocument] Response body: ${response.body}',
        name: 'TareaStateFlow',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La respuesta viene con estructura: { status, message, obra, processing_time_ms }
        if (data.containsKey('obra') && data['obra'] is Map) {
          final obraData = data['obra'] as Map<String, dynamic>;
          final obra = _mapObraFromApi(obraData);

          developer.log(
            '📄 [ProcessDocument] Obra procesada exitosamente: ${obra.id}',
            name: 'TareaStateFlow',
          );
          developer.log(
            '📄 [ProcessDocument] Tareas procesadas: ${obra.tareas.length}',
            name: 'TareaStateFlow',
          );

          return obra;
        } else {
          throw ServerException(
            'Respuesta del servidor en formato inesperado',
            response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        throw const AuthenticationException('No autorizado');
      } else if (response.statusCode >= 500) {
        String errorMessage =
            'Error interno del servidor al procesar el documento';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          // Intentar obtener el mensaje de error de diferentes campos posibles
          errorMessage =
              errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              errorData['msg']?.toString() ??
              errorMessage;

          // Si hay detalles adicionales, agregarlos al log
          if (errorData.containsKey('details')) {
            developer.log(
              '📄 [ProcessDocument] Error details: ${errorData['details']}',
              name: 'TareaStateFlow',
            );
          }
          if (errorData.containsKey('stack')) {
            developer.log(
              '📄 [ProcessDocument] Error stack: ${errorData['stack']}',
              name: 'TareaStateFlow',
            );
          }
        } catch (e) {
          // Si no se puede parsear como JSON, usar el body completo o mensaje por defecto
          developer.log(
            '📄 [ProcessDocument] No se pudo parsear error como JSON: $e',
            name: 'TareaStateFlow',
          );
          if (response.body.isNotEmpty &&
              !response.body.startsWith('<!DOCTYPE')) {
            errorMessage =
                'Error del servidor: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}';
          }
        }
        developer.log(
          '  [ProcessDocument] Error 500: $errorMessage',
          name: 'TareaStateFlow',
        );
        throw ServerException(errorMessage, response.statusCode);
      } else {
        String errorMessage = 'Error al procesar documento';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              errorData['msg']?.toString() ??
              errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        developer.log(
          '  [ProcessDocument] Error ${response.statusCode}: $errorMessage',
          name: 'TareaStateFlow',
        );
        throw ServerException(errorMessage, response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        '  [ProcessDocument] Exception: $e',
        name: 'TareaStateFlow',
      );
      developer.log(
        '  [ProcessDocument] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException('Error al procesar documento: ${e.toString()}');
    }
  }

  @override
  Future<ObraEntity> updateObra(ObraEntity obra) async {
    try {
      developer.log(
        '  [UpdateObra] Actualizando obra: ${obra.id}',
        name: 'TareaStateFlow',
      );

      if (obra.id.isEmpty) {
        throw ValidationException('No se puede actualizar una obra sin ID');
      }

      final body = <String, dynamic>{
        'title': obra.title,
        'description': obra.description,
        'location': obra.location,
        'city': obra.city,
        if (obra.departamento != null) 'departamento': obra.departamento,
        if (obra.responsable.id.isNotEmpty) 'responsable': obra.responsable.id,
        'costo': obra.costo,
        if (obra.costoEstimado != null) 'costoEstimado': obra.costoEstimado,
        if (obra.fechaInicio != null)
          'fecha_inicio': obra.fechaInicio!.toIso8601String(),
        if (obra.fechaEntrega != null)
          'fechaEntrega': obra.fechaEntrega!.toIso8601String(),
      };

      final response = await _httpService.put(
        '/master/obra/${obra.id}',
        body: body,
      );

      developer.log(
        '  [UpdateObra] Response status: ${response.statusCode}',
        name: 'TareaStateFlow',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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
            obraData = data;
          }
        } else if (data.containsKey('obra')) {
          obraData = data['obra'] as Map<String, dynamic>;
        } else {
          obraData = data;
        }

        final updatedObra = _mapObraFromApi(obraData);
        developer.log(
          '  [UpdateObra] Obra actualizada exitosamente',
          name: 'TareaStateFlow',
        );
        return updatedObra;
      } else if (response.statusCode == 401) {
        throw const AuthenticationException('No autorizado');
      } else if (response.statusCode == 404) {
        throw ServerException('Obra no encontrada', response.statusCode);
      } else if (response.statusCode >= 500) {
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al actualizar obra';
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
    } catch (e, stackTrace) {
      developer.log('  [UpdateObra] Exception: $e', name: 'TareaStateFlow');
      developer.log(
        '  [UpdateObra] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException('Error al actualizar obra: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteObra(String id) async {
    // Método no implementado - no se usa en la aplicación actual
    // No hacer nada para evitar errores
    return;
  }

  @override
  Future<Map<String, int>> updateObrasEstados() async {
    try {
      developer.log(
        '  [ObraEstados] Iniciando actualización de estados de obras',
        name: 'TareaStateFlow',
      );

      final response = await _httpService.post(
        '/master/obra/actualizar-estados',
        body: {}, // Sin body según el curl proporcionado
      );

      developer.log(
        '  [ObraEstados] Response status: ${response.statusCode}',
        name: 'TareaStateFlow',
      );
      developer.log(
        '  [ObraEstados] Response body: ${response.body}',
        name: 'TareaStateFlow',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data.containsKey('resultado') && data['resultado'] is Map) {
          final resultado = data['resultado'] as Map<String, dynamic>;
          final stats = {
            'total': resultado['total'] as int? ?? 0,
            'actualizadas': resultado['actualizadas'] as int? ?? 0,
            'noActualizadas': resultado['noActualizadas'] as int? ?? 0,
          };

          developer.log(
            '  [ObraEstados] Estados actualizados exitosamente',
            name: 'TareaStateFlow',
          );
          developer.log(
            '  [ObraEstados] Total: ${stats['total']}, Actualizadas: ${stats['actualizadas']}, No actualizadas: ${stats['noActualizadas']}',
            name: 'TareaStateFlow',
          );

          return stats;
        } else {
          developer.log(
            '  [ObraEstados] Respuesta no contiene "resultado"',
            name: 'TareaStateFlow',
          );
          throw ServerException(
            'Respuesta del servidor en formato inesperado',
            response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        developer.log(
          '  [ObraEstados] Error 401: No autorizado',
          name: 'TareaStateFlow',
        );
        throw const AuthenticationException('No autorizado');
      } else if (response.statusCode >= 500) {
        developer.log(
          '  [ObraEstados] Error ${response.statusCode}: Error del servidor',
          name: 'TareaStateFlow',
        );
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al actualizar estados de obras';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['message']?.toString() ?? errorMessage;
        } catch (_) {
          // Si no se puede parsear el error, usar el mensaje por defecto
        }
        developer.log(
          '  [ObraEstados] Error ${response.statusCode}: $errorMessage',
          name: 'TareaStateFlow',
        );
        throw ServerException(errorMessage, response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      developer.log('  [ObraEstados] Exception: $e', name: 'TareaStateFlow');
      developer.log(
        '  [ObraEstados] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException(
        'Error al actualizar estados de obras: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> saveReportePdf({
    required String obraId,
    required String url,
    required String nombre,
    required DateTime fechaGeneracion,
    required int tamano,
    int version = 1,
  }) async {
    try {
      developer.log(
        '  [SaveReportePdf] Guardando reporte PDF para obra: $obraId',
        name: 'TareaStateFlow',
      );

      final body = <String, dynamic>{
        'url': url,
        'nombre': nombre,
        'fecha_generacion': fechaGeneracion.toIso8601String(),
        'tamaño': tamano, // El backend espera 'tamaño' con ñ
        'version': version,
      };

      final response = await _httpService.post(
        '/master/obra/$obraId/reporte-pdf',
        body: body,
      );

      developer.log(
        '  [SaveReportePdf] Response status: ${response.statusCode}',
        name: 'TareaStateFlow',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La respuesta viene con estructura: { status, message, reporte }
        if (data.containsKey('reporte') && data['reporte'] is Map) {
          final reporteData = data['reporte'] as Map<String, dynamic>;

          developer.log(
            '  [SaveReportePdf] Reporte PDF guardado exitosamente: ${reporteData['id']}',
            name: 'TareaStateFlow',
          );

          return reporteData;
        } else {
          throw ServerException(
            'Respuesta del servidor en formato inesperado',
            response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        throw const AuthenticationException('No autorizado');
      } else if (response.statusCode == 404) {
        throw ServerException('Obra no encontrada', response.statusCode);
      } else if (response.statusCode >= 500) {
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al guardar reporte PDF';
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
    } catch (e, stackTrace) {
      developer.log('  [SaveReportePdf] Exception: $e', name: 'TareaStateFlow');
      developer.log(
        '  [SaveReportePdf] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException('Error al guardar reporte PDF: ${e.toString()}');
    }
  }

  @override
  Future<List<ReportePdfEntity>> getReportesPdf({
    required String obraId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      developer.log(
        '  [GetReportesPdf] Obteniendo reportes PDF para obra: $obraId',
        name: 'TareaStateFlow',
      );
      developer.log(
        '  [GetReportesPdf] Endpoint: /master/obra/$obraId/reporte-pdf?page=$page&limit=$limit',
        name: 'TareaStateFlow',
      );

      final response = await _httpService.get(
        '/master/obra/$obraId/reporte-pdf?page=$page&limit=$limit',
      );

      developer.log(
        '  [GetReportesPdf] Response status: ${response.statusCode}',
        name: 'TareaStateFlow',
      );
      developer.log(
        '  [GetReportesPdf] Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
        name: 'TareaStateFlow',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La respuesta viene con estructura: { status, data: { docs: [...], totalDocs, ... } }
        if (data.containsKey('data') && data['data'] is Map) {
          final dataObj = data['data'] as Map<String, dynamic>;
          
          if (dataObj.containsKey('docs') && dataObj['docs'] is List) {
            final docsList = dataObj['docs'] as List;
            final reportes = docsList
                .map((item) => ReportePdfEntity.fromJson(
                    item as Map<String, dynamic>))
                .toList();

            developer.log(
              '  [GetReportesPdf] Reportes PDF obtenidos: ${reportes.length}',
              name: 'TareaStateFlow',
            );

            return reportes;
          }
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 401) {
        throw const AuthenticationException('No autorizado');
      } else if (response.statusCode >= 500) {
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al obtener reportes PDF';
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
    } catch (e, stackTrace) {
      developer.log('  [GetReportesPdf] Exception: $e', name: 'TareaStateFlow');
      developer.log(
        '  [GetReportesPdf] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException('Error al obtener reportes PDF: ${e.toString()}');
    }
  }

  @override
  Future<List<ReportePdfEntity>> getAllReportesPdf({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      developer.log(
        '  [GetAllReportesPdf] Obteniendo todos los reportes PDF',
        name: 'TareaStateFlow',
      );
      developer.log(
        '  [GetAllReportesPdf] Endpoint: /master/reporte-pdf?page=$page&limit=$limit',
        name: 'TareaStateFlow',
      );

      final response = await _httpService.get(
        '/master/reporte-pdf?page=$page&limit=$limit',
      );

      developer.log(
        '  [GetAllReportesPdf] Response status: ${response.statusCode}',
        name: 'TareaStateFlow',
      );
      developer.log(
        '  [GetAllReportesPdf] Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
        name: 'TareaStateFlow',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La respuesta viene con estructura: { status, data: { docs: [...], totalDocs, ... } }
        if (data.containsKey('data') && data['data'] is Map) {
          final dataObj = data['data'] as Map<String, dynamic>;
          
          if (dataObj.containsKey('docs') && dataObj['docs'] is List) {
            final docsList = dataObj['docs'] as List;
            final reportes = docsList
                .map((item) => ReportePdfEntity.fromJson(
                    item as Map<String, dynamic>))
                .toList();

            developer.log(
              '  [GetAllReportesPdf] Reportes PDF obtenidos: ${reportes.length}',
              name: 'TareaStateFlow',
            );

            return reportes;
          }
        }
        return [];
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 401) {
        throw const AuthenticationException('No autorizado');
      } else if (response.statusCode >= 500) {
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al obtener reportes PDF';
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
    } catch (e, stackTrace) {
      developer.log('  [GetAllReportesPdf] Exception: $e', name: 'TareaStateFlow');
      developer.log(
        '  [GetAllReportesPdf] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException('Error al obtener reportes PDF: ${e.toString()}');
    }
  }

  @override
  Future<ReportePdfEntity> getReportePdfById(String reporteId) async {
    try {
      developer.log(
        '  [GetReportePdfById] Obteniendo reporte PDF por ID: $reporteId',
        name: 'TareaStateFlow',
      );

      final response = await _httpService.get(
        '/master/reporte-pdf/$reporteId',
      );

      developer.log(
        '  [GetReportePdfById] Response status: ${response.statusCode}',
        name: 'TareaStateFlow',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // La respuesta viene con estructura: { status, reporte: {...} }
        if (data.containsKey('reporte') && data['reporte'] is Map) {
          final reporteData = data['reporte'] as Map<String, dynamic>;
          final reporte = ReportePdfEntity.fromJson(reporteData);

          developer.log(
            '  [GetReportePdfById] Reporte PDF obtenido: ${reporte.nombre}',
            name: 'TareaStateFlow',
          );

          return reporte;
        } else {
          throw ServerException(
            'Respuesta del servidor en formato inesperado',
            response.statusCode,
          );
        }
      } else if (response.statusCode == 404) {
        throw ServerException('Reporte PDF no encontrado', response.statusCode);
      } else if (response.statusCode == 401) {
        throw const AuthenticationException('No autorizado');
      } else if (response.statusCode >= 500) {
        throw ServerException(
          'El servidor no está disponible. Intenta más tarde.',
          response.statusCode,
        );
      } else {
        String errorMessage = 'Error al obtener reporte PDF';
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
    } catch (e, stackTrace) {
      developer.log('  [GetReportePdfById] Exception: $e', name: 'TareaStateFlow');
      developer.log(
        '  [GetReportePdfById] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException('Error al obtener reporte PDF: ${e.toString()}');
    }
  }

  @override
  Future<Uint8List> downloadReportePdf(String reporteId) async {
    try {
      developer.log(
        '  [DownloadReportePdf] Descargando PDF para reporte: $reporteId',
        name: 'TareaStateFlow',
      );

      // Llamar al endpoint /download que devuelve el PDF directamente en bytes
      // Para descargas binarias, solo necesitamos Accept, no Content-Type
      final response = await _httpService.get(
        '/master/reporte-pdf/$reporteId/download',
        headers: {
          'Accept': 'application/pdf',
          // Content-Type vacío para que HttpService no agregue application/json
          'Content-Type': '',
        },
      );

      developer.log(
        '  [DownloadReportePdf] Response status: ${response.statusCode}',
        name: 'TareaStateFlow',
      );
      developer.log(
        '  [DownloadReportePdf] Response headers: ${response.headers}',
        name: 'TareaStateFlow',
      );

      if (response.statusCode == 200) {
        // El endpoint devuelve el PDF directamente en bytes
        final pdfBytes = response.bodyBytes;
        
        developer.log(
          '  [DownloadReportePdf] PDF descargado exitosamente: ${pdfBytes.length} bytes',
          name: 'TareaStateFlow',
        );

        return pdfBytes;
      } else if (response.statusCode == 404) {
        throw ServerException('Reporte PDF no encontrado', response.statusCode);
      } else if (response.statusCode == 401) {
        throw const AuthenticationException('No autorizado');
      } else if (response.statusCode >= 500) {
        // Intentar obtener más información del error del servidor
        String errorMessage = 'El servidor no está disponible. Intenta más tarde.';
        String errorDetails = '';
        
        // Obtener el body completo de la respuesta
        final responseBody = response.body;
        developer.log(
          '  [DownloadReportePdf] Response body completo: $responseBody',
          name: 'TareaStateFlow',
        );
        
        try {
          // Intentar parsear el error si viene como JSON
          if (responseBody.isNotEmpty) {
            final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
            errorMessage = errorData['message']?.toString() ?? 
                         errorData['error']?.toString() ?? 
                         errorMessage;
            errorDetails = errorData.toString();
          } else {
            // Si el body está vacío, usar el header x-vercel-error si existe
            final vercelError = response.headers['x-vercel-error'];
            if (vercelError != null && vercelError.isNotEmpty) {
              errorMessage = 'Error en el servidor: $vercelError';
              errorDetails = responseBody;
            }
          }
        } catch (e) {
          // Si no es JSON, usar el body como texto
          if (responseBody.isNotEmpty) {
            errorDetails = responseBody;
            // Intentar extraer información útil del mensaje
            if (responseBody.contains('FUNCTION_INVOCATION_FAILED')) {
              errorMessage = 'Error en el servidor: La función del backend falló. Verifica que el endpoint /download esté implementado correctamente.';
            } else {
              errorMessage = responseBody.length > 100 
                  ? responseBody.substring(0, 100) 
                  : responseBody;
            }
          }
        }
        
        developer.log(
          '  [DownloadReportePdf] Error 500 del servidor: $errorMessage',
          name: 'TareaStateFlow',
        );
        if (errorDetails.isNotEmpty) {
          developer.log(
            '  [DownloadReportePdf] Detalles del error: $errorDetails',
            name: 'TareaStateFlow',
          );
        }
        
        throw ServerException(errorMessage, response.statusCode);
      } else {
        String errorMessage = 'Error al descargar PDF';
        try {
          // Intentar parsear el error si viene como JSON
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body) as Map<String, dynamic>;
            errorMessage = errorData['message']?.toString() ?? errorMessage;
          }
        } catch (_) {
          // Si no es JSON, usar el mensaje por defecto
        }
        throw ServerException(errorMessage, response.statusCode);
      }
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      developer.log('  [DownloadReportePdf] Exception: $e', name: 'TareaStateFlow');
      developer.log(
        '  [DownloadReportePdf] Stack trace: $stackTrace',
        name: 'TareaStateFlow',
      );
      throw UnknownException('Error al descargar PDF: ${e.toString()}');
    }
  }
}
