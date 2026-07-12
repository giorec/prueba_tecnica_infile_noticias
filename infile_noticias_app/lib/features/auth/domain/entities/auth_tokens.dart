import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa los tokens de autenticación.
///
/// Esta entidad es agnóstica de la capa de datos — no depende de JSON ni de Dio.
/// Es el contrato que define la capa de dominio y que la UI consume.
final class AuthTokens extends Equatable {
  /// Access Token JWT de corta duración (15 min).
  final String accessToken;

  /// Refresh Token de larga duración (7 días).
  /// Se almacena en Secure Storage, nunca en memoria por más tiempo del necesario.
  final String refreshToken;

  /// Fecha y hora de expiración del Access Token (UTC).
  final DateTime accessTokenExpiresAt;

  /// Tipo de token (siempre "Bearer").
  final String tokenType;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    this.tokenType = 'Bearer',
  });

  /// Verifica si el Access Token ya expiró (con 1 min de margen).
  bool get isAccessTokenExpired =>
      DateTime.now().isAfter(accessTokenExpiresAt.subtract(const Duration(minutes: 1)));

  @override
  List<Object?> get props => [accessToken, refreshToken, accessTokenExpiresAt];
}
