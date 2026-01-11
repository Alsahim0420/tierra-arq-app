// ignore_for_file: use_build_context_synchronously, unused_catch_stack, duplicate_ignore, deprecated_member_use, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/obra_entity.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/entities/tarea_entity.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
// Imports para crear tareas en la obra
import '../../app/app.dart';
import '../../../core/injection/injection_container.dart' as di;
import '../../../domain/usecases/user/get_master_users_usecase.dart';
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
  
  UserEntity? _selectedResponsable;
  final List<UserEntity> _availableUsers = [];
  
  // Lista de tareas temporales que se agregarán a la obra al crearla
  final List<TareaEntity> _tareasToAdd = [];
  
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
    super.dispose();
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
                    backgroundColor: TierraApp.primary,
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

    if (!mounted) return;

    setState(() {
      _isCreating = true;
    });

    // Guardar referencias antes de async
    final obraBloc = context.read<ObraBloc>();

    try {
      final costo = double.tryParse(_costoController.text.trim()) ?? 0.0;

      // Validar que todas las tareas tengan ID (deben estar creadas en el servidor)
      final tareasSinId = _tareasToAdd.where((t) => t.id.isEmpty).toList();
      if (tareasSinId.isNotEmpty) {
        throw Exception('Algunas tareas no tienen ID. Por favor, asegúrate de que todas las tareas estén creadas correctamente.');
      }

      // Crear la entidad de obra con las tareas ya creadas (con sus IDs)
      // El backend automáticamente asociará las tareas a la obra
      final newObra = ObraEntity(
        id: '', // El backend asignará el ID
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        city: _cityController.text.trim(),
        responsable: _selectedResponsable!,
        costo: costo,
        tareas: _tareasToAdd, // Tareas ya creadas con sus IDs - el backend las asociará
      );

      // Enviar el evento CreateObra al Bloc para que maneje la creación
      // El Bloc se encargará de llamar al UseCase y actualizar el estado
      obraBloc.add(CreateObra(newObra));

      // Esperar a que el Bloc procese la creación
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
          // Si el estado es ObraLoaded, la obra se creó correctamente
        });
      } catch (e) {
        // Verificar el estado actual por si el timeout ocurrió pero la obra se creó
        final currentState = obraBloc.state;
        if (currentState is ObraError) {
          throw Exception(currentState.message);
        } else if (e.toString().contains('TimeoutException')) {
          throw Exception('Timeout al crear obra. Por favor, verifica tu conexión e intenta nuevamente.');
        } else {
          rethrow;
        }
      }

      if (mounted) {
        // La obra ya fue agregada al estado por el Bloc en _onCreateObra
        // No es necesario recargar todas las obras, evitando duplicaciones
        // El Bloc ya agregó la obra creada a la lista con deduplicación
        
        // Mostrar resultado exitoso
        Navigator.pop(context, true);
        CustomSnackBar.showSuccess(
          context,
          message: 'Obra creada correctamente con ${_tareasToAdd.length} tarea${_tareasToAdd.length > 1 ? 's' : ''} asociada${_tareasToAdd.length > 1 ? 's' : ''}',
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
        backgroundColor: TierraApp.getAppBarColor(isDark),
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
                        color: TierraApp.primary,
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
                        color: TierraApp.primary,
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
                // Ubicación y Ciudad
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  color: TierraApp.primary,
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ciudad',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cityController,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Bogota',
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
                                  color: TierraApp.primary,
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
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Costo
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
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: '604000',
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
                        color: TierraApp.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El costo es requerido';
                    }
                    final costo = double.tryParse(value.trim());
                    if (costo == null || costo <= 0) {
                      return 'Debe ser un número positivo';
                    }
                    return null;
                  },
                ),
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
                              color: TierraApp.primary,
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
                      foregroundColor: TierraApp.primary,
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
                              color: TierraApp.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: TierraApp.primary.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 18,
                                  color: TierraApp.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_tareasToAdd.length}',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: TierraApp.primary,
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
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _tareasToAdd.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareasToAdd[index];
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
                                    color: TierraApp.primary,
                                    onPressed: () => _editTarea(context, index),
                                    tooltip: 'Editar tarea',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                // Botón para agregar tarea - Diseño mejorado
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: TierraApp.primary.withValues(alpha: 0.3),
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
                              TierraApp.primary,
                              TierraApp.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: TierraApp.primary.withValues(alpha: 0.3),
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
                    : TierraApp.primary,
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

