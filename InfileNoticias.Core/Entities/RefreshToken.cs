namespace InfileNoticias.Core.Entities;

/// <summary>
/// Representa un Refresh Token rotativo almacenado en base de datos.
/// Se invalida y reemplaza con cada uso (rotación), defendiendo contra robo de tokens.
/// </summary>
public class RefreshToken
{
    /// <summary>Identificador único del refresh token.</summary>
    public int Id { get; set; }

    /// <summary>Id del usuario propietario del token.</summary>
    public string UserId { get; set; } = string.Empty;

    /// <summary>El valor del token (cadena aleatoria criptográficamente segura).</summary>
    public string Token { get; set; } = string.Empty;

    /// <summary>Fecha y hora de expiración del token (UTC).</summary>
    public DateTime ExpiresAtUtc { get; set; }

    /// <summary>Fecha de creación del token (UTC).</summary>
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    /// <summary>Fecha en que fue revocado/reemplazado. Null si aún está activo.</summary>
    public DateTime? RevokedAtUtc { get; set; }

    /// <summary>Token que lo reemplazó tras la rotación (para detección de reutilización).</summary>
    public string? ReplacedByToken { get; set; }

    /// <summary>Razón de la revocación (ej. "Rotación", "Logout", "Reuso detectado").</summary>
    public string? RevokedReason { get; set; }

    /// <summary>Dirección IP desde donde se emitió el token.</summary>
    public string? CreatedByIp { get; set; }

    /// <summary>Dirección IP desde donde se revocó el token.</summary>
    public string? RevokedByIp { get; set; }

    /// <summary>Relación de navegación al usuario propietario.</summary>
    public ApplicationUser User { get; set; } = null!;

    /// <summary>
    /// Indica si el token está vigente (no expirado y no revocado).
    /// </summary>
    public bool IsActive => RevokedAtUtc == null && DateTime.UtcNow < ExpiresAtUtc;

    /// <summary>Indica si el token ya expiró por tiempo.</summary>
    public bool IsExpired => DateTime.UtcNow >= ExpiresAtUtc;

    /// <summary>Indica si el token fue revocado manualmente (logout, rotación, etc.).</summary>
    public bool IsRevoked => RevokedAtUtc != null;
}
