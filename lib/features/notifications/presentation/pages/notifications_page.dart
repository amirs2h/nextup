import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/notifications_cubit.dart';

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
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
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
          Expanded(child: Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context)))),
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return GestureDetector(
                  onTap: () => context.read<NotificationsCubit>().markAllAsRead(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.electricPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('Mark all read', style: TextStyle(color: AppColors.electricPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
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
          if (state.grouped.isEmpty) {
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
            onRefresh: () async => context.read<NotificationsCubit>().loadNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.grouped.length,
              itemBuilder: (context, index) {
                final group = state.grouped[index];
                return _buildGroupedCard(context, group);
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildGroupedCard(BuildContext context, GroupedNotification group) {
    final hasPoster = group.posterPath != null && group.posterPath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateGrouped(context, group),
        child: GlassContainer(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(16),
          borderColor: group.isRead ? null : _getAccentColor(group.type).withValues(alpha: 0.3),
          child: Row(
            children: [
              // Left: Avatar(s)
              _buildGroupedAvatar(context, group),
              const SizedBox(width: 12),
              // Middle: Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupedTitle(context, group),
                    if (group.type == 'comment_like' && group.notifications.isNotEmpty)
                      _buildLikeCommentPreview(context, group),
                    if (group.type != 'comment_like' && group.notifications.first['body'] != null && (group.notifications.first['body'] as String).isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(group.notifications.first['body'], style: TextStyle(color: AppColors.textMuted(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Text(timeago.format(group.latestAt), style: TextStyle(color: AppColors.textMuted(context), fontSize: 10)),
                  ],
                ),
              ),
              // Right: Poster + unread dot
              if (hasPoster && _isContentType(group.type))
                GestureDetector(
                  onTap: () {
                    _markGroupAsRead(context, group);
                    if (group.tmdbId != null) {
                      context.push(group.mediaType == 'movie' ? '/movie/${group.tmdbId}' : '/show/${group.tmdbId}');
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: AppConfig.getImageUrl(group.posterPath, size: 'w92'),
                      width: 36,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(width: 36, height: 52, color: AppColors.cardBg(context)),
                    ),
                  ),
                ),
              if (!group.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _getAccentColor(group.type)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedAvatar(BuildContext context, GroupedNotification group) {
    // Stacked avatars for grouped notifications (max 3)
    if (group.avatarUrls.length >= 2) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          children: [
            // Third avatar (back, bottom-left)
            if (group.avatarUrls.length >= 3)
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.background(context), width: 2)),
                  child: ClipOval(child: CachedNetworkImage(imageUrl: group.avatarUrls[2], fit: BoxFit.cover, errorWidget: (c, u, e) => _buildInitial(context, group.usernames.length > 2 ? group.usernames[2] : '?'))),
                ),
              ),
            // Second avatar (back, bottom-right)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.background(context), width: 2)),
                child: ClipOval(child: CachedNetworkImage(imageUrl: group.avatarUrls[1], fit: BoxFit.cover, errorWidget: (c, u, e) => _buildInitial(context, group.usernames.length > 1 ? group.usernames[1] : '?'))),
              ),
            ),
            // First avatar (front, top-center)
            Positioned(
              left: 8,
              top: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background(context), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: ClipOval(child: CachedNetworkImage(imageUrl: group.avatarUrls[0], fit: BoxFit.cover, errorWidget: (c, u, e) => _buildInitial(context, group.usernames.isNotEmpty ? group.usernames[0] : '?'))),
              ),
            ),
          ],
        ),
      );
    }

    // Single avatar
    final avatarUrl = group.avatarUrls.isNotEmpty ? group.avatarUrls[0] : null;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final iconData = _getIconForType(group.type);
    final iconColor = _getAccentColor(group.type);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasAvatar ? null : iconColor.withValues(alpha: 0.15),
        border: hasAvatar ? Border.all(color: AppColors.border(context), width: 1) : null,
      ),
      child: hasAvatar
          ? ClipOval(child: CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => Icon(iconData, color: iconColor, size: 22)))
          : Icon(iconData, color: iconColor, size: 22),
    );
  }

  Widget _buildGroupedTitle(BuildContext context, GroupedNotification group) {
    final count = group.notifications.length;
    final accentColor = _getAccentColor(group.type);

    if (count == 1) {
      // Single notification - show full title
      final title = group.notifications.first['title'] ?? '';
      return _buildRichTitle(context, title, group);
    }

    // Grouped - show "X, Y and N others"
    final names = group.usernames.take(2).toList();
    final remaining = count - names.length;

    String namesText;
    if (names.length == 2) {
      namesText = '${names[0]}، ${names[1]} و $remaining نفر دیگه';
    } else if (names.length == 1) {
      namesText = '${names[0]} و ${count - 1} نفر دیگه';
    } else {
      namesText = '$count نفر';
    }

    String action;
    switch (group.type) {
      case 'comment_like':
        action = 'کامنت شما رو لایک کردن';
        break;
      case 'new_comment':
        action = 'کامنت گذاشتن';
        break;
      case 'comment_reply':
        action = 'جواب کامنت شما رو دادن';
        break;
      case 'follow':
        action = 'شما رو فالو کردن';
        break;
      default:
        action = 'فعالیت داشتن';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(namesText, style: TextStyle(color: AppColors.text(context), fontWeight: group.isRead ? FontWeight.normal : FontWeight.w600, fontSize: 13)),
        Text(action, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRichTitle(BuildContext context, String fullTitle, GroupedNotification group) {
    final isCommentType = _isContentType(group.type);
    final contentTitle = group.contentTitle;

    if (!isCommentType || contentTitle == null || contentTitle.isEmpty) {
      return Text(fullTitle, style: TextStyle(color: AppColors.text(context), fontWeight: group.isRead ? FontWeight.normal : FontWeight.w600, fontSize: 13));
    }

    final idx = fullTitle.indexOf(' on ');
    if (idx == -1) {
      return Text(fullTitle, style: TextStyle(color: AppColors.text(context), fontWeight: group.isRead ? FontWeight.normal : FontWeight.w600, fontSize: 13));
    }

    final beforeOn = fullTitle.substring(0, idx);
    final afterOn = fullTitle.substring(idx + 4);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(color: AppColors.textMuted(context), fontSize: 13, height: 1.3),
        children: [
          TextSpan(text: beforeOn, style: TextStyle(color: AppColors.text(context), fontWeight: group.isRead ? FontWeight.normal : FontWeight.w600, fontSize: 13)),
          TextSpan(text: ' on ', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
          TextSpan(
            text: afterOn,
            style: TextStyle(color: _getAccentColor(group.type), fontWeight: FontWeight.w600, fontSize: 13),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _markGroupAsRead(context, group);
                if (group.tmdbId != null) {
                  context.push(group.mediaType == 'movie' ? '/movie/${group.tmdbId}' : '/show/${group.tmdbId}');
                }
              },
          ),
        ],
      ),
    );
  }

  Widget _buildLikeCommentPreview(BuildContext context, GroupedNotification group) {
    final body = group.notifications.first['body'] as String? ?? '';
    if (body.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD93D).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFD93D).withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.format_quote_rounded, color: Color(0xFFFFD93D), size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(body, style: TextStyle(color: AppColors.textMuted(context), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(BuildContext context, String initial) {
    return Container(
      color: AppColors.cardBg(context),
      child: Center(
        child: Text(initial.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      ),
    );
  }

  bool _isContentType(String type) {
    return type == 'new_comment' || type == 'comment_like' || type == 'comment_reply';
  }

  Color _getAccentColor(String type) {
    switch (type) {
      case 'new_episode': return AppColors.success;
      case 'new_movie': return AppColors.electricPurple;
      case 'follow':
      case 'new_follower': return const Color(0xFF00D4FF);
      case 'new_comment': return const Color(0xFF6C63FF);
      case 'comment_like': return const Color(0xFFFFD93D);
      case 'comment_reply': return const Color(0xFF6C63FF);
      default: return AppColors.warning;
    }
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

  void _markGroupAsRead(BuildContext context, GroupedNotification group) {
    if (!group.isRead) {
      final unreadIds = group.notifications
          .where((n) => n['is_read'] != true)
          .map((n) => n['id'] as String)
          .toList();
      if (unreadIds.isNotEmpty) {
        context.read<NotificationsCubit>().markGroupAsRead(unreadIds);
      }
    }
  }

  void _navigateGrouped(BuildContext context, GroupedNotification group) {
    _markGroupAsRead(context, group);

    switch (group.type) {
      case 'new_episode':
      case 'new_movie':
        if (group.tmdbId != null) {
          context.push(group.mediaType == 'movie' ? '/movie/${group.tmdbId}' : '/show/${group.tmdbId}');
        }
        break;
      case 'new_comment':
      case 'comment_like':
      case 'comment_reply':
        if (group.tmdbId != null) {
          context.push('/comments', extra: {
            'tmdbId': group.tmdbId,
            'mediaType': group.mediaType ?? 'tv',
            'seasonNumber': group.notifications.first['data']?['season_number'],
            'episodeNumber': group.notifications.first['data']?['episode_number'],
            'title': group.contentTitle,
            'posterPath': group.posterPath,
            'commentId': group.commentId,
          });
        }
        break;
      case 'follow':
      case 'new_follower':
        final data = group.notifications.first['data'] as Map<String, dynamic>? ?? {};
        final uid = data['follower_id'] ?? data['user_id'];
        if (uid != null) {
          context.push('/user/$uid');
        }
        break;
    }
  }
}
