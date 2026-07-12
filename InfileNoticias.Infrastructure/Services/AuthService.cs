using InfileNoticias.Core.DTOs.Auth;
using InfileNoticias.Core.Entities;
using InfileNoticias.Core.Interfaces;
using InfileNoticias.Infrastructure.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace InfileNoticias.Infrastructure.Services;

/// <summary>
/// Implementación del servicio de autenticación.
/// Maneja el ciclo de vida completo de las sesiones:
/// registro, inicio de sesión, rotación de tokens y cierre de sesión.
/// </summary>
public sealed class AuthService : IAuthService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ITokenService               _tokenService;
    private readonly AppDbContext                _context;
    private readonly ILogger<AuthService>        _logger;

    public AuthService(
        UserManager<ApplicationUser> userManager,
        ITokenService                tokenService,
        AppDbContext                 context,
        ILogger<AuthService>         logger)
    {
        _userManager  = userManager;
        _tokenService = tokenService;
        _context      = context;
        _logger       = logger;
    }

    /// <inheritdoc/>
    public async Task<ApplicationUser> RegisterAsync(RegisterDto dto, CancellationToken cancellationToken = default)
    {
        // ── Validación de datos de entrada ────────────────────────────────────
        if (dto.Password != dto.ConfirmPassword)
            throw new ArgumentException("Las contraseñas no coinciden.");

        // Verificar que el email no esté ya registrado.
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);
        if (existingUser is not null)
            throw new InvalidOperationException($"El email '{dto.Email}' ya está registrado.");

        // ── Crear el usuario ─────────────────────────────────────────────────
        var user = new ApplicationUser
        {
            UserName  = dto.Email,
            Email     = dto.Email,
            FullName  = dto.FullName,
            IsActive  = true
        };

        // UserManager llama internamente al IPasswordHasher (Argon2id) configurado.
        var result = await _userManager.CreateAsync(user, dto.Password);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            _logger.LogWarning("Fallo al registrar usuario {Email}: {Errors}", dto.Email, errors);
            throw new InvalidOperationException($"Error al crear usuario: {errors}");
        }

        _logger.LogInformation("Usuario registrado exitosamente: {Email}", dto.Email);
        return user;
    }

    /// <inheritdoc/>
    public async Task<(TokenResponseDto TokenResponse, string RefreshToken)?> LoginAsync(
        LoginDto dto, string ipAddress, CancellationToken cancellationToken = default)
    {
        // ── Buscar usuario por email ──────────────────────────────────────────
        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user is null || !user.IsActive)
        {
            // Se retorna null en lugar de excepción para no filtrar información
            // sobre si el email existe (mitigación de enumeración de usuarios).
            _logger.LogWarning("Intento de login con credenciales inválidas para: {Email}", dto.Email);
            return null;
        }

        // ── Verificar contraseña con Argon2id ─────────────────────────────────
        var isPasswordValid = await _userManager.CheckPasswordAsync(user, dto.Password);
        if (!isPasswordValid)
        {
            _logger.LogWarning("Contraseña incorrecta para el usuario: {Email}", dto.Email);
            // Registrar el intento fallido para lockout.
            await _userManager.AccessFailedAsync(user);
            return null;
        }

        // Reiniciar contador de intentos fallidos tras login exitoso.
        await _userManager.ResetAccessFailedCountAsync(user);

        return await GenerateTokenPairAsync(user, ipAddress, cancellationToken);
    }

    /// <inheritdoc/>
    public async Task<(TokenResponseDto TokenResponse, string RefreshToken)?> RefreshTokenAsync(
        string refreshToken, string ipAddress, CancellationToken cancellationToken = default)
    {
        // ── Buscar el Refresh Token en la base de datos ───────────────────────
        var storedToken = await _context.RefreshTokens
            .Include(rt => rt.User)
            .SingleOrDefaultAsync(rt => rt.Token == refreshToken, cancellationToken);

        if (storedToken is null)
        {
            _logger.LogWarning("Intento de refresh con token desconocido desde IP: {Ip}", ipAddress);
            return null;
        }

        // ── Detección de reutilización (Refresh Token Rotation Attack) ────────
        // Si el token ya fue revocado y se intenta usar de nuevo, es una señal
        // de que fue robado. Se revocan TODOS los tokens del usuario (familia).
        if (storedToken.IsRevoked)
        {
            _logger.LogCritical(
                "⚠ ALERTA DE SEGURIDAD: Reutilización de refresh token detectada para usuario {UserId}. Revocando toda la familia de tokens.",
                storedToken.UserId);
            await RevokeDescendantRefreshTokensAsync(storedToken, storedToken.User, ipAddress,
                "Reutilización de token revocado detectada.", cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return null;
        }

        // ── Verificar vigencia del token ──────────────────────────────────────
        if (!storedToken.IsActive)
        {
            _logger.LogWarning("Intento de refresh con token expirado para usuario {UserId}", storedToken.UserId);
            return null;
        }

        // ── Revocar el token actual y generar uno nuevo (rotación) ────────────
        var newRefreshToken = _tokenService.GenerateRefreshToken(ipAddress);
        newRefreshToken.UserId = storedToken.UserId;

        // Marcar el token antiguo como revocado con referencia al nuevo.
        storedToken.RevokedAtUtc    = DateTime.UtcNow;
        storedToken.RevokedByIp     = ipAddress;
        storedToken.ReplacedByToken = newRefreshToken.Token;
        storedToken.RevokedReason   = "Rotación normal";

        await _context.RefreshTokens.AddAsync(newRefreshToken, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);

        var (accessToken, accessExpiresAt) = _tokenService.GenerateAccessToken(storedToken.User);
        return (new TokenResponseDto(accessToken, accessExpiresAt), newRefreshToken.Token);
    }

    /// <inheritdoc/>
    public async Task RevokeTokenAsync(string refreshToken, string ipAddress, CancellationToken cancellationToken = default)
    {
        var storedToken = await _context.RefreshTokens
            .Include(rt => rt.User)
            .SingleOrDefaultAsync(rt => rt.Token == refreshToken, cancellationToken);

        if (storedToken is null || !storedToken.IsActive)
            throw new ArgumentException("Refresh token inválido o ya revocado.");

        storedToken.RevokedAtUtc  = DateTime.UtcNow;
        storedToken.RevokedByIp   = ipAddress;
        storedToken.RevokedReason = "Cierre de sesión por el usuario";

        await _context.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Refresh token revocado para usuario {UserId}", storedToken.UserId);
    }

    // ── Métodos privados ──────────────────────────────────────────────────────

    /// <summary>
    /// Genera un nuevo par de tokens (Access + Refresh) para el usuario dado.
    /// Persiste el nuevo Refresh Token en la base de datos.
    /// </summary>
    private async Task<(TokenResponseDto TokenResponse, string RefreshToken)> GenerateTokenPairAsync(
        ApplicationUser user, string ipAddress, CancellationToken cancellationToken)
    {
        var (accessToken, accessExpiresAt) = _tokenService.GenerateAccessToken(user);
        var refreshToken                   = _tokenService.GenerateRefreshToken(ipAddress);
        refreshToken.UserId                = user.Id;

        await _context.RefreshTokens.AddAsync(refreshToken, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);

        return (new TokenResponseDto(accessToken, accessExpiresAt), refreshToken.Token);
    }

    /// <summary>
    /// Revoca recursivamente todos los tokens descendientes de una familia de refresh tokens.
    /// Se invoca cuando se detecta reutilización de un token previamente revocado.
    /// </summary>
    private async Task RevokeDescendantRefreshTokensAsync(
        RefreshToken refreshToken,
        ApplicationUser user,
        string ipAddress,
        string reason,
        CancellationToken cancellationToken)
    {
        // Recorrer la cadena de tokens hasta encontrar la hoja activa.
        if (!string.IsNullOrEmpty(refreshToken.ReplacedByToken))
        {
            var childToken = await _context.RefreshTokens
                .SingleOrDefaultAsync(rt => rt.Token == refreshToken.ReplacedByToken, cancellationToken);

            if (childToken is not null)
            {
                if (childToken.IsActive)
                {
                    childToken.RevokedAtUtc  = DateTime.UtcNow;
                    childToken.RevokedByIp   = ipAddress;
                    childToken.RevokedReason = reason;
                }
                else
                {
                    await RevokeDescendantRefreshTokensAsync(childToken, user, ipAddress, reason, cancellationToken);
                }
            }
        }
    }
}
