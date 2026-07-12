using System.Threading.Channels;
using System.Threading.Tasks;
using InfileNoticias.Core.Entities;

namespace InfileNoticias.Infrastructure.Services
{
    /// <summary>
    /// Canal en memoria para procesamiento asíncrono de votos.
    /// Permite a los controladores encolar votos rápidamente (Fire and Forget seguro)
    /// sin bloquear la respuesta HTTP, protegiendo la base de datos contra picos de carga.
    /// </summary>
    public class VoteChannel
    {
        private readonly Channel<NewsVote> _channel;

        public VoteChannel()
        {
            // Bounded channel para evitar quedarse sin memoria si la base de datos se cae
            // o se vuelve demasiado lenta. Limita la cola a 10,000 votos.
            var options = new BoundedChannelOptions(10000)
            {
                FullMode = BoundedChannelFullMode.Wait // Espera si el canal está lleno
            };
            
            _channel = Channel.CreateBounded<NewsVote>(options);
        }

        /// <summary>
        /// Agrega un voto a la cola para ser procesado.
        /// </summary>
        public async ValueTask AddVoteAsync(NewsVote vote)
        {
            await _channel.Writer.WriteAsync(vote);
        }

        /// <summary>
        /// Expone el lector para el BackgroundService.
        /// </summary>
        public ChannelReader<NewsVote> Reader => _channel.Reader;
    }
}
