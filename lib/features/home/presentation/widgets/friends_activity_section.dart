import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
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
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, List<FriendActivity> activities) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(context, activities[index]);
        },
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, FriendActivity activity) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(activity.mediaType == 'movie' ? '/movie/${activity.tmdbId}' : '/show/${activity.tmdbId}');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    activity.posterPath != null && activity.posterPath!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppConfig.getImageUrl(activity.posterPath, size: 'w500'),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: AppColors.cardBg(context),
                              highlightColor: AppColors.cardBgStrong(context),
                              child: Container(color: AppColors.cardBg(context)),
                            ),
                            errorWidget: (c, u, e) => Container(
                              color: AppColors.cardBg(context),
                              child: Icon(Icons.movie_rounded, color: AppColors.iconMuted(context), size: 40),
                            ),
                          )
                        : Container(
                            color: AppColors.cardBg(context),
                            child: Icon(Icons.movie_rounded, color: AppColors.iconMuted(context), size: 40),
                          ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/user/${activity.userId}');
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: ClipOval(
                                child: activity.avatarUrl != null && activity.avatarUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: activity.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: (c, u, e) => Center(
                                          child: Text(activity.username.isNotEmpty ? activity.username[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      )
                                    : Center(
                                        child: Text(activity.username.isNotEmpty ? activity.username[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(activity.username, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    Icon(activity.activityIcon, color: activity.activityColor, size: 10),
                                    const SizedBox(width: 3),
                                    Text(activity.activityLabel, style: TextStyle(color: activity.activityColor, fontSize: 9, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (activity.rating != null && activity.rating! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 10),
                                  const SizedBox(width: 2),
                                  Text(activity.rating!.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(activity.title, style: TextStyle(color: AppColors.text(context), fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(activity.activityIcon, color: activity.activityColor, size: 12),
                const SizedBox(width: 4),
                Text('${activity.username} • ${_formatTimeAgo(activity.timestamp)}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
              ],
            ),
          ],
        ),
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
