import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart' as core;
import '../../../core/entities/obra_entity.dart';
import '../../bloc/obra/obra_bloc.dart';
import '../../bloc/obra/obra_event.dart';
import '../../bloc/obra/obra_state.dart';
import '../../bloc/tarea/tarea_bloc.dart';
import '../../app/app.dart';
import '../../utils/user_role_utils.dart';
// COMENTADO: Imports de navegación movidos al BottomNavigationBar
// import '../profile/profile_screen.dart';
// import '../user/users_list_screen.dart';
import 'obra_detail_screen.dart';
import 'create_obra_screen.dart';

// Enum para opciones de ordenamiento
enum SortOption {
  none,
  costoAsc,
  costoDesc,
  tituloAsc,
  tituloDesc,
  ciudadAsc,
  ciudadDesc,
  tareasAsc,
  tareasDesc,
  antiguedadAsc,
  antiguedadDesc,
}

class ObrasListScreen extends StatefulWidget {
  const ObrasListScreen({
    super.key,
    required this.user,
    required this.onLogout,
    this.showFAB = false,
  });

  final core.UserEntity user;
  final VoidCallback onLogout;
  final bool showFAB; // Control para mostrar el FAB "Nueva Obra"

  @override
  State<ObrasListScreen> createState() => _ObrasListScreenState();
}

class _ObrasListScreenState extends State<ObrasListScreen> {
  bool _hasLoaded = false;
  ObraState?
  _lastValidState; // Mantener el último estado válido de obras activas

  // Controladores y estado para búsqueda y filtros
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedEstados = {}; // Estados seleccionados para filtrar
  final Set<String> _selectedCities = {}; // Ciudades seleccionadas para filtrar
  SortOption _sortOption = SortOption.none; // Opción de ordenamiento

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Actualizar cuando cambia el texto de búsqueda
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtrar y ordenar obras según búsqueda y filtros
  List<ObraEntity> _filterObras(List<ObraEntity> obras) {
    var filtered = List<ObraEntity>.from(obras);

    // Filtrar por texto de búsqueda
    final searchText = _searchController.text.toLowerCase().trim();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((obra) {
        return obra.title.toLowerCase().contains(searchText) ||
            obra.description.toLowerCase().contains(searchText) ||
            obra.location.toLowerCase().contains(searchText) ||
            obra.city.toLowerCase().contains(searchText);
      }).toList();
    }

    // Filtrar por estados seleccionados
    if (_selectedEstados.isNotEmpty) {
      filtered = filtered.where((obra) {
        final estadoNormalizado = obra.estado.toLowerCase();
        return _selectedEstados.any((selectedEstado) {
          final selectedNormalizado = selectedEstado.toLowerCase();
          return estadoNormalizado == selectedNormalizado ||
              estadoNormalizado == selectedNormalizado.replaceAll('_', ' ') ||
              selectedNormalizado == estadoNormalizado.replaceAll('_', ' ');
        });
      }).toList();
    }

    // Filtrar por ciudades seleccionadas
    if (_selectedCities.isNotEmpty) {
      filtered = filtered.where((obra) {
        return _selectedCities.contains(obra.city.toLowerCase());
      }).toList();
    }

    // Aplicar ordenamiento
    filtered = _sortObras(filtered);

