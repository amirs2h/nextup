import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/activity_cubit.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityCubit>().loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
          ],
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
            onTap: () => Navigator.pop(context),
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
          Text('Activity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        if (state is ActivityLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }

        if (state is ActivityError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
              ],
            ),
          );
        }

        if (state is ActivityLoaded) {
          if (state.activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No activity yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Follow people to see their activity', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.activities.length,
            itemBuilder: (context, index) {
              final activity = state.activities[index];
              return _buildActivityCard(context, activity);
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> activity) {
    final username = activity['username'] ?? 'User';
    final tmdbId = activity['tmdb_id'];
    final mediaType = activity['media_type'] ?? 'tv';
    final seasonNumber = activity['season_number'];
    final episodeNumber = activity['episode_number'];
    final watchedAt = activity['watched_at'] != null ? DateTime.parse(activity['watched_at']) : DateTime.now();

    String action;
    IconData icon;
    Color iconColor;

    if (mediaType == 'tv') {
      if (seasonNumber != null && episodeNumber != null) {
        action = 'watched S${seasonNumber}E${episodeNumber}';
        icon = Icons.play_circle;
        iconColor = const Color(0xFF00FF88);
      } else {
        action = 'started watching';
        icon = Icons.tv;
        iconColor = const Color(0xFF6C63FF);
      }
    } else {
      action = 'watched';
      icon = Icons.movie;
      iconColor = const Color(0xFFE50914);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push(mediaType == 'tv' ? '/show/$tmdbId' : '/movie/$tmdbId'),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.cardBg(context),
                child: Text(username[0].toUpperCase(), style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: AppColors.text(context), fontSize: 14),
                        children: [
                          TextSpan(text: username, style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: ' $action', style: TextStyle(color: AppColors.textSecondary(context))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(timeago.format(watchedAt), style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
