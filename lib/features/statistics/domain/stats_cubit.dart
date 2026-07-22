import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/utils/user_activity_stats.dart';

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
  List<Object?> get props => [
        totalShows,
        totalMovies,
        totalEpisodes,
        totalHours,
        monthlyWatched,
        topGenres,
        longestStreak,
        currentStreak,
        favoriteDay,
        favoriteTime,
        avgEpisodesPerShow,
        mostWatchedShow,
        mostWatchedShowEpisodes,
      ];
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
  List<Map<String, dynamic>> _lastTopGenres = const [];

  StatsCubit(this._supabaseService, this._tmdbService) : super(StatsInitial());

  Future<void> loadStats() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(StatsLoaded());
      return;
    }

    final hadLoaded = state is StatsLoaded;
    if (!hadLoaded) {
      if (isClosed) return;
      emit(StatsLoading());
    }

    try {
      final history = await _supabaseService.getWatchHistory(userId: user.id);
      final activity = UserActivityStats.fromHistory(history);

      var mostWatchedShow = activity.mostWatchedShowId;
      if (mostWatchedShow.isNotEmpty) {
        try {
          final data = await _tmdbService.getShowDetails(int.parse(mostWatchedShow));
          mostWatchedShow = data['name'] as String? ?? 'Unknown';
        } catch (_) {
          mostWatchedShow = 'Unknown';
        }
      }

      // Top genres from recent items; keep previous list if all TMDB calls fail
      final genreCounts = <String, int>{};
      var genreOk = 0;
      final recentItems = history.take(20).toList();
      final genreResults = await Future.wait(recentItems.map((item) async {
        try {
          final tmdbId = item['tmdb_id'] as int;
          final mediaType = item['media_type'] as String? ?? 'tv';
          final data = mediaType == 'tv'
              ? await _tmdbService.getShowDetails(tmdbId)
              : await _tmdbService.getMovieDetails(tmdbId);
          genreOk++;
          return (data['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? <String>[];
        } catch (_) {
          return <String>[];
        }
      }));
      for (final genres in genreResults) {
        for (final genre in genres) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }

      List<Map<String, dynamic>> topGenresList;
      if (genreOk == 0 && _lastTopGenres.isNotEmpty) {
        topGenresList = _lastTopGenres;
      } else {
        final topGenres = genreCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        topGenresList = topGenres
            .take(5)
            .map((e) => {'name': e.key, 'count': e.value})
            .toList();
        if (topGenresList.isNotEmpty) _lastTopGenres = topGenresList;
      }

      if (isClosed) return;
      emit(StatsLoaded(
        totalShows: activity.totalShows,
        totalMovies: activity.totalMovies,
        totalEpisodes: activity.totalEpisodes,
        totalHours: activity.totalHours,
        monthlyWatched: activity.monthlyWatched,
        topGenres: topGenresList,
        longestStreak: activity.longestStreak,
        currentStreak: activity.currentStreak,
        favoriteDay: activity.favoriteDay,
        favoriteTime: activity.favoriteTime,
        avgEpisodesPerShow: activity.avgEpisodesPerShow,
        mostWatchedShow: mostWatchedShow,
        mostWatchedShowEpisodes: activity.mostWatchedShowEpisodes,
      ));
    } catch (e) {
      if (isClosed) return;
      if (state is! StatsLoaded) {
        emit(StatsError('Something went wrong. Please try again.'));
      }
    }
  }
}
