import 'dart:io';
import 'dart:typed_data';
import '../../core/repositories/obra_repository.dart';
import '../../core/datasources/obra_datasource.dart';
import '../../core/entities/obra_entity.dart';
import '../../core/entities/reporte_pdf_entity.dart';

/// Implementación del repository de obras
class ObraRepositoryImpl implements ObraRepository {
  final ObraDataSource _dataSource;

  ObraRepositoryImpl(this._dataSource);

  @override
  Future<List<ObraEntity>> getObras() async {
    return await _dataSource.getObras();
  }

  @override
  Future<List<ObraEntity>> getObrasFinalizadas({int page = 1, int limit = 10}) async {
    return await _dataSource.getObrasFinalizadas(page: page, limit: limit);
  }

  // @override
  // Future<ObraEntity?> getObraById(String id) async {
  //   return await _dataSource.getObraById(id);
  // }

  @override
  Future<List<ObraEntity>> getObrasByResponsable(String userId) async {
    return await _dataSource.getObrasByResponsable(userId);
  }

  @override
  Future<ObraEntity> createObra(ObraEntity obra) async {
    return await _dataSource.createObra(obra);
  }

  @override
  Future<ObraEntity> updateObra(ObraEntity obra) async {
    return await _dataSource.updateObra(obra);
  }

  @override
  Future<void> deleteObra(String id) async {
    return await _dataSource.deleteObra(id);
  }

  @override
  Future<ObraEntity> processDocument(File file) async {
    return await _dataSource.processDocument(file);
  }

  @override
  Future<Map<String, int>> updateObrasEstados() async {
    return await _dataSource.updateObrasEstados();
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
    return await _dataSource.saveReportePdf(
      obraId: obraId,
      url: url,
      nombre: nombre,
      fechaGeneracion: fechaGeneracion,
      tamano: tamano,
      version: version,
    );
  }

  @override
  Future<List<ReportePdfEntity>> getReportesPdf({
    required String obraId,
    int page = 1,
    int limit = 10,
  }) async {
    return await _dataSource.getReportesPdf(
      obraId: obraId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<ReportePdfEntity>> getAllReportesPdf({
    int page = 1,
    int limit = 10,
  }) async {
    return await _dataSource.getAllReportesPdf(
      page: page,
      limit: limit,
    );
  }

  @override
  Future<ReportePdfEntity> getReportePdfById(String reporteId) async {
    return await _dataSource.getReportePdfById(reporteId);
  }

  @override
  Future<Uint8List> downloadReportePdf(String reporteId) async {
    return await _dataSource.downloadReportePdf(reporteId);
  }
}
