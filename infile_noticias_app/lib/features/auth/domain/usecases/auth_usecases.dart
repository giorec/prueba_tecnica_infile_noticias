import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: Iniciar sesión.
///
/// Encapsula la regla de negocio de autenticación.
/// La UI invoca este usecase sin conocer la implementación del repositorio.
final class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  /// Ejecuta el login con las credenciales proporcionadas.
  ///
  /// Lanza [ArgumentException] si el email o contraseña están vacíos.
  /// Lanza [AuthException] si las credenciales son incorrectas.
  Future<AuthTokens> call({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) {
      throw ArgumentError('Email y contraseña son requeridos.');
    }
    return _repository.login(email: email.trim(), password: password);
  }
}

/// Caso de uso: Registrar nuevo usuario.
final class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<AuthTokens> call({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _repository.register(
      fullName: fullName.trim(),
      email: email.trim(),
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}

/// Caso de uso: Cerrar sesión.
final class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}
