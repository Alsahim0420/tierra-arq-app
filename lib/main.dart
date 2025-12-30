import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/injection/injection_container.dart' as di;
import 'core/entities/user_entity.dart' as core;
import 'core/widgets/custom_snackbar.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/obra/obra_bloc.dart';
import 'presentation/bloc/obra/obra_event.dart';
import 'presentation/bloc/obra/obra_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.configureDependencies();
  runApp(const TierraApp());
}

class TierraApp extends StatelessWidget {
  const TierraApp({super.key});

  static const _primary = Color(0xFFD5B189);
  static const _dark = Color(0xFF0E0E0E);
  static const _card = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF8D8D8D);

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: _primary,
        secondary: const Color(0xFF9E7A55),
        surface: _card,
      ),
      scaffoldBackgroundColor: _dark,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      dividerColor: _muted.withValues(alpha: 0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.getIt<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider(
          create: (_) => di.getIt<ObraBloc>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TIERRA Control de Obras',
        theme: _buildTheme(),
        home: const AuthWrapper(),
      ),
    );
  }
}

// --- AUTH MODELS & MOCKS ------------------------------------------------

class User {
  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.lastname = '',
    this.phone,
    this.city = '',
    this.dni,
    this.address = '',
    this.specialty = '',
    this.experienceYears,
    this.birthDate,
    this.joinDate,
    this.status = 'Activo',
    this.notes = '',
  });

  final String id;
  final String email;
  final String password;
  final String name;
  final String lastname;
  final UserRole role;
  final int? phone;
  final String city;
  final int? dni;
  final String address;
  final String specialty;
  final int? experienceYears;
  final DateTime? birthDate;
  final DateTime? joinDate;
  final String status;
  final String notes;

  String get fullName => lastname.isEmpty ? name : '$name $lastname';
  String get roleLabel => role == UserRole.admin ? 'Administrador' : 'Maestro';

  String get formattedPhone => phone != null ? '+57 $phone' : 'No especificado';
  String get formattedBirthDate => birthDate != null
      ? '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'
      : 'No especificada';
  String get formattedJoinDate => joinDate != null
      ? '${joinDate!.day}/${joinDate!.month}/${joinDate!.year}'
      : 'No especificada';
  int? get age => birthDate != null
      ? DateTime.now().difference(birthDate!).inDays ~/ 365
      : null;
}

// --- AUTH WRAPPER -------------------------------------------------------

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          // Cargar obras del responsable al autenticarse
          context.read<ObraBloc>().add(
                LoadObrasByResponsable(state.user.id),
              );
          return ObrasListScreen(
            user: state.user,
            onLogout: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
          );
        } else {
          // Mostrar LoginScreen siempre que no esté autenticado
          // El loading se muestra en el botón, no como pantalla completa
          return LoginScreen();
        }
      },
    );
  }

}

// --- LOGIN SCREEN -------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    context.read<AuthBloc>().add(LoginRequested(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          CustomSnackBar.showError(
            context,
            message: state.message,
            actionLabel: 'Cerrar',
            onAction: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo/Brand
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TierraApp._primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.construction,
                          size: 64,
                          color: TierraApp._primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'TIERRA ARQ',
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Control de obras',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (!value.contains('@')) {
                            return 'Correo inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(context),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 32),
                      // Login button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => _handleLogin(context),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- OBRAS LIST SCREEN -------------------------------------------------------

