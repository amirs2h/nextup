import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/season_detail_cubit.dart';
import '../../../../shared/mixins/toggle_lock_mixin.dart';

class SeasonDetailPage extends StatelessWidget {
  final int showId;
  final int seasonNumber;

  const SeasonDetailPage({
    super.key,
    required this.showId,
    required this.seasonNumber,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SeasonDetailCubit(
        context.read<TmdbService>(),
        context.read<SupabaseService>(),
        showId,
        seasonNumber,
      ),
      child: _SeasonDetailView(showId: showId, seasonNumber: seasonNumber),
    );
  }
}

class _SeasonDetailView extends StatefulWidget {
  final int showId;
  final int seasonNumber;

  const _SeasonDetailView({required this.showId, required this.seasonNumber});

  @override
  State<_SeasonDetailView> createState() => _SeasonDetailViewState();
}

class _SeasonDetailViewState extends State<_SeasonDetailView> with ToggleLockMixin {
  bool _isMarkingAll = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeasonDetailCubit, SeasonDetailState>(
      builder: (context, state) {
        if (state is SeasonDetailLoading) {
          return Scaffold(body: AppBackground(child: const Center(child: CircularProgressIndicator(color: AppColors.primary))));
        }

        if (state is SeasonDetailError) {
          return Scaffold(
            body: AppBackground(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SeasonDetailCubit>().loadSeasonDetails(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is! SeasonDetailLoaded) {
          return Scaffold(body: AppBackground(child: const SizedBox()));
        }

        return Scaffold(
          body: AppBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, state),
                  _buildProgress(context, state),
                  Expanded(child: _buildEpisodeList(context, state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, SeasonDetailLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.season.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                Text('${state.season.episodes?.length ?? 0} episodes', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: AppColors.surface(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Mark All Episodes'),
                  content: const Text('Mark all episodes in this season as watched?'),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface(context),
                        foregroundColor: AppColors.text(context),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('Cancel', style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: _isMarkingAll ? null : () async {
                        Navigator.pop(dialogContext);
                        setState(() => _isMarkingAll = true);
                        try {
                          await context.read<SeasonDetailCubit>().markAllEpisodes();
                        } finally {
                          if (mounted) setState(() => _isMarkingAll = false);
                        }
                      },
                      child: _isMarkingAll
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Mark All', style: TextStyle(color: AppColors.electricPurple)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Mark All'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, SeasonDetailLoaded state) {
    final total = state.season.episodes?.length ?? 0;
    final watched = state.watchedEpisodes.values.where((v) => v).length;
    final progress = total > 0 ? watched / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$watched of $total watched', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.cardBg(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeList(BuildContext context, SeasonDetailLoaded state) {
    final episodes = state.season.episodes;
    if (episodes == null || episodes.isEmpty) {
      return Center(child: Text('No episodes available', style: TextStyle(color: AppColors.textMuted(context))));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final isWatched = state.watchedEpisodes[episode.episodeNumber] ?? false;
        return _buildEpisodeCard(context, episode, isWatched);
      },
    );
  }

  Widget _buildEpisodeCard(BuildContext context, EpisodeModel episode, bool isWatched) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      borderColor: isWatched ? AppColors.success.withValues(alpha: 0.3) : null,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/show/${widget.showId}/season/${widget.seasonNumber}/episode/${episode.episodeNumber}'),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 68,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.cardBg(context)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: episode.stillUrl != null
                        ? CachedNetworkImage(imageUrl: episode.stillUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Center(child: Icon(Icons.play_circle_outline, color: AppColors.iconMuted(context))))
                        : Center(child: Icon(Icons.play_circle_outline, color: AppColors.iconMuted(context))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E${episode.episodeNumber} • ${episode.name}',
                        style: TextStyle(color: isWatched ? AppColors.textMuted(context) : AppColors.text(context), fontWeight: FontWeight.w500, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (episode.runtime != null) ...[
                        const SizedBox(height: 4),
                        Text('${episode.runtime} min', style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => withToggleLock(() => context.read<SeasonDetailCubit>().toggleEpisodeWatched(episode.episodeNumber)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWatched ? AppColors.success.withValues(alpha: 0.2) : AppColors.cardBg(context),
                      border: Border.all(color: isWatched ? AppColors.success : AppColors.border(context)),
                    ),
                    child: Icon(Icons.check, color: isWatched ? AppColors.success : AppColors.iconMuted(context), size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Comments and Reactions
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                // TMDB Rating
                if (episode.voteAverage > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                        const SizedBox(width: 4),
                          Text(episode.voteAverage.toStringAsFixed(1), 
                            style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Comments button
                GestureDetector(
                  onTap: () => context.push('/comments', extra: {
                  'tmdbId': widget.showId,
                  'mediaType': 'tv',
                  'seasonNumber': widget.seasonNumber,
                    'episodeNumber': episode.episodeNumber,
                    'title': episode.name,
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, color: AppColors.textMuted(context), size: 16),
                        const SizedBox(width: 6),
                          Text('Comments', style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reactions
                ...['🔥', '😂', '😭', '❤️'].map((emoji) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () async {
                      final supabase = context.read<SupabaseService>();
                      final user = supabase.currentUser;
                      if (user != null) {
                        try {
                          await supabase.addReaction(
                            userId: user.id,
                            tmdbId: widget.showId,
                            seasonNumber: widget.seasonNumber,
                            episodeNumber: episode.episodeNumber,
                            emoji: emoji,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reacted with $emoji'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Failed to add reaction'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
