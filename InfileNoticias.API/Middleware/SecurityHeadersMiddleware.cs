using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;

namespace InfileNoticias.API.Middleware
{
    /// <summary>
    /// Middleware de Seguridad de Nivel Bancario.
    /// Inyecta encabezados HTTP de seguridad en todas las respuestas para mitigar ataques comunes
    /// como Clickjacking, MIME-Sniffing y ataques de inyección.
    /// </summary>
    public class SecurityHeadersMiddleware
    {
        private readonly RequestDelegate _next;

        public SecurityHeadersMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Agrega los encabezados de seguridad antes de procesar la respuesta
            context.Response.OnStarting(() =>
            {
                var headers = context.Response.Headers;

                // Prevenir Clickjacking (forza a que la página no se pueda cargar en un iframe)
                if (!headers.ContainsKey("X-Frame-Options"))
                {
                    headers.Append("X-Frame-Options", "DENY");
                }

                // Prevenir MIME-Sniffing (forza al navegador a respetar el Content-Type declarado)
                if (!headers.ContainsKey("X-Content-Type-Options"))
                {
                    headers.Append("X-Content-Type-Options", "nosniff");
                }

                // Habilitar protección XSS nativa del navegador en modo bloqueo
                if (!headers.ContainsKey("X-XSS-Protection"))
                {
                    headers.Append("X-XSS-Protection", "1; mode=block");
                }

                // Content-Security-Policy (CSP) restrictiva.
                // Restringe la carga de recursos externos. Solo permite recursos del mismo origen.
                if (!headers.ContainsKey("Content-Security-Policy"))
                {
                    headers.Append("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none';");
                }

                // En producción, HSTS se puede manejar mediante UseHsts() en Program.cs,
                // pero si queremos forzarlo manualmente aquí (Strict-Transport-Security):
                if (!headers.ContainsKey("Strict-Transport-Security"))
                {
                    // 31536000 segundos = 1 año
                    headers.Append("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload");
                }

                return Task.CompletedTask;
            });

            // Continuar con la tubería de solicitud
            await _next(context);
        }
    }
}
