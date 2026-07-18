import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../shared/widgets/glass_container.dart';
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/notifications_cubit.dart';
import '../../../../shared/services/supabase_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
          Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const Spacer(),
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context.read<NotificationsCubit>().markAllAsRead(),
                  child: const Text('Mark all read', style: TextStyle(color: AppColors.electricPurple)),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        if (state is NotificationsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is NotificationsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<NotificationsCubit>().loadNotifications(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is NotificationsLoaded) {
          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationsCubit>().loadNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _buildNotificationCard(context, notification);
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? '';
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final createdAt = notification['created_at'] != null ? DateTime.tryParse(notification['created_at']) ?? DateTime.now() : DateTime.now();
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    final avatarUrl = data['avatar_url'] as String?;
    final parentAvatarUrl = data['parent_avatar_url'] as String?;
    final followerId = data['follower_id'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        borderColor: isRead ? null : AppColors.electricPurple.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () {
            if (!isRead) {
              context.read<NotificationsCubit>().markAsRead(notification['id']);
            }
            _navigateToContent(context, notification);
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              _buildAvatar(context, type, avatarUrl, parentAvatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.text(context), fontWeight: isRead ? FontWeight.normal : FontWeight.w600, fontSize: 13)),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(body, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(timeago.format(createdAt), style: TextStyle(color: AppColors.textMuted(context), fontSize: 10)),
                        if (type == 'follow' && followerId != null) ...[
                          const Spacer(),
                          _buildFollowButton(context, followerId),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.electricPurple),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String type, String? avatarUrl, String? parentAvatarUrl) {
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    // Reply notification: show stacked avatars (replier + parent owner)
    if (type == 'comment_reply' && parentAvatarUrl != null && parentAvatarUrl.isNotEmpty) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          children: [
            // Parent owner avatar (back, bottom-right)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background(context), width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: parentAvatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(
                      color: AppColors.cardBg(context),
                      child: Icon(Icons.person, size: 16, color: AppColors.textMuted(context)),
                    ),
                  ),
                ),
              ),
            ),
            // Replier avatar (front, top-left)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background(context), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: ClipOval(
                  child: hasAvatar
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => _buildInitialAvatar(context, '?'),
                        )
                      : _buildInitialAvatar(context, '?'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Comment/Like/Follow: show single avatar or fallback to icon
    final iconData = _getIconForType(type);
    final iconColor = _getColorForType(type);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasAvatar ? null : iconColor.withValues(alpha: 0.15),
        border: hasAvatar ? Border.all(color: AppColors.border(context), width: 1) : null,
      ),
      child: hasAvatar
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => Icon(iconData, color: iconColor, size: 22),
              ),
            )
          : Icon(iconData, color: iconColor, size: 22),
    );
  }

  Widget _buildInitialAvatar(BuildContext context, String initial) {
    return Container(
      color: AppColors.cardBg(context),
      child: Center(
        child: Text(initial.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'new_episode': return Icons.new_releases;
      case 'new_movie': return Icons.movie;
      case 'follow':
      case 'new_follower': return Icons.person_add;
      case 'new_comment': return Icons.comment;
      case 'comment_like': return Icons.favorite;
      case 'comment_reply': return Icons.reply;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'new_episode': return AppColors.success;
      case 'new_movie': return AppColors.electricPurple;
      case 'follow':
      case 'new_follower': return const Color(0xFF00D4FF);
      case 'new_comment': return const Color(0xFF6C63FF);
      case 'comment_like': return AppColors.primary;
      case 'comment_reply': return const Color(0xFF6C63FF);
      default: return AppColors.warning;
    }
  }

  Widget _buildFollowButton(BuildContext context, String followerId) {
    return FutureBuilder<bool>(
      future: _checkIfFollowing(followerId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        if (isFollowing) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Following', style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
          );
        }
        return GestureDetector(
          onTap: () => _followBack(context, followerId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.electricPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Follow Back', style: TextStyle(color: AppColors.electricPurple, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Future<bool> _checkIfFollowing(String followerId) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return false;
    final supabase = context.read<SupabaseService>();
    return await supabase.isFollowing(authState.user.id, followerId);
  }

  Future<void> _followBack(BuildContext context, String followerId) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    HapticFeedback.lightImpact();
    try {
      final supabase = context.read<SupabaseService>();
      await supabase.followUser(authState.user.id, followerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Followed back!'), backgroundColor: AppColors.success),
        );
        // Refresh the notification to update the button
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to follow'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _navigateToContent(BuildContext context, Map<String, dynamic> notification) {
    final type = notification['type'] ?? '';
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final tmdbId = data['tmdb_id'];
    final followerId = data['follower_id'];
    final userId = data['user_id'];
    final mediaType = data['media_type'] ?? 'tv';
    final seasonNumber = data['season_number'];
    final episodeNumber = data['episode_number'];
    final title = data['title'] as String?;

    switch (type) {
      case 'new_episode':
      case 'new_movie':
        if (tmdbId != null) {
          context.push(mediaType == 'movie' ? '/movie/$tmdbId' : '/show/$tmdbId');
        }
        break;
      case 'new_comment':
      case 'comment_like':
      case 'comment_reply':
        if (tmdbId != null) {
          context.push('/comments', extra: {
            'tmdbId': tmdbId,
            'mediaType': mediaType,
            'seasonNumber': seasonNumber,
            'episodeNumber': episodeNumber,
            'title': title,
          });
        }
        break;
      case 'follow':
      case 'new_follower':
        final uid = followerId ?? userId;
        if (uid != null) {
          context.push('/user/$uid');
        }
        break;
    }
  }
}
