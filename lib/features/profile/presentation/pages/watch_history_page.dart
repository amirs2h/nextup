import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../auth/domain/auth_cubit.dart';
import '../../domain/watch_history_cubit.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<WatchHistoryCubit>().loadHistory();
    }
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
          Text('Watch History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<WatchHistoryCubit, WatchHistoryState>(
      builder: (context, state) {
        if (state is WatchHistoryLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is WatchHistoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<WatchHistoryCubit>().loadHistory(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is WatchHistoryLoaded) {
          if (state.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No watch history yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Start watching to build your history', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadHistory();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.history.length,
              itemBuilder: (context, index) {
                final item = state.history[index];
                final tmdbId = item['tmdb_id'] as int;
                final mediaType = item['media_type'] as String;
                final watchedAt = item['watched_at'] != null ? DateTime.parse(item['watched_at']) : DateTime.now();
                final seasonNumber = item['season_number'];
                final episodeNumber = item['episode_number'];

                String title = '';
                String? posterUrl;

                if (mediaType == 'tv' && state.shows.containsKey(tmdbId)) {
                  title = state.shows[tmdbId]!.name;
                  posterUrl = state.shows[tmdbId]!.posterUrl;
                } else if (mediaType == 'movie' && state.movies.containsKey(tmdbId)) {
                  title = state.movies[tmdbId]!.title;
                  posterUrl = state.movies[tmdbId]!.posterUrl;
                }

                String subtitle = '';
                if (seasonNumber != null && episodeNumber != null) {
                  subtitle = 'S${seasonNumber}E${episodeNumber}';
                } else if (mediaType == 'movie') {
                  subtitle = 'Movie';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      if (mediaType == 'tv' && seasonNumber != null && episodeNumber != null) {
                        context.push('/show/$tmdbId/season/$seasonNumber/episode/$episodeNumber');
                      } else {
                        context.push(mediaType == 'tv' ? '/show/$tmdbId' : '/movie/$tmdbId');
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 85,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: posterUrl != null
                                ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Icon(Icons.movie, color: AppColors.textMuted(context)))
                                : Container(color: AppColors.cardBg(context), child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              if (subtitle.isNotEmpty)
                                Text(subtitle, style: TextStyle(color: AppColors.electricPurple, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(timeago.format(watchedAt), style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}














