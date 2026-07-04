import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/models/comment_model.dart';

// States
abstract class CommentsState {}

class CommentsInitial extends CommentsState {}

class CommentsLoading extends CommentsState {}

class CommentsLoaded extends CommentsState {
  final List<CommentModel> comments;

  CommentsLoaded({required this.comments});
}

class CommentsError extends CommentsState {
  final String message;
  CommentsError(this.message);
}

// Cubit
class CommentsCubit extends Cubit<CommentsState> {
  final SupabaseService _supabaseService;

  CommentsCubit(this._supabaseService) : super(CommentsInitial());

  Future<void> loadComments({
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    emit(CommentsLoading());
    try {
      final data = await _supabaseService.getComments(
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      );

      final comments = data.map((json) => CommentModel.fromJson(json)).toList();
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> addComment({
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
    required String content,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.addComment(
        userId: user.id,
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        content: content,
      );

      // Reload comments
      await loadComments(
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      );
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> deleteComment(String commentId, {
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    try {
      await _supabaseService.deleteComment(commentId);

      // Reload comments
      await loadComments(
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      );
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> likeComment(String commentId, {
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.likeComment(user.id, commentId);
      await loadComments(
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> unlikeComment(String commentId, {
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.unlikeComment(user.id, commentId);
      await loadComments(
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      );
    } catch (e) {
      // Handle error
    }
  }
}
