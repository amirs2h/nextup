/// Shared activity stats derived from watch_history rows.
/// Single source of truth for Stats page, Compare, and consistent episode counting.
class UserActivityStats {
  final int totalShows;
  final int totalMovies;
  final int totalEpisodes;
  final int totalHours;
  final int longestStreak;
  final int currentStreak;
  final Map<String, int> monthlyWatched;
  final String favoriteDay;
  final String favoriteTime;
  final int avgEpisodesPerShow;
  final String mostWatchedShowId;
  final int mostWatchedShowEpisodes;
  final Map<String, int> showEpisodeCounts;

  const UserActivityStats({
    this.totalShows = 0,
    this.totalMovies = 0,
    this.totalEpisodes = 0,
    this.totalHours = 0,
    this.longestStreak = 0,
    this.currentStreak = 0,
    this.monthlyWatched = const {},
    this.favoriteDay = '',
    this.favoriteTime = '',
    this.avgEpisodesPerShow = 0,
    this.mostWatchedShowId = '',
    this.mostWatchedShowEpisodes = 0,
    this.showEpisodeCounts = const {},
  });

  Map<String, dynamic> toSummaryMap() => {
        'totalShows': totalShows,
        'totalMovies': totalMovies,
        'totalEpisodes': totalEpisodes,
        'totalHours': totalHours,
      };

  /// Unified rules:
  /// - TV show count: distinct tmdb_id where media_type == tv, from history + watchlist
  /// - Movie count: distinct tmdb_id where media_type == movie, from history + watchlist
  /// - Episode count: history tv rows with episode_number != null && > 0
  /// - Hours: (episodes * 45 + movies * 120) ~/ 60 (from history only)
  static UserActivityStats fromHistory(
    List<Map<String, dynamic>> history, {
    List<Map<String, dynamic>> watchlist = const [],
    List<Map<String, dynamic>> favorites = const [],
  }) {
    final showIds = <String>{};
    final movieIds = <String>{};
    var totalEpisodes = 0;
    final monthlyWatched = <String, int>{};
    final showEpisodeCounts = <String, int>{};
    final dayOfWeekCounts = <int, int>{};
    final hourCounts = <int, int>{};
    final activeDays = <String>{};

    for (final item in history) {
      final tmdbId = item['tmdb_id']?.toString() ?? '';
      final mediaType = item['media_type'] as String? ?? 'tv';
      final epNum = item['episode_number'];

      if (mediaType == 'tv') {
        if (tmdbId.isNotEmpty) showIds.add(tmdbId);
        final ep = epNum is int ? epNum : int.tryParse(epNum?.toString() ?? '');
        if (ep != null && ep > 0) {
          totalEpisodes++;
          if (tmdbId.isNotEmpty) {
            showEpisodeCounts[tmdbId] = (showEpisodeCounts[tmdbId] ?? 0) + 1;
          }
        }
      } else if (mediaType == 'movie') {
        if (tmdbId.isNotEmpty) movieIds.add(tmdbId);
      }

      final watchedAt = item['watched_at'];
      if (watchedAt != null) {
        final date = DateTime.tryParse(watchedAt.toString());
        if (date != null) {
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthlyWatched[monthKey] = (monthlyWatched[monthKey] ?? 0) + 1;
          dayOfWeekCounts[date.weekday] = (dayOfWeekCounts[date.weekday] ?? 0) + 1;
          hourCounts[date.hour] = (hourCounts[date.hour] ?? 0) + 1;
          activeDays.add(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          );
        }
      }
    }

    // Also count shows/movies from watchlist (not just history)
    for (final item in watchlist) {
      final tmdbId = item['tmdb_id']?.toString() ?? '';
      final mediaType = item['media_type'] as String? ?? 'tv';
      if (tmdbId.isEmpty) continue;
      if (mediaType == 'tv') {
        showIds.add(tmdbId);
      } else if (mediaType == 'movie') {
        movieIds.add(tmdbId);
      }
    }

    // Also count from favorites
    for (final item in favorites) {
      final tmdbId = item['tmdb_id']?.toString() ?? '';
      final mediaType = item['media_type'] as String? ?? 'tv';
      if (tmdbId.isEmpty) continue;
      if (mediaType == 'tv') {
        showIds.add(tmdbId);
      } else if (mediaType == 'movie') {
        movieIds.add(tmdbId);
      }
    }

    final totalShows = showIds.length;
    final totalMovies = movieIds.length;
    final totalHours = (totalEpisodes * 45 + totalMovies * 120) ~/ 60;
    final avgEpisodesPerShow = totalShows > 0 ? (totalEpisodes / totalShows).round() : 0;

    String mostWatchedShowId = '';
    var mostWatchedShowEpisodes = 0;
    showEpisodeCounts.forEach((id, count) {
      if (count > mostWatchedShowEpisodes) {
        mostWatchedShowEpisodes = count;
        mostWatchedShowId = id;
      }
    });

    final sortedDays = activeDays.toList()..sort();
    var longestStreak = 0;
    var tempStreak = 1;
    for (var i = 1; i < sortedDays.length; i++) {
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
    var currentStreak = 0;
    for (var i = 0; i < 365; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final checkKey =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (activeDays.contains(checkKey)) {
        currentStreak++;
      } else if (i > 0) {
        break;
      }
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    var favoriteDay = '';
    var maxDayCount = 0;
    dayOfWeekCounts.forEach((day, count) {
      if (count > maxDayCount && day >= 1 && day <= 7) {
        maxDayCount = count;
        favoriteDay = dayNames[day - 1];
      }
    });

    var favoriteTime = '';
    var maxHourCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxHourCount) {
        maxHourCount = count;
        if (hour >= 6 && hour < 12) {
          favoriteTime = 'Morning';
        } else if (hour >= 12 && hour < 18) {
          favoriteTime = 'Afternoon';
        } else if (hour >= 18 && hour < 22) {
          favoriteTime = 'Evening';
        } else {
          favoriteTime = 'Night';
        }
      }
    });

    final sortedMonthly = Map<String, int>.fromEntries(
      monthlyWatched.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return UserActivityStats(
      totalShows: totalShows,
      totalMovies: totalMovies,
      totalEpisodes: totalEpisodes,
      totalHours: totalHours,
      longestStreak: longestStreak,
      currentStreak: currentStreak,
      monthlyWatched: sortedMonthly,
      favoriteDay: favoriteDay,
      favoriteTime: favoriteTime,
      avgEpisodesPerShow: avgEpisodesPerShow,
      mostWatchedShowId: mostWatchedShowId,
      mostWatchedShowEpisodes: mostWatchedShowEpisodes,
      showEpisodeCounts: Map.unmodifiable(showEpisodeCounts),
    );
  }
}
