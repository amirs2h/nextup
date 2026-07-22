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

  Achievement copyWith({bool? isUnlocked, int? current}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: color,
      requirement: requirement,
      category: category,
      rarity: rarity,
      xpReward: xpReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      current: current ?? this.current,
      isHidden: isHidden,
    );
  }

  double get progress => requirement > 0 ? (current / requirement).clamp(0.0, 1.0) : 0.0;

  String get rarityLabel {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF9E9E9E);
      case AchievementRarity.rare:
        return const Color(0xFF2196F3);
      case AchievementRarity.epic:
        return const Color(0xFF9C27B0);
      case AchievementRarity.legendary:
        return const Color(0xFFFF9800);
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

class _ActivityStats {
  final int totalShows;
  final int totalMovies;
  final int totalEpisodes;
  final int totalHours;
  final int longestStreak;
  final int currentStreak;
  final bool isNightOwl;
  final bool isEarlyBird;
  final bool watchedInOctober;
  final bool watchedInDecember;
  final bool watchedInSummer;
  final Map<String, int> genreCounts;
  final Map<String, int> countryCounts;
  final int watchlistCount;
  final int favoriteCount;

  _ActivityStats({
    required this.totalShows,
    required this.totalMovies,
    required this.totalEpisodes,
    required this.totalHours,
    required this.longestStreak,
    required this.currentStreak,
    required this.isNightOwl,
    required this.isEarlyBird,
    required this.watchedInOctober,
    required this.watchedInDecember,
    required this.watchedInSummer,
    required this.genreCounts,
    required this.countryCounts,
    required this.watchlistCount,
    required this.favoriteCount,
  });
}

/// Seasonal IDs that must have watched_at evidence (cleanup target).
const _seasonalIds = {'halloween', 'christmas', 'summer_vacation'};

