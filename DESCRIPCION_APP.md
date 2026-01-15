# 📱 TIERRA - Control de Obras
## Descripción Completa de la Aplicación

---

## 🎯 Propósito General
Aplicación móvil Flutter para la gestión y control de obras de construcción. Permite a administradores y maestros (responsables de obra) gestionar proyectos, tareas, usuarios y realizar seguimiento de estados y costos.

---

## 👥 Roles de Usuario

### 1. **Administrador (admin)**
- Acceso completo a todas las funcionalidades
- Puede ver, crear, editar y eliminar obras
- Gestiona usuarios (maestros)
- Ve estadísticas completas en el Dashboard
- Puede editar todos los campos de tareas (incluyendo costo)
- Ve todas las obras sin filtros

### 2. **Maestro (master)**
- Solo ve las obras donde es responsable
- Puede ver y gestionar tareas de sus obras
- Puede cambiar estados de tareas
- Puede agregar evidencias (fotos)
- Acceso limitado: no ve Dashboard, no gestiona usuarios

---

## 🏗️ Arquitectura de la Aplicación

### **Patrón BLoC (Business Logic Component)**
- **AuthBloc**: Gestión de autenticación (login, logout)
- **ObraBloc**: Gestión de obras (cargar, crear, actualizar estados)
- **TareaBloc**: Gestión de tareas (crear, actualizar, cambiar estado)
- **DashboardBloc**: Gestión de datos del dashboard (solo admin)
- **UserBloc**: Gestión de usuarios (solo admin)
- **ThemeBloc**: Gestión de tema (oscuro/claro)

### **Arquitectura en Capas**
- **Core**: Entidades, interfaces, servicios base, excepciones
- **Data**: Implementaciones de datasources, repositorios, mapeo de datos
- **Domain**: Casos de uso (use cases)
- **Presentation**: UI (pantallas, widgets, BLoCs)

---

## 📱 Vistas y Flujos de Usuario

### 🔐 **1. AUTENTICACIÓN**

#### **Login Screen** (`login_screen.dart`)
- **Propósito**: Inicio de sesión de usuarios
- **Campos**: Email y contraseña
- **Funcionalidades**:
  - Validación de formulario
  - Login con credenciales
  - Navegación a registro (si aplica)
  - Manejo de errores (credenciales incorrectas, errores de servidor)
- **Flujo**:
  1. Usuario ingresa email y contraseña
  2. Valida formulario
  3. Envía petición al backend (`POST /auth/login`)
  4. Si es exitoso → Carga usuario y navega a `HomeScreen`
  5. Si falla → Muestra mensaje de error

#### **AuthWrapper** (`auth_wrapper.dart`)
- **Propósito**: Controlador de autenticación
- **Lógica**:
  - Verifica estado de autenticación
  - Si está autenticado → `HomeScreen`
  - Si no está autenticado → `LoginScreen`
  - Al autenticarse, dispara carga inicial de obras

---

### 🏠 **2. PANTALLA PRINCIPAL (Home)**

#### **HomeScreen** (`home_screen.dart`)
- **Propósito**: Contenedor principal con navegación inferior
- **Navegación Inferior (Bottom Navigation Bar)**:
  
  **Para ADMIN:**
  - **Inicio (Dashboard)**: Índice 0
  - **Obras**: Índice 1
  - **Maestros**: Índice 2
  - **Perfil**: Índice 3
  
  **Para MASTER:**
  - **Obras**: Índice 0
  - **Perfil**: Índice 1

- **Funcionalidades**:
  - Usa `IndexedStack` para mantener estado de pantallas
  - Actualiza estados de obras automáticamente al cambiar de pestaña
  - Callback para navegación desde Dashboard a Obras

---

### 📊 **3. DASHBOARD (Solo Admin)**

#### **DashboardScreen** (`dashboard_screen.dart`)
- **Propósito**: Vista principal con estadísticas y resumen financiero
- **Secciones**:

  **A. Estadísticas de Obras (3 tarjetas horizontales):**
  - **Total**: Total de obras
  - **Activas**: Obras en progreso (pendiente + en_proceso)
  - **Finalizadas**: Obras completadas
  
  **B. Estadísticas de Tareas (Layout 2x2):**
  - Fila 1: **Total** | **Pendientes**
  - Fila 2: **En Progreso** | **Completadas**

  **C. Resumen Financiero:**
  - **Presupuesto Proyectado**: Costo total proyectado
  - **Presupuesto Ejecutado**: Costo ejecutado hasta el momento
  - **Varianza Presupuestaria**: Diferencia entre proyectado y ejecutado
  - Indicador de porcentaje de ejecución con colores (verde/naranja/rojo)

  **D. Cronograma de Proyectos:**
  - **A Tiempo**: Obras en plazo
  - **Retrasadas**: Obras con fecha de entrega vencida
  - **Adelantadas**: Obras adelantadas respecto a fecha de entrega

  **E. Obras Recientes:**
  - Lista de últimas obras creadas/actualizadas
  - Navegación a detalle de obra

