namespace InfileNoticias.Core.DTOs.Auth;

/// <summary>
/// DTO para la solicitud de inicio de sesión.
/// </summary>
public record LoginDto(
    /// <summary>Correo electrónico del usuario.</summary>
    string Email,
    /// <summary>Contraseña en texto plano (se valida y hashea en el servidor).</summary>
    string Password
);

/// <summary>
/// DTO para el registro de un nuevo usuario.
/// </summary>
public record RegisterDto(
    /// <summary>Nombre completo del usuario.</summary>
    string FullName,
    /// <summary>Correo electrónico único del usuario.</summary>
    string Email,
    /// <summary>
    /// Contraseña en texto plano.
    /// Política: mínimo 13 caracteres, 1 mayúscula, 1 minúscula, 1 número, 1 caracter especial.
    /// </summary>
    string Password,
    /// <summary>Confirmación de contraseña (debe coincidir con Password).</summary>
    string ConfirmPassword
);

/// <summary>
/// DTO de respuesta tras autenticación exitosa.
/// Contiene el Access Token JWT y el Refresh Token.
/// </summary>
public record TokenResponseDto(
    /// <summary>Access Token JWT de corta duración (15 minutos por defecto).</summary>
    string AccessToken,
    /// <summary>Fecha y hora de expiración del Access Token (UTC).</summary>
    DateTime AccessTokenExpiresAtUtc,
    /// <summary>Tipo de token (siempre "Bearer").</summary>
    string TokenType = "Bearer"
);

/// <summary>
/// DTO para solicitar la renovación del Access Token usando un Refresh Token.
/// </summary>
public record RefreshTokenDto(
    /// <summary>El Refresh Token vigente almacenado en Secure Storage del cliente.</summary>
    string RefreshToken
);
