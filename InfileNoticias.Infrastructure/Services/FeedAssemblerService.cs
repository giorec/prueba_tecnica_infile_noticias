using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InfileNoticias.Core.Interfaces;
using InfileNoticias.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace InfileNoticias.Infrastructure.Services
{
    public class FeedAssemblerService : IFeedService
    {
        private readonly INewsService _newsService;
        private readonly AppDbContext _dbContext;
        private readonly ILogger<FeedAssemblerService> _logger;

        public FeedAssemblerService(
            INewsService newsService, 
            AppDbContext dbContext, 
            ILogger<FeedAssemblerService> logger)
        {
            _newsService = newsService;
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<List<NewsArticle>> GetPersonalizedFeedAsync(string userId, int limit = 20)
        {
            try
            {
                // 1. Calcular la afinidad del usuario
                var topCategory = await GetTopCategoryForUserAsync(userId);

                if (string.IsNullOrEmpty(topCategory))
                {
                    // Usuario sin historial de votos o sin una categoría dominante
                    _logger.LogInformation("Usuario {UserId} sin afinidad. Entregando 100% feed general.", userId);
                    return await _newsService.GetGeneralNewsAsync(limit);
                }

                _logger.LogInformation("Usuario {UserId} con afinidad: {Category}. Mezclando 70/30.", userId, topCategory);

                // 2. Mezcla 70/30
                int favoriteLimit = (int)Math.Ceiling(limit * 0.7);
                int generalLimit = limit - favoriteLimit;

                // Llamadas en paralelo para optimizar tiempo
                var favoriteNewsTask = _newsService.GetNewsByCategoryAsync(topCategory, favoriteLimit);
                var generalNewsTask = _newsService.GetGeneralNewsAsync(generalLimit);

                await Task.WhenAll(favoriteNewsTask, generalNewsTask);

                var favoriteNews = favoriteNewsTask.Result;
                var generalNews = generalNewsTask.Result;

                // 3. Mezclar y devolver
                var combinedFeed = new List<NewsArticle>(favoriteNews);
                
                // Evitar duplicados si una noticia general también es de la categoría favorita
                var favoriteIds = new HashSet<string>(favoriteNews.Select(n => n.Id));
                foreach (var article in generalNews)
                {
                    if (!favoriteIds.Contains(article.Id))
                    {
                        combinedFeed.Add(article);
                    }
                }

                // Barajar (shuffle) levemente para que no salgan las 70% juntas al inicio
                return combinedFeed.OrderBy(x => Guid.NewGuid()).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error ensamblando el feed para el usuario {UserId}", userId);
                // Fallback seguro: entregar noticias generales
                return await _newsService.GetGeneralNewsAsync(limit);
            }
        }

        private async Task<string?> GetTopCategoryForUserAsync(string userId)
        {
            // Puntuación: SUM(VoteType) agrupado por Categoría
            var categoryScores = await _dbContext.NewsVotes
                .Where(v => v.UserId == userId)
                .GroupBy(v => v.Category)
                .Select(g => new 
                {
                    Category = g.Key,
                    Score = g.Sum(v => v.VoteType) // Like = 1, Dislike = -1
                })
                .OrderByDescending(x => x.Score)
                .FirstOrDefaultAsync();

            // Solo consideramos afinidad si la puntuación es positiva
            if (categoryScores != null && categoryScores.Score > 0)
            {
                return categoryScores.Category;
            }

            return null;
        }
    }
}