- **Funcionalidades**:
  - Pull-to-refresh para actualizar datos
  - Tap en tarjetas muestra modales con listas filtradas
  - Botón flotante "Nueva Obra"
  - Actualización automática de estados de obras al entrar

---

### 🏗️ **4. OBRAS**

#### **ObrasListScreen** (`obras_list_screen.dart`)
- **Propósito**: Lista de obras activas (pendientes y en_proceso)
- **Filtros Disponibles**:
  - **Búsqueda por texto**: Nombre, descripción, ubicación, ciudad
  - **Filtro por Estado**: Pendiente, En Proceso, Estancado, Finalizado
  - **Filtro por Ciudad**: Multi-selección de ciudades
- **Ordenamiento**:
  - Por Costo (ascendente/descendente)
  - Por Título (A-Z / Z-A)
  - Por Ciudad (A-Z / Z-A)
  - Por Cantidad de Tareas (ascendente/descendente)
  - Por Antigüedad (más recientes / más antiguas)
- **Funcionalidades**:
  - **Para ADMIN**: Ve todas las obras activas
  - **Para MASTER**: Ve solo obras donde es responsable
  - Botón flotante "Nueva Obra" (solo si `showFAB = true`)
  - Actualización automática de estados al entrar a la pantalla
  - Refresh pull-to-refresh
- **Elementos mostrados por obra**:
  - Título
  - Ubicación y ciudad
  - Estado (badge coloreado)
  - Cantidad de tareas
  - Costo (formateado)
  - Responsable

#### **ObraDetailScreen** (`obra_detail_screen.dart`)
- **Propósito**: Detalle completo de una obra
- **Secciones**:

  **A. Información de la Obra:**
  - **Título**: Nombre de la obra
  - **Descripción**: Detalle del proyecto
  - **Ubicación**: Dirección y ciudad
  - **Costo**: Costo principal de la obra
  - **Responsable**: Persona asignada (maestro)
  - ~~**Costo Estimado**: (Comentado)~~
  - ~~**Costo Final**: (Comentado)~~

  **B. Tareas:**
  - Lista de todas las tareas asociadas a la obra
  - Cada tarea muestra:
    - Nombre y descripción
    - Estado (badge coloreado)
    - Duración (en días)
    - ~~Costo (solo admin)~~ (Comentado)
    - Evidencias (si tiene)
    - Responsable asignado (si tiene)
  - Tap en tarea → Navega a `TareaDetailScreen` o `TareaDetailModal`
  - **Para ADMIN**: Botón "Agregar Tarea" visible

- **Funcionalidades**:
  - Navegación a detalle de tareas
  - Mostrar evidencias en galería
  - Actualización en tiempo real desde BLoC

#### **CreateObraScreen** (`create_obra_screen.dart`)
- **Propósito**: Crear nueva obra
- **Campos del Formulario**:
  - **Título** (requerido)
  - **Descripción**
  - **Ubicación**
  - **Ciudad**
  - **Costo** (requerido)
  - **Costo Estimado** (opcional)
  - **Responsable**: Selector de maestros disponibles
  - **Tareas**: Selector de tareas existentes para asociar
- **Funcionalidades**:
  - Validación de campos requeridos
  - Selector de responsable desde lista de maestros
  - Selector de tareas existentes (con búsqueda)
  - Creación de tareas desde el mismo formulario
  - Guardado y navegación a detalle de obra creada

#### **ObrasFinalizadasScreen** (`obras_finalizadas_screen.dart`)
- **Propósito**: Lista de obras finalizadas
- **Funcionalidades**:
  - Muestra solo obras con estado "finalizado"
  - Paginación infinita (scroll)
  - Filtros y búsqueda similares a `ObrasListScreen`
  - Navegación a detalle de obra

---

###   **5. TAREAS**

