import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final DioClient _dioClient;

  FeedRepositoryImpl(this._dioClient);

  @override
  Future<List<NewsArticle>> getPersonalizedFeed({int limit = 20}) async {
    try {
      final response = await _dioClient.client.get(
        '/api/feed',
        queryParameters: {'limit': limit},
      );
      
      final List<dynamic> data = response.data;
      return data.map((json) => NewsArticle.fromJson(json)).toList();
    } catch (e) {
      // En un caso real se mapean las excepciones de Dio a excepciones de dominio
      throw Exception('Error al obtener el feed: $e');
    }
  }

  @override
  Future<void> submitVote(String articleId, String category, int voteType) async {
    try {
      // Optimistic UI, fire and forget
      await _dioClient.client.post(
        '/api/feed/vote',
        data: {
          'articleId': articleId,
          'category': category,
          'voteType': voteType,
        },
      );
    } catch (e) {
      throw Exception('Error al enviar el voto: $e');
    }
  }
}
