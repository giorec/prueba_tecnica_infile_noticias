using System.Text;
using System.Threading.RateLimiting;
using InfileNoticias.API.Middleware;
using InfileNoticias.Core.Entities;
using InfileNoticias.Core.Interfaces;
using InfileNoticias.Infrastructure.Data;
using InfileNoticias.Infrastructure.Identity;
using InfileNoticias.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

// ══════════════════════════════════════════════════════════════════════════════
//  INFILE NOTICIAS — Program.cs (Composición Raíz)
//  Configura el pipeline de ASP.NET Core 8 con seguridad de nivel bancario.
//  IMPORTANTE: Los secretos (JWT secret, connection string) NUNCA se hardcodean
//  aquí. Se leen desde variables de entorno o User Secrets en desarrollo.
// ══════════════════════════════════════════════════════════════════════════════

var builder = WebApplication.CreateBuilder(args);

// ── 1. BASE DE DATOS (PostgreSQL + Entity Framework Core) ────────────────────
// La cadena de conexión se obtiene de la variable de entorno:
//   ConnectionStrings__DefaultConnection (producción)
// o de appsettings.Development.json / User Secrets (desarrollo).
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions => npgsqlOptions.MigrationsAssembly("InfileNoticias.Infrastructure")
    ));

// ── 2. ASP.NET CORE IDENTITY ─────────────────────────────────────────────────
// Se configura con las reglas de contraseña estrictas del proyecto.
// El IPasswordHasher por defecto (PBKDF2) se sustituye por Argon2id.
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    // ── Política de contraseñas (mínimo 13 caracteres, requerida por el spec) ──
    options.Password.RequiredLength         = 13;   // ← Requisito explícito del proyecto
    options.Password.RequireUppercase       = true;
    options.Password.RequireLowercase       = true;
    options.Password.RequireDigit           = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequiredUniqueChars    = 1;

    // ── Política de bloqueo de cuenta (anti fuerza bruta a nivel Identity) ───
    // El rate limiting del middleware es la primera línea de defensa;
    // el lockout de Identity es la segunda.
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.DefaultLockoutTimeSpan  = TimeSpan.FromMinutes(15);
    options.Lockout.AllowedForNewUsers      = true;

    // ── Email único (previene duplicados) ────────────────────────────────────
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();

// ── Sustituir el hasher por defecto (PBKDF2) por Argon2id ───────────────────
// Se registra como Singleton para evitar reinstanciación innecesaria.
builder.Services.AddSingleton<IPasswordHasher<ApplicationUser>, Argon2PasswordHasher>();

// ── 3. AUTENTICACIÓN JWT BEARER ──────────────────────────────────────────────
var jwtSecret = builder.Configuration["Jwt:Secret"]
    ?? throw new InvalidOperationException(
        "❌ JWT secret no configurado. Configure la variable de entorno 'Jwt__Secret'.");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme    = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = true; // ← Prohibido HTTP plano (spec explícita)
    options.SaveToken            = false; // El token no se guarda en el servidor (stateless)
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
        ValidateIssuer           = true,
        ValidIssuer              = builder.Configuration["Jwt:Issuer"] ?? "InfileNoticiasAPI",
        ValidateAudience         = true,
        ValidAudience            = builder.Configuration["Jwt:Audience"] ?? "InfileNoticiasClient",
        ValidateLifetime         = true,
        ClockSkew                = TimeSpan.Zero // Sin tolerancia de reloj para mayor seguridad
    };
});

