import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/rankings_cubit.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<RankingsCubit>().loadRankings();
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
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              Text('Friend Rankings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<RankingsCubit, RankingsState>(
      builder: (context, state) {
        if (state is RankingsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is RankingsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<RankingsCubit>().loadRankings(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is RankingsLoaded) {
          if (state.rankings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_outlined, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No rankings yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Follow people to see rankings', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<RankingsCubit>().loadRankings();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.rankings.length,
              itemBuilder: (context, index) {
              final rank = state.rankings[index];
              final username = (rank['username'] as String?)?.isNotEmpty == true ? rank['username'] : 'User';
              final avatarUrl = rank['avatar_url'];
              final totalHours = rank['total_hours'] ?? '0';
              final isMe = rank['is_me'] ?? false;
              final position = index + 1;

              Color rankColor;
              IconData? rankIcon;
              if (position == 1) {
                rankColor = AppColors.warning;
                rankIcon = Icons.emoji_events;
              } else if (position == 2) {
                rankColor = const Color(0xFFC0C0C0);
                rankIcon = Icons.emoji_events;
              } else if (position == 3) {
                rankColor = const Color(0xFFCD7F32);
                rankIcon = Icons.emoji_events;
              } else {
                rankColor = AppColors.textMuted(context);
                rankIcon = null;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
                  borderColor: isMe ? AppColors.electricPurple : null,
                  child: Row(
                    children: [
                      // Rank position
                      SizedBox(
                        width: 36,
                        child: rankIcon != null
                            ? Icon(rankIcon, color: rankColor, size: 28)
                            : Text('#$position', style: TextStyle(color: rankColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isMe 
                                ? [AppColors.electricPurple, AppColors.neonPurple]
                                : [AppColors.primary, const Color(0xFFFF3D47)],
                          ),
                        ),
                        child: avatarUrl != null
                            ? ClipOval(child: CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))
                            : Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? '$username (You)' : username,
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 15,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hours
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${totalHours}h',
                            style: TextStyle(
                              color: isMe ? AppColors.electricPurple : AppColors.text(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('watched', style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                        ],
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














