import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/spoiler_widget.dart';
import '../../../../shared/models/comment_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/comments_cubit.dart';

class CommentsPage extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? title;

  const CommentsPage({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
    this.title,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _commentController = TextEditingController();
  bool _isSpoiler = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    context.read<CommentsCubit>().loadComments(
      tmdbId: widget.tmdbId,
      mediaType: widget.mediaType,
      seasonNumber: widget.seasonNumber,
      episodeNumber: widget.episodeNumber,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    if (_commentController.text.trim().isEmpty) return;
    if (_commentController.text.trim().length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Comment is too long (max 500 characters)'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final content = _isSpoiler
        ? '[SPOILER] ${_commentController.text.trim()}'
        : _commentController.text.trim();

    context.read<CommentsCubit>().addComment(
      tmdbId: widget.tmdbId,
      mediaType: widget.mediaType,
      seasonNumber: widget.seasonNumber,
      episodeNumber: widget.episodeNumber,
      content: content,
      title: widget.title,
    );

    _commentController.clear();
    setState(() => _isSpoiler = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildCommentsList()),
              _buildCommentInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg(context),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                if (widget.title != null)
                  Text(widget.title!, style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is CommentsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadComments, child: const Text('Retry')),
              ],
            ),
          );
        }

        if (state is CommentsLoaded) {
          if (state.comments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No comments yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Be the first to comment!', style: TextStyle(color: AppColors.textMuted(context))),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadComments(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: state.comments.length,
              itemBuilder: (context, index) {
                final comment = state.comments[index];
                final replies = state.replies[comment.id] ?? [];
                return _buildCommentThread(comment, replies);
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildCommentThread(CommentModel comment, List<CommentModel> replies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentCard(comment, isReply: false),
        // Replies
        if (replies.isNotEmpty)
          ...replies.map((reply) => Padding(
            padding: const EdgeInsets.only(left: 36),
            child: _buildCommentCard(reply, isReply: true),
          )),
        // View replies button
        if (comment.replyCount > 0 && replies.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 52, bottom: 8),
            child: GestureDetector(
              onTap: () => context.read<CommentsCubit>().loadReplies(comment.id),
              child: Row(
                children: [
                  Container(width: 24, height: 1, color: AppColors.textMuted(context).withValues(alpha: 0.3)),
                  const SizedBox(width: 8),
                  Text(
                    'View ${comment.replyCount} ${comment.replyCount == 1 ? 'reply' : 'replies'}',
                    style: TextStyle(color: AppColors.textMuted(context), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentCard(CommentModel comment, {required bool isReply}) {
    final userId = context.read<AuthCubit>().state is AuthAuthenticated
        ? (context.read<AuthCubit>().state as AuthAuthenticated).user.id
        : null;
    final isOwnComment = userId == comment.userId;
    final isSpoiler = comment.content.startsWith('[SPOILER]');
    final displayContent = isSpoiler ? (comment.content.length > 10 ? comment.content.substring(10) : '') : comment.content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + username + time + delete
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/user/${comment.userId}'),
                  child: Container(
                    width: isReply ? 28 : 32,
                    height: isReply ? 28 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border(context), width: 1),
                    ),
                    child: ClipOval(
                      child: comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: comment.userAvatar!,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Center(
                                child: Text(
                                  (comment.username ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(fontSize: isReply ? 10 : 12, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                (comment.username ?? 'U')[0].toUpperCase(),
                                style: TextStyle(fontSize: isReply ? 10 : 12, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.username ?? 'User',
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontWeight: FontWeight.w600,
                              fontSize: isReply ? 12 : 13,
                            ),
                          ),
                          if (isSpoiler) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Spoiler', style: TextStyle(color: Color(0xFFFFD93D), fontSize: 9, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        timeago.format(comment.createdAt),
                        style: TextStyle(color: AppColors.textMuted(context), fontSize: isReply ? 10 : 11),
                      ),
                    ],
                  ),
                ),
                if (isOwnComment)
                  GestureDetector(
                    onTap: () => _showDeleteDialog(comment),
                    child: Icon(Icons.more_horiz, color: AppColors.textMuted(context), size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Content
            SpoilerText(
              text: displayContent,
              isSpoiler: isSpoiler,
            ),
            const SizedBox(height: 8),
            // Actions: like + reply
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (comment.isLikedByMe) {
                      context.read<CommentsCubit>().unlikeComment(
                        comment.id,
                        tmdbId: widget.tmdbId,
                        mediaType: widget.mediaType,
                        seasonNumber: widget.seasonNumber,
                        episodeNumber: widget.episodeNumber,
                      );
                    } else {
                      context.read<CommentsCubit>().likeComment(
                        comment.id,
                        tmdbId: widget.tmdbId,
                        mediaType: widget.mediaType,
                        seasonNumber: widget.seasonNumber,
                        episodeNumber: widget.episodeNumber,
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        comment.isLikedByMe ? Icons.favorite : Icons.favorite_outline,
                        color: comment.isLikedByMe ? AppColors.primary : AppColors.textMuted(context),
                        size: 16,
                      ),
                      if (comment.likesCount > 0) ...[
                        const SizedBox(width: 4),
                        Text('${comment.likesCount}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                if (!isReply)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<CommentsCubit>().setReplyingTo(comment.id, comment.username ?? 'User');
                      FocusScope.of(context).requestFocus();
                    },
                    child: Row(
                      children: [
                        Icon(Icons.reply, color: AppColors.textMuted(context), size: 16),
                        const SizedBox(width: 4),
                        Text('Reply', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                      ],
                    ),
                  ),
                if (isReply)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<CommentsCubit>().setReplyingTo(comment.parentId ?? comment.id, comment.username ?? 'User');
                      FocusScope.of(context).requestFocus();
                    },
                    child: Row(
                      children: [
                        Icon(Icons.reply, color: AppColors.textMuted(context), size: 16),
                        const SizedBox(width: 4),
                        Text('Reply', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(CommentModel comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted(ctx).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Comment', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<CommentsCubit>().deleteComment(
                  comment.id,
                  tmdbId: widget.tmdbId,
                  mediaType: widget.mediaType,
                  seasonNumber: widget.seasonNumber,
                  episodeNumber: widget.episodeNumber,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    final isLoggedIn = context.read<AuthCubit>().state is AuthAuthenticated;

    if (!isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text('Login to comment', style: TextStyle(color: AppColors.textMuted(context))),
          ),
        ),
      );
    }

    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        final isReplying = state is CommentsLoaded && state.replyingToId != null;
        final replyingTo = state is CommentsLoaded ? state.replyingToUsername : null;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            border: Border(top: BorderSide(color: AppColors.border(context))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Replying to indicator
              if (isReplying)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.reply, color: AppColors.electricPurple, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Replying to @$replyingTo',
                          style: TextStyle(color: AppColors.electricPurple, fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.read<CommentsCubit>().clearReplyingTo(),
                        child: Icon(Icons.close, color: AppColors.textMuted(context), size: 18),
                      ),
                    ],
                  ),
                ),
              // Spoiler toggle + character count
              Row(
                children: [
                  SpoilerToggle(
                    isSpoiler: _isSpoiler,
                    onChanged: (value) => setState(() => _isSpoiler = value),
                  ),
                  const Spacer(),
                  Text(
                    '${_commentController.text.length}/500',
                    style: TextStyle(
                      color: _commentController.text.length > 500 ? AppColors.error : AppColors.textMuted(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Input row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(color: AppColors.text(context), fontSize: 14),
                        maxLength: 500,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: _isSpoiler ? 'Add a spoiler comment...' : (isReplying ? 'Write a reply...' : 'Add a comment...'),
                          hintStyle: TextStyle(color: AppColors.textMuted(context), fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendComment,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
