import 'dart:io';
import 'dart:typed_data';
import '../entities/obra_entity.dart';
import '../entities/reporte_pdf_entity.dart';

/// Datasource abstracto para obras
abstract class ObraDataSource {
  Future<List<ObraEntity>> getObras();
  Future<List<ObraEntity>> getObrasFinalizadas({int page = 1, int limit = 10});

  Future<List<ObraEntity>> getObrasByResponsable(String userId);
  Future<ObraEntity> createObra(ObraEntity obra);
  Future<ObraEntity> updateObra(ObraEntity obra);
  Future<void> deleteObra(String id);
  
  /// Procesa un documento y crea una obra con sus tareas
  Future<ObraEntity> processDocument(File file);
  
  /// Actualiza los estados de todas las obras basándose en el estado de sus tareas
  /// Retorna un mapa con las estadísticas: {total, actualizadas, noActualizadas}
  Future<Map<String, int>> updateObrasEstados();
  
  /// Guarda los metadatos de un reporte PDF generado para una obra
  /// Retorna un mapa con los datos del reporte guardado
  Future<Map<String, dynamic>> saveReportePdf({
    required String obraId,
    required String url,
    required String nombre,
    required DateTime fechaGeneracion,
    required int tamano,
    int version = 1,
  });
  
  /// Obtiene todos los reportes PDF generados para una obra
  /// Retorna una lista de reportes PDF con paginación
  Future<List<ReportePdfEntity>> getReportesPdf({
    required String obraId,
    int page = 1,
    int limit = 10,
  });
  
  /// Obtiene todos los reportes PDF generados en el sistema (sin filtrar por obra)
  /// Retorna una lista de reportes PDF con paginación
  Future<List<ReportePdfEntity>> getAllReportesPdf({
    int page = 1,
    int limit = 10,
  });
  
  /// Obtiene un reporte PDF específico por su ID
  /// Retorna el reporte PDF con su información actualizada
  Future<ReportePdfEntity> getReportePdfById(String reporteId);
  
  /// Descarga el PDF de un reporte específico desde el backend
  /// Retorna los bytes del PDF directamente
  Future<Uint8List> downloadReportePdf(String reporteId);
}
