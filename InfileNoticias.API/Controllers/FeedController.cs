using System;
using System.Security.Claims;
using System.Threading.Tasks;
using InfileNoticias.Core.Entities;
using InfileNoticias.Core.Interfaces;
using InfileNoticias.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace InfileNoticias.API.Controllers
{
    public class VoteDto
    {
        public string ArticleId { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        
        /// <summary>
        /// 1 para Like, -1 para Dislike
        /// </summary>
        public int VoteType { get; set; }
    }

    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Requiere JWT válido
    [EnableRateLimiting("fixed")] // Protección contra abusos
    public class FeedController : ControllerBase
    {
        private readonly IFeedService _feedService;
        private readonly VoteChannel _voteChannel;

        public FeedController(IFeedService feedService, VoteChannel voteChannel)
        {
            _feedService = feedService;
            _voteChannel = voteChannel;
        }

        [HttpGet]
        public async Task<IActionResult> GetFeed([FromQuery] int limit = 20)
        {
            // Extraer ID del usuario desde el JWT
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            var news = await _feedService.GetPersonalizedFeedAsync(userId, limit);
            return Ok(news);
        }

        [HttpPost("vote")]
        public async Task<IActionResult> SubmitVote([FromBody] VoteDto dto)
        {
            if (dto.VoteType != 1 && dto.VoteType != -1)
            {
                return BadRequest(new { message = "VoteType debe ser 1 (Me gusta) o -1 (No me gusta)." });
            }

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            var vote = new NewsVote
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ArticleId = dto.ArticleId,
                Category = dto.Category,
                VoteType = dto.VoteType,
                CreatedAtUtc = DateTime.UtcNow
            };

            // Encolar voto asíncronamente (Fire and Forget seguro)
            await _voteChannel.AddVoteAsync(vote);

            // Devolver 202 Accepted indicando que se recibió y está en proceso
            return Accepted(new { message = "Voto recibido y en proceso." });
        }
    }
}
