import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    context.read<AchievementsCubit>().loadAchievements();
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
            child: GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(14),
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
          final filteredAchievements = _selectedCategory == 'all'
              ? state.achievements
              : state.achievements.where((a) => a.category == _selectedCategory).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AchievementsCubit>().loadAchievements();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProgressCard(context, state),
                  const SizedBox(height: 20),
                  _buildStatsRow(context, state),
                  const SizedBox(height: 20),
                  _buildCategoryTabs(context),
                  const SizedBox(height: 16),
                  _buildAchievementsGrid(context, filteredAchievements),
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

  Widget _buildProgressCard(BuildContext context, AchievementsLoaded state) {
    final unlocked = state.unlockedCount;
    final total = state.achievements.length;
    final progress = total > 0 ? unlocked / total : 0.0;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.electricPurple],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Center(
                  child: Text('$unlocked', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Achievements Unlocked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    const SizedBox(height: 4),
                    Text('$unlocked of $total unlocked', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
                  ],
                ),
              ),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AchievementsLoaded state) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Shows', state.totalShows.toString(), Icons.tv_rounded, const Color(0xFF6C63FF))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Movies', state.totalMovies.toString(), Icons.movie_rounded, const Color(0xFFE50914))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Episodes', state.totalEpisodes.toString(), Icons.play_circle_rounded, const Color(0xFF00D4FF))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Hours', state.totalHours.toString(), Icons.access_time_rounded, const Color(0xFFFFD93D))),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          Text(label, style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryTab('All', 'all', Icons.grid_view_rounded),
          _buildCategoryTab('Shows', 'shows', Icons.tv_rounded),
          _buildCategoryTab('Movies', 'movies', Icons.movie_rounded),
          _buildCategoryTab('Episodes', 'episodes', Icons.play_circle_rounded),
          _buildCategoryTab('Hours', 'hours', Icons.access_time_rounded),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String label, String value, IconData icon) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedCategory = value);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textMuted(context), size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context, List<Achievement> achievements) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(context, achievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      borderColor: achievement.isUnlocked ? achievement.color.withValues(alpha: 0.3) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: achievement.isUnlocked
                  ? achievement.color.withValues(alpha: 0.2)
                  : AppColors.cardBg(context),
            ),
            child: Center(
              child: Icon(
                achievement.icon,
                color: achievement.isUnlocked ? achievement.color : AppColors.textMuted(context),
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            achievement.title,
            style: TextStyle(
              color: achievement.isUnlocked ? AppColors.text(context) : AppColors.textMuted(context),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Description
          Text(
            achievement.description,
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Progress bar or checkmark
          if (achievement.isUnlocked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: achievement.color, size: 16),
                const SizedBox(width: 4),
                Text('Unlocked', style: TextStyle(color: achievement.color, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            )
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: AppColors.border(context),
                    valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${achievement.current}/${achievement.requirement}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 10)),
              ],
            ),
        ],
      ),
    );
  }
}
