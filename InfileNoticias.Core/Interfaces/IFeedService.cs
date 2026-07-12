using System.Collections.Generic;
using System.Threading.Tasks;

namespace InfileNoticias.Core.Interfaces
{
    public interface IFeedService
    {
        /// <summary>
        /// Ensambla y devuelve un feed personalizado para el usuario según sus votos.
        /// (70% categoría favorita, 30% noticias generales).
        /// Si no tiene afinidad, devuelve 100% generales.
        /// </summary>
        Task<List<NewsArticle>> GetPersonalizedFeedAsync(string userId, int limit = 20);
    }
}