#### **TareaDetailScreen** (`tarea_detail_screen.dart`)
- **Propósito**: Vista detallada y edición de tarea (pantalla completa)
- **Secciones**:

  **A. Estado:**
  - Selector de estado (pendiente, en progreso, estancado, finalizado)
  - Para **MASTER**: Auto-actualiza a "finalizado" si agrega evidencias
  - Para **ADMIN**: Control total del estado

  **B. Descripción:**
  - **ADMIN**: Campo editable (TextFormField)
  - **MASTER**: Solo lectura (Card)

  **C. Información:**
  - **Duración (días)**:
    - **ADMIN**: Campo editable
    - **MASTER**: Solo lectura
  - ~~**Costo**: (Comentado)~~

  **D. Evidencias:**
  - Galería de fotos/evidencias
  - **Agregar Evidencias**: Botón para tomar foto o seleccionar de galería
  - Subida a servidor y actualización en tiempo real
  - Vista de galería expandida con zoom

  **E. Observaciones:**
  - Campo de texto para notas/observaciones
  - Botón "Editar" que abre modal
  - Guardado independiente de otros campos

- **Funcionalidades**:
  - Guardado de cambios (solo si hay modificaciones)
  - Validación de permisos (admin vs master)
  - Actualización en tiempo real desde BLoC
  - Permisos de cámara/galería

#### **TareaDetailModal** (`tarea_detail_modal.dart`)
- **Propósito**: Vista detallada de tarea en modal (bottom sheet)
- **Diferencia con Screen**: Mismo contenido pero en formato modal deslizable
- **Uso**: Se abre desde listas de tareas dentro de obras

#### **CreateTareaScreen** (`create_tarea_screen.dart`)
- **Propósito**: Crear nueva tarea (pantalla completa)
- **Campos**:
  - Nombre (requerido)
  - Descripción
  - Duración (días)
  - Estado inicial
- **Uso**: Para crear tareas independientes o desde navegación directa

#### **CreateTareaModal** (`create_tarea_modal.dart`)
- **Propósito**: Crear nueva tarea desde modal
- **Uso**: Se abre desde `CreateObraScreen` o `ObraDetailScreen`

#### **ObservationModal** (`observation_modal.dart`)
- **Propósito**: Modal para editar observaciones de tarea
- **Funcionalidades**:
  - Campo de texto multilínea
  - Guardado independiente
  - Cierre y actualización en tiempo real

---

### 👥 **6. GESTIÓN DE USUARIOS (Solo Admin)**

#### **UsersListScreen** (`users_list_screen.dart`)
- **Propósito**: Lista de maestros (usuarios tipo "master")
- **Funcionalidades**:
  - Paginación infinita (scroll)
  - Botón "Nuevo Maestro" que navega a `RegisterScreen`
  - Información mostrada:
    - Nombre completo
    - Email
    - Teléfono
    - Ciudad
    - DNI
  - Refresh pull-to-refresh
  - Carga más usuarios al hacer scroll

#### **RegisterScreen** (`register_screen.dart`)
- **Propósito**: Registrar nuevo maestro
- **Campos del Formulario**:
  - Nombre (requerido)
  - Apellido (requerido)
  - Email (requerido, validación)
  - Contraseña (requerido, mínimo 6 caracteres)
  - Confirmar Contraseña (debe coincidir)
  - Teléfono (opcional)
  - Ciudad (requerido)
  - DNI (requerido)
- **Funcionalidades**:
  - Validación de formulario
  - Registro de usuario tipo "master"
  - Navegación de vuelta a lista después de registrar

---

### 👤 **7. PERFIL**

#### **ProfileScreen** (`profile_screen.dart`)
- **Propósito**: Perfil del usuario autenticado
- **Información Mostrada**:
  - Avatar (ícono de persona)
  - Nombre completo
  - Rol (Administrador / Maestro)
  - Email
  - Teléfono (si tiene)
  - Ciudad (si tiene)
  - DNI (si tiene)
- **Funcionalidades**:
  - **Toggle de Tema**: Cambiar entre tema oscuro y claro
  - **Cerrar Sesión**: Botón que ejecuta logout y vuelve a LoginScreen
  - Persistencia de preferencia de tema (SharedPreferences)

---

##   FLUJOS PRINCIPALES

### **FLUJO 1: Autenticación y Acceso**
```
App Inicio
  ↓
AuthWrapper (Verifica autenticación)
  ↓
├─→ NO Autenticado → LoginScreen
│     ↓
│     Usuario ingresa credenciales
│     ↓
│     Login exitoso → HomeScreen
│
└─→ SI Autenticado → HomeScreen
```

