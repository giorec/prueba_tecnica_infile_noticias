using InfileNoticias.Core.DTOs.Auth;
using InfileNoticias.Core.Entities;

namespace InfileNoticias.Core.Interfaces;

/// <summary>
/// Contrato del servicio de generación y validación de tokens JWT y Refresh Tokens.
/// Separa la responsabilidad criptográfica del servicio de autenticación principal.
/// </summary>
public interface ITokenService
{
    /// <summary>
    /// Genera un Access Token JWT firmado con las claims del usuario.
    /// </summary>
    /// <param name="user">Usuario para el que se genera el token.</param>
    /// <returns>Tupla con el JWT en string y su fecha de expiración en UTC.</returns>
    (string Token, DateTime ExpiresAtUtc) GenerateAccessToken(ApplicationUser user);

    /// <summary>
    /// Genera un Refresh Token criptográficamente seguro (256 bits aleatorios en Base64).
    /// </summary>
    /// <param name="ipAddress">IP desde donde se solicita el token (auditoría).</param>
    /// <returns>Entidad RefreshToken lista para persistir en base de datos.</returns>
    RefreshToken GenerateRefreshToken(string ipAddress);

    /// <summary>
    /// Valida un Access Token JWT expirado y extrae las claims (para flujos de refresh).
    /// </summary>
    /// <param name="token">El JWT a validar (puede estar expirado).</param>
    /// <returns>
    /// Las claims del token si la firma es válida, aunque el token esté expirado.
    /// Retorna null si el token es inválido o la firma no corresponde.
    /// </returns>
    System.Security.Claims.ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
}
