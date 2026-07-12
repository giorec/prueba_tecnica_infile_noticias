import 'package:get_it/get_it.dart';
import 'core/network/dio_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'core/security/biometric_service.dart';
import 'features/feed/data/repositories/feed_repository_impl.dart';
import 'features/feed/domain/repositories/feed_repository.dart';
import 'features/feed/domain/usecases/feed_usecases.dart';
import 'features/feed/presentation/bloc/feed_cubit.dart';

/// Localizador de servicios global (Service Locator / DI Container).
final GetIt sl = GetIt.instance;

/// Inicializa todas las dependencias de la aplicación.
///
/// Orden de inicialización (dependencias primero):
/// 1. Servicios de infraestructura (Storage, Network)
/// 2. DataSources
/// 3. Repositories
/// 4. Use Cases
/// 5. BLoC / Cubits
Future<void> initializeDependencies() async {
  // ── 1. Infraestructura ──────────────────────────────────────────────────────

  // SecureStorage — Singleton (una sola instancia para toda la app)
  sl.registerSingleton<SecureStorageService>(SecureStorageService.instance);

  // Inicializar cliente Dio con el SecureStorage (para el interceptor de auth)
  DioClient.instance.initialize(sl<SecureStorageService>());

  // Biometric Service
  sl.registerSingleton<BiometricService>(BiometricService());

  // ── 2. DataSources ──────────────────────────────────────────────────────────

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(DioClient.instance.client),
  );
  sl.registerLazySingleton<FeedRepositoryImpl>(
    () => FeedRepositoryImpl(DioClient.instance),
  );

  // ── 3. Repositories ──────────────────────────────────────────────────────────

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      storage: sl<SecureStorageService>(),
    ),
  );
  sl.registerLazySingleton<FeedRepository>(
    () => sl<FeedRepositoryImpl>(),
  );

  // ── 4. Use Cases ──────────────────────────────────────────────────────────────

  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  
  sl.registerLazySingleton(() => GetFeedUseCase(sl<FeedRepository>()));
  sl.registerLazySingleton(() => SubmitVoteUseCase(sl<FeedRepository>()));

  // ── 5. Cubits (Factory: nueva instancia por cada uso) ─────────────────────────

  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      storage: sl<SecureStorageService>(),
      biometricService: sl<BiometricService>(),
    ),
  );

  sl.registerFactory(
    () => FeedCubit(sl<GetFeedUseCase>(), sl<SubmitVoteUseCase>()),
  );
}
