import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/achievements_cubit.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AchievementsCubit>().loadAchievements();
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
          Text('Achievements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<AchievementsCubit, AchievementsState>(
      builder: (context, state) {
        if (state is AchievementsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is AchievementsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AchievementsCubit>().loadAchievements(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is AchievementsLoaded) {
          final unlocked = state.achievements.where((a) => a.isUnlocked).length;
          final total = state.achievements.length;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AchievementsCubit>().loadAchievements();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProgressCard(context, unlocked, total),
                  const SizedBox(height: 24),
                  _buildStatsRow(context, state),
                  const SizedBox(height: 24),
                  _buildAchievementsList(context, state.achievements),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildProgressCard(BuildContext context, int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
              Text('$unlocked/$total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% complete', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AchievementsLoaded state) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Shows', state.totalShows.toString(), Icons.tv, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Movies', state.totalMovies.toString(), Icons.movie, AppColors.electricPurple)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Hours', state.totalHours.toString(), Icons.access_time, AppColors.warning)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(BuildContext context, List<Achievement> achievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 12),
        ...achievements.map((achievement) => _buildAchievementCard(context, achievement)),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        borderColor: achievement.isUnlocked ? AppColors.success.withOpacity(0.3) : null,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 24,
                    color: achievement.isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
                  ),
                ],
              ),
            ),
            if (achievement.isUnlocked)
              const Icon(Icons.check_circle, color: AppColors.success, size: 24)
            else
              Icon(Icons.lock_outline, color: AppColors.textMuted(context), size: 24),
          ],
        ),
      ),
    );
  }
}














