import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/friends_activity_cubit.dart';

class FriendsActivitySection extends StatelessWidget {
  const FriendsActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsActivityCubit, FriendsActivityState>(
      builder: (context, state) {
        if (state is FriendsActivityLoading) {
          return _buildLoadingState(context);
        }

        if (state is FriendsActivityEmpty) {
          return const SizedBox();
        }

        if (state is FriendsActivityLoaded) {
          return _buildActivityList(context, state.activities);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.cardBg(context),
            highlightColor: AppColors.cardBgStrong(context),
            child: Container(
              width: 260,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, List<FriendActivity> activities) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return _buildGlassActivityCard(context, activities[index]);
        },
      ),
    );
  }

  Widget _buildGlassActivityCard(BuildContext context, FriendActivity activity) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(activity.mediaType == 'movie' ? '/movie/${activity.tmdbId}' : '/show/${activity.tmdbId}');
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(10),
          useBlur: true,
          child: Row(
            children: [
              _buildPoster(context, activity),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo(context, activity)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context, FriendActivity activity) {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: activity.posterPath != null && activity.posterPath!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: AppConfig.getImageUrl(activity.posterPath, size: 'w185'),
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColors.cardBg(context),
                  highlightColor: AppColors.cardBgStrong(context),
                  child: Container(color: AppColors.cardBg(context)),
                ),
                errorWidget: (c, u, e) => Container(
                  color: AppColors.cardBg(context),
                  child: Icon(Icons.movie_rounded, color: AppColors.iconMuted(context), size: 20),
                ),
              )
            : Container(
                color: AppColors.cardBg(context),
                child: Icon(Icons.movie_rounded, color: AppColors.iconMuted(context), size: 20),
              ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, FriendActivity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top row: avatar + username + activity badge
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/user/${activity.userId}');
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border(context), width: 1),
                ),
                child: ClipOval(
                  child: activity.avatarUrl != null && activity.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: activity.avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Center(
                            child: Text(
                              activity.username.isNotEmpty ? activity.username[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            activity.username.isNotEmpty ? activity.username[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                activity.username,
                style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _buildActivityBadge(context, activity),
          ],
        ),
        const SizedBox(height: 6),
        // Title
        Text(
          activity.title,
          style: TextStyle(color: AppColors.text(context), fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // Bottom row: rating (if exists) + time ago
        Row(
          children: [
            if (activity.rating != null && activity.rating! > 0) ...[
              _buildRatingBadge(context, activity),
              const SizedBox(width: 8),
            ],
            Icon(Icons.access_time_rounded, color: AppColors.textMuted(context), size: 11),
            const SizedBox(width: 3),
            Text(
              _formatTimeAgo(activity.timestamp),
              style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityBadge(BuildContext context, FriendActivity activity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: activity.activityColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: activity.activityColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(activity.activityIcon, color: activity.activityColor, size: 10),
          const SizedBox(width: 3),
          Text(
            activity.activityLabel,
            style: TextStyle(color: activity.activityColor, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context, FriendActivity activity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD93D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 11),
          const SizedBox(width: 2),
          Text(
            activity.rating!.toStringAsFixed(1),
            style: const TextStyle(color: Color(0xFFFFD93D), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 3),
          Text(
            "${activity.username}'s",
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 9, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