### **FLUJO 2: Navegación Principal (Admin)**
```
HomeScreen (Bottom Navigation)
  ↓
├─→ Tab 0: DashboardScreen
│     ├─→ Ver estadísticas
│     ├─→ Tap en tarjeta → Modal con lista filtrada
│     ├─→ Tap en obra reciente → ObraDetailScreen
│     └─→ FAB "Nueva Obra" → CreateObraScreen
│
├─→ Tab 1: ObrasListScreen
│     ├─→ Ver obras activas
│     ├─→ Filtros y búsqueda
│     ├─→ Tap en obra → ObraDetailScreen
│     └─→ FAB "Nueva Obra" → CreateObraScreen
│
├─→ Tab 2: UsersListScreen
│     ├─→ Ver lista de maestros
│     └─→ FAB "Nuevo Maestro" → RegisterScreen
│
└─→ Tab 3: ProfileScreen
      ├─→ Ver perfil
      ├─→ Cambiar tema
      └─→ Cerrar sesión
```

### **FLUJO 3: Navegación Principal (Master)**
```
HomeScreen (Bottom Navigation)
  ↓
├─→ Tab 0: ObrasListScreen
│     ├─→ Ver SOLO obras donde es responsable
│     ├─→ Tap en obra → ObraDetailScreen
│     └─→ NO tiene acceso a crear obras
│
└─→ Tab 1: ProfileScreen
      ├─→ Ver perfil
      ├─→ Cambiar tema
      └─→ Cerrar sesión
```

### **FLUJO 4: Gestión de Obra**
```
ObraDetailScreen
  ↓
├─→ Ver información de obra
├─→ Ver lista de tareas
│     ↓
│     Tap en tarea
│     ↓
│     └─→ TareaDetailScreen / TareaDetailModal
│           ├─→ Ver detalles
│           ├─→ Cambiar estado
│           ├─→ Editar descripción (solo admin)
│           ├─→ Editar duración (solo admin)
│           ├─→ Agregar evidencias
│           └─→ Editar observaciones
│
└─→ Botón "Agregar Tarea" (solo admin)
      ↓
      CreateTareaModal
        ↓
        Crear tarea → Regresa a ObraDetailScreen
```

### **FLUJO 5: Creación de Obra (Admin)**
```
CreateObraScreen
  ↓
1. Llenar formulario (título, descripción, ubicación, ciudad, costo)
  ↓
2. Seleccionar Responsable (maestro)
  ↓
3. (Opcional) Seleccionar Tareas Existentes o Crear Nuevas
  ↓
4. Guardar
  ↓
5. Navega a ObraDetailScreen de la obra creada
```

### **FLUJO 6: Actualización de Estados de Obras**
```
Trigger: Entrada a Dashboard o ObrasListScreen
  ↓
POST /master/obra/actualizar-estados
  ↓
Backend actualiza estados de obras basándose en estados de tareas
  ↓
Automaticamente recarga lista de obras
  ↓
UI se actualiza con nuevos estados
```

---

## 🎨 ESTADOS Y COLORES

### **Estados de Obra:**
- **Pendiente**: Naranja (`Colors.orange`)
- **En Proceso / En Progreso**: Azul (`Colors.blue`)
- **Estancado / Estancada**: Ámbar (`Colors.amber`)
- **Finalizado / Finalizada**: Verde (`Colors.green`)

### **Estados de Tarea:**
- **Pendiente**: Naranja (`Colors.orange`)
- **En Progreso**: Azul (`Colors.blue`)
- **Estancado**: Ámbar (`Colors.amber`)
- **Finalizado / Completada**: Verde (`Colors.green`)

### **Colores de la Aplicación:**
- **Primary**: `#D5B189` (beige/dorado)
- **Secondary**: `#9E7A55` (marrón)
- **Dark Background**: `#0E0E0E`
- **Card Dark**: `#1B1B1B`
- **Light Background**: `#F5F5F5`
- **Card Light**: `#FFFFFF`

---

## 🔌 ENDPOINTS PRINCIPALES

### **Autenticación:**
- `POST /auth/login` - Login de usuario
- `POST /auth/register` - Registro de nuevo maestro

### **Obras:**
- `GET /master/obra?estado=activas` - Obtener obras activas (paginated)
- `GET /master/obra?estado=finalizadas` - Obtener obras finalizadas (paginated)
- `GET /master/obra/{obraId}` - Obtener detalle de obra
- `POST /master/obra` - Crear nueva obra
- `POST /master/obra/actualizar-estados` - Actualizar estados de todas las obras
- `GET /master/responsable/{userId}` - Obtener obras de un responsable (master)

