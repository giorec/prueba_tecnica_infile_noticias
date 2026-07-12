using InfileNoticias.Core.DTOs.Auth;
using InfileNoticias.Core.Entities;

namespace InfileNoticias.Core.Interfaces;

/// <summary>
/// Contrato principal del servicio de autenticación.
/// Define las operaciones de registro, login, renovación y cierre de sesión.
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// Registra un nuevo usuario en el sistema.
    /// </summary>
    /// <param name="dto">Datos del nuevo usuario (nombre, email, contraseña).</param>
    /// <param name="cancellationToken">Token de cancelación.</param>
    /// <returns>El usuario creado o lanza una excepción si falla la validación.</returns>
    Task<ApplicationUser> RegisterAsync(RegisterDto dto, CancellationToken cancellationToken = default);

    /// <summary>
    /// Autentica un usuario con email y contraseña.
    /// </summary>
    /// <param name="dto">Credenciales del usuario.</param>
    /// <param name="ipAddress">Dirección IP de la solicitud (para auditoría del token).</param>
    /// <param name="cancellationToken">Token de cancelación.</param>
    /// <returns>Par de tokens (Access Token + Refresh Token) o null si las credenciales son inválidas.</returns>
    Task<(TokenResponseDto TokenResponse, string RefreshToken)?> LoginAsync(
        LoginDto dto, string ipAddress, CancellationToken cancellationToken = default);

    /// <summary>
    /// Rota el Refresh Token: invalida el actual y genera un nuevo par de tokens.
    /// Si el token fue reutilizado (ya estaba revocado), revoca toda la familia de tokens.
    /// </summary>
    /// <param name="refreshToken">El Refresh Token actual del cliente.</param>
    /// <param name="ipAddress">Dirección IP de la solicitud.</param>
    /// <param name="cancellationToken">Token de cancelación.</param>
    /// <returns>Nuevo par de tokens o null si el token es inválido/expirado.</returns>
    Task<(TokenResponseDto TokenResponse, string RefreshToken)?> RefreshTokenAsync(
        string refreshToken, string ipAddress, CancellationToken cancellationToken = default);

    /// <summary>
    /// Revoca el Refresh Token del usuario (cierre de sesión).
    /// </summary>
    /// <param name="refreshToken">El Refresh Token a revocar.</param>
    /// <param name="ipAddress">Dirección IP de la solicitud.</param>
    /// <param name="cancellationToken">Token de cancelación.</param>
    Task RevokeTokenAsync(string refreshToken, string ipAddress, CancellationToken cancellationToken = default);
}
