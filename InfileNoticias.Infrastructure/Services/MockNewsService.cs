using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InfileNoticias.Core.Interfaces;

namespace InfileNoticias.Infrastructure.Services
{
    /// <summary>
    /// Implementación simulada (Mock) del proveedor de noticias.
    /// Utiliza datos estáticos para facilitar el desarrollo de la lógica 70/30
    /// sin depender de cuotas de API de terceros.
    /// </summary>
    public class MockNewsService : INewsService
    {
        private readonly List<NewsArticle> _allMockArticles;

        public MockNewsService()
        {
            _allMockArticles = GenerateMockArticles();
        }

        public Task<List<NewsArticle>> GetGeneralNewsAsync(int limit = 20)
        {
            // Devuelve una mezcla aleatoria de noticias generales
            var results = _allMockArticles
                .OrderBy(a => Guid.NewGuid()) // Shuffle simple
                .Take(limit)
                .ToList();
                
            return Task.FromResult(results);
        }

        public Task<List<NewsArticle>> GetNewsByCategoryAsync(string category, int limit = 20)
        {
            // Filtra por categoría y toma el límite
            var results = _allMockArticles
                .Where(a => a.Category.Equals(category, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(a => a.PublishedAtUtc)
                .Take(limit)
                .ToList();

            // Si no hay suficientes, rellenamos con otras (comportamiento de fallback)
            if (results.Count < limit)
            {
                var fallback = _allMockArticles
                    .Where(a => !a.Category.Equals(category, StringComparison.OrdinalIgnoreCase))
                    .OrderBy(a => Guid.NewGuid())
                    .Take(limit - results.Count);
                results.AddRange(fallback);
            }
                
            return Task.FromResult(results);
        }

        private List<NewsArticle> GenerateMockArticles()
        {
            var articles = new List<NewsArticle>();
            var categories = new[] { "Tecnología", "Deportes", "Negocios", "Entretenimiento", "Salud" };
            
            int idCounter = 1;
            foreach (var category in categories)
            {
                for (int i = 1; i <= 20; i++)
                {
                    articles.Add(new NewsArticle
                    {
                        Id = $"mock-article-{idCounter}",
                        Title = $"Noticia importante sobre {category} #{i}",
                        Summary = $"Este es un resumen generado automáticamente para una noticia de {category}. Contiene información relevante para la aplicación Infile Noticias.",
                        ImageUrl = "https://via.placeholder.com/600x400/003DA5/FFFFFF?text=Infile+Noticias",
                        Category = category,
                        Source = "Infile Mock API",
                        PublishedAtUtc = DateTime.UtcNow.AddHours(-i)
                    });
                    idCounter++;
                }
            }
            
            return articles;
        }
    }
}
