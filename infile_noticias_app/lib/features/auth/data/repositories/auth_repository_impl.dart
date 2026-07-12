import 'package:dio/dio.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/storage/secure_storage_service.dart';

/// Excepción de autenticación con mensaje legible para el usuario.
final class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Implementación concreta del [AuthRepository].
///
/// Conecta el datasource remoto con el Secure Storage:
/// - Tras un login/register exitoso, persiste los tokens.
/// - En logout, limpia el Secure Storage y notifica al servidor.
/// - Convierte errores Dio en excepciones tipadas para la UI.
final class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService storage,
  })  : _remoteDataSource = remoteDataSource,
        _storage = storage;

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      final tokens = model.toEntity();

      // Persistir en Secure Storage inmediatamente tras el login.
      await _storage.saveSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessTokenExpiry: tokens.accessTokenExpiresAt,
      );

      return tokens;
    } on DioException catch (e) {
      throw AuthException(_parseDioError(e));
    }
  }

  @override
  Future<AuthTokens> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final model = await _remoteDataSource.register(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      final tokens = model.toEntity();

      await _storage.saveSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessTokenExpiry: tokens.accessTokenExpiresAt,
      );

      return tokens;
    } on DioException catch (e) {
      throw AuthException(_parseDioError(e));
    }
  }

  @override
  Future<void> logout() async {
    // 1. Revocar en servidor (puede fallar, no es crítico).
    await _remoteDataSource.logout();
    // 2. Limpiar Secure Storage — garantizado independientemente del servidor.
    await _storage.clearSession();
  }

  // ── Mapeo de errores Dio a mensajes legibles ───────────────────────────────
  String _parseDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    // Si el backend devuelve un mensaje estructurado, usarlo.
    if (responseData is Map<String, dynamic> && responseData['message'] != null) {
      return responseData['message'] as String;
    }

    return switch (statusCode) {
      400 => 'Datos inválidos. Verifica la información ingresada.',
      401 => 'Credenciales incorrectas.',
      409 => 'El correo electrónico ya está registrado.',
      429 => 'Demasiados intentos. Por favor espera un momento.',
      500 => 'Error del servidor. Por favor intenta más tarde.',
      _ => e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout
          ? 'Tiempo de espera agotado. Verifica tu conexión.'
          : 'Error de conexión. Verifica tu red.',
    };
  }
}
