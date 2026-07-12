using Microsoft.AspNetCore.Identity;

namespace InfileNoticias.Core.Entities;

/// <summary>
/// Entidad de usuario extendida de IdentityUser.
/// Agrega campos adicionales para auditoría y trazabilidad.
/// </summary>
public class ApplicationUser : IdentityUser
{
    /// <summary>Nombre completo del usuario.</summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>Fecha y hora de creación del registro (UTC).</summary>
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    /// <summary>Indica si la cuenta está activa. El administrador puede desactivarla.</summary>
    public bool IsActive { get; set; } = true;

    /// <summary>Colección de refresh tokens asociados al usuario.</summary>
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
}
