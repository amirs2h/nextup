import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';

abstract class StatsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final int totalShows;
  final int totalMovies;
  final int totalEpisodes;
  final int totalHours;
  final Map<String, int> monthlyWatched;
  final List<Map<String, dynamic>> topGenres;
  final int longestStreak;
  final int currentStreak;
  final String favoriteDay;
  final String favoriteTime;
  final int avgEpisodesPerShow;
  final String mostWatchedShow;
  final int mostWatchedShowEpisodes;

  StatsLoaded({
    this.totalShows = 0,
    this.totalMovies = 0,
    this.totalEpisodes = 0,
    this.totalHours = 0,
    this.monthlyWatched = const {},
    this.topGenres = const [],
    this.longestStreak = 0,
    this.currentStreak = 0,
    this.favoriteDay = '',
    this.favoriteTime = '',
    this.avgEpisodesPerShow = 0,
    this.mostWatchedShow = '',
    this.mostWatchedShowEpisodes = 0,
  });

  @override
  List<Object?> get props => [totalShows, totalMovies, totalEpisodes, totalHours, monthlyWatched, topGenres, longestStreak, currentStreak, favoriteDay, favoriteTime, avgEpisodesPerShow, mostWatchedShow, mostWatchedShowEpisodes];
}

class StatsError extends StatsState {
  final String message;
  StatsError(this.message);

  @override
  List<Object?> get props => [message];
}

class StatsCubit extends Cubit<StatsState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  StatsCubit(this._supabaseService, this._tmdbService) : super(StatsInitial());

  Future<void> loadStats() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(StatsLoaded());
      return;
    }

    if (isClosed) return;
    emit(StatsLoading());
    try {
      final history = await _supabaseService.getWatchHistory(userId: user.id);

      int totalShows = 0;
      int totalMovies = 0;
      int totalEpisodes = 0;
      Set<String> showIds = {};
      Set<String> movieIds = {};
      Map<String, int> monthlyWatched = {};
      Map<String, int> showEpisodeCounts = {};
      Map<int, int> dayOfWeekCounts = {};
      Map<int, int> hourCounts = {};
      Set<String> activeDays = {};

      for (final item in history) {
        if (item['media_type'] == 'tv') {
          final tmdbId = item['tmdb_id'].toString();
          showIds.add(tmdbId);
          if (item['episode_number'] != null) {
            totalEpisodes++;
            showEpisodeCounts[tmdbId] = (showEpisodeCounts[tmdbId] ?? 0) + 1;
          }
        } else {
          movieIds.add(item['tmdb_id'].toString());
        }

        if (item['watched_at'] != null) {
          final date = DateTime.tryParse(item['watched_at']);
          if (date != null) {
            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            monthlyWatched[monthKey] = (monthlyWatched[monthKey] ?? 0) + 1;
            dayOfWeekCounts[date.weekday] = (dayOfWeekCounts[date.weekday] ?? 0) + 1;
            hourCounts[date.hour] = (hourCounts[date.hour] ?? 0) + 1;
            activeDays.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
          }
        }
      }

      totalShows = showIds.length;
      totalMovies = movieIds.length;
      final totalHours = (totalEpisodes * 45 + totalMovies * 120) ~/ 60;
      final avgEpisodesPerShow = totalShows > 0 ? (totalEpisodes / totalShows).round() : 0;

      // Find most watched show
      String mostWatchedShow = '';
      int mostWatchedShowEpisodes = 0;
      showEpisodeCounts.forEach((tmdbId, count) {
        if (count > mostWatchedShowEpisodes) {
          mostWatchedShowEpisodes = count;
          mostWatchedShow = tmdbId;
        }
      });

      // Fetch title for most watched show
      if (mostWatchedShow.isNotEmpty) {
        try {
          final data = await _tmdbService.getShowDetails(int.parse(mostWatchedShow));
          mostWatchedShow = data['name'] ?? 'Unknown';
        } catch (e) {
          mostWatchedShow = 'Unknown';
        }
      }

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
      
      // Current streak: count consecutive days ending today
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

      // Favorite day of week
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      String favoriteDay = '';
      int maxDayCount = 0;
      dayOfWeekCounts.forEach((day, count) {
        if (count > maxDayCount) {
          maxDayCount = count;
          favoriteDay = dayNames[day - 1];
        }
      });

      // Favorite time of day
      String favoriteTime = '';
      int maxHourCount = 0;
      hourCounts.forEach((hour, count) {
        if (count > maxHourCount) {
          maxHourCount = count;
          if (hour >= 6 && hour < 12) favoriteTime = 'Morning';
          else if (hour >= 12 && hour < 18) favoriteTime = 'Afternoon';
          else if (hour >= 18 && hour < 22) favoriteTime = 'Evening';
          else favoriteTime = 'Night';
        }
      });

      // Sort monthly data
      final sortedMonthly = Map.fromEntries(
        monthlyWatched.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      // Top genres
      Map<String, int> genreCounts = {};
      final recentItems = history.take(20).toList();
      final genreFutures = recentItems.map((item) async {
        try {
          final tmdbId = item['tmdb_id'] as int;
          final mediaType = item['media_type'] as String;
          if (mediaType == 'tv') {
            final data = await _tmdbService.getShowDetails(tmdbId);
            return (data['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? [];
          } else {
            final data = await _tmdbService.getMovieDetails(tmdbId);
            return (data['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? [];
          }
        } catch (e) {
          return <String>[];
        }
      });
      final genreResults = await Future.wait(genreFutures);
      for (final genres in genreResults) {
        for (final genre in genres) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }
      final topGenres = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topGenresList = topGenres.take(5).map((e) => {
        'name': e.key,
        'count': e.value,
      }).toList();

      if (isClosed) return;
      emit(StatsLoaded(
        totalShows: totalShows,
        totalMovies: totalMovies,
        totalEpisodes: totalEpisodes,
        totalHours: totalHours,
        monthlyWatched: sortedMonthly,
        topGenres: topGenresList,
        longestStreak: longestStreak,
        currentStreak: currentStreak,
        favoriteDay: favoriteDay,
        favoriteTime: favoriteTime,
        avgEpisodesPerShow: avgEpisodesPerShow,
        mostWatchedShow: mostWatchedShow,
        mostWatchedShowEpisodes: mostWatchedShowEpisodes,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(StatsError('Something went wrong. Please try again.'));
    }
  }
}