// ── 4. RATE LIMITING (Anti fuerza bruta en endpoints de auth) ────────────────
// Se usa Sliding Window Rate Limiter: permite X peticiones en una ventana de tiempo
// que se desliza, siendo más restrictivo que una ventana fija.
builder.Services.AddRateLimiter(options =>
{
    // Política específica para endpoints de autenticación.
    options.AddSlidingWindowLimiter("AuthPolicy", limiterOptions =>
    {
        limiterOptions.PermitLimit            = 5;                        // Máximo 5 peticiones
        limiterOptions.Window                 = TimeSpan.FromMinutes(1); // por minuto (ventana)
        limiterOptions.SegmentsPerWindow      = 6;                        // Granularidad de 10s
        limiterOptions.QueueProcessingOrder   = QueueProcessingOrder.OldestFirst;
        limiterOptions.QueueLimit             = 0;                        // Sin cola, rechazar inmediatamente
    });

    // Política global más permisiva para el resto de la API.
    options.AddSlidingWindowLimiter("GlobalPolicy", limiterOptions =>
    {
        limiterOptions.PermitLimit       = 100;
        limiterOptions.Window            = TimeSpan.FromMinutes(1);
        limiterOptions.SegmentsPerWindow = 6;
        limiterOptions.QueueLimit        = 10;
    });

    // Respuesta estándar cuando se excede el límite (HTTP 429 Too Many Requests).
    options.OnRejected = async (context, cancellationToken) =>
    {
        context.HttpContext.Response.StatusCode  = StatusCodes.Status429TooManyRequests;
        context.HttpContext.Response.ContentType = "application/json";
        await context.HttpContext.Response.WriteAsJsonAsync(new
        {
            status  = 429,
            message = "Demasiadas solicitudes. Por favor espere un momento antes de intentar de nuevo.",
            retryAfter = "60 segundos"
        }, cancellationToken);
    };
});

// ── 5. SERVICIOS DE APLICACIÓN ───────────────────────────────────────────────
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();

// Fase 3: Motor de Votaciones y Feed 70/30
builder.Services.AddScoped<INewsService, MockNewsService>();
builder.Services.AddScoped<IFeedService, FeedAssemblerService>();
builder.Services.AddSingleton<VoteChannel>();
builder.Services.AddHostedService<VoteProcessorBackgroundService>();

// ── 6. CORS ──────────────────────────────────────────────────────────────────
// Configuración restrictiva: solo permite el origen del cliente Flutter.
// En producción, cambiar "*" por el dominio real.
builder.Services.AddCors(options =>
{
    options.AddPolicy("InfileNoticiasPolicy", policy =>
    {
        policy
            .WithOrigins(
                builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
                ?? ["http://localhost:3000"])
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials(); // Necesario para cookies HttpOnly (refresh token)
    });
});

// ── 7. CONTROLADORES + SWAGGER ───────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title       = "Infile Noticias API",
        Version     = "v1",
        Description = "API de noticias con autenticación segura (Argon2id + JWT + Refresh Tokens rotativos)"
    });

    // Permite usar el JWT Bearer token en Swagger UI.
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name         = "Authorization",
        Type         = SecuritySchemeType.Http,
        Scheme       = "Bearer",
        BearerFormat = "JWT",
        In           = ParameterLocation.Header,
        Description  = "Ingrese el Access Token JWT. Ejemplo: Bearer {token}"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

// ── 8. HEALTH CHECKS ─────────────────────────────────────────────────────────
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("PostgreSQL");

// ── CONSTRUCCIÓN DEL PIPELINE ─────────────────────────────────────────────────
var app = builder.Build();

// ── Middleware de excepción global (debe ir primero) ─────────────────────────
app.UseMiddleware<GlobalExceptionMiddleware>();

// ── Security Headers Middleware (Capa de defensa HTTP) ──────────────────────
app.UseMiddleware<SecurityHeadersMiddleware>();

// ── Swagger (solo en Development) ───────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Infile Noticias API v1");
        c.RoutePrefix = string.Empty; // Swagger en la raíz /
    });
}

// ── HTTPS forzado (nunca HTTP plano en producción) ───────────────────────────
app.UseHttpsRedirection();

// ── Rate Limiting ─────────────────────────────────────────────────────────────
app.UseRateLimiter();

// ── CORS ──────────────────────────────────────────────────────────────────────
app.UseCors("InfileNoticiasPolicy");

// ── Autenticación y Autorización (orden importa: primero Auth, luego Authz) ──
app.UseAuthentication();
app.UseAuthorization();

// ── Controladores ─────────────────────────────────────────────────────────────
app.MapControllers();

// ── Health Check endpoint ────────────────────────────────────────────────────
app.MapHealthChecks("/health");

// ── Aplicar migraciones pendientes automáticamente al iniciar ────────────────
// Solo recomendado para desarrollo. En producción usar un proceso separado.
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
}

app.Run();
