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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLevelCard(context, state),
                  const SizedBox(height: 16),
                  _buildCategoryTabs(context),
                  const SizedBox(height: 16),
                  _buildAchievementsList(context, filteredAchievements),
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

  Widget _buildLevelCard(BuildContext context, AchievementsLoaded state) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.electricPurple]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Center(child: Text('${state.level}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${state.level}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    const SizedBox(height: 4),
                    Text('${state.unlockedCount}/${state.achievements.length} unlocked', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(height: 4),
                  Text('${state.currentStreak}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                  Text('streak', style: TextStyle(color: AppColors.textMuted(context), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${state.currentXp} XP', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
              Text('${state.xpToNextLevel} XP', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.currentXp / state.xpToNextLevel,
              backgroundColor: AppColors.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryTab('All', 'all', Icons.grid_view_rounded),
          _buildCategoryTab('Watching', 'watching', Icons.play_circle_rounded),
          _buildCategoryTab('Genre', 'genre', Icons.category_rounded),
          _buildCategoryTab('Country', 'country', Icons.flag_rounded),
          _buildCategoryTab('Watchlist', 'watchlist', Icons.bookmark_rounded),
          _buildCategoryTab('Time', 'time', Icons.access_time_rounded),
          _buildCategoryTab('Collection', 'collection', Icons.collections_rounded),
          _buildCategoryTab('Funny', 'funny', Icons.emoji_emotions_rounded),
          _buildCategoryTab('Seasonal', 'seasonal', Icons.celebration_rounded),
          _buildCategoryTab('Hidden', 'hidden', Icons.help_rounded),
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

  Widget _buildAchievementsList(BuildContext context, List<Achievement> achievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: achievements.map((achievement) => _buildAchievementCard(context, achievement)).toList(),
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(14),
        borderColor: achievement.isUnlocked ? achievement.color.withValues(alpha: 0.3) : null,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: achievement.isUnlocked ? achievement.color.withValues(alpha: 0.2) : AppColors.cardBg(context),
                boxShadow: achievement.isUnlocked ? [BoxShadow(color: achievement.color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: Center(
                child: Icon(achievement.icon, color: achievement.isUnlocked ? achievement.color : AppColors.textMuted(context), size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(achievement.title, style: TextStyle(color: achievement.isUnlocked ? AppColors.text(context) : AppColors.textMuted(context), fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: achievement.rarityColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(achievement.rarityLabel, style: TextStyle(color: achievement.rarityColor, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(achievement.description, style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                  const SizedBox(height: 6),
                  if (achievement.isUnlocked)
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: achievement.color, size: 14),
                        const SizedBox(width: 4),
                        Text('Unlocked', style: TextStyle(color: achievement.color, fontSize: 11, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('+${achievement.xpReward} XP', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: achievement.progress,
                              backgroundColor: AppColors.border(context),
                              valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${achievement.current}/${achievement.requirement}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 10)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