    return filtered;
  }

  // Ordenar obras según la opción seleccionada
  List<ObraEntity> _sortObras(List<ObraEntity> obras) {
    final sorted = List<ObraEntity>.from(obras);

    switch (_sortOption) {
      case SortOption.costoAsc:
        sorted.sort((a, b) => a.costo.compareTo(b.costo));
        break;
      case SortOption.costoDesc:
        sorted.sort((a, b) => b.costo.compareTo(a.costo));
        break;
      case SortOption.tituloAsc:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOption.tituloDesc:
        sorted.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case SortOption.ciudadAsc:
        sorted.sort(
          (a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        );
        break;
      case SortOption.ciudadDesc:
        sorted.sort(
          (a, b) => b.city.toLowerCase().compareTo(a.city.toLowerCase()),
        );
        break;
      case SortOption.tareasAsc:
        sorted.sort((a, b) => a.tareas.length.compareTo(b.tareas.length));
        break;
      case SortOption.tareasDesc:
        sorted.sort((a, b) => b.tareas.length.compareTo(a.tareas.length));
        break;
      case SortOption.antiguedadAsc:
        // Ordenar por ID (asumiendo que IDs más antiguos tienen números menores o son más cortos)
        sorted.sort((a, b) => a.id.compareTo(b.id));
        break;
      case SortOption.antiguedadDesc:
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
      case SortOption.none:
        // Sin ordenamiento
        break;
    }

    return sorted;
  }

  // Toggle de estado en filtros
  void _toggleEstadoFilter(String estado) {
    setState(() {
      if (_selectedEstados.contains(estado)) {
        _selectedEstados.remove(estado);
      } else {
        _selectedEstados.add(estado);
      }
    });
  }

  // Toggle de ciudad en filtros
  void _toggleCityFilter(String city) {
    setState(() {
      final cityLower = city.toLowerCase();
      if (_selectedCities.contains(cityLower)) {
        _selectedCities.remove(cityLower);
      } else {
        _selectedCities.add(cityLower);
      }
    });
  }

  // Obtener lista única de ciudades de las obras
  List<String> _getUniqueCities(List<ObraEntity> obras) {
    final cities = obras
        .map((obra) => obra.city)
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  // Limpiar todos los filtros
  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedEstados.clear();
      _selectedCities.clear();
      _sortOption = SortOption.none;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Solo cargar si realmente necesitamos datos
    final currentState = context.read<ObraBloc>().state;

    // Si el estado actual es ObraLoaded, guardarlo como válido
    if (currentState is ObraLoaded) {
      _hasLoaded = true;
      _lastValidState = currentState;
    } else if (currentState is ObraInitial && !_hasLoaded) {
      // Solo cargar si es el estado inicial y no hemos cargado aún
      _loadObrasActivas();
    }
  }

  void _loadObrasActivas() {
    if (!_hasLoaded && mounted) {
      // NO marcar _hasLoaded aquí - solo se marca cuando se recibe ObraLoaded exitosamente
      context.read<ObraBloc>().add(const LoadObras());
    }
  }

  // Función helper para obtener el color según el estado
  static Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Función helper para obtener el nombre a mostrar según el estado
  static String _getEstadoDisplayName(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
      case 'en progreso':
        return 'En Proceso';
      case 'finalizado':
        return 'Finalizado';
      default:
        return estado;
    }
  }

  // Obtener etiqueta para opción de ordenamiento
  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.costoAsc:
        return 'Costo: Menor a Mayor';
      case SortOption.costoDesc:
        return 'Costo: Mayor a Menor';
      case SortOption.tituloAsc:
        return 'Título: A-Z';
      case SortOption.tituloDesc:
        return 'Título: Z-A';
      case SortOption.ciudadAsc:
        return 'Ciudad: A-Z';
      case SortOption.ciudadDesc:
        return 'Ciudad: Z-A';
      case SortOption.tareasAsc:
        return 'Tareas: Menos a Más';
      case SortOption.tareasDesc:
        return 'Tareas: Más a Menos';
      case SortOption.antiguedadAsc:
        return 'Antigüedad: Más Antigua';
      case SortOption.antiguedadDesc:
        return 'Antigüedad: Más Reciente';
      case SortOption.none:
        return '';
    }
  }

  // Mostrar modal de filtros avanzados
  void _showAdvancedFilters(BuildContext context, List<ObraEntity> obras) {
    final uniqueCities = _getUniqueCities(obras);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtros y Ordenamiento',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ordenamiento
                    Text(
                      'Ordenar por',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...SortOption.values
                        .where((option) => option != SortOption.none)
                        .map((option) {
                          return RadioListTile<SortOption>(
                            title: Text(_getSortOptionLabel(option)),
                            value: option,
                            groupValue: _sortOption,
                            onChanged: (value) {
                              setState(() {
                                _sortOption = value!;
                              });
                            },
                            activeColor: TierraApp.primary,
                          );
                        }),
                    RadioListTile<SortOption>(
                      title: const Text('Sin ordenamiento'),
                      value: SortOption.none,
                      groupValue: _sortOption,
                      onChanged: (value) {
                        setState(() {
                          _sortOption = value!;
                        });
                      },
                      activeColor: TierraApp.primary,
                    ),
                    const SizedBox(height: 24),
                    // Filtros por estado
                    Text(
                      'Filtrar por estado',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'Pendiente',
                          isSelected: _selectedEstados.contains('pendiente'),
                          onTap: () => _toggleEstadoFilter('pendiente'),
                          color: Colors.orange,
                          isDark: isDark,
                        ),
                        _FilterChip(
                          label: 'En Proceso',
                          isSelected:
                              _selectedEstados.contains('en_proceso') ||
                              _selectedEstados.contains('en progreso'),
                          onTap: () => _toggleEstadoFilter('en_proceso'),
                          color: Colors.blue,
                          isDark: isDark,
                        ),
                        _FilterChip(
                          label: 'Finalizado',
                          isSelected: _selectedEstados.contains('finalizado'),
                          onTap: () => _toggleEstadoFilter('finalizado'),
                          color: Colors.green,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Filtros por ciudad
                    if (uniqueCities.isNotEmpty) ...[
                      Text(
                        'Filtrar por ciudad',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: uniqueCities.map((city) {
                          return _FilterChip(
                            label: city,
                            isSelected: _selectedCities.contains(
                              city.toLowerCase(),
                            ),
                            onTap: () => _toggleCityFilter(city),
                            isDark: isDark,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Botones de acción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: TierraApp.primary,
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isMaster = UserRoleUtils.isMaster(widget.user);

    final roleDisplayName = UserRoleUtils.getRoleDisplayName(widget.user);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Mis Obras',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),

        backgroundColor: TierraApp.getAppBarColor(isDark),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Badge del rol a la derecha (más grande, al menos el doble)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: TierraApp.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TierraApp.primary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMaster
                          ? Icons.construction
                          : Icons.admin_panel_settings,
                      size: 20,
                      color: TierraApp.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleDisplayName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: TierraApp.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ObraBloc, ObraState>(
        listener: (context, state) {
          // Guardar el estado válido de obras activas
          if (state is ObraLoaded) {
            _hasLoaded = true;
            _lastValidState = state;
          }
        },
        builder: (context, state) {
          // Determinar qué estado renderizar
          ObraState stateToRender = state;

          // Si el estado es de obras finalizadas u otros tipos, usar el último estado válido de activas
          if (state is ObrasFinalizadasLoaded ||
              state is ObrasFinalizadasLoading) {
            // Si tenemos un estado válido previo, usarlo
            if (_lastValidState is ObraLoaded) {
              stateToRender = _lastValidState!;
            } else {
              // Si no hay estado previo, cargar obras activas
              if (!_hasLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_hasLoaded) {
                    _loadObrasActivas();
                  }
                });
              }
              return const Center(child: CircularProgressIndicator());
            }
          }

          // Cargar obras activas cuando la pantalla se construye por primera vez
          if (!_hasLoaded &&
              stateToRender is! ObraLoaded &&
              stateToRender is! ObrasActivasLoading &&
              stateToRender is! ObraError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasLoaded) {
                _loadObrasActivas();
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Mostrar loading solo para obras activas
          if (stateToRender is ObrasActivasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stateToRender is ObraLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stateToRender is ObraError) {
            final errorState = stateToRender; // Cast para acceso directo
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorState.message,
                    style: textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      _hasLoaded = false;
                      context.read<ObraBloc>().add(const LoadObras());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (stateToRender is ObraLoaded) {
            final obrasLoaded = stateToRender; // Cast para acceso directo
            final filteredObras = _filterObras(obrasLoaded.obras);

            return Column(
              children: [
                // Barra de búsqueda y filtros
                Container(
                  color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Barra de búsqueda
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar obras...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filtros y ordenamiento
                      Row(
                        children: [
                          // Botón de filtros avanzados
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showAdvancedFilters(
                                context,
                                obrasLoaded.obras,
                              ),
                              icon: Icon(
                                Icons.tune,
                                size: 18,
                                color:
                                    (_selectedEstados.isNotEmpty ||
                                        _selectedCities.isNotEmpty ||
                                        _sortOption != SortOption.none)
                                    ? TierraApp.primary
                                    : null,
                              ),
                              label: Text(
                                'Filtros',
                                style: TextStyle(
                                  color:
                                      (_selectedEstados.isNotEmpty ||
                                          _selectedCities.isNotEmpty ||
                                          _sortOption != SortOption.none)
                                      ? TierraApp.primary
                                      : null,
                                  fontWeight:
                                      (_selectedEstados.isNotEmpty ||
                                          _selectedCities.isNotEmpty ||
                                          _sortOption != SortOption.none)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                side: BorderSide(
                                  color:
                                      (_selectedEstados.isNotEmpty ||
                                          _selectedCities.isNotEmpty ||
                                          _sortOption != SortOption.none)
                                      ? TierraApp.primary
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.1,
                                              )),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón de limpiar filtros
                          if (_selectedEstados.isNotEmpty ||
                              _selectedCities.isNotEmpty ||
                              _sortOption != SortOption.none ||
                              _searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: _clearAllFilters,
                              icon: const Icon(Icons.clear_all),
                              tooltip: 'Limpiar filtros',
                              color: TierraApp.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Chips de filtros activos
                      if (_selectedEstados.isNotEmpty ||
                          _selectedCities.isNotEmpty ||
                          _sortOption != SortOption.none)
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Filtros de estado activos
                              ..._selectedEstados.map((estado) {
                                final color = estado == 'pendiente'
                                    ? Colors.orange
                                    : estado == 'en_proceso' ||
                                          estado == 'en progreso'
                                    ? Colors.blue
                                    : Colors.green;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(_getEstadoDisplayName(estado)),
                                    onDeleted: () =>
                                        _toggleEstadoFilter(estado),
                                    backgroundColor: color.withValues(
                                      alpha: isDark ? 0.2 : 0.1,
                                    ),
                                    deleteIconColor: color,
                                    labelStyle: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }),
                              // Filtros de ciudad activos
                              ..._selectedCities.map((city) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(city),
                                    onDeleted: () => _toggleCityFilter(city),
                                    backgroundColor: TierraApp.primary
                                        .withValues(alpha: isDark ? 0.2 : 0.1),
                                    deleteIconColor: TierraApp.primary,
                                    labelStyle: TextStyle(
                                      color: TierraApp.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }),
                              // Ordenamiento activo
                              if (_sortOption != SortOption.none)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(
                                      _getSortOptionLabel(_sortOption),
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _sortOption = SortOption.none;
                                      });
                                    },
                                    backgroundColor: Colors.purple.withValues(
                                      alpha: isDark ? 0.2 : 0.1,
                                    ),
                                    deleteIconColor: Colors.purple,
                                    labelStyle: const TextStyle(
                                      color: Colors.purple,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Lista de obras filtradas
                Expanded(
                  child: filteredObras.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                obrasLoaded.obras.isEmpty
                                    ? Icons.construction_outlined
                                    : Icons.search_off,
                                size: 64,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                obrasLoaded.obras.isEmpty
                                    ? (isMaster
                                          ? 'No hay obras registradas'
                                          : 'No tienes obras asignadas')
                                    : 'No se encontraron obras',
                                style: textTheme.titleMedium?.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _hasLoaded = false;
                            context.read<ObraBloc>().add(const LoadObras());
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredObras.length,
                            itemBuilder: (context, index) {
                              final obra = filteredObras[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ObraDetailScreen(obra: obra),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Leading: Icono y Estado
                                        SizedBox(
                                          width: 80,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: TierraApp.primary
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.construction,
                                                  color: TierraApp.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 70,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getEstadoColor(
                                                    obra.estado,
                                                  ).withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: _getEstadoColor(
                                                      obra.estado,
                                                    ).withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    _getEstadoDisplayName(
                                                      obra.estado,
                                                    ),
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              _getEstadoColor(
                                                                obra.estado,
                                                              ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 10,
                                                          height: 1.0,
                                                        ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Contenido principal
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                obra.title,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (obra.description.isNotEmpty)
                                                Text(
                                                  obra.description,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black54,
                                                      ),
                                                ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black54,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${obra.city}, ${obra.location}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors
                                                                      .black54,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (obra.tareas.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.assignment,
                                                      size: 16,
                                                      color: isDark
                                                          ? Colors.white54
                                                          : Colors.black54,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${obra.tareas.length} tarea${obra.tareas.length > 1 ? 's' : ''}',
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors
                                                                      .black54,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Trailing: Chevron
                                        Icon(
                                          Icons.chevron_right,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          // Estado inicial o desconocido: mostrar loading
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton:
          (widget.showFAB && UserRoleUtils.isAdmin(widget.user))
          ? FloatingActionButton.extended(
              heroTag:
                  'fab_nueva_obra', // Tag único para evitar conflictos de Hero
              onPressed: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ObraBloc>()),
                        BlocProvider.value(value: context.read<TareaBloc>()),
                      ],
                      child: const CreateObraScreen(),
                    ),
                  ),
                );
                // La obra ya se refrescó en la pantalla
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Obra'),
              backgroundColor: TierraApp.primary,
            )
          : null,
    );
  }
}

// Widget para chips de filtro
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? TierraApp.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor.withValues(alpha: isDark ? 0.25 : 0.15),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected
            ? chipColor
            : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected
            ? chipColor
            : (isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1)),
        width: isSelected ? 1.5 : 1,
      ),
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
