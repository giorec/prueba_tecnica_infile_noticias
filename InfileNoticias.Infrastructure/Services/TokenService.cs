using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using InfileNoticias.Core.Entities;
using InfileNoticias.Core.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace InfileNoticias.Infrastructure.Services;

/// <summary>
/// Implementación del servicio de generación y validación de tokens.
/// Genera Access Tokens JWT firmados con HMAC-SHA256 y Refresh Tokens
/// criptográficamente aleatorios (256 bits).
/// </summary>
public sealed class TokenService : ITokenService
{
    private readonly IConfiguration _config;

    /// <summary>
    /// Constructor que inyecta la configuración para leer los parámetros JWT
    /// desde variables de entorno o appsettings (nunca hardcodeados).
    /// </summary>
    public TokenService(IConfiguration config)
    {
        _config = config;
    }

    /// <inheritdoc/>
    public (string Token, DateTime ExpiresAtUtc) GenerateAccessToken(ApplicationUser user)
    {
        // ── Leer configuración JWT desde environment/appsettings ─────────────
        var jwtSecret      = _config["Jwt:Secret"]
            ?? throw new InvalidOperationException("JWT secret no configurado. Usar variable de entorno Jwt__Secret.");
        var issuer         = _config["Jwt:Issuer"]     ?? "InfileNoticiasAPI";
        var audience       = _config["Jwt:Audience"]   ?? "InfileNoticiasClient";
        var expiryMinutes  = int.Parse(_config["Jwt:AccessTokenExpiryMinutes"] ?? "15");

        var key       = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret));
        var creds     = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes);

        // ── Claims del Access Token ──────────────────────────────────────────
        // Se incluye solo la información necesaria (principio de mínimo privilegio).
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub,   user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new Claim(JwtRegisteredClaimNames.Jti,   Guid.NewGuid().ToString()), // ID único del token
            new Claim("fullName", user.FullName),
        };

        var token = new JwtSecurityToken(
            issuer:             issuer,
            audience:           audience,
            claims:             claims,
            expires:            expiresAt,
            signingCredentials: creds
        );

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }

    /// <inheritdoc/>
    public RefreshToken GenerateRefreshToken(string ipAddress)
    {
        // Genera 64 bytes aleatorios de alta entropía (512 bits).
        var randomBytes = RandomNumberGenerator.GetBytes(64);
        var refreshToken = new RefreshToken
        {
            Token         = Convert.ToBase64String(randomBytes),
            ExpiresAtUtc  = DateTime.UtcNow.AddDays(
                int.Parse(_config["Jwt:RefreshTokenExpiryDays"] ?? "7")),
            CreatedAtUtc  = DateTime.UtcNow,
            CreatedByIp   = ipAddress
        };
        return refreshToken;
    }

    /// <inheritdoc/>
    public ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
    {
        var jwtSecret = _config["Jwt:Secret"]
            ?? throw new InvalidOperationException("JWT secret no configurado.");

        // Al validar un token expirado para el flujo de refresh, se desactiva
        // la validación del tiempo de expiración (solo se verifica la firma).
        var tokenValidationParams = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ValidateIssuer           = true,
            ValidIssuer              = _config["Jwt:Issuer"] ?? "InfileNoticiasAPI",
            ValidateAudience         = true,
            ValidAudience            = _config["Jwt:Audience"] ?? "InfileNoticiasClient",
            ValidateLifetime         = false, // ← Se permite el token expirado para renovación
            ClockSkew                = TimeSpan.Zero
        };

        try
        {
            var handler    = new JwtSecurityTokenHandler();
            var principal  = handler.ValidateToken(token, tokenValidationParams, out var validatedToken);

            // Verificación adicional: el algoritmo del token debe coincidir.
            if (validatedToken is not JwtSecurityToken jwtToken ||
                !jwtToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.OrdinalIgnoreCase))
            {
                return null;
            }

            return principal;
        }
        catch
        {
            // Cualquier excepción de validación se trata como token inválido.
            return null;
        }
    }
}
