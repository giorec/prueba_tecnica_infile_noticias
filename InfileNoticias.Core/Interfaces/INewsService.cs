using System.Collections.Generic;
using System.Threading.Tasks;

namespace InfileNoticias.Core.Interfaces
{
    public class NewsArticle
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Summary { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Source { get; set; } = string.Empty;
        public DateTime PublishedAtUtc { get; set; }
    }

    /// <summary>
    /// Contrato para el proveedor externo de noticias (NewsAPI, MediaStack, etc.)
    /// </summary>
    public interface INewsService
    {
        /// <summary>
        /// Obtiene noticias principales o generales.
        /// </summary>
        Task<List<NewsArticle>> GetGeneralNewsAsync(int limit = 20);

        /// <summary>
        /// Obtiene noticias para una categoría específica.
        /// </summary>
        Task<List<NewsArticle>> GetNewsByCategoryAsync(string category, int limit = 20);
    }
}
