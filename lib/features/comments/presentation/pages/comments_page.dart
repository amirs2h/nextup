import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
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

  const CommentsPage({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg(context),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text('Comments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
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

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: state.comments.length,
            itemBuilder: (context, index) {
              final comment = state.comments[index];
              return _buildCommentCard(comment);
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    final userId = context.read<AuthCubit>().state is AuthAuthenticated
        ? (context.read<AuthCubit>().state as AuthAuthenticated).user.id
        : null;
    final isOwnComment = userId == comment.userId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.cardBg(context),
                  child: Text(
                    (comment.username ?? 'U').isNotEmpty ? (comment.username ?? 'U')[0].toUpperCase() : 'U',
                    style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.username ?? 'User',
                            style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600),
                          ),
                          if (comment.content.startsWith('[SPOILER]')) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD93D).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Spoiler', style: TextStyle(color: Color(0xFFFFD93D), fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        timeago.format(comment.createdAt),
                        style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isOwnComment)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () {
                      context.read<CommentsCubit>().deleteComment(
                        comment.id,
                        tmdbId: widget.tmdbId,
                        mediaType: widget.mediaType,
                        seasonNumber: widget.seasonNumber,
                        episodeNumber: widget.episodeNumber,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SpoilerText(
              text: comment.content.startsWith('[SPOILER] ') ? comment.content.substring(10) : comment.content,
              isSpoiler: comment.content.startsWith('[SPOILER]'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
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
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likesCount}',
                        style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    _commentController.text = '@${comment.username ?? 'User'} ';
                    FocusScope.of(context).requestFocus();
                  },
                  child: Row(
                    children: [
                      Icon(Icons.reply, color: AppColors.textMuted(context), size: 18),
                      const SizedBox(width: 4),
                      Text('Reply', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
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

  Widget _buildCommentInput() {
    final isLoggedIn = context.read<AuthCubit>().state is AuthAuthenticated;

    if (!isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Text('Login to comment', style: TextStyle(color: Colors.white54)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spoiler toggle
          Row(
            children: [
              SpoilerToggle(
                isSpoiler: _isSpoiler,
                onChanged: (value) => setState(() => _isSpoiler = value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Input row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: AppColors.text(context)),
                    decoration: InputDecoration(
                      hintText: _isSpoiler ? 'Add a spoiler comment...' : 'Add a comment...',
                      hintStyle: TextStyle(color: AppColors.textMuted(context)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (_commentController.text.trim().isNotEmpty) {
                    final content = _isSpoiler
                        ? '[SPOILER] ${_commentController.text.trim()}'
                        : _commentController.text.trim();
                    context.read<CommentsCubit>().addComment(
                      tmdbId: widget.tmdbId,
                      mediaType: widget.mediaType,
                      seasonNumber: widget.seasonNumber,
                      episodeNumber: widget.episodeNumber,
                      content: content,
                    );
                    _commentController.clear();
                    setState(() => _isSpoiler = false);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Icon(Icons.send, color: AppColors.text(context), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
