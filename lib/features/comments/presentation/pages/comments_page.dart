import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E)],
          ),
        ),
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
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Comments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }

        if (state is CommentsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
                const SizedBox(height: 16),
                Text(state.message, style: const TextStyle(color: Colors.white70)),
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
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No comments yet', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Be the first to comment!', style: TextStyle(color: Colors.white.withOpacity(0.3))),
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
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: Text(
                    (comment.username ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.username ?? 'User',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        timeago.format(comment.createdAt),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isOwnComment)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4757), size: 20),
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
              text: comment.content,
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
                        color: comment.isLikedByMe ? const Color(0xFFE50914) : Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likesCount}',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
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
                      Icon(Icons.reply, color: Colors.white.withOpacity(0.5), size: 18),
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
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spoiler toggle
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isSpoiler = !_isSpoiler),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isSpoiler ? const Color(0xFFFFD93D).withOpacity(0.2) : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isSpoiler ? const Color(0xFFFFD93D) : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _isSpoiler ? const Color(0xFFFFD93D) : Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Spoiler',
                        style: TextStyle(
                          color: _isSpoiler ? const Color(0xFFFFD93D) : Colors.white54,
                          fontSize: 12,
                          fontWeight: _isSpoiler ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isSpoiler ? 'Add a spoiler comment...' : 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
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
                    gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFFF3D47)]),
                    boxShadow: [BoxShadow(color: const Color(0xFFE50914).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
