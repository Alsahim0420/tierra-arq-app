// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/injection/injection_container.dart' as di;
import '../../../domain/usecases/user/get_master_users_usecase.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../app/app.dart';
import '../../utils/user_role_utils.dart';
import '../auth/register_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final List<UserEntity> _users = [];
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!di.getIt.isRegistered<GetMasterUsersUseCase>()) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isInitialLoading = false;
            _errorMessage = 'Error: GetMasterUsersUseCase no está registrado';
          });
        }
        return;
      }

      final getMasterUsersUseCase = di.getIt<GetMasterUsersUseCase>();
      final users = await getMasterUsersUseCase.call(
        page: _currentPage,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          _users.addAll(users);
          _hasMore = users.length == _limit;
          _isLoading = false;
          _isInitialLoading = false;
          if (users.length < _limit) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
          _errorMessage = 'Error al cargar usuarios: ${e.toString()}';
        });
      }
    }
  }

  void _loadMore() {
    if (_hasMore && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      _loadUsers();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _users.clear();
      _isInitialLoading = true;
    });
    await _loadUsers();
  }

  Future<void> _navigateToRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(returnOnSuccess: true),
      ),
    );

    // Si se creó un usuario exitosamente, refrescar la lista
    if (result == true && mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Maestros',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: TierraApp.getAppBarColor(isDark),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated &&
              UserRoleUtils.isAdmin(authState.user)) {
            return FloatingActionButton.extended(
              heroTag: 'fab_nuevo_maestro',
              onPressed: _navigateToRegister,
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo Maestro'),
              backgroundColor: TierraApp.primary,
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: _buildBody(textTheme, isDark),
    );
  }

  Widget _buildBody(TextTheme textTheme, bool isDark) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios maestros registrados',
              style: textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            // Botón para cargar más
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : FilledButton.icon(
                        onPressed: _loadMore,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Cargar más'),
                      ),
              ),
            );
          }

          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: TierraApp.primary.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: TierraApp.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (user.email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: 14,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      user.email,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.construction,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Maestro',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (user.phone != null ||
                      user.city.isNotEmpty ||
                      user.dni != null) ...[
                    Divider(color: isDark ? Colors.white24 : Colors.black12),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (user.phone != null)
                          _buildInfoChip(
                            icon: Icons.phone,
                            label: 'Teléfono',
                            value: user.phone.toString(),
                            isDark: isDark,
                            textTheme: textTheme,
                          ),
                        if (user.city.isNotEmpty)
                          _buildInfoChip(
                            icon: Icons.location_city,
                            label: 'Ciudad',
                            value: user.city,
                            isDark: isDark,
                            textTheme: textTheme,
                          ),
                        if (user.dni != null)
                          _buildInfoChip(
                            icon: Icons.badge,
                            label: 'DNI',
                            value: user.dni.toString(),
                            isDark: isDark,
                            textTheme: textTheme,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required TextTheme textTheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black54),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
