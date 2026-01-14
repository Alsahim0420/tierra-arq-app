// ignore_for_file: unused_catch_stack, duplicate_ignore

import 'dart:convert';
import 'dart:developer' as developer;
import '../../core/datasources/dashboard_datasource.dart';
import '../../core/entities/dashboard_entity.dart';
import '../../core/entities/obra_entity.dart';
import '../../core/entities/user_entity.dart';
import '../../core/entities/tarea_entity.dart';
import '../../core/services/http_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Implementación concreta del datasource del dashboard
class DashboardDataSourceImpl implements DashboardDataSource {
  final HttpService _httpService;

  DashboardDataSourceImpl({
    required HttpService httpService,
  }) : _httpService = httpService;

  /// Obtiene los datos del dashboard
  ///
  /// Endpoint: GET /master/dashboard
  /// Retorna DashboardEntity con todas las estadísticas y obras recientes
  @override
  Future<DashboardEntity> getDashboard() async {
    try {
      final response = await _httpService.get('/master/dashboard');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        developer.log('📋 [Dashboard] Verificando estructura del JSON completo:', name: 'DashboardDataSource');
        developer.log('  - Keys en nivel raíz: ${data.keys.toList()}', name: 'DashboardDataSource');
        
        // La respuesta tiene estructura: {"status":"success","data":{...}}
        if (data.containsKey('data') && data['data'] is Map) {
          final dataObj = data['data'] as Map<String, dynamic>;
          
          developer.log('📋 [Dashboard] Verificando estructura de dataObj:', name: 'DashboardDataSource');
          developer.log('  - Keys disponibles: ${dataObj.keys.toList()}', name: 'DashboardDataSource');
          developer.log('  - obras_a_tiempo_lista existe: ${dataObj.containsKey('obras_a_tiempo_lista')}', name: 'DashboardDataSource');
          developer.log('  - obras_retrasadas_lista existe: ${dataObj.containsKey('obras_retrasadas_lista')}', name: 'DashboardDataSource');
          developer.log('  - obras_adelantadas_lista existe: ${dataObj.containsKey('obras_adelantadas_lista')}', name: 'DashboardDataSource');
          
          // Verificar si las listas están en el nivel raíz en lugar de dentro de data
          if (!dataObj.containsKey('obras_a_tiempo_lista') && data.containsKey('obras_a_tiempo_lista')) {
            developer.log('⚠️ [Dashboard] obras_a_tiempo_lista está en el nivel raíz, no en data', name: 'DashboardDataSource');
          }
          
          if (dataObj.containsKey('obras_a_tiempo_lista')) {
            developer.log('  - obras_a_tiempo_lista tipo: ${dataObj['obras_a_tiempo_lista'].runtimeType}', name: 'DashboardDataSource');
            developer.log('  - obras_a_tiempo_lista es List: ${dataObj['obras_a_tiempo_lista'] is List}', name: 'DashboardDataSource');
            if (dataObj['obras_a_tiempo_lista'] is List) {
              developer.log('  - obras_a_tiempo_lista length: ${(dataObj['obras_a_tiempo_lista'] as List).length}', name: 'DashboardDataSource');
            }
          }
          
          try {
            final dashboard = _mapDashboardFromApi(dataObj);
            return dashboard;
          // ignore: unused_catch_stack
          } catch (e, stackTrace) {
            rethrow;
          }
        }
        throw ServerException(
          'Formato de respuesta inválido',
          response.statusCode,
        );
      } else if (response.statusCode == 404) {
        throw ServerException('Dashboard no encontrado', response.statusCode);
      } else {
        throw ServerException(
          'Error al obtener dashboard',
          response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException('Error al obtener dashboard: ${e.toString()}');
    }
  }

  /// Método auxiliar para extraer un int de forma segura desde un Map
  int _safeIntFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is bool) {
      // Si es un bool, convertir a int (true = 1, false = 0)
      return value ? 1 : 0;
    }
    return 0;
  }

  /// Mapear respuesta del API a DashboardEntity
  DashboardEntity _mapDashboardFromApi(Map<String, dynamic> data) {
    // Mapear obras por estado
    final obrasPorEstado = data['obras_por_estado'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    
    int obrasPendientes = _safeIntFromMap(obrasPorEstado, 'pendiente');
    int obrasEnProceso = _safeIntFromMap(obrasPorEstado, 'en_proceso');
    int obrasFinalizadas = _safeIntFromMap(obrasPorEstado, 'finalizado');
    int obrasEstancadas = _safeIntFromMap(obrasPorEstado, 'estancado');

    // Mapear tareas por estado
    final tareasPorEstado = data['tareas_por_estado'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    
    int tareasPendientes = _safeIntFromMap(tareasPorEstado, 'pendiente');
    int tareasEnProceso = _safeIntFromMap(tareasPorEstado, 'en_proceso');
    int tareasFinalizadas = _safeIntFromMap(tareasPorEstado, 'finalizado');
    int tareasEstancadas = _safeIntFromMap(tareasPorEstado, 'estancado');

    // Mapear obras recientes
    developer.log('📋 Mapeando obras_recientes', name: 'DashboardDataSource');
    developer.log('obras_recientes tipo: ${data['obras_recientes']?.runtimeType}', name: 'DashboardDataSource');
    developer.log('obras_recientes es null: ${data['obras_recientes'] == null}', name: 'DashboardDataSource');
    developer.log('obras_recientes es List: ${data['obras_recientes'] is List}', name: 'DashboardDataSource');
    
    List<ObraEntity> obrasRecientes = [];
    if (data['obras_recientes'] != null &&
        data['obras_recientes'] is List) {
      final obrasList = data['obras_recientes'] as List;
      
      obrasRecientes = obrasList
          .asMap()
          .entries
          .map((entry) {
            final item = entry.value;
            
            if (item is! Map<String, dynamic>) {
              return null;
            }
            
            try {
              return _mapObraFromApi(item);
            } catch (e, stackTrace) {
              rethrow;
            }
          })
          .whereType<ObraEntity>()
          .toList();
    }

    int totalObras = _safeIntFromMap(data, 'total_obras');
    int totalTareas = _safeIntFromMap(data, 'total_tareas');
    double presupuestoProyectado = (data['costo_total'] ?? 0.0).toDouble();
    double presupuestoEjecutado = (data['presupuesto_ejecutado'] ?? 0.0).toDouble();
    double varianzaPresupuestaria = (data['varianza_presupuestaria'] ?? 0.0).toDouble();
    int obrasATiempo = _safeIntFromMap(data, 'obras_a_tiempo');
    int obrasRetrasadas = _safeIntFromMap(data, 'obras_retrasadas');
    int obrasAdelantadas = _safeIntFromMap(data, 'obras_adelantadas');
    double? porcentajeAvancePromedio = data['porcentaje_avance_promedio'] != null
        ? (data['porcentaje_avance_promedio'] as num).toDouble()
        : null;

    // Mapear listas de obras por estado de cronograma
    List<ObraEntity> obrasATiempoLista = [];
    try {
      developer.log('📋 [Dashboard] Iniciando mapeo de obras_a_tiempo_lista', name: 'DashboardDataSource');
      final tieneObrasATiempo = data.containsKey('obras_a_tiempo_lista');
      final obrasATiempoValue = data['obras_a_tiempo_lista'];
      developer.log('  - data contiene obras_a_tiempo_lista: $tieneObrasATiempo', name: 'DashboardDataSource');
      developer.log('  - data[obras_a_tiempo_lista] es null: ${obrasATiempoValue == null}', name: 'DashboardDataSource');
      if (tieneObrasATiempo) {
        developer.log('  - data[obras_a_tiempo_lista] tipo: ${obrasATiempoValue.runtimeType}', name: 'DashboardDataSource');
        developer.log('  - data[obras_a_tiempo_lista] es List: ${obrasATiempoValue is List}', name: 'DashboardDataSource');
      }
      if (obrasATiempoValue != null && obrasATiempoValue is List) {
        final obrasList = obrasATiempoValue;
        developer.log('📋 [Dashboard] obras_a_tiempo_lista tiene ${obrasList.length} elementos', name: 'DashboardDataSource');
        
        obrasATiempoLista = obrasList
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final item = entry.value;
              
              if (item is! Map<String, dynamic>) {
                developer.log('⚠️ [Dashboard] Obra $index en obras_a_tiempo_lista no es Map, tipo: ${item.runtimeType}', name: 'DashboardDataSource');
                return null;
              }
              
              try {
                final obra = _mapObraFromApi(item);
                developer.log('✅ [Dashboard] Obra $index mapeada exitosamente: ${obra.title}', name: 'DashboardDataSource');
                return obra;
              } catch (e, stackTrace) {
                developer.log('❌ [Dashboard] Error al mapear obra $index en obras_a_tiempo_lista: $e', name: 'DashboardDataSource');
                developer.log('Stack trace: $stackTrace', name: 'DashboardDataSource');
                return null;
              }
            })
            .whereType<ObraEntity>()
            .toList();
        
        developer.log('✅ [Dashboard] obras_a_tiempo_lista mapeada: ${obrasATiempoLista.length} de ${obrasList.length} obras exitosas', name: 'DashboardDataSource');
      } else {
        developer.log('⚠️ [Dashboard] obras_a_tiempo_lista es null o no es List', name: 'DashboardDataSource');
      }
    } catch (e, stackTrace) {
      developer.log('❌ [Dashboard] Error general al mapear obras_a_tiempo_lista: $e', name: 'DashboardDataSource');
      developer.log('Stack trace: $stackTrace', name: 'DashboardDataSource');
      obrasATiempoLista = [];
    }

    List<ObraEntity> obrasRetrasadasLista = [];
    try {
      developer.log('📋 [Dashboard] Iniciando mapeo de obras_retrasadas_lista', name: 'DashboardDataSource');
      final tieneObrasRetrasadas = data.containsKey('obras_retrasadas_lista');
      final obrasRetrasadasValue = data['obras_retrasadas_lista'];
      developer.log('  - data contiene obras_retrasadas_lista: $tieneObrasRetrasadas', name: 'DashboardDataSource');
      developer.log('  - data[obras_retrasadas_lista] es null: ${obrasRetrasadasValue == null}', name: 'DashboardDataSource');
      if (tieneObrasRetrasadas) {
        developer.log('  - data[obras_retrasadas_lista] tipo: ${obrasRetrasadasValue.runtimeType}', name: 'DashboardDataSource');
        developer.log('  - data[obras_retrasadas_lista] es List: ${obrasRetrasadasValue is List}', name: 'DashboardDataSource');
      }
      if (obrasRetrasadasValue != null && obrasRetrasadasValue is List) {
        final obrasList = obrasRetrasadasValue;
        developer.log('📋 [Dashboard] obras_retrasadas_lista tiene ${obrasList.length} elementos', name: 'DashboardDataSource');
        
        obrasRetrasadasLista = obrasList
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final item = entry.value;
              
              if (item is! Map<String, dynamic>) {
                developer.log('⚠️ [Dashboard] Obra $index en obras_retrasadas_lista no es Map, tipo: ${item.runtimeType}', name: 'DashboardDataSource');
                return null;
              }
              
              try {
                final obra = _mapObraFromApi(item);
                developer.log('✅ [Dashboard] Obra $index mapeada exitosamente: ${obra.title}', name: 'DashboardDataSource');
                return obra;
              } catch (e, stackTrace) {
                developer.log('❌ [Dashboard] Error al mapear obra $index en obras_retrasadas_lista: $e', name: 'DashboardDataSource');
                developer.log('Stack trace: $stackTrace', name: 'DashboardDataSource');
                return null;
              }
            })
            .whereType<ObraEntity>()
            .toList();
        
        developer.log('✅ [Dashboard] obras_retrasadas_lista mapeada: ${obrasRetrasadasLista.length} de ${obrasList.length} obras exitosas', name: 'DashboardDataSource');
      } else {
        developer.log('⚠️ [Dashboard] obras_retrasadas_lista es null o no es List', name: 'DashboardDataSource');
      }
    } catch (e, stackTrace) {
      developer.log('❌ [Dashboard] Error general al mapear obras_retrasadas_lista: $e', name: 'DashboardDataSource');
      developer.log('Stack trace: $stackTrace', name: 'DashboardDataSource');
      obrasRetrasadasLista = [];
    }

    List<ObraEntity> obrasAdelantadasLista = [];
    try {
      developer.log('📋 [Dashboard] Iniciando mapeo de obras_adelantadas_lista', name: 'DashboardDataSource');
      final tieneObrasAdelantadas = data.containsKey('obras_adelantadas_lista');
      final obrasAdelantadasValue = data['obras_adelantadas_lista'];
      developer.log('  - data contiene obras_adelantadas_lista: $tieneObrasAdelantadas', name: 'DashboardDataSource');
      developer.log('  - data[obras_adelantadas_lista] es null: ${obrasAdelantadasValue == null}', name: 'DashboardDataSource');
      if (tieneObrasAdelantadas) {
        developer.log('  - data[obras_adelantadas_lista] tipo: ${obrasAdelantadasValue.runtimeType}', name: 'DashboardDataSource');
        developer.log('  - data[obras_adelantadas_lista] es List: ${obrasAdelantadasValue is List}', name: 'DashboardDataSource');
      }
      if (obrasAdelantadasValue != null && obrasAdelantadasValue is List) {
        final obrasList = obrasAdelantadasValue;
        developer.log('📋 [Dashboard] obras_adelantadas_lista tiene ${obrasList.length} elementos', name: 'DashboardDataSource');
        
        obrasAdelantadasLista = obrasList
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final item = entry.value;
              
              if (item is! Map<String, dynamic>) {
                developer.log('⚠️ [Dashboard] Obra $index en obras_adelantadas_lista no es Map, tipo: ${item.runtimeType}', name: 'DashboardDataSource');
                return null;
              }
              
              try {
                final obra = _mapObraFromApi(item);
                developer.log('✅ [Dashboard] Obra $index mapeada exitosamente: ${obra.title}', name: 'DashboardDataSource');
                return obra;
              } catch (e, stackTrace) {
                developer.log('❌ [Dashboard] Error al mapear obra $index en obras_adelantadas_lista: $e', name: 'DashboardDataSource');
                developer.log('Stack trace: $stackTrace', name: 'DashboardDataSource');
                return null;
              }
            })
            .whereType<ObraEntity>()
            .toList();
        
        developer.log('✅ [Dashboard] obras_adelantadas_lista mapeada: ${obrasAdelantadasLista.length} de ${obrasList.length} obras exitosas', name: 'DashboardDataSource');
      } else {
        developer.log('⚠️ [Dashboard] obras_adelantadas_lista es null o no es List', name: 'DashboardDataSource');
      }
    } catch (e, stackTrace) {
      developer.log('❌ [Dashboard] Error general al mapear obras_adelantadas_lista: $e', name: 'DashboardDataSource');
      developer.log('Stack trace: $stackTrace', name: 'DashboardDataSource');
      obrasAdelantadasLista = [];
    }

    developer.log('📊 [Dashboard] Creando DashboardEntity con listas:', name: 'DashboardDataSource');
    developer.log('  - obrasATiempoLista: ${obrasATiempoLista.length} obras', name: 'DashboardDataSource');
    developer.log('  - obrasRetrasadasLista: ${obrasRetrasadasLista.length} obras', name: 'DashboardDataSource');
    developer.log('  - obrasAdelantadasLista: ${obrasAdelantadasLista.length} obras', name: 'DashboardDataSource');
    
    return DashboardEntity(
      totalObras: totalObras,
      obrasActivas: obrasPendientes + obrasEnProceso,
      obrasFinalizadas: obrasFinalizadas,
      obrasEstancadas: obrasEstancadas > 0 ? obrasEstancadas : null,
      totalTareas: totalTareas,
      tareasPendientes: tareasPendientes,
      tareasEnProgreso: tareasEnProceso,
      tareasCompletadas: tareasFinalizadas,
      tareasEstancadas: tareasEstancadas > 0 ? tareasEstancadas : null,
      presupuestoProyectado: presupuestoProyectado,
      presupuestoEjecutado: presupuestoEjecutado,
      varianzaPresupuestaria: varianzaPresupuestaria,
      obrasATiempo: obrasATiempo,
      obrasRetrasadas: obrasRetrasadas,
      obrasAdelantadas: obrasAdelantadas,
      obrasATiempoLista: obrasATiempoLista,
      obrasRetrasadasLista: obrasRetrasadasLista,
      obrasAdelantadasLista: obrasAdelantadasLista,
      obrasRecientes: obrasRecientes,
      porcentajeAvancePromedio: porcentajeAvancePromedio,
    );
  }

  /// Mapear obra desde API (reutiliza la lógica de ObraDataSourceImpl)
  ObraEntity _mapObraFromApi(Map<String, dynamic> data) {
    try {
      final obraId = data['_id']?.toString() ?? data['id']?.toString() ?? '';
      final obraTitle = data['title']?.toString() ?? data['name']?.toString() ?? '';
      
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

      final costoEstimadoValue = data['costo_estimado'] ?? data['costoEstimado'] ?? data['estimatedCost'];
      final double? costoEstimado = costoEstimadoValue != null
          ? (costoEstimadoValue as num).toDouble()
          : null;
      
      // Mapear costoFinal de forma segura
      final costoFinalValue = data['costoFinal'] ?? data['costo_final'] ?? data['finalCost'];
      double? costoFinal;
      if (costoFinalValue != null) {
        if (costoFinalValue is num) {
          costoFinal = costoFinalValue.toDouble();
        } else if (costoFinalValue is String) {
          costoFinal = double.tryParse(costoFinalValue);
        }
      }

      final obra = ObraEntity(
        id: obraId,
        title: obraTitle,
        description: data['description']?.toString() ?? '',
        location: data['location']?.toString() ?? '',
        city: data['city']?.toString() ?? '',
        costo: (data['costo'] ?? data['cost'] ?? 0.0).toDouble(),
        costoEstimado: costoEstimado,
        costoFinal: costoFinal,
        responsable: _mapUserFromApi(responsableData),
        tareas: _mapTareasFromApi(tareasList),
        estado: data['estado']?.toString() ?? 'pendiente',
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        fechaEntrega: fechaEntrega,
      );
      
      return obra;
    } catch (e, stackTrace) {
      developer.log('❌ [Dashboard] Error en _mapObraFromApi para obra ${data['id'] ?? data['_id'] ?? 'sin_id'}: $e', name: 'DashboardDataSource');
      developer.log('Stack trace: $stackTrace', name: 'DashboardDataSource');
      developer.log('Datos de la obra: ${data.keys}', name: 'DashboardDataSource');
      rethrow;
    }
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
    if (normalized == 'estancado' ||
        normalized == 'estancada' ||
        normalized == 'stalled') {
      return 'estancado';
    }
    return normalized;
  }

  /// Mapear tareas desde API
  List<TareaEntity> _mapTareasFromApi(List<dynamic> data) {
    developer.log('📋 Mapeando ${data.length} tareas', name: 'DashboardDataSource');
    
    return data
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final item = entry.value;
          developer.log('Mapeando tarea $index, tipo: ${item.runtimeType}', name: 'DashboardDataSource');
          
          if (item is! Map<String, dynamic>) {
            developer.log('❌ Tarea $index no es Map', name: 'DashboardDataSource');
            return null;
          }
          final tareaData = item;
          developer.log('Tarea $index keys: ${tareaData.keys}', name: 'DashboardDataSource');

          // Mapear assignedTo de forma segura
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

          try {
            developer.log('Creando TareaEntity $index', name: 'DashboardDataSource');
            developer.log('duration valor: ${tareaData['duration']}, tipo: ${tareaData['duration']?.runtimeType}', name: 'DashboardDataSource');
            
            final duration = tareaData['duration'] != null
                ? int.tryParse(tareaData['duration'].toString()) ?? 0
                : 0;
            developer.log('✅ duration: $duration', name: 'DashboardDataSource');
            
            final tarea = TareaEntity(
              id: tareaData['_id']?.toString() ??
                  tareaData['id']?.toString() ??
                  '',
              name: tareaData['name']?.toString() ??
                  tareaData['title']?.toString() ??
                  '',
              description: tareaData['description']?.toString() ?? '',
              state: _normalizeTareaState(
                tareaData['state']?.toString() ??
                    tareaData['status']?.toString() ??
                    'pendiente',
              ),
              duration: duration,
              evidences: evidences,
              assignedTo: assignedTo,
              observation: tareaData['observation']?.toString(),
              obraTareaId: obraTareaId,
            );
            developer.log('✅ TareaEntity $index creada exitosamente', name: 'DashboardDataSource');
            return tarea;
          } catch (e, stackTrace) {
            developer.log('❌ Error al crear TareaEntity $index: $e', name: 'DashboardDataSource');
            developer.log('Stack trace: $stackTrace', name: 'DashboardDataSource');
            developer.log('Datos de la tarea: $tareaData', name: 'DashboardDataSource');
            rethrow;
          }
        })
        .whereType<TareaEntity>()
        .toList();
  }
}
