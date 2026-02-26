/// Entidad que representa un reporte PDF de una obra
class ReportePdfEntity {
  ReportePdfEntity({
    required this.id,
    required this.obraId,
    required this.url,
    required this.nombre,
    required this.fechaGeneracion,
    required this.tamano,
    this.version = 1,
    this.clave,
  });

  final String id;
  final String obraId;
  final String url;
  final String nombre;
  final DateTime fechaGeneracion;
  final int tamano;
  final int version;
  final String? clave;

  /// Crea una instancia desde un mapa JSON de la API
  factory ReportePdfEntity.fromJson(Map<String, dynamic> json) {
    DateTime fechaGeneracion;
    try {
      fechaGeneracion = DateTime.parse(json['fecha_generacion'] as String);
    } catch (_) {
      fechaGeneracion = DateTime.now();
    }

    // Manejar obra_id que puede venir como string, objeto o "[object Object]"
    String obraId = '';
    if (json['obra_id'] != null) {
      if (json['obra_id'] is String) {
        obraId = json['obra_id'] as String;
      } else if (json['obra_id'] is Map) {
        final obraIdMap = json['obra_id'] as Map<String, dynamic>;
        obraId = obraIdMap['id']?.toString() ?? 
                 obraIdMap['_id']?.toString() ?? 
                 '';
      } else {
        obraId = json['obra_id'].toString();
        // Si es "[object Object]", intentar extraer de otra forma o dejar vacío
        if (obraId == '[object Object]') {
          obraId = '';
        }
      }
    }

    return ReportePdfEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      obraId: obraId,
      url: json['url']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      fechaGeneracion: fechaGeneracion,
      tamano: (json['tamaño'] ?? json['tamano'] ?? 0) as int,
      version: (json['version'] ?? 1) as int,
      clave: json['clave']?.toString(),
    );
  }
}
