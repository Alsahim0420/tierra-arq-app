import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../entities/obra_entity.dart';

/// Servicio para generar PDFs de reportes de obras orientados al cliente
class PdfService {
  /// Genera un PDF del reporte de la obra para presentar al cliente
  /// Incluye información relevante sin detalles operativos internos
  Future<pw.Document> generateObraClientReport(ObraEntity obra) async {
    final pdf = pw.Document();

    // Calcular estadísticas de tareas
    final totalTareas = obra.tareas.length;
    final tareasFinalizadas = obra.tareas.where((t) {
      final state = t.state.toLowerCase().trim();
      return state == 'finalizado' || state == 'finalizada' || 
             state == 'completado' || state == 'completada' ||
             state == 'completed';
    }).length;
    final tareasEnProgreso = obra.tareas.where((t) {
      final state = t.state.toLowerCase().trim();
      return state == 'en_proceso' || state == 'en_progreso' ||
             state.contains('progreso') || state.contains('proceso');
    }).length;
    final tareasPendientes = obra.tareas.where((t) {
      final state = t.state.toLowerCase().trim();
      return state == 'pendiente' || state == 'pending';
    }).length;

    // Calcular porcentaje: tareas finalizadas = 100%, en progreso = 50%
    final porcentajeCompletado = totalTareas > 0 
        ? (((tareasFinalizadas * 100 + tareasEnProgreso * 50) / totalTareas).round())
        : 0;

    // Formateador de fechas (usar formato manual para evitar problemas de locale)
    String formatDate(DateTime? date) {
      if (date == null) return '';
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    }

    String formatDateTime(DateTime date) {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REPORTE DE PROYECTO',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Generado el ${formatDateTime(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Información del Proyecto
            _buildSectionTitle('Información del Proyecto'),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    obra.title,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  if (obra.description.isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Descripción:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      obra.description,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Text(
                        '- ',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        '${obra.city}, ${obra.location}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  if (obra.departamento != null && obra.departamento!.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Departamento: ${obra.departamento}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Text(
                        '- ',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Responsable: ${obra.responsable.fullName}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  if (obra.fechaInicio != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Fecha de inicio: ${formatDate(obra.fechaInicio)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                  if (obra.fechaFin != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Fecha de finalización planificada: ${formatDate(obra.fechaFin)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                  if (obra.fechaEntrega != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Fecha de entrega proyectada: ${formatDate(obra.fechaEntrega)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Estado del Proyecto
            _buildSectionTitle('Estado del Proyecto'),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Estado general: ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        _formatEstado(obra.estado),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _getEstadoColor(obra.estado),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Progreso del proyecto:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Barra de progreso visual con porcentaje
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Stack(
                          children: [
                            // Fondo gris completo con borde
                            pw.Container(
                              width: double.infinity,
                              height: 24,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey400),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                                color: PdfColors.grey200,
                              ),
                            ),
                            // Barra de progreso verde
                            // Ancho disponible aproximado: A4 (595) - márgenes (80) - padding contenedor (32) = ~483
                            if (porcentajeCompletado > 0)
                              pw.Positioned(
                                left: 0,
                                top: 0,
                                child: pw.Container(
                                  width: 483 * (porcentajeCompletado / 100).clamp(0.0, 1.0),
                                  height: 24,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.green600,
                                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                                  ),
                                ),
                              ),
                            // Texto del porcentaje centrado (siempre en negro)
                            pw.Container(
                              width: double.infinity,
                              height: 24,
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '$porcentajeCompletado%',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('Total', totalTareas.toString(), PdfColors.blueGrey700),
                      _buildStatBox('Finalizadas', tareasFinalizadas.toString(), PdfColors.green700),
                      _buildStatBox('En Progreso', tareasEnProgreso.toString(), PdfColors.blue700),
                      _buildStatBox('Pendientes', tareasPendientes.toString(), PdfColors.orange700),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Resumen de Tareas
            if (obra.tareas.isNotEmpty) ...[
              _buildSectionTitle('Resumen de Actividades'),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Encabezado de la tabla
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Actividad',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Center(
                            child: pw.Text(
                              'Estado',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Center(
                            child: pw.Text(
                              'Duración',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Filas de tareas
                    ...obra.tareas.map((tarea) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  tarea.name,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                                if (tarea.description.isNotEmpty) ...[
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    tarea.description.length > 100
                                        ? '${tarea.description.substring(0, 100)}...'
                                        : tarea.description,
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Center(
                              child: pw.Text(
                                _formatEstado(tarea.state),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: _getEstadoColor(tarea.state),
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Center(
                              child: pw.Text(
                                tarea.duration > 0 
                                    ? '${tarea.duration} días'
                                    : 'N/A',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 20),

            // Pie de página
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Este reporte ha sido generado automáticamente por el sistema de gestión de obras.',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Construye un título de sección
  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey900,
      ),
    );
  }

  /// Construye una caja de estadística
  pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 70,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _colorWithOpacity(color, 0.1),
        border: pw.Border.all(color: _colorWithOpacity(color, 0.3)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Crea un color con opacidad (simulación)
  PdfColor _colorWithOpacity(PdfColor color, double opacity) {
    if (opacity >= 0.5) {
      return color;
    }
    // Para opacidades bajas, usar colores más claros
    if (color == PdfColors.blueGrey700) {
      return PdfColors.blueGrey300;
    } else if (color == PdfColors.green700) {
      return PdfColors.green300;
    } else if (color == PdfColors.blue700) {
      return PdfColors.blue300;
    } else if (color == PdfColors.orange700) {
      return PdfColors.orange300;
    }
    return PdfColors.grey300;
  }

  /// Formatea el estado para mostrar
  String _formatEstado(String estado) {
    final normalized = estado.toLowerCase().trim();
    if (normalized == 'en_proceso' || normalized == 'en_progreso') {
      return 'En Progreso';
    }
    if (normalized == 'pendiente' || normalized == 'pending') {
      return 'Pendiente';
    }
    if (normalized == 'finalizado' || normalized == 'finalizada' ||
        normalized == 'completado' || normalized == 'completada' ||
        normalized == 'completed') {
      return 'Finalizado';
    }
    if (normalized == 'estancado' || normalized == 'estancada' ||
        normalized == 'stalled') {
      return 'Estancado';
    }
    // Capitalizar primera letra
    if (estado.isNotEmpty) {
      return estado[0].toUpperCase() + estado.substring(1);
    }
    return estado;
  }

  /// Obtiene el color según el estado
  PdfColor _getEstadoColor(String estado) {
    final normalized = estado.toLowerCase().trim();
    if (normalized == 'finalizado' || normalized == 'finalizada' ||
        normalized == 'completado' || normalized == 'completada' ||
        normalized == 'completed') {
      return PdfColors.green700;
    }
    if (normalized == 'en_proceso' || normalized == 'en_progreso' ||
        normalized.contains('progreso') || normalized.contains('proceso')) {
      return PdfColors.blue700;
    }
    if (normalized == 'pendiente' || normalized == 'pending') {
      return PdfColors.orange700;
    }
    if (normalized == 'estancado' || normalized == 'estancada' ||
        normalized == 'stalled') {
      return PdfColors.amber700;
    }
    return PdfColors.grey700;
  }
}
