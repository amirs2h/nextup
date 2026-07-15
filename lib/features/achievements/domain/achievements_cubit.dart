import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

enum AchievementRarity { common, rare, epic, legendary }

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requirement;
  final String category;
  final AchievementRarity rarity;
  final int xpReward;
  final bool isUnlocked;
  final int current;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirement,
    required this.category,
    required this.rarity,
    required this.xpReward,
    this.isUnlocked = false,
    this.current = 0,
    this.unlockedAt,
  });

  double get progress => requirement > 0 ? (current / requirement).clamp(0.0, 1.0) : 0.0;

  String get rarityLabel {
    switch (rarity) {
      case AchievementRarity.common: return 'Common';
      case AchievementRarity.rare: return 'Rare';
      case AchievementRarity.epic: return 'Epic';
      case AchievementRarity.legendary: return 'Legendary';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common: return const Color(0xFF9E9E9E);
      case AchievementRarity.rare: return const Color(0xFF2196F3);
      case AchievementRarity.epic: return const Color(0xFF9C27B0);
      case AchievementRarity.legendary: return const Color(0xFFFF9800);
    }
  }

  @override
  List<Object?> get props => [id, title, description, icon, color, requirement, category, rarity, xpReward, isUnlocked, current, unlockedAt];
}

abstract class AchievementsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AchievementsInitial extends AchievementsState {}

class AchievementsLoading extends AchievementsState {}

class AchievementsLoaded extends AchievementsState {
  final List<Achievement> achievements;
  final int totalShows;
  final int totalMovies;
  final int totalEpisodes;
  final int totalHours;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final int longestStreak;
  final int currentStreak;

  AchievementsLoaded({
    required this.achievements,
    this.totalShows = 0,
    this.totalMovies = 0,
    this.totalEpisodes = 0,
    this.totalHours = 0,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100,
    this.longestStreak = 0,
    this.currentStreak = 0,
  });

  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;
  int get totalXp => achievements.where((a) => a.isUnlocked).fold(0, (sum, a) => sum + a.xpReward);

  @override
  List<Object?> get props => [achievements, totalShows, totalMovies, totalEpisodes, totalHours, level, currentXp, xpToNextLevel, longestStreak, currentStreak];
}

class AchievementsError extends AchievementsState {
  final String message;
  AchievementsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AchievementsCubit extends Cubit<AchievementsState> {
  final SupabaseService _supabaseService;

  AchievementsCubit(this._supabaseService) : super(AchievementsInitial());

  Future<void> loadAchievements() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(AchievementsLoaded(achievements: _getAchievements(0, 0, 0, 0)));
      return;
    }

