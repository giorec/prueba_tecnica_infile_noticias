import 'package:equatable/equatable.dart';

/// Estados del flujo de autenticación.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de verificar la sesión.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Verificando si hay una sesión activa (al abrir la app).
final class AuthCheckingSession extends AuthState {
  const AuthCheckingSession();
}

/// Procesando login o registro (request HTTP en curso).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Autenticación exitosa — tokens guardados en Secure Storage.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();

  @override
  List<Object?> get props => [];
}

/// Sin sesión activa — debe ir a /login.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error de autenticación con mensaje para mostrar al usuario.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
