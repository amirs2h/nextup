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
      final results = await Future.wait([
        _supabaseService.getWatchHistory(userId: user.id),
        _supabaseService.getUserStats(user.id),
      ]);
      final history = List<Map<String, dynamic>>.from(results[0] as List);
      final rpcStats = results[1] as Map<String, dynamic>?;
      final activity = UserActivityStats.fromHistory(history);

      // Use RPC for accurate counts (handles 1000+ row users)
      final accurateShows = (rpcStats?['total_shows'] as num?)?.toInt() ?? activity.totalShows;
      final accurateMovies = (rpcStats?['total_movies'] as num?)?.toInt() ?? activity.totalMovies;
      final accurateEpisodes = (rpcStats?['total_episodes'] as num?)?.toInt() ?? activity.totalEpisodes;
      final accurateHours = (rpcStats?['total_hours'] as num?)?.toInt() ?? activity.totalHours;

      var mostWatchedShow = activity.mostWatchedShowId;
      if (mostWatchedShow.isNotEmpty) {
        try {
          final data = await _tmdbService.getShowDetails(int.parse(mostWatchedShow));
          mostWatchedShow = data['name'] as String? ?? 'Unknown';
        } catch (_) {
          mostWatchedShow = 'Unknown';
        }
      }

      // Top genres from denormalized genres column (all history items, not just 20)
      final genreCounts = <String, int>{};
      final seenTitleKeys = <String>{};
      for (final item in history) {
        final tmdbId = item['tmdb_id'];
        final mediaType = item['media_type'] as String? ?? 'tv';
        if (tmdbId == null) continue;
        final titleKey = '$mediaType:$tmdbId';
        if (seenTitleKeys.contains(titleKey)) continue;
        seenTitleKeys.add(titleKey);
        final rawGenres = item['genres'];
        if (rawGenres is List) {
          for (final g in rawGenres) {
            final name = g?.toString();
            if (name != null && name.isNotEmpty) {
              genreCounts[name] = (genreCounts[name] ?? 0) + 1;
            }
          }
        }
      }

      final topGenres = genreCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topGenresList = topGenres
          .take(5)
          .map((e) => {'name': e.key, 'count': e.value})
          .toList();

      if (isClosed) return;
      emit(StatsLoaded(
        totalShows: accurateShows,
        totalMovies: accurateMovies,
        totalEpisodes: accurateEpisodes,
        totalHours: accurateHours,
        monthlyWatched: activity.monthlyWatched,
        topGenres: topGenresList,
        longestStreak: activity.longestStreak,
        currentStreak: activity.currentStreak,
        favoriteDay: activity.favoriteDay,
        favoriteTime: activity.favoriteTime,
        avgEpisodesPerShow: accurateShows > 0 ? (accurateEpisodes / accurateShows).round() : 0,
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
