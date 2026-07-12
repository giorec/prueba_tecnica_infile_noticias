import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/security/biometric_service.dart';
import 'auth_state.dart';

/// Cubit que maneja el estado de autenticación de la aplicación.
///
/// Es el único punto de entrada de la UI para operaciones de auth.
/// Gestiona: verificación de sesión al inicio, login, registro y logout.
final class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final SecureStorageService _storage;
  final BiometricService _biometricService;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required SecureStorageService storage,
    required BiometricService biometricService,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _storage = storage,
        _biometricService = biometricService,
        super(const AuthInitial());

  /// Verifica al iniciar la app si existe una sesión válida en Secure Storage.
  ///
  /// GoRouter escucha este estado para decidir si redirigir a /login o /home.
  Future<void> checkSession() async {
    emit(const AuthCheckingSession());

    final hasSession = await _storage.hasValidSession();
    final hasRefresh = await _storage.hasRefreshToken();

    if (hasSession || hasRefresh) {
      // Requerir biometría antes de permitir el acceso al Feed.
      final isAuthenticated = await _biometricService.authenticate(
        reason: 'Verifique su identidad para acceder a su Feed seguro',
      );

      if (isAuthenticated) {
        emit(const AuthAuthenticated());
      } else {
        // Si cancela la biometría o falla repetidamente, cerramos sesión por seguridad.
        await logout();
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Inicia sesión con email y contraseña.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      await _loginUseCase(email: email, password: password);
      emit(const AuthAuthenticated());
    } on ArgumentError catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('AuthException: ', '')));
    }
  }

  /// Registra un nuevo usuario.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    emit(const AuthLoading());
    try {
      await _registerUseCase(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('AuthException: ', '')));
    }
  }

  /// Cierra la sesión del usuario: revoca tokens en servidor y limpia storage.
  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _logoutUseCase();
    } catch (_) {
      // Ignorar errores de logout — la sesión local se limpia de todas formas.
    }
    emit(const AuthUnauthenticated());
  }
}
