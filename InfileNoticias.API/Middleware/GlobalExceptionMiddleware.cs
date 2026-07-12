using System.Net;
using System.Text.Json;

namespace InfileNoticias.API.Middleware;

/// <summary>
/// Middleware global de manejo de excepciones no capturadas.
/// Garantiza que cualquier excepción no controlada retorne una respuesta JSON
/// estructurada y nunca exponga stack traces al cliente (seguridad OWASP A05).
/// </summary>
public sealed class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
    {
        _next   = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            // Se registra el error completo en los logs del servidor (no se expone al cliente).
            _logger.LogError(ex, "Excepción no controlada en {Method} {Path}",
                context.Request.Method, context.Request.Path);

            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        // Mapear tipos de excepción conocidos a códigos HTTP apropiados.
        var (statusCode, message) = exception switch
        {
            ArgumentException       => (HttpStatusCode.BadRequest,             "Solicitud inválida."),
            InvalidOperationException => (HttpStatusCode.Conflict,             "La operación no puede completarse."),
            UnauthorizedAccessException => (HttpStatusCode.Unauthorized,       "No autorizado."),
            _                       => (HttpStatusCode.InternalServerError,    "Ocurrió un error interno. Por favor intente más tarde.")
        };

        context.Response.ContentType = "application/json";
        context.Response.StatusCode  = (int)statusCode;

        // Respuesta estructurada: nunca incluye el stack trace.
        var response = new
        {
            status  = (int)statusCode,
            message,
            traceId = context.TraceIdentifier // ID para correlacionar con los logs del servidor.
        };

        return context.Response.WriteAsync(JsonSerializer.Serialize(response));
    }
}
