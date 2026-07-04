import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/tmdb_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/models/show_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/season_detail_cubit.dart';

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

class _SeasonDetailView extends StatelessWidget {
  final int showId;
  final int seasonNumber;

  const _SeasonDetailView({required this.showId, required this.seasonNumber});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeasonDetailCubit, SeasonDetailState>(
      builder: (context, state) {
        if (state is SeasonDetailLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))));
        }

        if (state is SeasonDetailError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SeasonDetailCubit>().loadSeasonDetails(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! SeasonDetailLoaded) {
          return const Scaffold(body: SizedBox());
        }

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
                  _buildHeader(context, state),
                  _buildProgress(state),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.season.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${state.season.episodes?.length ?? 0} episodes', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => context.read<SeasonDetailCubit>().markAllEpisodes(),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Mark All'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(SeasonDetailLoaded state) {
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
              Text('$watched of $total watched', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
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
      return Center(child: Text('No episodes available', style: TextStyle(color: Colors.white.withOpacity(0.5))));
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isWatched ? const Color(0xFF00FF88).withOpacity(0.3) : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 120,
                  height: 68,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withOpacity(0.1)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: episode.stillUrl != null
                        ? CachedNetworkImage(imageUrl: episode.stillUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Center(child: Icon(Icons.play_circle_outline, color: Colors.white24)))
                        : const Center(child: Icon(Icons.play_circle_outline, color: Colors.white24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E${episode.episodeNumber} • ${episode.name}',
                        style: TextStyle(color: isWatched ? Colors.white54 : Colors.white, fontWeight: FontWeight.w500, decoration: isWatched ? TextDecoration.lineThrough : null),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (episode.runtime != null) ...[
                        const SizedBox(height: 4),
                        Text('${episode.runtime} min', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.read<SeasonDetailCubit>().toggleEpisodeWatched(episode.episodeNumber),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWatched ? const Color(0xFF00FF88).withOpacity(0.2) : Colors.white.withOpacity(0.08),
                      border: Border.all(color: isWatched ? const Color(0xFF00FF88) : Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.check, color: isWatched ? const Color(0xFF00FF88) : Colors.white24, size: 20),
                  ),
                ),
              ],
            ),
            // Comments and Reactions for this episode
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  // Comments button
                  GestureDetector(
                    onTap: () => context.push('/comments', extra: {
                      'tmdbId': showId,
                      'mediaType': 'tv',
                      'seasonNumber': seasonNumber,
                      'episodeNumber': episode.episodeNumber,
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Colors.white.withOpacity(0.5), size: 16),
                          const SizedBox(width: 6),
                          Text('Comments', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reactions
                  ...['🔥', '😂', '😭', '❤️'].map((emoji) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Add reaction
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
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
      ),
    );
  }
}
