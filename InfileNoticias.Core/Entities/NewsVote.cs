using System;

namespace InfileNoticias.Core.Entities
{
    public class NewsVote
    {
        public Guid Id { get; set; }
        public string UserId { get; set; } = null!;
        public string ArticleId { get; set; } = null!;
        public string Category { get; set; } = null!;
        
        /// <summary>
        /// 1 para "Me gusta", -1 para "No me gusta"
        /// </summary>
        public int VoteType { get; set; }
        
        public DateTime CreatedAtUtc { get; set; }
        
        // Navegación (si fuera necesario mapear explícitamente)
        public virtual ApplicationUser? User { get; set; }
    }
}
