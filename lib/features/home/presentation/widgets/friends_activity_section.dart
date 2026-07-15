import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
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
          return _buildEmptyState(context);
        }

        if (state is FriendsActivityLoaded) {
          return _buildActivityList(context, state.activities);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_rounded, color: Color(0xFF6C63FF), size: 18),
              ),
              const SizedBox(width: 10),
              Text('Friends Are Watching', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted(context)),
            const SizedBox(height: 12),
            Text('Friends Are Watching', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            const SizedBox(height: 8),
            Text('Follow other users to see what they\'re watching', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Find Users'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, List<FriendActivity> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_rounded, color: Color(0xFF6C63FF), size: 18),
              ),
              const SizedBox(width: 10),
              Text('Friends Are Watching', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _buildActivityCard(context, activities[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, FriendActivity activity) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(activity.mediaType == 'movie' ? '/movie/${activity.tmdbId}' : '/show/${activity.tmdbId}');
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster with activity badge
            Stack(
              children: [
                Container(
                  width: 160,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: activity.posterPath != null && activity.posterPath!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w300${activity.posterPath}',
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Container(
                              color: AppColors.cardBg(context),
                              child: Icon(Icons.movie_rounded, color: AppColors.textMuted(context)),
                            ),
                          )
                        : Container(
                            color: AppColors.cardBg(context),
                            child: Icon(Icons.movie_rounded, color: AppColors.textMuted(context)),
                          ),
                  ),
                ),
                // Activity badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: activity.activityColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activity.activityIcon, color: Colors.white, size: 10),
                        const SizedBox(width: 3),
                        Text(activity.activityLabel, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                // Rating badge (if rated)
                if (activity.rating != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 10),
                          const SizedBox(width: 2),
                          Text('${activity.rating}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Friend info
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/user/${activity.userId}');
                  },
                  child: Container(
                    width: 24,
                    height: 24,
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
                                child: Text(activity.username.isNotEmpty ? activity.username[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            )
                          : Center(
                              child: Text(activity.username.isNotEmpty ? activity.username[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.username, style: TextStyle(color: AppColors.text(context), fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(_formatTimeAgo(activity.timestamp), style: TextStyle(color: AppColors.textMuted(context), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Title
            Text(activity.title, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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
