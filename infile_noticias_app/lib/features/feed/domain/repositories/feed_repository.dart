import '../entities/news_article.dart';

abstract class FeedRepository {
  /// Obtiene el feed personalizado 70/30
  Future<List<NewsArticle>> getPersonalizedFeed({int limit = 20});

  /// Envia un voto de manera asíncrona (1 para Like, -1 para Dislike)
  Future<void> submitVote(String articleId, String category, int voteType);
}