class AchievementsCubit extends Cubit<AchievementsState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  Map<String, int> _cachedGenreCounts = {};
  Map<String, int> _cachedCountryCounts = {};
  bool _syncing = false;

  AchievementsCubit(this._supabaseService, this._tmdbService) : super(AchievementsInitial());

  Future<void> loadAchievements({bool forceLoading = false}) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(AchievementsLoaded(achievements: []));
      return;
    }

    final hadLoaded = state is AchievementsLoaded;
    if (!hadLoaded || forceLoading) {
      if (isClosed) return;
      emit(AchievementsLoading());
    }

    try {
      final loaded = await _computeForUser(user.id, persist: true);
      if (isClosed) return;
      emit(loaded);
    } catch (e) {
      if (isClosed) return;
      if (state is! AchievementsLoaded) {
        emit(AchievementsError('Something went wrong. Please try again.'));
      }
    }
  }

  /// Light refresh after watch/watchlist/favorite (never revokes non-seasonal).
  Future<void> syncAfterActivity() async {
    if (_syncing) return;
    final user = _supabaseService.currentUser;
    if (user == null) return;
    _syncing = true;
    try {
      final loaded = await _computeForUser(user.id, persist: true);
      if (!isClosed) emit(loaded);
    } catch (_) {
      // keep previous state
    } finally {
      _syncing = false;
    }
  }

  Future<AchievementsLoaded> calculateForUser(String userId) async {
    return _computeForUser(userId, persist: userId == _supabaseService.currentUser?.id);
  }

  Future<AchievementsLoaded> _computeForUser(String userId, {required bool persist}) async {
    // Backfill genres for older history rows (best-effort, limited)
    if (persist) {
      try {
        await _supabaseService.backfillHistoryGenres(
          userId: userId,
          fetchDetails: (tmdbId, mediaType) async {
            if (mediaType == 'tv') return _tmdbService.getShowDetails(tmdbId);
            return _tmdbService.getMovieDetails(tmdbId);
          },
          limit: 50,
        );
      } catch (_) {}
    }

    final results = await Future.wait([
      _supabaseService.getWatchHistory(userId: userId),
      _supabaseService.getWatchlist(userId: userId),
      _supabaseService.getFavorites(userId: userId),
      _supabaseService.getUserAchievements(userId),
    ]);

    final history = List<Map<String, dynamic>>.from(results[0] as List);
    final watchlist = List<Map<String, dynamic>>.from(results[1] as List);
    final favorites = List<Map<String, dynamic>>.from(results[2] as List);
    final persisted = List<Map<String, dynamic>>.from(results[3] as List);

    final stats = await _buildActivityStats(
      history: history,
      watchlistCount: watchlist.length,
      favoriteCount: favorites.length,
    );

    // Rule-based unlocks from current activity (seasonal uses watched_at evidence)
    final ruleBased = _buildAchievements(stats);
    final ruleUnlocked = {
      for (final a in ruleBased)
        if (a.isUnlocked) a.id: a.xpReward,
    };

    // Persisted unlocks from DB
    final persistedMap = <String, int>{};
    for (final row in persisted) {
      final id = row['achievement_id'] as String?;
      if (id == null) continue;
      persistedMap[id] = (row['xp_awarded'] as num?)?.toInt() ?? 0;
    }

    // Cleanup: seasonal in DB without evidence → remove
    final seasonalToRemove = <String>[];
    for (final id in _seasonalIds) {
      if (persistedMap.containsKey(id) && !ruleUnlocked.containsKey(id)) {
        seasonalToRemove.add(id);
      }
    }
    if (persist && seasonalToRemove.isNotEmpty) {
      await _supabaseService.deleteUserAchievements(userId: userId, achievementIds: seasonalToRemove);
      for (final id in seasonalToRemove) {
        persistedMap.remove(id);
      }
    }

    // Never revoke: final unlocks = persisted (after cleanup) ∪ newly rule-unlocked
    final finalUnlocked = <String, int>{...persistedMap};
    final newlyUnlocked = <Map<String, dynamic>>[];
    for (final entry in ruleUnlocked.entries) {
      if (!finalUnlocked.containsKey(entry.key)) {
        finalUnlocked[entry.key] = entry.value;
        newlyUnlocked.add({
          'achievement_id': entry.key,
          'xp_awarded': entry.value,
        });
      }
    }

    if (persist && newlyUnlocked.isNotEmpty) {
      await _supabaseService.unlockAchievements(userId: userId, achievements: newlyUnlocked);
    }

    // Map catalog with unlock flags from final set
    final catalog = _buildAchievements(stats).map((a) {
      final unlocked = finalUnlocked.containsKey(a.id);
      return a.copyWith(isUnlocked: unlocked);
    }).toList();

    // Hidden completionist based on final unlock count (excluding itself first)
    final unlockedCount = catalog.where((a) => a.isUnlocked && a.id != 'hidden_completionist').length;
    final completionistIdx = catalog.indexWhere((a) => a.id == 'hidden_completionist');
    if (completionistIdx >= 0) {
      final shouldUnlock = unlockedCount >= 20;
      catalog[completionistIdx] = catalog[completionistIdx].copyWith(
        isUnlocked: finalUnlocked.containsKey('hidden_completionist') || shouldUnlock,
        current: unlockedCount,
      );
      if (shouldUnlock && !finalUnlocked.containsKey('hidden_completionist') && persist) {
        await _supabaseService.unlockAchievements(userId: userId, achievements: [
          {'achievement_id': 'hidden_completionist', 'xp_awarded': 100},
        ]);
        finalUnlocked['hidden_completionist'] = 100;
      }
    }

    final totalXpFinal = finalUnlocked.values.fold<int>(0, (s, v) => s + v);
    final levelFinal = (totalXpFinal / 100).floor() + 1;
    final currentXpFinal = totalXpFinal % 100;

    return AchievementsLoaded(
      achievements: catalog,
      totalShows: stats.totalShows,
      totalMovies: stats.totalMovies,
      totalEpisodes: stats.totalEpisodes,
      totalHours: stats.totalHours,
      level: levelFinal,
      currentXp: currentXpFinal,
      xpToNextLevel: 100,
      longestStreak: stats.longestStreak,
      currentStreak: stats.currentStreak,
    );
  }

  Future<_ActivityStats> _buildActivityStats({
    required List<Map<String, dynamic>> history,
    required int watchlistCount,
    required int favoriteCount,
  }) async {
    int totalEpisodes = 0;
    int totalMinutes = 0;
    final showIds = <String>{};
    final movieIds = <String>{};
    final activeDays = <String>{};
    var isNightOwl = false;
    var isEarlyBird = false;
    var watchedInOctober = false;
    var watchedInDecember = false;
    var watchedInSummer = false;

    for (final item in history) {
      final mediaType = item['media_type'] as String? ?? 'tv';
      final tmdbId = item['tmdb_id']?.toString() ?? '';
      final epRaw = item['episode_number'];
      final ep = epRaw is int ? epRaw : int.tryParse(epRaw?.toString() ?? '');
      final runtimeMin = item['runtime_minutes'] is int
          ? item['runtime_minutes'] as int
          : int.tryParse(item['runtime_minutes']?.toString() ?? '');

      if (mediaType == 'tv') {
        if (ep != null && ep > 0) {
          if (tmdbId.isNotEmpty) showIds.add(tmdbId);
          totalEpisodes++;
          totalMinutes += runtimeMin ?? 45;
        }
      } else {
        if (tmdbId.isNotEmpty) movieIds.add(tmdbId);
        totalMinutes += runtimeMin ?? 120;
      }
      if (item['watched_at'] != null) {
        final date = DateTime.tryParse(item['watched_at'].toString());
        if (date != null) {
          activeDays.add(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          );
          if (date.hour >= 0 && date.hour < 4) isNightOwl = true;
          if (date.hour >= 5 && date.hour < 7) isEarlyBird = true;
          if (date.month == 10) watchedInOctober = true;
          if (date.month == 12) watchedInDecember = true;
          if (date.month >= 6 && date.month <= 8) watchedInSummer = true;
        }
      }
    }

    final totalShows = showIds.length;
    final totalMovies = movieIds.length;
    final totalHours = totalMinutes ~/ 60;

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
      final checkKey =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (activeDays.contains(checkKey)) {
        currentStreak++;
      } else if (i > 0) {
        break;
      }
    }

    // Genres: prefer denormalized columns on history (distinct titles).
    // Fallback: TMDB for missing rows only; never wipe cache on total failure.
    final genreTitleSets = <String, Set<String>>{};
    final countryTitleSets = <String, Set<String>>{};
    final missingMeta = <Map<String, dynamic>>[];

    final seenTitles = <String>{};
    for (final item in history) {
      final tmdbId = item['tmdb_id'];
      final mediaType = item['media_type'] as String? ?? 'tv';
      if (tmdbId == null) continue;
      final titleKey = '$mediaType:$tmdbId';
      if (seenTitles.contains(titleKey)) continue;
      seenTitles.add(titleKey);

      final genres = _parseStringList(item['genres']);
      final countries = _parseStringList(item['origin_countries']);

      if (genres.isEmpty && countries.isEmpty) {
        missingMeta.add({'tmdb_id': tmdbId is int ? tmdbId : int.tryParse(tmdbId.toString()), 'media_type': mediaType, 'key': titleKey});
        continue;
      }
      for (final genre in genres) {
        genreTitleSets.putIfAbsent(genre, () => <String>{}).add(titleKey);
      }
      for (final country in countries) {
        countryTitleSets.putIfAbsent(country, () => <String>{}).add(titleKey);
      }
    }

    // Fallback TMDB only for titles still missing metadata (cap 30)
    var genreFetchOk = 0;
    for (final row in missingMeta.take(30)) {
      final tmdbId = row['tmdb_id'] as int?;
      final mediaType = row['media_type'] as String? ?? 'tv';
      final titleKey = row['key'] as String;
      if (tmdbId == null) continue;
      try {
        final data = mediaType == 'tv'
            ? await _tmdbService.getShowDetails(tmdbId)
            : await _tmdbService.getMovieDetails(tmdbId);
        genreFetchOk++;
        final genres = (data['genres'] as List?)
                ?.map((g) => g['name']?.toString())
                .whereType<String>()
                .where((n) => n.isNotEmpty)
                .toList() ??
            <String>[];
        List<String> countries = [];
        if (mediaType == 'tv') {
          countries = (data['origin_country'] as List?)?.map((c) => c.toString()).toList() ?? [];
        } else {
          countries = (data['production_countries'] as List?)
                  ?.map((c) => c is Map ? c['iso_3166_1']?.toString() : c.toString())
                  .whereType<String>()
                  .toList() ??
              [];
        }
        for (final genre in genres) {
          genreTitleSets.putIfAbsent(genre, () => <String>{}).add(titleKey);
        }
        for (final country in countries) {
          countryTitleSets.putIfAbsent(country, () => <String>{}).add(titleKey);
        }
      } catch (_) {}
    }

    final genreCounts = <String, int>{
      for (final e in genreTitleSets.entries) e.key: e.value.length,
    };
    final countryCounts = <String, int>{
      for (final e in countryTitleSets.entries) e.key: e.value.length,
    };

    if (genreCounts.isEmpty && genreFetchOk == 0 && _cachedGenreCounts.isNotEmpty) {
      genreCounts.addAll(_cachedGenreCounts);
      countryCounts.addAll(_cachedCountryCounts);
    } else if (genreCounts.isNotEmpty) {
      _cachedGenreCounts = Map.from(genreCounts);
      _cachedCountryCounts = Map.from(countryCounts);
    }

    return _ActivityStats(
      totalShows: totalShows,
      totalMovies: totalMovies,
      totalEpisodes: totalEpisodes,
      totalHours: totalHours,
      longestStreak: longestStreak,
      currentStreak: currentStreak,
      isNightOwl: isNightOwl,
      isEarlyBird: isEarlyBird,
      watchedInOctober: watchedInOctober,
      watchedInDecember: watchedInDecember,
      watchedInSummer: watchedInSummer,
      genreCounts: genreCounts,
      countryCounts: countryCounts,
      watchlistCount: watchlistCount,
      favoriteCount: favoriteCount,
    );
  }

  List<String> _parseStringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      // postgres array text fallback "{Horror,Thriller}"
      final cleaned = raw.replaceAll('{', '').replaceAll('}', '');
      if (cleaned.isEmpty) return const [];
      return cleaned.split(',').map((s) => s.trim().replaceAll('"', '')).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  List<Achievement> _buildAchievements(_ActivityStats s) {
    final totalTitles = s.totalShows + s.totalMovies;
    final g = s.genreCounts;
    final c = s.countryCounts;

    final achievements = <Achievement>[
      Achievement(id: 'first_episode', title: 'First Episode', description: 'Watch your first episode', icon: Icons.play_circle, color: const Color(0xFF6C63FF), requirement: 1, category: 'watching', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: s.totalEpisodes >= 1, current: s.totalEpisodes),
      Achievement(id: 'binge_master', title: 'Binge Master', description: 'Watch 50 episodes', icon: Icons.bolt, color: const Color(0xFFFFD93D), requirement: 50, category: 'watching', rarity: AchievementRarity.rare, xpReward: 25, isUnlocked: s.totalEpisodes >= 50, current: s.totalEpisodes),
      Achievement(id: 'marathon_monster', title: 'Marathon Monster', description: 'Watch 200 episodes', icon: Icons.flash_on, color: const Color(0xFFE50914), requirement: 200, category: 'watching', rarity: AchievementRarity.epic, xpReward: 50, isUnlocked: s.totalEpisodes >= 200, current: s.totalEpisodes),
      Achievement(id: 'night_owl', title: 'Night Owl', description: 'Watch between 12AM-4AM', icon: Icons.nightlight_round, color: const Color(0xFF6C63FF), requirement: 1, category: 'watching', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: s.isNightOwl, current: s.isNightOwl ? 1 : 0),
      Achievement(id: 'early_bird', title: 'Early Bird', description: 'Watch before 7AM', icon: Icons.wb_sunny, color: const Color(0xFFFFD93D), requirement: 1, category: 'watching', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: s.isEarlyBird, current: s.isEarlyBird ? 1 : 0),
      Achievement(id: 'daily_streak', title: 'Daily Streak', description: '7 days in a row', icon: Icons.local_fire_department, color: const Color(0xFFE50914), requirement: 7, category: 'watching', rarity: AchievementRarity.rare, xpReward: 30, isUnlocked: s.longestStreak >= 7, current: s.longestStreak),
      Achievement(id: 'monthly_streak', title: 'Monthly Streak', description: '30 days in a row', icon: Icons.local_fire_department, color: const Color(0xFF9C27B0), requirement: 30, category: 'watching', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: s.longestStreak >= 30, current: s.longestStreak),
      Achievement(id: 'year_streak', title: 'One Year Streak', description: '365 days in a row', icon: Icons.local_fire_department, color: const Color(0xFFFF9800), requirement: 365, category: 'watching', rarity: AchievementRarity.legendary, xpReward: 500, isUnlocked: s.longestStreak >= 365, current: s.longestStreak),
      Achievement(id: 'movie_maniac', title: 'Movie Maniac', description: 'Watch 100 movies', icon: Icons.movie, color: const Color(0xFFE50914), requirement: 100, category: 'watching', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: s.totalMovies >= 100, current: s.totalMovies),
      Achievement(id: 'series_addict', title: 'Series Addict', description: 'Watch 50 shows', icon: Icons.tv, color: const Color(0xFF6C63FF), requirement: 50, category: 'watching', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: s.totalShows >= 50, current: s.totalShows),
      Achievement(id: 'episode_hunter', title: 'Episode Hunter', description: 'Watch 1000 episodes', icon: Icons.play_circle, color: const Color(0xFF00D4FF), requirement: 1000, category: 'watching', rarity: AchievementRarity.legendary, xpReward: 250, isUnlocked: s.totalEpisodes >= 1000, current: s.totalEpisodes),
      Achievement(id: 'action_lover', title: 'Action Lover', description: 'Watch 5 action titles', icon: Icons.local_fire_department, color: const Color(0xFFE50914), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (g['Action'] ?? 0) >= 5, current: g['Action'] ?? 0),
      Achievement(id: 'comedy_expert', title: 'Comedy Expert', description: 'Watch 5 comedy titles', icon: Icons.sentiment_very_satisfied, color: const Color(0xFFFFD93D), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (g['Comedy'] ?? 0) >= 5, current: g['Comedy'] ?? 0),
      Achievement(id: 'scifi_explorer', title: 'Sci-Fi Explorer', description: 'Watch 5 sci-fi titles', icon: Icons.rocket_launch, color: const Color(0xFF00D4FF), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (g['Science Fiction'] ?? 0) >= 5, current: g['Science Fiction'] ?? 0),
      Achievement(id: 'fantasy_wizard', title: 'Fantasy Wizard', description: 'Watch 5 fantasy titles', icon: Icons.auto_awesome, color: const Color(0xFF9C27B0), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (g['Fantasy'] ?? 0) >= 5, current: g['Fantasy'] ?? 0),
      Achievement(id: 'crime_detective', title: 'Crime Detective', description: 'Watch 5 crime titles', icon: Icons.gavel, color: const Color(0xFF795548), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (g['Crime'] ?? 0) >= 5, current: g['Crime'] ?? 0),
      Achievement(id: 'horror_survivor', title: 'Horror Survivor', description: 'Watch 5 horror titles', icon: Icons.sentiment_very_dissatisfied, color: const Color(0xFFE50914), requirement: 5, category: 'genre', rarity: AchievementRarity.rare, xpReward: 20, isUnlocked: (g['Horror'] ?? 0) >= 5, current: g['Horror'] ?? 0),
      Achievement(id: 'romance_expert', title: 'Romance Expert', description: 'Watch 5 romance titles', icon: Icons.favorite, color: const Color(0xFFE91E63), requirement: 5, category: 'genre', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (g['Romance'] ?? 0) >= 5, current: g['Romance'] ?? 0),
      Achievement(id: 'genre_explorer', title: 'Genre Explorer', description: 'Watch from 5 different genres', icon: Icons.explore, color: const Color(0xFF00D4FF), requirement: 5, category: 'genre', rarity: AchievementRarity.rare, xpReward: 30, isUnlocked: g.length >= 5, current: g.length),
      Achievement(id: 'hollywood_tourist', title: 'Hollywood Tourist', description: 'Watch 5 US titles', icon: Icons.movie, color: const Color(0xFF2196F3), requirement: 5, category: 'country', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (c['US'] ?? 0) >= 5, current: c['US'] ?? 0),
      Achievement(id: 'korean_fan', title: 'K-Drama Fan', description: 'Watch 5 Korean titles', icon: Icons.tv, color: const Color(0xFFE91E63), requirement: 5, category: 'country', rarity: AchievementRarity.rare, xpReward: 20, isUnlocked: (c['KR'] ?? 0) >= 5, current: c['KR'] ?? 0),
      Achievement(id: 'anime_world', title: 'Anime World', description: 'Watch 5 Japanese titles', icon: Icons.animation, color: const Color(0xFFE50914), requirement: 5, category: 'country', rarity: AchievementRarity.rare, xpReward: 20, isUnlocked: (c['JP'] ?? 0) >= 5, current: c['JP'] ?? 0),
      Achievement(id: 'first_save', title: 'First Save', description: 'Add first item to watchlist', icon: Icons.bookmark, color: const Color(0xFF6C63FF), requirement: 1, category: 'watchlist', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: s.watchlistCount >= 1, current: s.watchlistCount),
      Achievement(id: 'collector', title: 'Collector', description: 'Add 10 items to watchlist', icon: Icons.bookmark, color: const Color(0xFF6C63FF), requirement: 10, category: 'watchlist', rarity: AchievementRarity.common, xpReward: 25, isUnlocked: s.watchlistCount >= 10, current: s.watchlistCount),
      Achievement(id: 'wishlist_king', title: 'Wishlist King', description: 'Add 100 items to watchlist', icon: Icons.bookmark, color: const Color(0xFF9C27B0), requirement: 100, category: 'watchlist', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: s.watchlistCount >= 100, current: s.watchlistCount),
      Achievement(id: 'first_favorite', title: 'First Favorite', description: 'Add your first favorite', icon: Icons.favorite, color: const Color(0xFFE50914), requirement: 1, category: 'favorites', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: s.favoriteCount >= 1, current: s.favoriteCount),
      Achievement(id: 'favorites_10', title: 'Heart Collector', description: 'Add 10 favorites', icon: Icons.favorite, color: const Color(0xFFE91E63), requirement: 10, category: 'favorites', rarity: AchievementRarity.common, xpReward: 25, isUnlocked: s.favoriteCount >= 10, current: s.favoriteCount),
      Achievement(id: 'favorites_50', title: 'Super Fan', description: 'Add 50 favorites', icon: Icons.favorite, color: const Color(0xFF9C27B0), requirement: 50, category: 'favorites', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: s.favoriteCount >= 50, current: s.favoriteCount),
      Achievement(id: 'hours_10', title: 'Getting Started', description: 'Watch 10 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 10, category: 'time', rarity: AchievementRarity.common, xpReward: 10, isUnlocked: s.totalHours >= 10, current: s.totalHours),
      Achievement(id: 'hours_100', title: 'Dedicated Viewer', description: 'Watch 100 hours', icon: Icons.access_time, color: const Color(0xFFFFD93D), requirement: 100, category: 'time', rarity: AchievementRarity.rare, xpReward: 50, isUnlocked: s.totalHours >= 100, current: s.totalHours),
      Achievement(id: 'hours_500', title: 'Time Master', description: 'Watch 500 hours', icon: Icons.access_time, color: const Color(0xFF9C27B0), requirement: 500, category: 'time', rarity: AchievementRarity.epic, xpReward: 100, isUnlocked: s.totalHours >= 500, current: s.totalHours),
      Achievement(id: 'hours_1000', title: 'Ultimate Fan', description: 'Watch 1000 hours', icon: Icons.access_time, color: const Color(0xFFFF9800), requirement: 1000, category: 'time', rarity: AchievementRarity.legendary, xpReward: 250, isUnlocked: s.totalHours >= 1000, current: s.totalHours),
      Achievement(id: 'unique_50', title: 'Variety Seeker', description: 'Watch 50 unique titles', icon: Icons.collections, color: const Color(0xFF6C63FF), requirement: 50, category: 'collection', rarity: AchievementRarity.rare, xpReward: 30, isUnlocked: totalTitles >= 50, current: totalTitles),
      Achievement(id: 'unique_100', title: 'Content Explorer', description: 'Watch 100 unique titles', icon: Icons.collections, color: const Color(0xFF9C27B0), requirement: 100, category: 'collection', rarity: AchievementRarity.epic, xpReward: 50, isUnlocked: totalTitles >= 100, current: totalTitles),
      Achievement(id: 'unique_500', title: 'The Archivist', description: 'Watch 500 unique titles', icon: Icons.collections, color: const Color(0xFFFF9800), requirement: 500, category: 'collection', rarity: AchievementRarity.legendary, xpReward: 250, isUnlocked: totalTitles >= 500, current: totalTitles),
      Achievement(id: 'pizza_movies', title: 'Pizza & Movies', description: 'Watch 10 movies', icon: Icons.local_pizza, color: const Color(0xFFFFD93D), requirement: 10, category: 'funny', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: s.totalMovies >= 10, current: s.totalMovies),
      Achievement(id: 'cry_baby', title: 'Cry Baby', description: 'Watch 10 dramas', icon: Icons.sentiment_very_dissatisfied, color: const Color(0xFF2196F3), requirement: 10, category: 'funny', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: (g['Drama'] ?? 0) >= 10, current: g['Drama'] ?? 0),
      // Seasonal: based on watched_at evidence (never DateTime.now alone)
      Achievement(id: 'halloween', title: 'Halloween Special', description: 'Watch something in October', icon: Icons.emoji_emotions, color: const Color(0xFFFF9800), requirement: 1, category: 'seasonal', rarity: AchievementRarity.rare, xpReward: 25, isUnlocked: s.watchedInOctober, current: s.watchedInOctober ? 1 : 0),
      Achievement(id: 'christmas', title: 'Christmas Spirit', description: 'Watch something in December', icon: Icons.celebration, color: const Color(0xFFE50914), requirement: 1, category: 'seasonal', rarity: AchievementRarity.rare, xpReward: 25, isUnlocked: s.watchedInDecember, current: s.watchedInDecember ? 1 : 0),
      Achievement(id: 'summer_vacation', title: 'Summer Vibes', description: 'Watch something in summer', icon: Icons.wb_sunny, color: const Color(0xFFFFD93D), requirement: 1, category: 'seasonal', rarity: AchievementRarity.common, xpReward: 15, isUnlocked: s.watchedInSummer, current: s.watchedInSummer ? 1 : 0),
      Achievement(id: 'hidden_completionist', title: 'Completionist', description: 'Unlock 20 achievements', icon: Icons.emoji_events, color: const Color(0xFF9C27B0), requirement: 20, category: 'hidden', rarity: AchievementRarity.epic, xpReward: 100, isHidden: true, isUnlocked: false, current: 0),
    ];

    return achievements;
  }
}
