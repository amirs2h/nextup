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
  final Map<String, List<CommentModel>> replies;
  final String? replyingToId;
  final String? replyingToUsername;

  CommentsLoaded({
    required this.comments,
    this.replies = const {},
    this.replyingToId,
    this.replyingToUsername,
  });

  @override
  List<Object?> get props => [comments, replies, replyingToId, replyingToUsername];
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

      // Load replies for comments that have replies
      final Map<String, List<CommentModel>> repliesMap = {};
      for (final comment in comments) {
        if (comment.replyCount > 0) {
          final repliesData = await _supabaseService.getReplies(
            parentId: comment.id,
            userId: user?.id,
          );
          repliesMap[comment.id] = repliesData.map((json) => CommentModel.fromJson(json)).toList();
        }
      }

      if (isClosed) return;
      emit(CommentsLoaded(comments: comments, replies: repliesMap));
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
    String? title,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    final currentState = state;
    final parentId = currentState is CommentsLoaded ? currentState.replyingToId : null;

    try {
      await _supabaseService.addComment(
        userId: user.id,
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        content: content,
        title: title,
        parentId: parentId,
      );

      // Clear reply state
      if (currentState is CommentsLoaded && currentState.replyingToId != null) {
        if (!isClosed) {
          emit(CommentsLoaded(
            comments: currentState.comments,
            replies: currentState.replies,
            replyingToId: null,
            replyingToUsername: null,
          ));
        }
      }

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

  void setReplyingTo(String commentId, String username) {
    final currentState = state;
    if (currentState is CommentsLoaded) {
      if (isClosed) return;
      emit(CommentsLoaded(
        comments: currentState.comments,
        replies: currentState.replies,
        replyingToId: commentId,
        replyingToUsername: username,
      ));
    }
  }

  void clearReplyingTo() {
    final currentState = state;
    if (currentState is CommentsLoaded) {
      if (isClosed) return;
      emit(CommentsLoaded(
        comments: currentState.comments,
        replies: currentState.replies,
        replyingToId: null,
        replyingToUsername: null,
      ));
    }
  }

  Future<void> loadReplies(String parentId) async {
    final user = _supabaseService.currentUser;
    final currentState = state;
    if (currentState is! CommentsLoaded) return;

    try {
      final repliesData = await _supabaseService.getReplies(
        parentId: parentId,
        userId: user?.id,
      );
      final replies = repliesData.map((json) => CommentModel.fromJson(json)).toList();

      final updatedReplies = Map<String, List<CommentModel>>.from(currentState.replies);
      updatedReplies[parentId] = replies;

      if (isClosed) return;
      emit(CommentsLoaded(
        comments: currentState.comments,
        replies: updatedReplies,
        replyingToId: currentState.replyingToId,
        replyingToUsername: currentState.replyingToUsername,
      ));
    } catch (e) {
      // Silent fail
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

    final currentState = state;
    if (currentState is! CommentsLoaded) return;

    // Optimistic update
    _updateCommentLike(commentId, true);

    try {
      await _supabaseService.likeComment(user.id, commentId);
    } catch (e) {
      // Revert on failure
      _updateCommentLike(commentId, false);
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

    final currentState = state;
    if (currentState is! CommentsLoaded) return;

    // Optimistic update
    _updateCommentLike(commentId, false);

    try {
      await _supabaseService.unlikeComment(user.id, commentId);
    } catch (e) {
      // Revert on failure
      _updateCommentLike(commentId, true);
    }
  }

  void _updateCommentLike(String commentId, bool liked) {
    final currentState = state;
    if (currentState is! CommentsLoaded) return;
    if (isClosed) return;

    // Update in main comments list
    final updatedComments = currentState.comments.map((c) {
      if (c.id == commentId) {
        return CommentModel(
          id: c.id, userId: c.userId, username: c.username, userAvatar: c.userAvatar,
          tmdbId: c.tmdbId, mediaType: c.mediaType, seasonNumber: c.seasonNumber,
          episodeNumber: c.episodeNumber, content: c.content,
          likesCount: liked ? c.likesCount + 1 : (c.likesCount > 0 ? c.likesCount - 1 : 0),
          isLikedByMe: liked, createdAt: c.createdAt,
          parentId: c.parentId, title: c.title, replyCount: c.replyCount, isReply: c.isReply,
        );
      }
      return c;
    }).toList();

    // Update in replies map too
    final updatedReplies = <String, List<CommentModel>>{};
    for (final entry in currentState.replies.entries) {
      updatedReplies[entry.key] = entry.value.map((c) {
        if (c.id == commentId) {
          return CommentModel(
            id: c.id, userId: c.userId, username: c.username, userAvatar: c.userAvatar,
            tmdbId: c.tmdbId, mediaType: c.mediaType, seasonNumber: c.seasonNumber,
            episodeNumber: c.episodeNumber, content: c.content,
            likesCount: liked ? c.likesCount + 1 : (c.likesCount > 0 ? c.likesCount - 1 : 0),
            isLikedByMe: liked, createdAt: c.createdAt,
            parentId: c.parentId, title: c.title, replyCount: c.replyCount, isReply: c.isReply,
          );
        }
        return c;
      }).toList();
    }

    emit(CommentsLoaded(
      comments: updatedComments,
      replies: updatedReplies,
      replyingToId: currentState.replyingToId,
      replyingToUsername: currentState.replyingToUsername,
    ));
  }
}
