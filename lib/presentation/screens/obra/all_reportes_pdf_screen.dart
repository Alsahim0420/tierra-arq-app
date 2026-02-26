// ignore_for_file: unused_catch_stack

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../core/entities/reporte_pdf_entity.dart';
import '../../../core/repositories/obra_repository.dart';
import '../../../core/injection/injection_container.dart' as di;
import '../../utils/format_utils.dart';
import 'obra_detail_screen.dart';

/// Pantalla para listar y mostrar todos los reportes PDF del sistema
class AllReportesPdfScreen extends StatefulWidget {
  const AllReportesPdfScreen({super.key});

  @override
  State<AllReportesPdfScreen> createState() => _AllReportesPdfScreenState();
}

class _AllReportesPdfScreenState extends State<AllReportesPdfScreen> {
  List<ReportePdfEntity> _reportes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  Future<void> _loadReportes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final obraRepository = di.getIt<ObraRepository>();
      final reportes = await obraRepository.getAllReportesPdf(
        page: 1,
        limit: 100, // Obtener todos los reportes
      );

      setState(() {
        _reportes = reportes;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = 'Error al cargar reportes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openPdf(ReportePdfEntity reporte) async {
    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Descargar el PDF directamente desde el backend usando el endpoint /download
      final obraRepository = di.getIt<ObraRepository>();
      
      Uint8List pdfBytes;
      try {
        pdfBytes = await obraRepository.downloadReportePdf(reporte.id);
      } catch (e) {
        rethrow;
      }

      // Cerrar el indicador de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar el preview del PDF usando el PdfPreviewScreen existente
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfBytes: pdfBytes,
              fileName: reporte.nombre,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Cerrar el indicador de carga si está abierto
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PDFs Creados',
          style: textTheme.headlineSmall?.copyWith(
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadReportes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: isDark ? Colors.white54 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReportes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _reportes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 64,
                            color: isDark ? Colors.white54 : Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay reportes PDF',
                            style: textTheme.bodyLarge?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReportes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reportes.length,
                        itemBuilder: (context, index) {
                          final reporte = _reportes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _openPdf(reporte),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reporte.nombre,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                FormatUtils.formatDate(
                                                    reporte.fechaGeneracion),
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tamaño: ${_formatFileSize(reporte.tamano)}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                        if (reporte.version > 1) ...[
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.layers,
                                            size: 16,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Versión ${reporte.version}',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