### **Tareas:**
- `GET /master/tarea` - Obtener lista de tareas (paginated)
- `GET /master/tarea/{tareaId}` - Obtener detalle de tarea
- `POST /master/obra/{obraId}/tarea` - Crear tarea en obra
- `PUT /master/obra/{obraId}/tarea/{tareaId}` - Actualizar tarea
- `PUT /master/obra/{obraId}/tarea/{tareaId}/estado` - Cambiar estado de tarea
- `DELETE /master/tarea/{tareaId}` - Eliminar tarea

### **Dashboard:**
- `GET /master/dashboard` - Obtener estadísticas y datos del dashboard

### **Usuarios:**
- `GET /master/user` - Obtener lista de maestros (paginated)

---

## 📊 DIAGRAMA DE FLUJO SIMPLIFICADO

```
┌─────────────────┐
│   APP INICIO    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AuthWrapper    │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│ Login  │ │  Home    │
│ Screen │ │  Screen  │
└───┬────┘ └────┬─────┘
    │           │
    │           ├──────────┬──────────┬──────────┐
    │           │          │          │          │
    ▼           ▼          ▼          ▼          ▼
┌─────────┐ ┌──────────┐ ┌───────┐ ┌────────┐ ┌────────┐
│ Usuario │ │Dashboard │ │ Obras │ │Maestros│ │ Perfil │
│ Ingresa │ │ (Admin)  │ │ Lista │ │(Admin) │ │ Screen │
│Credencial│ └────┬─────┘ └───┬───┘ └───┬────┘ └───┬────┘
└─────────┘      │            │         │          │
                 │            │         │          │
                 ▼            ▼         ▼          ▼
          ┌───────────┐ ┌────────┐ ┌──────┐ ┌─────────┐
          │ Estadísticas│ │ Obra  │ │ Nuevo│ │ Logout  │
          │ Financiero  │ │Detail │ │Maestro│ │         │
          │ Cronograma  │ └───┬───┘ └───┬──┘ └─────────┘
          └─────────────┘     │         │
                              │         ▼
                              │    ┌──────────┐
                              │    │Register  │
                              │    │ Screen   │
                              │    └──────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  TareaDetail     │
                    │  Screen/Modal    │
                    └─────────┬────────┘
                              │
                              ├──► Cambiar Estado
                              ├──► Agregar Evidencias
                              ├──► Editar Observaciones
                              └──► Editar Info (Admin)
```

---

## 🔑 FUNCIONALIDADES CLAVE

### **Filtrado y Búsqueda:**
- Búsqueda por texto libre en obras y tareas
- Filtros por estado (multi-selección)
- Filtros por ciudad (multi-selección)
- Ordenamiento múltiple

### **Paginación:**
- Paginación infinita con scroll
- Carga automática de más elementos

### **Actualización en Tiempo Real:**
- Actualización automática de estados de obras
- Sincronización de datos mediante BLoC
- Refresh pull-to-refresh

### **Permisos y Roles:**
- Vista diferenciada según rol (admin vs master)
- Filtrado automático de datos según permisos
- Acciones condicionales según rol

### **Gestión de Evidencias:**
- Subida de fotos desde cámara o galería
- Permisos de cámara y almacenamiento
- Galería con zoom y navegación

### **Temas:**
- Soporte para tema oscuro y claro
- Persistencia de preferencia
- Colores consistentes en toda la app

---

## 📝 NOTAS IMPORTANTES

1. **Campo de Costo en Tareas**: Actualmente COMENTADO en la UI, pero la entidad y mapeo siguen funcionando.

2. **Costo Estimado y Costo Final**: Actualmente COMENTADOS en la vista de detalle de obra.

3. **Estados Estancados**: Estado implementado pero las tarjetas están comentadas en Dashboard.

4. **Actualización Automática**: Los estados de obras se actualizan automáticamente al entrar a Dashboard o Lista de Obras (con throttling de 5 segundos).

5. **Filtrado por Rol**: Los maestros solo ven obras donde son responsables. Los admins ven todas las obras.

---

## 🚀 MEJORAS Y CARACTERÍSTICAS FUTURAS

- Notificaciones push
- Sincronización offline
- Exportación de reportes
- Dashboard más detallado
- Filtros avanzados
- Búsqueda global