class ObrasListScreen extends StatelessWidget {
  const ObrasListScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final core.UserEntity user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Obras',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    user: user,
                    onLogout: onLogout,
                  ),
                ),
              );
            },
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: BlocBuilder<ObraBloc, ObraState>(
        builder: (context, state) {
          if (state is ObraLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ObraError) {
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
                    state.message,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<ObraBloc>().add(
                            LoadObrasByResponsable(user.id),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is ObraLoaded) {
            if (state.obras.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 64,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes obras asignadas',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ObraBloc>().add(
                      LoadObrasByResponsable(user.id),
                    );
                // Esperar un momento para que el estado cambie
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.obras.length,
                itemBuilder: (context, index) {
                  final obra = state.obras[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: TierraApp._primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.construction,
                          color: TierraApp._primary,
                        ),
                      ),
                      title: Text(
                        obra.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (obra.description.isNotEmpty)
                            Text(
                              obra.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${obra.city}, ${obra.location}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
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
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${obra.tareas.length} tarea${obra.tareas.length > 1 ? 's' : ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        // TODO: Navegar a detalle de obra
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// --- PROFILE SCREEN ----------------------------------------------------------

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final core.UserEntity user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar y nombre
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: TierraApp._primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: TierraApp._primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TierraApp._primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role == 'admin' ? 'Administrador' : 'Maestro',
                      style: textTheme.bodySmall?.copyWith(
                        color: TierraApp._primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Información de contacto
            _InfoSection(
              title: 'Información de contacto',
              children: [
                _InfoRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: user.email,
                ),
                if (user.phone != null)
                  _InfoRow(
                    icon: Icons.phone,
                    label: 'Teléfono',
                    value: '+57 ${user.phone}',
                  ),
                if (user.city.isNotEmpty)
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Ciudad',
                    value: user.city,
                  ),
              ],
            ),
            // Información personal
            if (user.dni != null)
              _InfoSection(
                title: 'Información personal',
                children: [
                  _InfoRow(
                    icon: Icons.badge,
                    label: 'DNI',
                    value: user.dni.toString(),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            // Botón de cerrar sesión
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  onLogout();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final User user;
  final VoidCallback onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<Project> _projects;
  late Project _selected;
  Project? _maestroSelectedProject;
  int _selectedIndex = 0;

  UserRole get _role => widget.user.role;
  String get _activeMaestro => widget.user.fullName;

  @override
  void initState() {
    super.initState();
    _projects = seedProjects.map((project) => project.deepCopy()).toList();
    _selected = _projects.first;
  }

  List<Task> _maestroTasks(Project project) {
    return project.tasks
        .where((task) => task.assignedTo == _activeMaestro)
        .toList();
  }

  List<Project> _maestroProjects() {
    return _projects
        .where((project) => _maestroTasks(project).isNotEmpty)
        .toList();
  }

  void _handleCreateTask() {
    _openTaskEditor();
  }

  void _handleEditTask(Task task) {
    _openTaskEditor(existingTask: task);
  }

  void _handleAddEvidence(Task task) {
    _openEvidenceEditor(task: task);
  }

  Future<void> _openEvidenceEditor({required Task task}) async {
    // Solicitar permisos ANTES de abrir el modal para que aparezca el diálogo del sistema
    // Esto es esencial para que el usuario vea los diálogos de permisos

    // 1. Cámara - solicitar directamente (mostrará el diálogo del sistema si es necesario)
    var cameraStatus = await Permission.camera.request();
    debugPrint(
      '📱 Estado cámara después de solicitar: ${cameraStatus.toString()}',
    );

    if (cameraStatus.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Permiso de cámara denegado. Ve a configuración para habilitarlo.',
          ),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () => openAppSettings(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (!cameraStatus.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se necesita permiso de cámara para tomar fotos y grabar videos',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 2. Galería (fotos/videos) - solicitar directamente
    if (Platform.isAndroid) {
      await Permission.photos.request();
      await Permission.videos.request();
    } else {
      // iOS - solicitar permiso de fotos directamente
      var photosStatus = await Permission.photos.request();
      debugPrint(
        '📱 Estado galería después de solicitar: ${photosStatus.toString()}',
      );

      if (photosStatus.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permiso de galería denegado. Ve a configuración para habilitarlo.',
            ),
            action: SnackBarAction(
              label: 'Abrir',
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      if (!photosStatus.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se necesita permiso de galería para seleccionar fotos y videos',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // 3. Micrófono (opcional para videos con audio)
    await Permission.microphone.request();

    // Ahora abrimos el modal después de solicitar los permisos
    if (!mounted) return;
    final evidence = await showModalBottomSheet<Evidence>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EvidenceEditorSheet(task: task, maestroName: _activeMaestro),
    );

    if (evidence == null) return;

    final selectedIndex = _projects.indexWhere(
      (project) => project.id == _selected.id,
    );
    if (selectedIndex == -1) return;

    final taskIndex = _selected.tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    final updatedTask = _selected.tasks[taskIndex].copyWith(
      evidences: [..._selected.tasks[taskIndex].evidences, evidence],
    );

    final tasks = List<Task>.from(_selected.tasks);
    tasks[taskIndex] = updatedTask;

    final updatedProject = _selected.copyWith(tasks: tasks);
    setState(() {
      _projects[selectedIndex] = updatedProject;
      _selected = updatedProject;
      if (_maestroSelectedProject != null) {
        _maestroSelectedProject = updatedProject;
      }
    });
  }

  Future<void> _openTaskEditor({Task? existingTask}) async {
    final updatedTask = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskEditorSheet(initialTask: existingTask),
    );

    if (updatedTask == null) return;

    final selectedIndex = _projects.indexWhere(
      (project) => project.id == _selected.id,
    );
    if (selectedIndex == -1) return;

    final tasks = List<Task>.from(_selected.tasks);
    if (existingTask == null) {
      tasks.add(updatedTask);
    } else {
      final taskIndex = tasks.indexWhere((task) => task.id == existingTask.id);
      if (taskIndex == -1) return;
      tasks[taskIndex] = updatedTask;
    }

    final updatedProject = _selected.copyWith(tasks: tasks);
    setState(() {
      _projects[selectedIndex] = updatedProject;
      _selected = updatedProject;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final textTheme = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(
            leading: _selectedIndex == 0 && _maestroSelectedProject == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_role == UserRole.maestro &&
                          _maestroSelectedProject != null) {
                        setState(() => _maestroSelectedProject = null);
                      } else if (_selectedIndex != 0) {
                        setState(() => _selectedIndex = 0);
                      }
                    },
                    tooltip: 'Regresar',
                  ),
            titleSpacing: isCompact ? 16 : 24,
            title: Text(
              _selectedIndex == 0
                  ? (_role == UserRole.admin
                        ? 'Control de obras'
                        : 'Registro de campo')
                  : _selectedIndex == 1
                  ? 'Tareas'
                  : _selectedIndex == 2
                  ? 'Evidencias'
                  : 'Perfil',
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
          body: _selectedIndex == 3
              ? _ProfileView(
                  user: widget.user,
                  onLogout: widget.onLogout,
                  isCompact: isCompact,
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedIndex == 0) ...[
                        if (_role == UserRole.admin) ...[
                          _ProjectHero(
                            project: _selected,
                            isCompact: isCompact,
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_role == UserRole.admin)
                          _AdminContent(
                            isCompact: isCompact,
                            projects: _projects,
                            selected: _selected,
                            onSelect: (project) =>
                                setState(() => _selected = project),
                            onCreateTask: _handleCreateTask,
                            onEditTask: _handleEditTask,
                          )
                        else ...[
                          if (_maestroSelectedProject != null) ...[
                            _ProjectHero(
                              project: _maestroSelectedProject!,
                              isCompact: isCompact,
                            ),
                            const SizedBox(height: 20),
                            _MaestroProjectDetail(
                              maestroName: _activeMaestro,
                              project: _maestroSelectedProject!,
                              tasks: _maestroTasks(_maestroSelectedProject!),
                              onBack: () => setState(
                                () => _maestroSelectedProject = null,
                              ),
                              onAddEvidence: _handleAddEvidence,
                            ),
                          ] else
                            _MaestroProjectList(
                              maestroName: _activeMaestro,
                              projects: _maestroProjects(),
                              onSelect: (project) => setState(
                                () => _maestroSelectedProject = project,
                              ),
                            ),
                        ],
                      ] else if (_selectedIndex == 1) ...[
                        // Vista de Tareas
                        Text('Tareas', style: textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Text(
                          'Vista de tareas próximamente',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ] else if (_selectedIndex == 2) ...[
                        // Vista de Evidencias
                        Text('Evidencias', style: textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Text(
                          'Vista de evidencias próximamente',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
          bottomNavigationBar: NavigationBar(
            height: 68,
            backgroundColor: Colors.black,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_customize),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Tareas',
              ),
              NavigationDestination(
                icon: Icon(Icons.photo_camera_back_outlined),
                selectedIcon: Icon(Icons.photo_camera_back),
                label: 'Evidencias',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
        );
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.user,
    required this.onLogout,
    required this.isCompact,
  });

  final User user;
  final VoidCallback onLogout;
  final bool isCompact;

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TierraApp._primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: TierraApp._primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Información principal del usuario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: TierraApp._primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.role == UserRole.admin
                        ? Icons.security
                        : Icons.construction,
                    size: 48,
                    color: TierraApp._primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user.fullName,
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: TierraApp._primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TierraApp._primary),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: TierraApp._primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Información de contacto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de contacto',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(
                  context,
                  Icons.email_outlined,
                  'Correo electrónico',
                  user.email,
                ),
                if (user.phone != null)
                  _buildInfoRow(
                    context,
                    Icons.phone_outlined,
                    'Teléfono',
                    '+57 ${user.phone}',
                  ),
                if (user.city.isNotEmpty)
                  _buildInfoRow(
                    context,
                    Icons.location_city_outlined,
                    'Ciudad',
                    user.city,
                  ),
              ],
            ),
          ),
          if (user.dni != null) ...[
            const SizedBox(height: 16),
            // Información personal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información personal',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    context,
                    Icons.badge_outlined,
                    'Documento de identidad',
                    '${user.dni}',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Botón de cerrar sesión
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.red.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1B1B1B),
                      title: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        '¿Estás seguro de que deseas cerrar sesión?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onLogout();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Cerrar sesión',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({required this.project, required this.isCompact});

  final Project project;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final totalTasks = project.tasks.length;
    final completed = project.tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final progress = completed / totalTasks;

    final metricsRow = Row(
      children: [
        _MetricChip(
          value: '${project.tasks.length}',
          label: 'Tareas planificadas',
        ),
        const SizedBox(width: 12),
        _MetricChip(value: project.resident, label: 'Residente'),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Avance ${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D1D1D), Color(0xFF363029)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${project.location} · ${project.area} m²',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricChip(
                      value: '${project.tasks.length}',
                      label: 'Tareas planificadas',
                    ),
                    _MetricChip(value: project.resident, label: 'Residente'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avance ${(progress * 100).round()}%',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            metricsRow,
        ],
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent({
    required this.isCompact,
    required this.projects,
    required this.selected,
    required this.onSelect,
    required this.onCreateTask,
    required this.onEditTask,
  });

  final bool isCompact;
  final List<Project> projects;
  final Project selected;
  final ValueChanged<Project> onSelect;
  final VoidCallback onCreateTask;
  final void Function(Task task) onEditTask;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProjectCarousel(
          projects: projects,
          selected: selected,
          isCompact: isCompact,
          onSelect: onSelect,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Tareas del proyecto', style: textTheme.titleLarge),
            const Spacer(),
            TextButton.icon(
              onPressed: onCreateTask,
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarea'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...selected.tasks.map(
          (task) => _TaskCard(
            task: task,
            showAdminActions: true,
            onEdit: () => onEditTask(task),
          ),
        ),
        const SizedBox(height: 24),
        Text('Evidencias recientes', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: selected.latestEvidence.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => SizedBox(
              width: 200,
              child: _EvidenceCard(evidence: selected.latestEvidence[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _MaestroProjectList extends StatelessWidget {
  const _MaestroProjectList({
    required this.maestroName,
    required this.projects,
    required this.onSelect,
  });

  final String maestroName;
  final List<Project> projects;
  final ValueChanged<Project> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, $maestroName', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Estos son los proyectos donde tienes actividades asignadas.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Tus proyectos', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          Text(
            'Por ahora no tienes obras asignadas.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white54),
          )
        else
          ...projects.map((project) {
            final totalTasks = project.tasks.length;
            final completed = project.tasks
                .where((task) => task.status == TaskStatus.completed)
                .length;
            final progress = totalTasks == 0
                ? 0.0
                : completed / totalTasks.toDouble();
            return GestureDetector(
              onTap: () => onSelect(project),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      project.location,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${project.area} m²',
                          style: textTheme.titleLarge?.copyWith(
                            color: TierraApp._primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Avance ${(progress * 100).round()}%',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => onSelect(project),
                        icon: const Icon(Icons.arrow_outward),
                        label: const Text('Ver detalle'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MaestroProjectDetail extends StatelessWidget {
  const _MaestroProjectDetail({
    required this.maestroName,
    required this.project,
    required this.tasks,
    required this.onBack,
    required this.onAddEvidence,
  });

  final String maestroName;
  final Project project;
  final List<Task> tasks;
  final VoidCallback onBack;
  final void Function(Task) onAddEvidence;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          label: const Text('Volver a proyectos'),
        ),
        const SizedBox(height: 12),
        Text(project.name, style: textTheme.titleLarge),
        Text(
          'Coordinado por $maestroName',
          style: textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ubicación', style: textTheme.labelMedium),
              Text(project.location),
              const SizedBox(height: 10),
              Text('Área', style: textTheme.labelMedium),
              Text('${project.area} m²'),
              const SizedBox(height: 10),
              Text('Residente', style: textTheme.labelMedium),
              Text(project.resident),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Tus tareas', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Text(
            'Aún no tienes tareas asociadas a esta obra.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white54),
          )
        else
          ...tasks.map(
            (task) => _TaskCard(
              task: task,
              compact: true,
              callToAction: ElevatedButton.icon(
                onPressed: () => onAddEvidence(task),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Registrar evidencia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TierraApp._primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProjectCarousel extends StatelessWidget {
  const _ProjectCarousel({
    required this.projects,
    required this.selected,
    required this.isCompact,
    required this.onSelect,
  });

  final List<Project> projects;
  final Project selected;
  final bool isCompact;
  final ValueChanged<Project> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proyectos activos', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        isCompact
            ? SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: PageController(
                    viewportFraction: 0.9,
                    initialPage: projects
                        .indexWhere((project) => project.id == selected.id)
                        .clamp(0, projects.length - 1),
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _ProjectCard(
                      project: project,
                      isSelected: project.id == selected.id,
                      textTheme: textTheme,
                      onTap: () => onSelect(project),
                      width: double.infinity,
                    );
                  },
                ),
              )
            : SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _ProjectCard(
                      project: project,
                      isSelected: project.id == selected.id,
                      textTheme: textTheme,
                      onTap: () => onSelect(project),
                      width: 200,
                    );
                  },
                ),
              ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.isSelected,
    required this.textTheme,
    required this.onTap,
    required this.width,
  });

  final Project project;
  final bool isSelected;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white10 : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? TierraApp._primary : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              project.location,
              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              '${project.area} m²',
              style: textTheme.titleLarge?.copyWith(color: TierraApp._primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({this.initialTask, super.key});

  final Task? initialTask;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _assignedController;
  late final TextEditingController _deadlineController;
  late final TextEditingController _checklistTotalController;
  late final TextEditingController _checklistDoneController;
  final _formKey = GlobalKey<FormState>();
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTask;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _assignedController = TextEditingController(
      text: initial?.assignedTo ?? '',
    );
    _deadlineController = TextEditingController(
      text: initial?.deadlineLabel ?? '',
    );
    _checklistTotalController = TextEditingController(
      text: (initial?.totalChecklist ?? 6).toString(),
    );
    _checklistDoneController = TextEditingController(
      text: (initial?.completedChecklist ?? 0).toString(),
    );
    _status = initial?.status ?? TaskStatus.pending;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedController.dispose();
    _deadlineController.dispose();
    _checklistTotalController.dispose();
    _checklistDoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final total = int.tryParse(_checklistTotalController.text) ?? 0;
    final completed = int.tryParse(_checklistDoneController.text) ?? 0;
    final evidence = widget.initialTask == null
        ? <Evidence>[]
        : widget.initialTask!.evidences.map((e) => e.copy()).toList();
    final task = Task(
      id:
          widget.initialTask?.id ??
          'task-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      assignedTo: _assignedController.text.trim(),
      deadlineLabel: _deadlineController.text.trim(),
      evidences: evidence,
      completedChecklist: completed.clamp(0, total),
      totalChecklist: total,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white10),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.initialTask == null ? 'Nueva tarea' : 'Editar tarea',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _assignedController,
                  decoration: const InputDecoration(labelText: 'Responsable'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha / hora',
                    hintText: '15 Feb · 16:00',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _checklistDoneController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Checklist completado',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _checklistTotalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Checklist total',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: TaskStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(switch (status) {
                            TaskStatus.pending => 'Pendiente',
                            TaskStatus.inProgress => 'En progreso',
                            TaskStatus.completed => 'Completada',
                          }),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: TierraApp._primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.initialTask == null
                        ? 'Crear tarea'
                        : 'Guardar cambios',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    this.compact = false,
    this.callToAction,
    this.showAdminActions = false,
    this.onEdit,
  });

  final Task task;
  final bool compact;
  final Widget? callToAction;
  final bool showAdminActions;
  final VoidCallback? onEdit;

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case TaskStatus.pending:
        return Colors.white24;
      case TaskStatus.inProgress:
        return const Color(0xFF9E7A55);
      case TaskStatus.completed:
        return const Color(0xFF3BA892);
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.inProgress:
        return 'En progreso';
      case TaskStatus.completed:
        return 'Completada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showAdminActions)
                  PopupMenuButton<String>(
                    tooltip: 'Más acciones',
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) {
                        onEdit!();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                    ],
                  ),
                if (showAdminActions) const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor(context)),
                  ),
                  child: Text(_statusLabel, style: textTheme.labelMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (task.evidences.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: task.evidences
                    .take(compact ? 2 : 3)
                    .map(
                      (evidence) => _EvidenceChip(
                        label: evidence.timeLabel,
                        note: evidence.note,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.assignedTo,
                    style: textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(task.deadlineLabel, style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.photo_camera_back,
                  size: 18,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${task.evidences.length} evidencias',
                    style: textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.checklist, size: 18, color: Colors.white54),
                const SizedBox(width: 6),
                Text(
                  '${task.completedChecklist}/${task.totalChecklist}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            if (callToAction != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: callToAction!),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  const _EvidenceChip({required this.label, required this.note});

  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.evidence});

  final Evidence evidence;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_front, color: TierraApp._primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  evidence.taskTitle,
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evidence.note,
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              Text(evidence.timeLabel, style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              Text(evidence.recordedBy, style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// --- EVIDENCE EDITOR SHEET ------------------------------------------------

class EvidenceEditorSheet extends StatefulWidget {
  const EvidenceEditorSheet({
    super.key,
    required this.task,
    required this.maestroName,
  });

  final Task task;
  final String maestroName;

  @override
  State<EvidenceEditorSheet> createState() => _EvidenceEditorSheetState();
}

class _EvidenceEditorSheetState extends State<EvidenceEditorSheet> {
  final _noteController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      // image_picker maneja los permisos automáticamente en iOS
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        if (e.code == 'photo_library_access_denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Se necesita permiso de galería. Ve a configuración para habilitarlo.',
              ),
              action: SnackBarAction(
                label: 'Abrir',
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al seleccionar imágenes: ${e.message}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imágenes: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      // image_picker maneja los permisos automáticamente en iOS
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        if (e.code == 'camera_access_denied' ||
            e.code == 'photo_library_access_denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Se necesita permiso de cámara. Ve a configuración para habilitarlo.',
              ),
              action: SnackBarAction(
                label: 'Abrir',
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al tomar foto: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
      }
    }
  }

  Future<void> _pickVideosFromGallery() async {
    try {
      // image_picker maneja los permisos automáticamente en iOS
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _selectedVideos.add(video);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        if (e.code == 'photo_library_access_denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Se necesita permiso de galería. Ve a configuración para habilitarlo.',
              ),
              action: SnackBarAction(
                label: 'Abrir',
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al seleccionar video: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar video: $e')),
        );
      }
    }
  }

  Future<void> _recordVideo() async {
    try {
      // image_picker maneja los permisos automáticamente en iOS
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
      );
      if (video != null) {
        setState(() {
          _selectedVideos.add(video);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        if (e.code == 'camera_access_denied' ||
            e.code == 'photo_library_access_denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Se necesita permiso de cámara y micrófono. Ve a configuración para habilitarlo.',
              ),
              action: SnackBarAction(
                label: 'Abrir',
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al grabar video: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al grabar video: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  void _showMediaSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Agregar multimedia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: TierraApp._primary),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: TierraApp._primary,
              ),
              title: const Text('Seleccionar imágenes'),
              onTap: () {
                Navigator.pop(context);
                _pickImagesFromGallery();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.videocam, color: TierraApp._primary),
              title: const Text('Grabar video'),
              onTap: () {
                Navigator.pop(context);
                _recordVideo();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.video_library,
                color: TierraApp._primary,
              ),
              title: const Text('Seleccionar video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideosFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final note = _noteController.text.trim();
    if (note.isEmpty && _selectedImages.isEmpty && _selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una nota, imagen o video'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final timeLabel = _formatTimeLabel(now);

    final evidence = Evidence(
      taskTitle: widget.task.title,
      note: note.isEmpty ? 'Evidencia registrada' : note,
      recordedBy: widget.maestroName,
      timeLabel: timeLabel,
      imagePaths: _selectedImages.map((img) => img.path).toList(),
      videoPaths: _selectedVideos.map((vid) => vid.path).toList(),
    );

    Navigator.of(context).pop(evidence);
  }

  String _formatTimeLabel(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white10),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Registrar evidencia', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                widget.task.title,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Nota o descripción',
                        hintText: 'Describe el avance o situación observada...',
                        alignLabelWithHint: true,
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Multimedia (${_selectedImages.length + _selectedVideos.length})',
                          style: textTheme.titleMedium,
                        ),
                        TextButton.icon(
                          onPressed: _showMediaSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate, size: 20),
                          label: const Text('Agregar'),
                          style: TextButton.styleFrom(
                            foregroundColor: TierraApp._primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImages.isEmpty && _selectedVideos.isEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white12,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay multimedia seleccionada',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: _showMediaSourceDialog,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Agregar multimedia'),
                              style: FilledButton.styleFrom(
                                backgroundColor: TierraApp._primary,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount:
                            _selectedImages.length + _selectedVideos.length,
                        itemBuilder: (context, index) {
                          final isImage = index < _selectedImages.length;
                          final mediaIndex = isImage
                              ? index
                              : index - _selectedImages.length;

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: isImage
                                    ? Image.file(
                                        File(_selectedImages[mediaIndex].path),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.black87,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Center(
                                              child: Icon(
                                                Icons.play_circle_filled,
                                                size: 48,
                                                color: Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.videocam,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Video',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Material(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: () => isImage
                                        ? _removeImage(mediaIndex)
                                        : _removeVideo(mediaIndex),
                                    borderRadius: BorderRadius.circular(20),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: TierraApp._primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Guardar evidencia'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- DATA MOCKS -------------------------------------------------------------

enum UserRole { admin, maestro }

enum TaskStatus { pending, inProgress, completed }

class Project {
  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.area,
    required this.resident,
    required this.tasks,
    required this.latestEvidence,
  });

  final String id;
  final String name;
  final String location;
  final int area;
  final String resident;
  final List<Task> tasks;
  final List<Evidence> latestEvidence;

  Project copyWith({
    String? name,
    String? location,
    int? area,
    String? resident,
    List<Task>? tasks,
    List<Evidence>? latestEvidence,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      area: area ?? this.area,
      resident: resident ?? this.resident,
      tasks: tasks ?? this.tasks.map((task) => task.copyWith()).toList(),
      latestEvidence:
          latestEvidence ??
          this.latestEvidence.map((evidence) => evidence.copy()).toList(),
    );
  }

  Project deepCopy() => copyWith();
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.deadlineLabel,
    required this.evidences,
    required this.completedChecklist,
    required this.totalChecklist,
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final String assignedTo;
  final String deadlineLabel;
  final List<Evidence> evidences;
  final int completedChecklist;
  final int totalChecklist;

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    String? assignedTo,
    String? deadlineLabel,
    List<Evidence>? evidences,
    int? completedChecklist,
    int? totalChecklist,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      deadlineLabel: deadlineLabel ?? this.deadlineLabel,
      evidences:
          evidences ??
          this.evidences.map((evidence) => evidence.copy()).toList(),
      completedChecklist: completedChecklist ?? this.completedChecklist,
      totalChecklist: totalChecklist ?? this.totalChecklist,
    );
  }
}

class Evidence {
  Evidence({
    required this.taskTitle,
    required this.note,
    required this.recordedBy,
    required this.timeLabel,
    this.imagePaths = const [],
    this.videoPaths = const [],
  });

  final String taskTitle;
  final String note;
  final String recordedBy;
  final String timeLabel;
  final List<String> imagePaths;
  final List<String> videoPaths;

  Evidence copy() {
    return Evidence(
      taskTitle: taskTitle,
      note: note,
      recordedBy: recordedBy,
      timeLabel: timeLabel,
      imagePaths: List<String>.from(imagePaths),
      videoPaths: List<String>.from(videoPaths),
    );
  }

  Evidence copyWith({
    String? taskTitle,
    String? note,
    String? recordedBy,
    String? timeLabel,
    List<String>? imagePaths,
    List<String>? videoPaths,
  }) {
    return Evidence(
      taskTitle: taskTitle ?? this.taskTitle,
      note: note ?? this.note,
      recordedBy: recordedBy ?? this.recordedBy,
      timeLabel: timeLabel ?? this.timeLabel,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPaths: videoPaths ?? this.videoPaths,
    );
  }
}

final seedProjects = [
  Project(
    id: 'project-novaterra',
    name: 'Apartamento Novaterra · Torre C',
    location: 'Cali · Ciudad Jardín',
    area: 185,
    resident: 'Laura Peña',
    tasks: [
      Task(
        id: 'task-novaterra-structure',
        title: 'Recibo y control de estructura',
        description:
            'Revisión de plomos, nivelaciones y tolerancias antes de iniciar acabados.',
        status: TaskStatus.completed,
        assignedTo: 'Ing. Morales',
        deadlineLabel: '12 Feb · 08:30',
        evidences: [
          Evidence(
            taskTitle: 'Recibo y control de estructura',
            note: 'Fotografías de columnas E3-E4 niveladas.',
            recordedBy: 'Carlos P.',
            timeLabel: 'Hoy · 10:14',
          ),
        ],
        completedChecklist: 8,
        totalChecklist: 8,
      ),
      Task(
        id: 'task-novaterra-electric',
        title: 'Instalaciones eléctricas',
        description:
            'Tendido de redes y pruebas de continuidad para zonas sociales.',
        status: TaskStatus.inProgress,
        assignedTo: 'Maestro Pérez',
        deadlineLabel: '15 Feb · 16:00',
        evidences: [
          Evidence(
            taskTitle: 'Instalaciones eléctricas',
            note: 'Canaletas cerradas · piso 12.',
            recordedBy: 'Maestro Pérez',
            timeLabel: 'Ayer · 18:45',
          ),
          Evidence(
            taskTitle: 'Instalaciones eléctricas',
            note: 'Check de tablero principal.',
            recordedBy: 'Téc. Silva',
            timeLabel: 'Ayer · 11:20',
          ),
        ],
        completedChecklist: 5,
        totalChecklist: 9,
      ),
      Task(
        id: 'task-novaterra-drywall',
        title: 'Mampostería liviana',
        description: 'Divisiones internas drywall con acabado liso.',
        status: TaskStatus.pending,
        assignedTo: 'Equipo Dryline',
        deadlineLabel: '21 Feb · 09:00',
        evidences: const [],
        completedChecklist: 0,
        totalChecklist: 6,
      ),
    ],
    latestEvidence: [
      Evidence(
        taskTitle: 'Instalaciones eléctricas',
        note: 'Ruta de cables embebida sellada.',
        recordedBy: 'Maestro Pérez',
        timeLabel: 'Hace 2h',
      ),
      Evidence(
        taskTitle: 'Recibo y control de estructura',
        note: 'Firma de residente registrada.',
        recordedBy: 'Laura Peña',
        timeLabel: 'Hace 6h',
      ),
    ],
  ),
  Project(
    id: 'project-tierra-hq',
    name: 'Centro Corporativo Tierra HQ',
    location: 'Bogotá · Chicó Norte',
    area: 1430,
    resident: 'Diego Sandoval',
    tasks: [
      Task(
        id: 'task-hq-excavacion',
        title: 'Excavación y contención',
        description:
            'Wall shotcrete y anclajes temporales bajo supervisión geotécnica.',
        status: TaskStatus.inProgress,
        assignedTo: 'Consorcio Cimentar',
        deadlineLabel: '28 Feb · 17:00',
        evidences: [
          Evidence(
            taskTitle: 'Excavación y contención',
            note: 'Informe de laboratorio #231',
            recordedBy: 'Diego S.',
            timeLabel: 'Hoy · 07:40',
          ),
        ],
        completedChecklist: 3,
        totalChecklist: 10,
      ),
      Task(
        id: 'task-hq-seguridad',
        title: 'Plan de seguridad obra',
        description:
            'Actualización listas de verificación y brief al personal subcontratado.',
        status: TaskStatus.pending,
        assignedTo: 'HSE · Adriana Ruiz',
        deadlineLabel: '10 Feb · 07:00',
        evidences: const [],
        completedChecklist: 0,
        totalChecklist: 5,
      ),
    ],
    latestEvidence: [
      Evidence(
        taskTitle: 'Excavación y contención',
        note: 'Shotcrete aplicado eje D.',
        recordedBy: 'Consorcio Cimentar',
        timeLabel: 'Ayer · 19:12',
      ),
    ],
  ),
];
