import '../entities/auth_tokens.dart';

/// Contrato del repositorio de autenticación (capa de dominio).
///
/// Define las operaciones disponibles sin exponer detalles de implementación
/// (HTTP, base de datos, etc.). La UI solo interactúa con esta interfaz.
abstract interface class AuthRepository {
  /// Autentica al usuario con email y contraseña.
  ///
  /// Retorna [AuthTokens] en éxito, o lanza una excepción tipada en caso de error.
  Future<AuthTokens> login({
    required String email,
    required String password,
  });

  /// Registra un nuevo usuario con los datos proporcionados.
  ///
  /// Retorna [AuthTokens] en éxito (auto-login tras registro).
  Future<AuthTokens> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  });

  /// Cierra la sesión del usuario.
  ///
  /// Revoca el Refresh Token en el servidor y limpia el Secure Storage.
  Future<void> logout();
}
