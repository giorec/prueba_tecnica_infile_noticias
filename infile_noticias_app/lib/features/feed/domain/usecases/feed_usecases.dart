import '../entities/news_article.dart';
import '../repositories/feed_repository.dart';

class GetFeedUseCase {
  final FeedRepository _repository;

  GetFeedUseCase(this._repository);

  Future<List<NewsArticle>> call({int limit = 20}) async {
    return await _repository.getPersonalizedFeed(limit: limit);
  }
}

class SubmitVoteUseCase {
  final FeedRepository _repository;

  SubmitVoteUseCase(this._repository);

  Future<void> call(String articleId, String category, int voteType) async {
    return await _repository.submitVote(articleId, category, voteType);
  }
}
