using InfileNoticias.Core.DTOs.Auth;
using InfileNoticias.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace InfileNoticias.API.Controllers;

/// <summary>
/// Controlador de autenticación e identidad.
/// Expone los endpoints para registro, login, renovación y cierre de sesión.
/// Todos los endpoints de autenticación están limitados por rate limiting
/// para prevenir ataques de fuerza bruta.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[EnableRateLimiting("AuthPolicy")] // Aplica rate limiting a todos los endpoints del controlador.
public class AuthController : ControllerBase
{
    private readonly IAuthService     _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger      = logger;
    }

    /// <summary>
    /// Registra un nuevo usuario en el sistema.
    /// </summary>
    /// <param name="dto">Datos del usuario a registrar.</param>
    /// <param name="cancellationToken">Token de cancelación.</param>
    /// <returns>201 Created con el Id y email del nuevo usuario, o 400/409 en caso de error.</returns>
    [HttpPost("register")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Register(
        [FromBody] RegisterDto dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var user = await _authService.RegisterAsync(dto, cancellationToken);
            _logger.LogInformation("Nuevo usuario registrado con Id: {UserId}", user.Id);

            return CreatedAtAction(nameof(Register), new
            {
                userId = user.Id,
                email  = user.Email
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex) when (ex.Message.Contains("ya está registrado"))
        {
            // Retorna 409 Conflict si el email ya existe.
            return Conflict(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Autentica al usuario y devuelve el par de tokens (Access + Refresh).
    /// El Refresh Token se envía en una cookie HttpOnly para mayor seguridad.
    /// </summary>
    /// <param name="dto">Credenciales de inicio de sesión.</param>
    /// <param name="cancellationToken">Token de cancelación.</param>
    /// <returns>200 OK con el Access Token, o 401 si las credenciales son inválidas.</returns>
    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(TokenResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login(
        [FromBody] LoginDto dto,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var ipAddress = GetClientIpAddress();
        var result    = await _authService.LoginAsync(dto, ipAddress, cancellationToken);

        if (result is null)
        {
            // Mensaje genérico para no filtrar si el email existe (OWASP A07).
            return Unauthorized(new { message = "Credenciales inválidas." });
        }

        // El Refresh Token se envía en cookie HttpOnly/Secure/SameSite=Strict
        // para que el JavaScript del cliente NO pueda acceder a él.
        SetRefreshTokenCookie(result.Value.RefreshToken);

        return Ok(result.Value.TokenResponse);
    }

    /// <summary>
    /// Rota el Refresh Token y genera un nuevo par de tokens.
    /// Lee el Refresh Token actual de la cookie HttpOnly.
    /// </summary>
    /// <param name="cancellationToken">Token de cancelación.</param>
    /// <returns>200 OK con el nuevo Access Token, o 401 si el token es inválido.</returns>
    [HttpPost("refresh-token")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(TokenResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> RefreshToken(CancellationToken cancellationToken)
    {
        // Se lee el refresh token desde la cookie HttpOnly (no del body).
        var refreshToken = Request.Cookies["refreshToken"];
        if (string.IsNullOrWhiteSpace(refreshToken))
            return Unauthorized(new { message = "Refresh token no encontrado." });

        var ipAddress = GetClientIpAddress();
        var result    = await _authService.RefreshTokenAsync(refreshToken, ipAddress, cancellationToken);

        if (result is null)
            return Unauthorized(new { message = "Refresh token inválido o expirado." });

        SetRefreshTokenCookie(result.Value.RefreshToken);
        return Ok(result.Value.TokenResponse);
    }

    /// <summary>
    /// Revoca el Refresh Token del usuario (cierre de sesión seguro).
    /// Solo funciona para el token de la sesión actual.
    /// </summary>
    /// <param name="cancellationToken">Token de cancelación.</param>
    /// <returns>200 OK si el token fue revocado, o 400 si no había token.</returns>
    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Logout(CancellationToken cancellationToken)
    {
        var refreshToken = Request.Cookies["refreshToken"];
        if (string.IsNullOrWhiteSpace(refreshToken))
            return BadRequest(new { message = "No hay sesión activa." });

        var ipAddress = GetClientIpAddress();

        try
        {
            await _authService.RevokeTokenAsync(refreshToken, ipAddress, cancellationToken);
        }
        catch (ArgumentException)
        {
            // El token ya estaba revocado; igual se elimina la cookie.
        }

        // Eliminar la cookie del cliente.
        Response.Cookies.Delete("refreshToken");
        return Ok(new { message = "Sesión cerrada correctamente." });
    }

    // ── Métodos privados ──────────────────────────────────────────────────────

    /// <summary>
    /// Escribe el Refresh Token en una cookie HttpOnly/Secure/SameSite=Strict.
    /// Esto previene el acceso desde JavaScript (XSS) y ataques CSRF.
    /// </summary>
    private void SetRefreshTokenCookie(string refreshToken)
    {
        var cookieOptions = new CookieOptions
        {
            HttpOnly = true,                        // No accesible desde JavaScript
            Secure   = true,                        // Solo HTTPS
            SameSite = SameSiteMode.Strict,         // Mitiga CSRF
            Expires  = DateTimeOffset.UtcNow.AddDays(7)
        };
        Response.Cookies.Append("refreshToken", refreshToken, cookieOptions);
    }

    /// <summary>
    /// Extrae la IP real del cliente, considerando proxies y load balancers.
    /// </summary>
    private string GetClientIpAddress()
    {
        // Si hay un proxy inverso configurado, la IP real viene en X-Forwarded-For.
        return Request.Headers["X-Forwarded-For"].FirstOrDefault()
            ?? HttpContext.Connection.RemoteIpAddress?.ToString()
            ?? "unknown";
    }
}
