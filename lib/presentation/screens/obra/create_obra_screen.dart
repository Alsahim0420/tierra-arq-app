// ignore_for_file: use_build_context_synchronously, unused_catch_stack, duplicate_ignore, deprecated_member_use, prefer_final_fields

import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/entities/obra_entity.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/constants/colombian_cities.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
// Imports para crear tareas en la obra
import '../../../core/theme/app_colors.dart';
import '../../../core/injection/injection_container.dart' as di;
import '../../../domain/usecases/user/get_master_users_usecase.dart';
import '../../../domain/usecases/obra_usecases.dart';
import '../../utils/format_utils.dart';
import '../tarea/create_tarea_screen.dart';
import '../../bloc/obra/obra_state.dart';

class CreateObraScreen extends StatefulWidget {
  const CreateObraScreen({super.key});

  @override
  State<CreateObraScreen> createState() => _CreateObraScreenState();
}

class _CreateObraScreenState extends State<CreateObraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _costoController = TextEditingController();
  final _costoEstimadoController = TextEditingController();
  
  UserEntity? _selectedResponsable;
  final List<UserEntity> _availableUsers = [];
  
  // Selector de departamento y ciudad
  String? _selectedDepartment;
  String? _selectedCity;
  
  // Fecha de entrega de la obra
  DateTime? _fechaEntrega;
  
  // Lista de tareas temporales que se agregarán a la obra al crearla
  final List<TareaEntity> _tareasToAdd = [];
  
  // Obra procesada desde archivo
  ObraEntity? _processedObra;
  bool _isProcessingDocument = false;
  
  int _usersPage = 1;
  final int _limit = 10;
  bool _hasMoreUsers = true;
  bool _isLoadingUsers = false;
  bool _isCreating = false;
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cargar datos después de que el widget esté completamente en el árbol
    // y el contexto esté disponible (incluyendo los BlocProviders)
        if (!_hasLoadedInitialData) {
        _hasLoadedInitialData = true;
        // Usar un pequeño delay para asegurar que todo esté montado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadUsers();
            // COMENTADO: Carga de tareas independientes como templates deshabilitada
            // _loadTareas();
          } else {
          }
        });
      }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _costoController.dispose();
    _costoEstimadoController.dispose();
    super.dispose();
  }

  /// Encontrar el departamento que contiene una ciudad específica
  /// Busca de forma case-insensitive y normalizada (sin acentos)
  String? _findDepartmentForCity(String cityName) {
    final normalizedCity = _normalizeString(cityName);
    for (final entry in ColombianCities.departments.entries) {
      for (final city in entry.value) {
        if (_normalizeString(city) == normalizedCity) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// Normalizar string para comparación (minúsculas, sin acentos)
  String _normalizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  Future<void> _loadUsers() async {
    if (_isLoadingUsers || !_hasMoreUsers) {
      return;
    }
    
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      // Verificar si está registrado
      if (!di.getIt.isRegistered<GetMasterUsersUseCase>()) {
        if (mounted) {
          setState(() {
            _isLoadingUsers = false;
          });
        }
        return;
      }
      
      // Usar GetMasterUsersUseCase directamente desde GetIt (ya está registrado)
      GetMasterUsersUseCase getMasterUsersUseCase;
      try {
        getMasterUsersUseCase = di.getIt<GetMasterUsersUseCase>();
      // ignore: unused_catch_stack
      } catch (e, stackTrace) {
        if (mounted) {
          setState(() {
            _isLoadingUsers = false;
          });
        }
        return;
      }
      
      final masterUsers = await getMasterUsersUseCase.call(page: _usersPage, limit: _limit);
      
      if (mounted) {
        setState(() {
          _availableUsers.addAll(masterUsers);
          _hasMoreUsers = masterUsers.length == _limit;
          _isLoadingUsers = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  void _loadMoreUsers() {
    if (_hasMoreUsers && !_isLoadingUsers) {
      setState(() {
        _usersPage++;
      });
      _loadUsers();
    }
  }

  Future<void> _selectAndProcessFile() async {
    try {
      // Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // Usuario canceló
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        CustomSnackBar.showError(
          context,
          message: 'No se pudo obtener la ruta del archivo',
        );
        return;
      }

      final file = File(filePath);
      
      // Obtener información del archivo para debugging
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final fileSize = await file.length();
      final fileExists = await file.exists();
      
      developer.log('📄 [FilePicker] Archivo seleccionado:', name: 'TareaStateFlow');
      developer.log('📄 [FilePicker] Nombre: $fileName', name: 'TareaStateFlow');
      developer.log('📄 [FilePicker] Extensión: $fileExtension', name: 'TareaStateFlow');
      developer.log('📄 [FilePicker] Tamaño: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)', name: 'TareaStateFlow');
      developer.log('📄 [FilePicker] Ruta completa: $filePath', name: 'TareaStateFlow');
      developer.log('📄 [FilePicker] Archivo existe: $fileExists', name: 'TareaStateFlow');
      
      if (!fileExists) {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            message: 'El archivo seleccionado no existe',
          );
        }
        return;
      }

      // Mostrar diálogo de carga
      if (!mounted) return;
      _showProcessingDialog();

      setState(() {
        _isProcessingDocument = true;
      });

      // Procesar documento
      ProcessDocumentUseCase processDocumentUseCase;
      try {
        processDocumentUseCase = di.getIt<ProcessDocumentUseCase>();
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo
          CustomSnackBar.showError(
            context,
            message: 'Error al inicializar servicio de procesamiento',
          );
        }
        return;
      }

      final obra = await processDocumentUseCase(file);

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga

        setState(() {
          _processedObra = obra;
          _isProcessingDocument = false;
        });

        // Pre-llenar formulario
        _titleController.text = obra.title;
        _descriptionController.text = obra.description;
        _locationController.text = obra.location;
        _cityController.text = obra.city; // Mantener para compatibilidad
        _costoController.text = FormatUtils.formatCurrency(obra.costo);
        if (obra.costoEstimado != null) {
          _costoEstimadoController.text = FormatUtils.formatCurrency(obra.costoEstimado!);
        }
        
        // Pre-llenar fecha de entrega si existe
        if (obra.fechaEntrega != null) {
          setState(() {
            _fechaEntrega = obra.fechaEntrega;
          });
        }

        // Pre-seleccionar departamento y ciudad si existe
        if (obra.departamento != null && obra.departamento!.isNotEmpty) {
          // Si la obra tiene departamento, usarlo directamente
          final cities = ColombianCities.getCitiesForDepartment(obra.departamento!);
          // Buscar la ciudad exacta en la lista
          String? matchedCity;
          if (obra.city.isNotEmpty) {
            final normalizedObraCity = _normalizeString(obra.city);
            for (final city in cities) {
              if (_normalizeString(city) == normalizedObraCity) {
                matchedCity = city;
                break;
              }
            }
          }
          
          setState(() {
            _selectedDepartment = obra.departamento;
            _selectedCity = matchedCity;
          });
        } else if (obra.city.isNotEmpty) {
          // Si no tiene departamento, buscar por ciudad
          final department = _findDepartmentForCity(obra.city);
          if (department != null) {
            final cities = ColombianCities.getCitiesForDepartment(department);
            // Buscar la ciudad exacta en la lista
            String? matchedCity;
            final normalizedObraCity = _normalizeString(obra.city);
            for (final city in cities) {
              if (_normalizeString(city) == normalizedObraCity) {
                matchedCity = city;
                break;
              }
            }
            
            setState(() {
              _selectedDepartment = department;
              _selectedCity = matchedCity;
            });
          }
        }

        // Pre-seleccionar responsable si existe
        if (obra.responsable.id.isNotEmpty) {
          final responsableIndex = _availableUsers.indexWhere(
            (u) => u.id == obra.responsable.id,
          );
          if (responsableIndex >= 0) {
            _selectedResponsable = _availableUsers[responsableIndex];
          }
        }

        // Agregar tareas procesadas
        setState(() {
          _tareasToAdd.clear();
          _tareasToAdd.addAll(obra.tareas);
        });

        CustomSnackBar.showSuccess(
          context,
          message: 'Documento procesado exitosamente. ${obra.tareas.length} tareas cargadas.',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo si está abierto
        setState(() {
          _isProcessingDocument = false;
        });
        CustomSnackBar.showError(
          context,
          message: 'Error al procesar documento: ${e.toString()}',
        );
      }
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // No permitir cerrar
        child: Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1B1B1B)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Subiendo archivo...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Por favor espera, esto puede demorar unos momentos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'El servidor está procesando tu documento...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black38,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateTareaScreen() async {
    final result = await Navigator.push<TareaEntity>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTareaScreen(),
      ),
    );

    if (result != null && mounted) {
      // Verificar si la tarea ya existe en la lista
      final existingIndex = _tareasToAdd.indexWhere((t) => t.id == result.id);
      
      if (existingIndex >= 0) {
        // Actualizar tarea existente
        setState(() {
          _tareasToAdd[existingIndex] = result;
        });
      } else {
        // Agregar nueva tarea
        setState(() {
          _tareasToAdd.add(result);
        });
      }
    }
  }

  Future<void> _editTarea(BuildContext context, int index) async {
    final tarea = _tareasToAdd[index];
    
    // Si la tarea no tiene ID, no se puede editar (aún no está creada en el servidor)
    if (tarea.id.isEmpty) {
      CustomSnackBar.showError(
        context,
        message: 'Esta tarea aún no ha sido creada en el servidor',
      );
      return;
    }

    // Navegar a la pantalla de edición
    final result = await Navigator.push<TareaEntity>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTareaScreen(tarea: tarea),
      ),
    );

    if (result != null && mounted) {
      // Actualizar la tarea en la lista con el resultado
      setState(() {
        _tareasToAdd[index] = result;
      });
    }
  }

  void _showTareaDetails(BuildContext context, TareaEntity tarea) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y botón cerrar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tarea.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: isDark ? Colors.white70 : Colors.black54,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Descripción
                      if (tarea.description.isNotEmpty) ...[
                        Text(
                          'Descripción',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tarea.description,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Información adicional
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailInfoCard(
                              context,
                              textTheme,
                              isDark,
                              'Estado',
                              FormatUtils.formatStateText(tarea.state),
                              FormatUtils.getStateColor(tarea.state),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailInfoCard(
                              context,
                              textTheme,
                              isDark,
                              'Duración',
                              '${tarea.duration} días',
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      // Observación
                      if (tarea.observation != null && tarea.observation!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Observación',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tarea.observation!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailInfoCard(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
    String label,
    String value,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2B2B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createObra(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que haya al menos una tarea
    if (_tareasToAdd.isEmpty) {
      CustomSnackBar.showError(
        context,
        message: 'Debes agregar al menos una tarea',
      );
      return;
    }

    // Validar que haya un responsable seleccionado
    if (_selectedResponsable == null) {
      CustomSnackBar.showError(
        context,
        message: 'Debes seleccionar un responsable',
      );
      return;
    }

    // Validar que haya un departamento y ciudad seleccionados
    if (_selectedDepartment == null || _selectedCity == null) {
      CustomSnackBar.showError(
        context,
        message: 'Debes seleccionar un departamento y una ciudad',
      );
      return;
    }

    // Validar fecha de entrega si está seleccionada
    if (_fechaEntrega != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDate = DateTime(_fechaEntrega!.year, _fechaEntrega!.month, _fechaEntrega!.day);
      
      if (selectedDate.isBefore(today) || selectedDate.isAtSameMomentAs(today)) {
        CustomSnackBar.showError(
          context,
          message: 'La fecha de entrega debe ser posterior al día actual',
        );
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _isCreating = true;
    });

    // Guardar referencias antes de async
    final obraBloc = context.read<ObraBloc>();

    try {
      final costo = FormatUtils.parseCurrency(_costoController.text.trim()) ?? 0.0;
      final costoEstimado = _costoEstimadoController.text.trim().isNotEmpty
          ? FormatUtils.parseCurrency(_costoEstimadoController.text.trim())
          : null;

      // Validar que todas las tareas tengan ID (deben estar creadas en el servidor)
      final tareasSinId = _tareasToAdd.where((t) => t.id.isEmpty).toList();
      if (tareasSinId.isNotEmpty) {
        throw Exception('Algunas tareas no tienen ID. Por favor, asegúrate de que todas las tareas estén creadas correctamente.');
      }

      // Crear la entidad de obra con los datos del formulario
      // Si hay una obra procesada, usar su ID para actualizar
      final obraId = _processedObra?.id ?? '';
      
      // Si es una obra nueva (sin ID), establecer fechaInicio como fecha actual
      // Si es una actualización (con ID), mantener la fechaInicio existente o usar la de la obra procesada
      final fechaInicio = obraId.isEmpty 
          ? DateTime.now() // Nueva obra: fecha actual
          : (_processedObra?.fechaInicio); // Actualización: mantener fecha existente
      
      final newObra = ObraEntity(
        id: obraId, // Si viene de archivo procesado, tiene ID; si no, será vacío
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        city: _selectedCity ?? _cityController.text.trim(), // Usar selector si está disponible, sino el controller
        departamento: _selectedDepartment, // Departamento seleccionado
        responsable: _selectedResponsable!,
        costo: costo,
        costoEstimado: costoEstimado,
        fechaInicio: fechaInicio, // Fecha de inicio (actual para nuevas, existente para actualizaciones)
        fechaEntrega: _fechaEntrega, // Fecha de entrega seleccionada
        tareas: _tareasToAdd, // Tareas ya creadas con sus IDs - el backend las asociará
      );

      // Si la obra ya tiene ID (fue procesada desde archivo), actualizar
      // Si no tiene ID, crear nueva
      if (obraId.isNotEmpty) {
        obraBloc.add(UpdateObra(newObra));
      } else {
        obraBloc.add(CreateObra(newObra));
      }

      // Esperar a que el Bloc procese la creación o actualización
      final isUpdate = obraId.isNotEmpty;
      try {
        // Esperar a que el estado cambie después de enviar el evento
        // El Bloc primero emite ObraLoading, luego ObraLoaded o ObraError
        await obraBloc.stream
            .where((state) => state is! ObraLoading)
            .timeout(const Duration(seconds: 15))
            .first
            .then((state) {
          if (state is ObraError) {
            throw Exception(state.message);
          }
          // Si el estado es ObraLoaded, la obra se creó/actualizó correctamente
        });
      } catch (e) {
        // Verificar el estado actual por si el timeout ocurrió pero la obra se procesó
        final currentState = obraBloc.state;
        if (currentState is ObraError) {
          throw Exception(currentState.message);
        } else if (e.toString().contains('TimeoutException')) {
          throw Exception('Timeout al ${isUpdate ? 'actualizar' : 'crear'} obra. Por favor, verifica tu conexión e intenta nuevamente.');
        } else {
          rethrow;
        }
      }

      if (mounted) {
        // La obra ya fue agregada/actualizada al estado por el Bloc
        // No es necesario recargar todas las obras, evitando duplicaciones
        
        // Mostrar resultado exitoso
        Navigator.pop(context, true);
        CustomSnackBar.showSuccess(
          context,
          message: 'Obra ${isUpdate ? 'actualizada' : 'creada'} correctamente con ${_tareasToAdd.length} tarea${_tareasToAdd.length > 1 ? 's' : ''} asociada${_tareasToAdd.length > 1 ? 's' : ''}',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: 'Error al crear obra: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Nueva Obra',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: AppColors.appBarColor(isDark),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de subida de archivo
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isProcessingDocument ? null : _selectAndProcessFile,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              color: Colors.black,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Subir Archivo de Obra',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'O sube un archivo para procesar automáticamente los datos de la obra',
                  style: textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Tarjeta de resumen si hay obra procesada
                if (_processedObra != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Obra Procesada Exitosamente',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          context,
                          textTheme,
                          isDark,
                          'Título',
                          _processedObra!.title,
                          Icons.title,
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          context,
                          textTheme,
                          isDark,
                          'Costo',
                          FormatUtils.formatCurrency(_processedObra!.costo),
                          Icons.attach_money,
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          context,
                          textTheme,
                          isDark,
                          'Tareas',
                          '${_processedObra!.tareas.length} tareas procesadas',
                          Icons.task_alt,
                        ),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          title: Text(
                            'Ver Tareas (${_processedObra!.tareas.length})',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          children: _processedObra!.tareas.take(10).map((tarea) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tarea.name,
                                          style: textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (tarea.costo != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            FormatUtils.formatCurrency(tarea.costo!),
                                            style: textTheme.bodySmall?.copyWith(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: FormatUtils.getStateColor(tarea.state)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      FormatUtils.formatStateText(tarea.state),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: FormatUtils.getStateColor(tarea.state),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Título
                Text(
                  'Título',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej: Construcción Casa',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Descripción
                Text(
                  'Descripción',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe la obra...',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es requerida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Departamento
                Text(
                  'Departamento',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Selecciona un departamento',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: const Icon(Icons.map_outlined),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    if (_selectedDepartment == null) {
                      return [
                        Text(
                          'Selecciona un departamento',
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ];
                    }
                    return [
                      Text(
                        _selectedDepartment!,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ];
                  },
                  items: ColombianCities.departmentsList.map((department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(
                        department,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                      _selectedCity = null; // Reset ciudad cuando cambia el departamento
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Ciudad
                Text(
                  'Ciudad',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: _selectedDepartment != null
                        ? 'Selecciona una ciudad'
                        : 'Primero selecciona un departamento',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  ),
                  selectedItemBuilder: _selectedCity != null
                      ? (BuildContext context) {
                          return [
                            Text(
                              _selectedCity!,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ];
                        }
                      : null,
                  items: _selectedDepartment != null
                      ? ColombianCities.getCitiesForDepartment(_selectedDepartment!)
                          .map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(
                                city,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList()
                      : [],
                  onChanged: _selectedDepartment != null
                      ? (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        }
                      : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Ubicación
                Text(
                  'Ubicación',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Calle 123',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Costo y Costo Estimado
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Costo',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _costoController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              // COMENTADO: prefixText duplicado - CurrencyInputFormatter ya agrega el "$ "
                              // prefixText: '\$ ',
                              // prefixStyle: textTheme.bodyMedium?.copyWith(
                              //   color: isDark ? Colors.white70 : Colors.black87,
                              //   fontWeight: FontWeight.w500,
                              // ),
                              hintText: '604.000',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El costo es requerido';
                              }
                              final costo = FormatUtils.parseCurrency(value.trim());
                              if (costo == null || costo <= 0) {
                                return 'Debe ser un número positivo';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Costo Estimado',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _costoEstimadoController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              // COMENTADO: prefixText duplicado - CurrencyInputFormatter ya agrega el "$ "
                              // prefixText: '\$ ',
                              // prefixStyle: textTheme.bodyMedium?.copyWith(
                              //   color: isDark ? Colors.white70 : Colors.black87,
                              //   fontWeight: FontWeight.w500,
                              // ),
                              hintText: '500.000',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final costoEstimado = FormatUtils.parseCurrency(value.trim());
                                if (costoEstimado == null || costoEstimado <= 0) {
                                  return 'Debe ser un número positivo';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Fecha de Entrega
                Text(
                  'Fecha de Entrega',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final firstDate = DateTime(now.year, now.month, now.day + 1); // Mañana como mínimo
                    final lastDate = DateTime(now.year + 10, 12, 31); // 10 años en el futuro
                    
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _fechaEntrega ?? firstDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: isDark
                                ? ColorScheme.dark(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.black,
                                    surface: const Color(0xFF2B2B2B),
                                  )
                                : ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.black,
                                    surface: Colors.white,
                                  ),
                            dialogBackgroundColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                          ),
                          child: child!,
                        );
                      },
                    );
                    
                    if (pickedDate != null && mounted) {
                      setState(() {
                        _fechaEntrega = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fechaEntrega != null
                                ? '${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year}'
                                : 'Selecciona una fecha de entrega',
                            style: textTheme.bodyMedium?.copyWith(
                              color: _fechaEntrega != null
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ),
                        if (_fechaEntrega != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            color: isDark ? Colors.white54 : Colors.black54,
                            onPressed: () {
                              setState(() {
                                _fechaEntrega = null;
                              });
                            },
                            tooltip: 'Limpiar fecha',
                          ),
                      ],
                    ),
                  ),
                ),
                if (_fechaEntrega != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'La fecha de entrega debe ser posterior al día actual',
                    style: textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Responsable
                Text(
                  'Responsable',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    if (_isLoadingUsers && _availableUsers.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Cargando responsables...',
                              style: textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                        ),
                      ),
                      child: DropdownButtonFormField<UserEntity>(
                        value: _selectedResponsable,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        dropdownColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        hint: Text(
                          _isLoadingUsers 
                              ? 'Cargando responsables...'
                              : 'Selecciona un responsable',
                          style: textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        items: _availableUsers.map((user) {
                          return DropdownMenuItem<UserEntity>(
                            value: user,
                            child: Text(
                              user.fullName,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedResponsable = value;
                          });
                        },
                      ),
                    );
                  },
                ),
                if (_hasMoreUsers && !_isLoadingUsers && _availableUsers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadMoreUsers,
                    icon: const Icon(Icons.expand_more, size: 16),
                    label: const Text('Cargar más responsables'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Sección de Tareas - Diseño mejorado
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_tareasToAdd.length}',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _tareasToAdd.length == 1 ? 'tarea' : 'tareas',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tareas de la Obra',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_tareasToAdd.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '* Requerido',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Lista de tareas agregadas
                if (_tareasToAdd.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: _tareasToAdd.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tarea = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showTareaDetails(context, tarea),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              title: Text(
                                tarea.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: tarea.description.isNotEmpty
                                  ? Text(
                                      tarea.description,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Estado de la tarea
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: FormatUtils.getStateColor(tarea.state).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      FormatUtils.formatStateText(tarea.state),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: FormatUtils.getStateColor(tarea.state),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${tarea.duration}d',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Icono de editar
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    color: AppColors.primary,
                                    onPressed: () => _editTarea(context, index),
                                    tooltip: 'Editar tarea',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                // Botón para agregar tarea - Diseño mejorado
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openCreateTareaScreen,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Agregar Tarea',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isCreating
                  ? null
                  : () => _createObra(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isCreating
                    ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300)
                    : AppColors.primary,
                foregroundColor: _isCreating
                    ? (isDark ? Colors.white54 : Colors.black54)
                    : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Crear obra',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