    if (isClosed) return;
    emit(AchievementsLoading());
    try {
      final results = await Future.wait([
        _supabaseService.getWatchHistory(userId: user.id),
        _supabaseService.getWatchlist(userId: user.id),
      ]);

      final history = results[0] as List<Map<String, dynamic>>;
      final watchlist = results[1] as List<Map<String, dynamic>>;

      int totalShows = 0;
      int totalMovies = 0;
      int totalEpisodes = 0;
      Set<String> showIds = {};
      Set<String> movieIds = {};
      Set<String> activeDays = {};

      for (final item in history) {
        if (item['media_type'] == 'tv') {
          showIds.add(item['tmdb_id'].toString());
          if (item['episode_number'] != null) {
            totalEpisodes++;
          }
        } else {
          movieIds.add(item['tmdb_id'].toString());
        }
        if (item['watched_at'] != null) {
          final date = DateTime.tryParse(item['watched_at']);
          if (date != null) {
            activeDays.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
          }
        }
      }

      totalShows = showIds.length;
      totalMovies = movieIds.length;
      final totalHours = (totalEpisodes * 45 + totalMovies * 120) ~/ 60;

      // Calculate streaks
      final sortedDays = activeDays.toList()..sort();
      int longestStreak = 0;
      int currentStreak = 0;
      int tempStreak = 1;
      for (int i = 1; i < sortedDays.length; i++) {
        final prev = DateTime.parse(sortedDays[i - 1]);
        final curr = DateTime.parse(sortedDays[i]);
        if (curr.difference(prev).inDays == 1) {
          tempStreak++;
        } else {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 1;
        }
      }
      if (tempStreak > longestStreak) longestStreak = tempStreak;

      final now = DateTime.now();
      currentStreak = 0;
      for (int i = 0; i < 365; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final checkKey = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (activeDays.contains(checkKey)) {
          currentStreak++;
        } else if (i > 0) {
          break;
        }
      }

      // Calculate level and XP
      final achievements = _getAchievements(totalShows, totalMovies, totalEpisodes, totalHours);
      final totalXp = achievements.where((a) => a.isUnlocked).fold(0, (sum, a) => sum + a.xpReward);
      final level = (totalXp / 100).floor() + 1;
      final currentXp = totalXp % 100;
      const xpToNextLevel = 100;

      if (isClosed) return;
      emit(AchievementsLoaded(
        achievements: achievements,
        totalShows: totalShows,
        totalMovies: totalMovies,
        totalEpisodes: totalEpisodes,
        totalHours: totalHours,
        level: level,
        currentXp: currentXp,
        xpToNextLevel: xpToNextLevel,
        longestStreak: longestStreak,
        currentStreak: currentStreak,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(AchievementsError('Something went wrong. Please try again.'));
    }
  }

  List<Achievement> _getAchievements(int shows, int movies, int episodes, int hours) {
    return [
      // ===== SHOWS =====
      Achievement(id: 'first_show', title: 'First Steps', description: 'Watch your first show', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 1, category: 'shows', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: shows >= 1, current: shows),
      Achievement(id: 'show_5', title: 'Show Lover', description: 'Watch 5 different shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 5, category: 'shows', rarity: AchievementRarity.common, xpReward: 25, isUnlocked: shows >= 5, current: shows),
      Achievement(id: 'show_10', title: 'Show Expert', description: 'Watch 10 different shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 10, category: 'shows', rarity: AchievementRarity.rare, xpReward: 50, isUnlocked: shows >= 10, current: shows),
      Achievement(id: 'show_25', title: 'Show Master', description: 'Watch 25 different shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 25, category: 'shows', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: shows >= 25, current: shows),
      Achievement(id: 'show_50', title: 'Show Legend', description: 'Watch 50 different shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 50, category: 'shows', rarity: AchievementRarity.legendary, xpReward: 250, isUnlocked: shows >= 50, current: shows),
      // ===== MOVIES =====
      Achievement(id: 'first_movie', title: 'Movie Night', description: 'Watch your first movie', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 1, category: 'movies', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: movies >= 1, current: movies),
      Achievement(id: 'movie_10', title: 'Movie Buff', description: 'Watch 10 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 10, category: 'movies', rarity: AchievementRarity.common, xpReward: 25, isUnlocked: movies >= 10, current: movies),
      Achievement(id: 'movie_25', title: 'Movie Addict', description: 'Watch 25 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 25, category: 'movies', rarity: AchievementRarity.rare, xpReward: 50, isUnlocked: movies >= 25, current: movies),
      Achievement(id: 'movie_50', title: 'Cinema King', description: 'Watch 50 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 50, category: 'movies', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: movies >= 50, current: movies),
      Achievement(id: 'movie_100', title: 'Movie Legend', description: 'Watch 100 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 100, category: 'movies', rarity: AchievementRarity.legendary, xpReward: 250, isUnlocked: movies >= 100, current: movies),
      // ===== EPISODES =====
      Achievement(id: 'episode_10', title: 'Getting Started', description: 'Watch 10 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 10, category: 'episodes', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: episodes >= 10, current: episodes),
      Achievement(id: 'episode_50', title: 'Binge Watcher', description: 'Watch 50 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 50, category: 'episodes', rarity: AchievementRarity.common, xpReward: 25, isUnlocked: episodes >= 50, current: episodes),
      Achievement(id: 'episode_100', title: 'Binge Master', description: 'Watch 100 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 100, category: 'episodes', rarity: AchievementRarity.rare, xpReward: 50, isUnlocked: episodes >= 100, current: episodes),
      Achievement(id: 'episode_500', title: 'Binge Legend', description: 'Watch 500 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 500, category: 'episodes', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: episodes >= 500, current: episodes),
      Achievement(id: 'episode_1000', title: 'Binge God', description: 'Watch 1000 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 1000, category: 'episodes', rarity: AchievementRarity.legendary, xpReward: 500, isUnlocked: episodes >= 1000, current: episodes),
      // ===== HOURS =====
      Achievement(id: 'hours_10', title: 'Just Started', description: 'Watch 10 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 10, category: 'hours', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: hours >= 10, current: hours),
      Achievement(id: 'hours_50', title: 'Regular Viewer', description: 'Watch 50 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 50, category: 'hours', rarity: AchievementRarity.common, xpReward: 25, isUnlocked: hours >= 50, current: hours),
      Achievement(id: 'hours_100', title: 'Dedicated Fan', description: 'Watch 100 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 100, category: 'hours', rarity: AchievementRarity.rare, xpReward: 50, isUnlocked: hours >= 100, current: hours),
      Achievement(id: 'hours_500', title: 'Time Master', description: 'Watch 500 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 500, category: 'hours', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: hours >= 500, current: hours),
      Achievement(id: 'hours_1000', title: 'Ultimate Fan', description: 'Watch 1000 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 1000, category: 'hours', rarity: AchievementRarity.legendary, xpReward: 500, isUnlocked: hours >= 1000, current: hours),
    ];
  }
}
