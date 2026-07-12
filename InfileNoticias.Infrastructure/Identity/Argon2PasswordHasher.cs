using InfileNoticias.Core.Entities;
using Isopoh.Cryptography.Argon2;
using Microsoft.AspNetCore.Identity;

namespace InfileNoticias.Infrastructure.Identity;

/// <summary>
/// Implementación personalizada de IPasswordHasher que sustituye el algoritmo
/// PBKDF2 por defecto de ASP.NET Identity por Argon2id.
///
/// Argon2id es el ganador de la Password Hashing Competition (PHC) y combina
/// resistencia a ataques de canal lateral (Argon2i) con resistencia a ataques GPU/ASIC (Argon2d).
/// Es la elección recomendada por OWASP para aplicaciones de nivel bancario.
/// </summary>
public sealed class Argon2PasswordHasher : IPasswordHasher<ApplicationUser>
{
    // ── Parámetros Argon2id recomendados por OWASP (2024) ───────────────────
    // Ajustados para un equilibrio entre seguridad y latencia de autenticación.

    /// <summary>Número de iteraciones (factor de costo de tiempo).</summary>
    private const int Iterations = 3;

    /// <summary>Memoria a utilizar en KB (64 MB).</summary>
    private const int MemoryCostKb = 65536;

    /// <summary>Grado de paralelismo (hilos).</summary>
    private const int Parallelism = 4;

    /// <summary>Longitud del hash resultante en bytes.</summary>
    private const int HashLength = 32;

    /// <inheritdoc/>
    /// <summary>
    /// Genera el hash Argon2id de la contraseña en texto plano.
    /// El resultado incluye los parámetros y el salt codificados en Base64 (PHC string format).
    /// </summary>
    public string HashPassword(ApplicationUser user, string password)
    {
        var config = new Argon2Config
        {
            Type          = Argon2Type.HybridAddressing, // Argon2id
            Version       = Argon2Version.Nineteen,
            TimeCost      = Iterations,
            MemoryCost    = MemoryCostKb,
            Lanes         = Parallelism,
            Threads       = Parallelism,
            HashLength    = HashLength,
            Password      = System.Text.Encoding.UTF8.GetBytes(password)
        };

        using var argon2 = new Argon2(config);
        using var hash   = argon2.Hash();
        return config.EncodeString(hash.Buffer);
    }

    /// <inheritdoc/>
    /// <summary>
    /// Verifica que la contraseña en texto plano coincide con el hash almacenado.
    /// </summary>
    public PasswordVerificationResult VerifyHashedPassword(
        ApplicationUser user,
        string hashedPassword,
        string providedPassword)
    {
        // Verifica usando la cadena PHC que incluye los parámetros y el salt.
        bool isValid = Argon2.Verify(hashedPassword, providedPassword);
        return isValid
            ? PasswordVerificationResult.Success
            : PasswordVerificationResult.Failed;
    }
}
