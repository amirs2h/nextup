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
                  const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Row(
            children: [
              // Stats
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildMiniStat(Icons.tv_rounded, state.totalShows.toString(), const Color(0xFF6C63FF)),
                        const SizedBox(width: 16),
                        _buildMiniStat(Icons.movie_rounded, state.totalMovies.toString(), const Color(0xFFE50914)),
                        const SizedBox(width: 16),
                        _buildMiniStat(Icons.play_circle_rounded, state.totalEpisodes.toString(), const Color(0xFF00D4FF)),
                        const SizedBox(width: 16),
                        _buildMiniStat(Icons.access_time_rounded, state.totalHours.toString(), const Color(0xFFFFD93D)),
                      ],
                    ),
                  ],
                ),
              ),
              // Progress circle
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.border(context),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 6,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$unlocked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                        Text('of $total', style: TextStyle(fontSize: 11, color: AppColors.textMuted(context))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context))),
      ],
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    return SizedBox(
      height: 36,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.textMuted(context), size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary(context), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 12)),
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
        childAspectRatio: 1.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(context, achievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
      borderColor: achievement.isUnlocked ? achievement.color.withValues(alpha: 0.3) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
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
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            achievement.title,
            style: TextStyle(
              color: achievement.isUnlocked ? AppColors.text(context) : AppColors.textMuted(context),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Description
          Text(
            achievement.description,
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Progress or checkmark
          if (achievement.isUnlocked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: achievement.color, size: 14),
                const SizedBox(width: 4),
                Text('Unlocked', style: TextStyle(color: achievement.color, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            )
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    backgroundColor: AppColors.border(context),
                    valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
                    minHeight: 3,
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
