import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/news_article.dart';
import '../bloc/feed_cubit.dart';

class NewsCardWidget extends StatefulWidget {
  final NewsArticle article;

  const NewsCardWidget({super.key, required this.article});

  @override
  State<NewsCardWidget> createState() => _NewsCardWidgetState();
}

class _NewsCardWidgetState extends State<NewsCardWidget> {
  // Estado local para UI optimista
  int? _localVote; 

  void _handleVote(int voteType) {
    setState(() {
      _localVote = voteType;
    });
    context.read<FeedCubit>().vote(
          widget.article.id,
          widget.article.category,
          voteType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen de la noticia
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: widget.article.imageUrl,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 180,
                color: AppColors.surface,
                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categoría Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infileBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.article.category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.infileBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Título
                Text(
                  widget.article.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Resumen
                Text(
                  widget.article.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumGray,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Acciones (Me gusta / No me gusta)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _localVote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                        color: _localVote == -1 ? Colors.red : AppColors.mediumGray,
                      ),
                      onPressed: () => _handleVote(-1),
                      tooltip: 'No me interesa',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _localVote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: _localVote == 1 ? AppColors.infileBlue : AppColors.mediumGray,
                      ),
                      onPressed: () => _handleVote(1),
                      tooltip: 'Me gusta',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
