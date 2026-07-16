import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/models/comment_model.dart';

// States
abstract class CommentsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CommentsInitial extends CommentsState {}

class CommentsLoading extends CommentsState {}

class CommentsLoaded extends CommentsState {
  final List<CommentModel> comments;

  CommentsLoaded({required this.comments});

  @override
  List<Object?> get props => [comments];
}

class CommentsError extends CommentsState {
  final String message;
  CommentsError(this.message);

  @override
  List<Object?> get props => [message];
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
    if (isClosed) return;
    emit(CommentsLoading());
    try {
      final user = _supabaseService.currentUser;
      final data = await _supabaseService.getComments(
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        userId: user?.id,
      );

      final comments = data.map((json) => CommentModel.fromJson(json)).toList();
      if (isClosed) return;
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      if (isClosed) return;
      emit(CommentsError('Something went wrong. Please try again.'));
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
      if (isClosed) return;
      emit(CommentsError('Something went wrong. Please try again.'));
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
      if (isClosed) return;
      emit(CommentsError('Something went wrong. Please try again.'));
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
      if (isClosed) return;
      emit(CommentsError('Failed to like comment. Please try again.'));
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
      if (isClosed) return;
      emit(CommentsError('Failed to unlike comment. Please try again.'));
    }
  }
}