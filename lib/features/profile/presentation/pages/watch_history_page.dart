import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../auth/domain/auth_cubit.dart';
import '../../../../core/config/app_config.dart';

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
    _loadHistory();
  }

  void _loadHistory() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<WatchHistoryCubit>().loadHistory();
    }
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
              Expanded(
                child: BlocBuilder<WatchHistoryCubit, WatchHistoryState>(
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
                            ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
                          ],
                        ),
                      );
                    }

                    if (state is WatchHistoryLoaded) {
                      if (state.groupedHistory.isEmpty) {
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: state.groupedHistory.length,
                          itemBuilder: (context, index) {
                            final item = state.groupedHistory[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => context.push(item.mediaType == 'movie' ? '/movie/${item.tmdbId}' : '/show/${item.tmdbId}'),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(12),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Row(
                                    children: [
                                      // Poster
                                      Container(
                                        width: 60,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: AppColors.cardBg(context),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: item.posterPath != null && item.posterPath!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: AppConfig.getImageUrl(item.posterPath, size: 'w154'),
                                                  fit: BoxFit.cover,
                                                  errorWidget: (c, u, e) => Center(child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                                                )
                                              : Center(child: Icon(Icons.movie, color: AppColors.textMuted(context))),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            if (item.mediaType == 'tv' && item.latestSeason != null && item.latestEpisode != null)
                                              Text(
                                                'S${item.latestSeason} E${item.latestEpisode}',
                                                style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13),
                                              ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (item.mediaType == 'tv') ...[
                                                  Icon(Icons.play_circle_outline, color: AppColors.textMuted(context), size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${item.episodeCount} episodes',
                                                    style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 12),
                                                ],
                                                Icon(Icons.access_time, color: AppColors.textMuted(context), size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatTimeAgo(item.latestWatchedAt),
                                                  style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ),
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

  String _formatTimeAgo(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'en');
  }
}
