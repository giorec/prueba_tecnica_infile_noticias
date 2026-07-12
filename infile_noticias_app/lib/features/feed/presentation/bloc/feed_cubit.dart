import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/feed_usecases.dart';
import 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final GetFeedUseCase _getFeed;
  final SubmitVoteUseCase _submitVote;

  FeedCubit(this._getFeed, this._submitVote) : super(FeedInitial());

  Future<void> fetchFeed({bool refresh = false}) async {
    if (!refresh) {
      emit(FeedLoading());
    }

    try {
      final articles = await _getFeed(limit: 20);
      emit(FeedLoaded(articles));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> vote(String articleId, String category, int voteType) async {
    try {
      // Optamos por no emitir un estado de "Loading" aquí para no redibujar toda la lista
      // y arruinar el scroll del usuario (Optimistic UI).
      await _submitVote(articleId, category, voteType);
    } catch (e) {
      // En un caso real se podría usar un EventHandler paralelo para mostrar un Snackbar,
      // pero para evitar bloquear el UI simplemente ignoramos o loggeamos el error.
    }
  }
}
