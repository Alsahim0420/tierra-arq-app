import '../models/user_model.dart';
import '../models/obra_model.dart';
import '../models/tarea_model.dart';

/// Servicio centralizado para manejar los datos de la aplicación
/// En el futuro, aquí se conectaría con una API o base de datos
class DataService {
  // Datos mock iniciales
  final List<UserModel> _users = [];
  final List<ObraModel> _obras = [];
  final List<TareaModel> _tareas = [];

  // --- USUARIOS ---
  Future<List<UserModel>> getUsers() async {
    return List.from(_users);
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      return _users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    _users.add(user);
    return user;
  }

  Future<UserModel> updateUser(UserModel user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
    return user;
  }

  Future<void> deleteUser(String id) async {
    _users.removeWhere((user) => user.id == id);
  }

  // --- OBRAS ---
  Future<List<ObraModel>> getObras() async {
    return List.from(_obras);
  }

  Future<ObraModel?> getObraById(String id) async {
    try {
      return _obras.firstWhere((obra) => obra.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<ObraModel>> getObrasByResponsable(String userId) async {
    return _obras.where((obra) => obra.responsable.id == userId).toList();
  }

  Future<ObraModel> createObra(ObraModel obra) async {
    _obras.add(obra);
    return obra;
  }

  Future<ObraModel> updateObra(ObraModel obra) async {
    final index = _obras.indexWhere((o) => o.id == obra.id);
    if (index != -1) {
      _obras[index] = obra;
    }
    return obra;
  }

  Future<void> deleteObra(String id) async {
    _obras.removeWhere((obra) => obra.id == id);
  }

  // --- TAREAS ---
  Future<List<TareaModel>> getTareas() async {
    return List.from(_tareas);
  }

  Future<TareaModel?> getTareaById(String id) async {
    try {
      return _tareas.firstWhere((tarea) => tarea.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<TareaModel>> getTareasByObra(String obraId) async {
    return _obras
        .where((obra) => obra.id == obraId)
        .expand((obra) => obra.tareas)
        .toList();
  }

  Future<List<TareaModel>> getTareasByUser(String userId) async {
    return _tareas.where((tarea) => tarea.assignedTo?.id == userId).toList();
  }

  Future<TareaModel> createTarea(TareaModel tarea, String obraId) async {
    final obra = await getObraById(obraId);
    if (obra != null) {
      final updatedTareas = [...obra.tareas, tarea];
      final updatedObra = obra.copyWith(tareas: updatedTareas);
      await updateObra(updatedObra);
    }
    _tareas.add(tarea);
    return tarea;
  }

  Future<TareaModel> updateTarea(TareaModel tarea) async {
    final index = _tareas.indexWhere((t) => t.id == tarea.id);
    if (index != -1) {
      _tareas[index] = tarea;
    }
    // Actualizar también en la obra correspondiente
    for (final obra in _obras) {
      final tareaIndex = obra.tareas.indexWhere((t) => t.id == tarea.id);
      if (tareaIndex != -1) {
        final updatedTareas = List<TareaModel>.from(obra.tareas);
        updatedTareas[tareaIndex] = tarea;
        await updateObra(obra.copyWith(tareas: updatedTareas));
        break;
      }
    }
    return tarea;
  }

  Future<void> deleteTarea(String id, String obraId) async {
    _tareas.removeWhere((tarea) => tarea.id == id);
    final obra = await getObraById(obraId);
    if (obra != null) {
      final updatedTareas = obra.tareas.where((t) => t.id != id).toList();
      await updateObra(obra.copyWith(tareas: updatedTareas));
    }
  }

  // Inicializar datos mock
  void initializeMockData() {
    // Usuarios mock
    final admin = UserModel(
      id: 'admin-1',
      type: 'admin',
      name: 'Administrador',
      lastname: '',
      email: 'admin@tierra.com',
      phone: 1234567890,
      city: 'Bogotá',
      dni: 12345678,
    );

    final maestro = UserModel(
      id: 'maestro-1',
      type: 'maestro',
      name: 'Maestro',
      lastname: 'Pérez',
      email: 'maestro@tierra.com',
      phone: 9876543210,
      city: 'Cali',
      dni: 87654321,
    );

    _users.addAll([admin, maestro]);

    // Obras y tareas mock (se pueden agregar más datos de ejemplo aquí)
  }
}

