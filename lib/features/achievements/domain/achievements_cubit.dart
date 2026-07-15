import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';

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
  final bool isHidden;

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
    this.isHidden = false,
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
  List<Object?> get props => [id, title, description, icon, color, requirement, category, rarity, xpReward, isUnlocked, current, isHidden];
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
  final TmdbService _tmdbService;

  AchievementsCubit(this._supabaseService, this._tmdbService) : super(AchievementsInitial());

  Future<void> loadAchievements() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(AchievementsLoaded(achievements: []));
      return;
    }

    if (isClosed) return;
    emit(AchievementsLoading());
    try {
      final results = await Future.wait([
        _supabaseService.getWatchHistory(userId: user.id),
        _supabaseService.getWatchlist(userId: user.id),
        _supabaseService.getFavorites(userId: user.id),
      ]);

      final history = results[0] as List<Map<String, dynamic>>;
      final watchlist = results[1] as List<Map<String, dynamic>>;
      final favorites = results[2] as List<Map<String, dynamic>>;

      // Calculate stats
      int totalShows = 0;
      int totalMovies = 0;
      int totalEpisodes = 0;
      Set<String> showIds = {};
      Set<String> movieIds = {};
      Set<String> activeDays = {};
      Map<String, int> genreCounts = {};
      Map<String, int> countryCounts = {};

      for (final item in history) {
        if (item['media_type'] == 'tv') {
          showIds.add(item['tmdb_id'].toString());
          if (item['episode_number'] != null) totalEpisodes++;
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
      int currentStreak = 0;
      for (int i = 0; i < 365; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final checkKey = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (activeDays.contains(checkKey)) {
          currentStreak++;
        } else if (i > 0) {
          break;
        }
      }

      // Get genres from recent items
      final recentItems = history.take(20).toList();
      for (final item in recentItems) {
        try {
          final tmdbId = item['tmdb_id'] as int;
          final mediaType = item['media_type'] as String;
          Map<String, dynamic> data;
          if (mediaType == 'tv') {
            data = await _tmdbService.getShowDetails(tmdbId);
          } else {
            data = await _tmdbService.getMovieDetails(tmdbId);
          }
          final genres = (data['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? [];
          for (final genre in genres) {
            genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
          }
          final originCountries = (data['origin_country'] as List?)?.map((c) => c.toString()).toList() ?? [];
          for (final country in originCountries) {
            countryCounts[country] = (countryCounts[country] ?? 0) + 1;
          }
        } catch (e) {
          // Skip failed items
        }
      }

      // Check night owl / early bird
      bool isNightOwl = false;
      bool isEarlyBird = false;
      for (final item in history) {
        if (item['watched_at'] != null) {
          final date = DateTime.tryParse(item['watched_at']);
          if (date != null) {
            if (date.hour >= 0 && date.hour < 4) isNightOwl = true;
            if (date.hour >= 5 && date.hour < 7) isEarlyBird = true;
          }
        }
      }

      // Build achievements
      final achievements = _getAchievements(
        shows: totalShows,
        movies: totalMovies,
        episodes: totalEpisodes,
        hours: totalHours,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        isNightOwl: isNightOwl,
        isEarlyBird: isEarlyBird,
        genreCounts: genreCounts,
        countryCounts: countryCounts,
        watchlistCount: watchlist.length,
        favoriteCount: favorites.length,
      );

      final totalXp = achievements.where((a) => a.isUnlocked).fold(0, (sum, a) => sum + a.xpReward);
      final level = (totalXp / 100).floor() + 1;
      final currentXp = totalXp % 100;

      if (isClosed) return;
      emit(AchievementsLoaded(
        achievements: achievements,
        totalShows: totalShows,
        totalMovies: totalMovies,
        totalEpisodes: totalEpisodes,
        totalHours: totalHours,
        level: level,
        currentXp: currentXp,
        xpToNextLevel: 100,
        longestStreak: longestStreak,
        currentStreak: currentStreak,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(AchievementsError('Something went wrong. Please try again.'));
    }
  }

  List<Achievement> _getAchievements({
    required int shows,
    required int movies,
    required int episodes,
    required int hours,
    required int currentStreak,
    required int longestStreak,
    required bool isNightOwl,
    required bool isEarlyBird,
    required Map<String, int> genreCounts,
    required Map<String, int> countryCounts,
    required int watchlistCount,
    required int favoriteCount,
  }) {
    final totalTitles = shows + movies;
    final now = DateTime.now();
    final isHalloween = now.month == 10;
    final isChristmas = now.month == 12;
    final isValentine = now.month == 2 && now.day == 14;
    final isSummer = now.month >= 6 && now.month <= 8;

    return [
      // ===== WATCHING =====
      Achievement(id: 'first_episode', title: 'First Episode', description: 'Watch your first episode', icon: Icons.play_circle, color: const Color(0xFF6C63FF), requirement: 1, category: 'watching', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: episodes >= 1, current: episodes),
      Achievement(id: 'binge_master', title: 'Binge Master', description: 'Watch 50 episodes', icon: Icons.bolt, color: const Color(0xFFFFD93D), requirement: 50, category: 'watching', rarity: AchievementRarity.rare, xpReward: 25, isUnlocked: episodes >= 50, current: episodes),
      Achievement(id: 'marathon_monster', title: 'Marathon Monster', description: 'Watch 200 episodes', icon: Icons.flash_on, color: const Color(0xFFE50914), requirement: 200, category: 'watching', rarity: AchievementRarity.epic, xpReward: 50, isUnlocked: episodes >= 200, current: episodes),
      Achievement(id: 'night_owl', title: 'Night Owl', description: 'Watch between 12AM-4AM', icon: Icons.nightlight_round, color: const Color(0xFF6C63FF), requirement: 1, category: 'watching', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: isNightOwl, current: isNightOwl ? 1 : 0),
      Achievement(id: 'early_bird', title: 'Early Bird', description: 'Watch before 7AM', icon: Icons.wb_sunny, color: const Color(0xFFFFD93D), requirement: 1, category: 'watching', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: isEarlyBird, current: isEarlyBird ? 1 : 0),
      Achievement(id: 'daily_streak', title: 'Daily Streak', description: '7 days in a row', icon: Icons.local_fire_department, color: const Color(0xFFE50914), requirement: 7, category: 'watching', rarity: AchievementRarity.rare, xpReward: 30, isUnlocked: longestStreak >= 7, current: longestStreak),
      Achievement(id: 'monthly_streak', title: 'Monthly Streak', description: '30 days in a row', icon: Icons.local_fire_department, color: const Color(0xFF9C27B0), requirement: 30, category: 'watching', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: longestStreak >= 30, current: longestStreak),
      Achievement(id: 'year_streak', title: 'One Year Streak', description: '365 days in a row', icon: Icons.local_fire_department, color: const Color(0xFFFF9800), requirement: 365, category: 'watching', rarity: AchievementRarity.legendary, xpReward: 500, isUnlocked: longestStreak >= 365, current: longestStreak),
      Achievement(id: 'movie_maniac', title: 'Movie Maniac', description: 'Watch 100 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 100, category: 'watching', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: movies >= 100, current: movies),
      Achievement(id: 'series_addict', title: 'Series Addict', description: 'Watch 50 shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 50, category: 'watching', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: shows >= 50, current: shows),
      Achievement(id: 'episode_hunter', title: 'Episode Hunter', description: 'Watch 1000 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 1000, category: 'watching', rarity: AchievementRarity.legendary, xpReward: 250, isUnlocked: episodes >= 1000, current: episodes),

      // ===== GENRES =====
      Achievement(id: 'action_lover', title: 'Action Lover', description: 'Watch 5 action titles', icon: Icons.local_fire_department, color: const Color(0xFFE50914), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (genreCounts['Action'] ?? 0) >= 5, current: genreCounts['Action'] ?? 0),
      Achievement(id: 'comedy_expert', title: 'Comedy Expert', description: 'Watch 5 comedy titles', icon: Icons.sentiment_very_satisfied, color: const Color(0xFFFFD93D), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (genreCounts['Comedy'] ?? 0) >= 5, current: genreCounts['Comedy'] ?? 0),
      Achievement(id: 'scifi_explorer', title: 'Sci-Fi Explorer', description: 'Watch 5 sci-fi titles', icon: Icons.rocket_launch, color: const Color(0xFF00D4FF), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (genreCounts['Science Fiction'] ?? 0) >= 5, current: genreCounts['Science Fiction'] ?? 0),
      Achievement(id: 'fantasy_wizard', title: 'Fantasy Wizard', description: 'Watch 5 fantasy titles', icon: Icons.auto_awesome, color: const Color(0xFF9C27B0), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (genreCounts['Fantasy'] ?? 0) >= 5, current: genreCounts['Fantasy'] ?? 0),
      Achievement(id: 'crime_detective', title: 'Crime Detective', description: 'Watch 5 crime titles', icon: Icons.gavel, color: const Color(0xFF795548), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (genreCounts['Crime'] ?? 0) >= 5, current: genreCounts['Crime'] ?? 0),
      Achievement(id: 'horror_survivor', title: 'Horror Survivor', description: 'Watch 5 horror titles', icon: Icons.sentiment_very_dissatisfied, color: const Color(0xFFE50914), requirement: 5, category: 'genre', rarity: AchievementRarity.rare, xpReward: 20, isUnlocked: (genreCounts['Horror'] ?? 0) >= 5, current: genreCounts['Horror'] ?? 0),
      Achievement(id: 'romance_expert', title: 'Romance Expert', description: 'Watch 5 romance titles', icon: Icons.favorite, color: const Color(0xFFE91E63), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (genreCounts['Romance'] ?? 0) >= 5, current: genreCounts['Romance'] ?? 0),
      Achievement(id: 'genre_explorer', title: 'Genre Explorer', description: 'Watch from 5 different genres', icon: Icons.explore, color: const Color(0xFF00D4FF), requirement: 5, category: 'genre', rarity: AchievementRarity.rare, xpReward: 30, isUnlocked: genreCounts.length >= 5, current: genreCounts.length),

      // ===== COUNTRY =====
      Achievement(id: 'hollywood_tourist', title: 'Hollywood Tourist', description: 'Watch 5 US titles', icon: Icons.movie, color: const Color(0xFF2196F3), requirement: 5, category: 'country', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (countryCounts['US'] ?? 0) >= 5, current: countryCounts['US'] ?? 0),
      Achievement(id: 'korean_fan', title: 'K-Drama Fan', description: 'Watch 5 Korean titles', icon: Icons.tv, color: const Color(0xFFE91E63), requirement: 5, category: 'country', rarity: AchievementRarity.rare, xpReward: 20, isUnlocked: (countryCounts['KR'] ?? 0) >= 5, current: countryCounts['KR'] ?? 0),
      Achievement(id: 'anime_world', title: 'Anime World', description: 'Watch 5 Japanese titles', icon: Icons.animation, color: const Color(0xFFE50914), requirement: 5, category: 'country', rarity: AchievementRarity.rare, xpReward: 20, isUnlocked: (countryCounts['JP'] ?? 0) >= 5, current: countryCounts['JP'] ?? 0),

      // ===== WATCHLIST =====
      Achievement(id: 'first_save', title: 'First Save', description: 'Add first item to watchlist', icon: Icons.bookmark, color: const Color(0xFF6C63FF), requirement: 1, category: 'watchlist', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: watchlistCount >= 1, current: watchlistCount),
      Achievement(id: 'collector', title: 'Collector', description: 'Add 10 items to watchlist', icon: Icons.bookmark, color: const Color(0xFF6C63FF), requirement: 10, category: 'watchlist', rarity: AchievementRarity.common, xpReward: 25, isUnlocked: watchlistCount >= 10, current: watchlistCount),
      Achievement(id: 'wishlist_king', title: 'Wishlist King', description: 'Add 100 items to watchlist', icon: Icons.bookmark, color: const Color(0xFF9C27B0), requirement: 100, category: 'watchlist', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: watchlistCount >= 100, current: watchlistCount),

      // ===== TIME =====
      Achievement(id: 'hours_10', title: 'Getting Started', description: 'Watch 10 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 10, category: 'time', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: hours >= 10, current: hours),
      Achievement(id: 'hours_100', title: 'Dedicated Viewer', description: 'Watch 100 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 100, category: 'time', rarity: AchievementRarity.rare, xpReward: 50, isUnlocked: hours >= 100, current: hours),
      Achievement(id: 'hours_500', title: 'Time Master', description: 'Watch 500 hours', icon: Icons.access_time, color: const Color(0xFF9C27B0), requirement: 500, category: 'time', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: hours >= 500, current: hours),
      Achievement(id: 'hours_1000', title: 'Ultimate Fan', description: 'Watch 1000 hours', icon: Icons.access_time, color: const Color(0xFFFF9800), requirement: 1000, category: 'time', rarity: AchievementRarity.legendary, xpReward: 250, isUnlocked: hours >= 1000, current: hours),

      // ===== COLLECTION =====
      Achievement(id: 'unique_50', title: 'Variety Seeker', description: 'Watch 50 unique titles', icon: Icons.collections, color: const Color(0xFF6C63FF), requirement: 50, category: 'collection', rarity: AchievementRarity.rare, xpReward: 30, isUnlocked: totalTitles >= 50, current: totalTitles),
      Achievement(id: 'unique_100', title: 'Content Explorer', description: 'Watch 100 unique titles', icon: Icons.collections, color: const Color(0xFF9C27B0), requirement: 100, category: 'collection', rarity: AchievementRarity.epic, xpReward: 50, isUnlocked: totalTitles >= 100, current: totalTitles),
      Achievement(id: 'unique_500', title: 'The Archivist', description: 'Watch 500 unique titles', icon: Icons.collections, color: const Color(0xFFFF9800), requirement: 500, category: 'collection', rarity: AchievementRarity.legendary, xpReward: 250, isUnlocked: totalTitles >= 500, current: totalTitles),

      // ===== FUNNY =====
      Achievement(id: 'pizza_movies', title: 'Pizza & Movies', description: 'Watch 10 movies', icon: Icons.local_pizza, color: const Color(0xFFFFD93D), requirement: 10, category: 'funny', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: movies >= 10, current: movies),
      Achievement(id: 'cry_baby', title: 'Cry Baby', description: 'Watch 10 dramas', icon: Icons.sentiment_very_dissatisfied, color: const Color(0xFF2196F3), requirement: 10, category: 'funny', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (genreCounts['Drama'] ?? 0) >= 10, current: genreCounts['Drama'] ?? 0),

      // ===== SEASONAL =====
      Achievement(id: 'halloween', title: 'Halloween Special', description: 'Watch during October', icon: Icons.emoji_emotions, color: const Color(0xFFFF9800), requirement: 1, category: 'seasonal', rarity: AchievementRarity.rare, xpReward: 25, isUnlocked: isHalloween, current: isHalloween ? 1 : 0),
      Achievement(id: 'christmas', title: 'Christmas Spirit', description: 'Watch during December', icon: Icons.celebration, color: const Color(0xFFE50914), requirement: 1, category: 'seasonal', rarity: AchievementRarity.rare, xpReward: 25, isUnlocked: isChristmas, current: isChristmas ? 1 : 0),
      Achievement(id: 'summer_vacation', title: 'Summer Vibes', description: 'Watch during summer', icon: Icons.wb_sunny, color: const Color(0xFFFFD93D), requirement: 1, category: 'seasonal', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: isSummer, current: isSummer ? 1 : 0),

      // ===== HIDDEN =====
      Achievement(id: 'hidden_completionist', title: '???', description: 'Unlock 20 achievements', icon: Icons.help, color: const Color(0xFF9C27B0), requirement: 20, category: 'hidden', rarity: AchievementRarity.epic, xpReward: 100, isHidden: true, isUnlocked: false, current: 0),
    ];
  }
}
