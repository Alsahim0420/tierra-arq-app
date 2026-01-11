import 'package:get_it/get_it.dart';
import '../../core/datasources/user_datasource.dart';
import '../../core/datasources/obra_datasource.dart';
import '../../core/datasources/tarea_datasource.dart';
import '../../data/datasources/user_datasource_impl.dart';
import '../../data/datasources/obra_datasource_impl.dart';
import '../../data/datasources/tarea_datasource_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/obra_repository_impl.dart';
import '../../data/repositories/tarea_repository_impl.dart';
import '../../core/repositories/user_repository.dart';
import '../../core/repositories/obra_repository.dart';
import '../../core/repositories/tarea_repository.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/services/http_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/obra_usecases.dart';
import '../../domain/usecases/tarea_usecases.dart';
import '../../domain/usecases/user/get_user_usecase.dart';
import '../../domain/usecases/user/get_all_users_usecase.dart';
import '../../domain/usecases/user/get_master_users_usecase.dart';
import '../../domain/usecases/user/create_user_usecase.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/obra/obra_bloc.dart';
import '../../presentation/bloc/tarea/tarea_bloc.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';
import '../../presentation/bloc/user/user_bloc.dart';

final getIt = GetIt.instance;

/// Configuración de inyección de dependencias usando GetIt
Future<void> configureDependencies() async {
  // --- SERVICES ---
  final tokenStorage = TokenStorageService();
  await tokenStorage.init(); // Inicializar Hive

  getIt.registerLazySingleton<TokenStorageService>(() => tokenStorage);
  getIt.registerLazySingleton<HttpService>(
    () => HttpService(tokenStorage: getIt<TokenStorageService>()),
  );
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<CloudinaryService>(
    () => CloudinaryService(
      cloudName: 'dxywuapq7',
      apiKey: '836177411616825',
      apiSecret: 'ZoUJBhDwEA8AJ5tOsi2lBi-B-KY',
    ),
  );

  // --- DATASOURCES ---
  getIt.registerLazySingleton<UserDataSource>(
    () => UserDataSourceImpl(
      httpService: getIt<HttpService>(),
      tokenStorage: getIt<TokenStorageService>(),
    ),
  );
  getIt.registerLazySingleton<ObraDataSource>(
    () => ObraDataSourceImpl(
      httpService: getIt<HttpService>(),
      tokenStorage: getIt<TokenStorageService>(),
    ),
  );
  getIt.registerLazySingleton<TareaDataSource>(
    () => TareaDataSourceImpl(
      httpService: getIt<HttpService>(),
    ),
  );

  // --- REPOSITORIES ---
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt<UserDataSource>()),
  );
  getIt.registerLazySingleton<ObraRepository>(
    () => ObraRepositoryImpl(getIt<ObraDataSource>()),
  );
  getIt.registerLazySingleton<TareaRepository>(
    () => TareaRepositoryImpl(getIt<TareaDataSource>()),
  );

  // --- USE CASES ---
  // Auth
  getIt.registerLazySingleton(() => LoginUseCase(getIt<UserRepository>()));
  getIt.registerLazySingleton(
    () => LogoutUseCase(getIt<TokenStorageService>()),
  );
  getIt.registerLazySingleton(
    () => GetCurrentUserUseCase(
      getIt<TokenStorageService>(),
      getIt<UserRepository>(),
    ),
  );
  getIt.registerLazySingleton<GetUserUseCase>(
    () => GetUserUseCase(getIt<UserRepository>()),
  );
  getIt.registerLazySingleton<GetAllUsersUseCase>(
    () => GetAllUsersUseCase(getIt<UserRepository>()),
  );
  getIt.registerLazySingleton<GetMasterUsersUseCase>(
    () => GetMasterUsersUseCase(getIt<UserRepository>()),
  );
  getIt.registerLazySingleton<CreateUserUseCase>(
    () => CreateUserUseCase(getIt<UserRepository>()),
  );

  // Obra
  getIt.registerLazySingleton(() => GetObrasUseCase(getIt<ObraRepository>()));
  getIt.registerLazySingleton(
    () => GetObrasFinalizadasUseCase(getIt<ObraRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetObrasByResponsableUseCase(getIt<ObraRepository>()),
  );
  getIt.registerLazySingleton(() => CreateObraUseCase(getIt<ObraRepository>()));
  getIt.registerLazySingleton(() => UpdateObraUseCase(getIt<ObraRepository>()));
  getIt.registerLazySingleton(() => DeleteObraUseCase(getIt<ObraRepository>()));

  // Tarea
  getIt.registerLazySingleton(() => GetTareasUseCase(getIt<TareaRepository>()));
  getIt.registerLazySingleton(
    () => GetTareaByIdUseCase(getIt<TareaRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetObraTareaByIdUseCase(getIt<TareaRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetTareasByObraUseCase(getIt<TareaRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetTareasByUserUseCase(getIt<TareaRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateTareaUseCase(getIt<TareaRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateTareaUseCase(getIt<TareaRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateTareaStateUseCase(getIt<TareaRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateTareaEvidencesUseCase(getIt<TareaRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteTareaUseCase(getIt<TareaRepository>()),
  );

  // --- BLoCs ---
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => ObraBloc(
      getObrasUseCase: getIt<GetObrasUseCase>(),
      getObrasFinalizadasUseCase: getIt<GetObrasFinalizadasUseCase>(),
      getObrasByResponsableUseCase: getIt<GetObrasByResponsableUseCase>(),
      createObraUseCase: getIt<CreateObraUseCase>(),
      updateObraUseCase: getIt<UpdateObraUseCase>(),
      deleteObraUseCase: getIt<DeleteObraUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => TareaBloc(
      getTareasUseCase: getIt<GetTareasUseCase>(),
      getTareaByIdUseCase: getIt<GetTareaByIdUseCase>(),
      getObraTareaByIdUseCase: getIt<GetObraTareaByIdUseCase>(),
      getTareasByObraUseCase: getIt<GetTareasByObraUseCase>(),
      getTareasByUserUseCase: getIt<GetTareasByUserUseCase>(),
      createTareaUseCase: getIt<CreateTareaUseCase>(),
      updateTareaUseCase: getIt<UpdateTareaUseCase>(),
      updateTareaStateUseCase: getIt<UpdateTareaStateUseCase>(),
      updateTareaEvidencesUseCase: getIt<UpdateTareaEvidencesUseCase>(),
      deleteTareaUseCase: getIt<DeleteTareaUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => ThemeBloc(getIt<ThemeService>()),
  );
  getIt.registerFactory<UserBloc>(
    () => UserBloc(
      getIt<GetUserUseCase>(),
      getIt<GetAllUsersUseCase>(),
      getIt<CreateUserUseCase>(),
    ),
  );
}
