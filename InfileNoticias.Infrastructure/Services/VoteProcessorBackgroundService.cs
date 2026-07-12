using System;
using System.Threading;
using System.Threading.Tasks;
using InfileNoticias.Core.Entities;
using InfileNoticias.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace InfileNoticias.Infrastructure.Services
{
    /// <summary>
    /// Servicio en segundo plano que procesa los votos de la cola.
    /// Garantiza que la inserción a la base de datos se haga sin bloquear los request HTTP.
    /// </summary>
    public class VoteProcessorBackgroundService : BackgroundService
    {
        private readonly VoteChannel _voteChannel;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<VoteProcessorBackgroundService> _logger;

        public VoteProcessorBackgroundService(
            VoteChannel voteChannel, 
            IServiceProvider serviceProvider, 
            ILogger<VoteProcessorBackgroundService> logger)
        {
            _voteChannel = voteChannel;
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("VoteProcessorBackgroundService iniciado.");

            // Esperar asíncronamente a que haya elementos para leer
            await foreach (var vote in _voteChannel.Reader.ReadAllAsync(stoppingToken))
            {
                try
                {
                    // Crear un scope por cada procesamiento (o bloque)
                    using var scope = _serviceProvider.CreateScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                    // Verificar si ya existe un voto (Upsert)
                    var existingVote = await dbContext.NewsVotes
                        .FirstOrDefaultAsync(v => v.UserId == vote.UserId && v.ArticleId == vote.ArticleId, stoppingToken);

                    if (existingVote != null)
                    {
                        // Actualizar voto si cambió (ej. de Dislike a Like)
                        existingVote.VoteType = vote.VoteType;
                        existingVote.CreatedAtUtc = DateTime.UtcNow; // Actualizar timestamp de afinidad
                    }
                    else
                    {
                        // Voto nuevo
                        dbContext.NewsVotes.Add(vote);
                    }

                    await dbContext.SaveChangesAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al procesar voto del usuario {UserId} para el artículo {ArticleId}", vote.UserId, vote.ArticleId);
                }
            }
        }
    }
}
