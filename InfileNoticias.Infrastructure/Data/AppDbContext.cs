using InfileNoticias.Core.Entities;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace InfileNoticias.Infrastructure.Data;

/// <summary>
/// Contexto principal de la base de datos.
/// Hereda de IdentityDbContext para integrar las tablas de ASP.NET Core Identity
/// con el esquema de la aplicación en PostgreSQL.
/// </summary>
public class AppDbContext : IdentityDbContext<ApplicationUser>
{
    /// <summary>
    /// Constructor que recibe las opciones de configuración (cadena de conexión, proveedor, etc.).
    /// </summary>
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    /// <summary>Tabla de Refresh Tokens rotativos.</summary>
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    /// <summary>Tabla de votos de los usuarios sobre las noticias.</summary>
    public DbSet<NewsVote> NewsVotes => Set<NewsVote>();

    /// <inheritdoc/>
    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // ── Esquema de tablas de Identity ────────────────────────────────────
        // Se mueve todas las tablas de Identity al schema "identity" para
        // separar responsabilidades en PostgreSQL.
        builder.HasDefaultSchema("public");

        // ── ApplicationUser ──────────────────────────────────────────────────
        builder.Entity<ApplicationUser>(entity =>
        {
            entity.ToTable("Users");
            entity.Property(u => u.FullName)
                .HasMaxLength(200)
                .IsRequired();
            entity.Property(u => u.CreatedAtUtc)
                .HasDefaultValueSql("NOW() AT TIME ZONE 'UTC'");
        });

        // ── RefreshToken ─────────────────────────────────────────────────────
        builder.Entity<RefreshToken>(entity =>
        {
            entity.ToTable("RefreshTokens");

            entity.HasKey(rt => rt.Id);

            entity.Property(rt => rt.Token)
                .HasMaxLength(512)
                .IsRequired();

            entity.Property(rt => rt.CreatedAtUtc)
                .HasDefaultValueSql("NOW() AT TIME ZONE 'UTC'");

            // Índice único sobre Token para búsquedas rápidas al validar.
            entity.HasIndex(rt => rt.Token).IsUnique();

            // Relación: un usuario tiene muchos refresh tokens.
            entity.HasOne(rt => rt.User)
                .WithMany(u => u.RefreshTokens)
                .HasForeignKey(rt => rt.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ── NewsVote ─────────────────────────────────────────────────────────
        builder.Entity<NewsVote>(entity =>
        {
            entity.ToTable("NewsVotes");
            entity.HasKey(nv => nv.Id);
            
            entity.Property(nv => nv.ArticleId).HasMaxLength(255).IsRequired();
            entity.Property(nv => nv.Category).HasMaxLength(100).IsRequired();
            entity.Property(nv => nv.CreatedAtUtc).HasDefaultValueSql("NOW() AT TIME ZONE 'UTC'");

            // Constraint único: Un usuario solo puede tener un voto activo por noticia.
            entity.HasIndex(nv => new { nv.UserId, nv.ArticleId }).IsUnique();

            // Relación
            entity.HasOne(nv => nv.User)
                .WithMany() // No agregamos colección a ApplicationUser para mantenerlo ligero
                .HasForeignKey(nv => nv.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
