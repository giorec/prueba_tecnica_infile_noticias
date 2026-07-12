import 'package:equatable/equatable.dart';

class NewsArticle extends Equatable {
  final String id;
  final String title;
  final String summary;
  final String imageUrl;
  final String category;
  final String source;
  final DateTime publishedAtUtc;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.category,
    required this.source,
    required this.publishedAtUtc,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      source: json['source'] ?? '',
      publishedAtUtc: DateTime.tryParse(json['publishedAtUtc'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        imageUrl,
        category,
        source,
        publishedAtUtc,
      ];
}
