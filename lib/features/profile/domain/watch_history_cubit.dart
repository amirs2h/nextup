import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

abstract class WatchHistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WatchHistoryInitial extends WatchHistoryState {}

class WatchHistoryLoading extends WatchHistoryState {}

class WatchHistoryGroupedItem {
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterPath;
  final int episodeCount;
  final int? latestSeason;
  final int? latestEpisode;
  final DateTime latestWatchedAt;

  WatchHistoryGroupedItem({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    required this.episodeCount,
    this.latestSeason,
    this.latestEpisode,
    required this.latestWatchedAt,
  });
}

class WatchHistoryLoaded extends WatchHistoryState {
  final List<Map<String, dynamic>> history;
  final Map<int, ShowModel> shows;
  final Map<int, MovieModel> movies;
  final List<WatchHistoryGroupedItem> groupedHistory;

  WatchHistoryLoaded({
    required this.history,
    required this.shows,
    required this.movies,
    required this.groupedHistory,
  });

  @override
  List<Object?> get props => [history, shows, movies, groupedHistory];
}

class WatchHistoryError extends WatchHistoryState {
  final String message;
  WatchHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class WatchHistoryCubit extends Cubit<WatchHistoryState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  WatchHistoryCubit(this._supabaseService, this._tmdbService) : super(WatchHistoryInitial());

  Future<void> loadHistory() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(WatchHistoryLoaded(history: [], shows: {}, movies: {}, groupedHistory: []));
      return;
    }

    if (isClosed) return;
    emit(WatchHistoryLoading());
    try {
      final history = await _supabaseService.getWatchHistory(userId: user.id);

      if (history.isEmpty) {
        if (isClosed) return;
        emit(WatchHistoryLoaded(history: [], shows: {}, movies: {}, groupedHistory: []));
        return;
      }

      // Group by tmdb_id
      final Map<int, List<Map<String, dynamic>>> groupedItems = {};
      for (final item in history) {
        final tmdbId = item['tmdb_id'] as int;
        groupedItems.putIfAbsent(tmdbId, () => []).add(item);
      }

      // Build grouped history
      final List<WatchHistoryGroupedItem> groupedHistory = [];
      for (final entry in groupedItems.entries) {
        final items = entry.value;
        final firstItem = items.first;
        final mediaType = firstItem['media_type'] as String? ?? 'tv';
        final title = firstItem['title'] as String? ?? 'Unknown';
        final posterPath = firstItem['poster_path'] as String?;

        // Find latest watched_at
        DateTime latestWatched = DateTime.fromMillisecondsSinceEpoch(0);
        int? latestSeason;
        int? latestEpisode;
        for (final item in items) {
          final watchedAt = DateTime.tryParse(item['watched_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          if (watchedAt.isAfter(latestWatched)) {
            latestWatched = watchedAt;
            latestSeason = item['season_number'] as int?;
            latestEpisode = item['episode_number'] as int?;
          }
        }

        groupedHistory.add(WatchHistoryGroupedItem(
          tmdbId: entry.key,
          mediaType: mediaType,
          title: title,
          posterPath: posterPath,
          episodeCount: items.length,
          latestSeason: latestSeason,
          latestEpisode: latestEpisode,
          latestWatchedAt: latestWatched,
        ));
      }

      // Sort by latest watched_at descending
      groupedHistory.sort((a, b) => b.latestWatchedAt.compareTo(a.latestWatchedAt));

      // Deduplicate by tmdb_id for show/movie metadata
      final uniqueShowIds = <int>{};
      final uniqueMovieIds = <int>{};
      for (final item in history) {
        final tmdbId = item['tmdb_id'] as int;
        if (item['media_type'] == 'tv') {
          uniqueShowIds.add(tmdbId);
        } else {
          uniqueMovieIds.add(tmdbId);
        }
      }

      // Build lookup from history for title/poster_path
      final Map<int, Map<String, dynamic>> showLookup = {};
      final Map<int, Map<String, dynamic>> movieLookup = {};
      for (final item in history) {
        final tmdbId = item['tmdb_id'] as int;
        if (item['media_type'] == 'tv') {
          showLookup[tmdbId] = item;
        } else {
          movieLookup[tmdbId] = item;
        }
      }

      final showFutures = uniqueShowIds.map((id) async {
        try {
          final item = showLookup[id]!;
          final hasTitle = item['title'] != null && (item['title'] as String).isNotEmpty;
          final hasPoster = item['poster_path'] != null && (item['poster_path'] as String).isNotEmpty;
          if (hasTitle && hasPoster) {
            return MapEntry(id, ShowModel(
              id: id,
              name: item['title'],
              posterPath: item['poster_path'],
            ));
          }
          final data = await _tmdbService.getShowDetails(id);
          return MapEntry(id, ShowModel.fromJson(data));
        } catch (e) {
          return null;
        }
      }).toList();

      final movieFutures = uniqueMovieIds.map((id) async {
        try {
          final item = movieLookup[id]!;
          final hasTitle = item['title'] != null && (item['title'] as String).isNotEmpty;
          final hasPoster = item['poster_path'] != null && (item['poster_path'] as String).isNotEmpty;
          if (hasTitle && hasPoster) {
            return MapEntry(id, MovieModel(
              id: id,
              title: item['title'],
              posterPath: item['poster_path'],
            ));
          }
          final data = await _tmdbService.getMovieDetails(id);
          return MapEntry(id, MovieModel.fromJson(data));
        } catch (e) {
          return null;
        }
      }).toList();

      final results = await Future.wait([...showFutures, ...movieFutures]);

      Map<int, ShowModel> shows = {};
      Map<int, MovieModel> movies = {};

      for (final result in results) {
        if (result == null) continue;
        if (result.value is ShowModel) {
          shows[result.key] = result.value as ShowModel;
        } else {
          movies[result.key] = result.value as MovieModel;
        }
      }

      // Update groupedHistory with correct titles from TMDB
      for (int i = 0; i < groupedHistory.length; i++) {
        final item = groupedHistory[i];
        if (item.title == 'Unknown' || item.posterPath == null || item.posterPath!.isEmpty) {
          String? correctTitle;
          String? correctPoster;
          
          if (item.mediaType == 'tv' && shows.containsKey(item.tmdbId)) {
            correctTitle = shows[item.tmdbId]!.name;
            correctPoster = shows[item.tmdbId]!.posterPath;
          } else if (item.mediaType == 'movie' && movies.containsKey(item.tmdbId)) {
            correctTitle = movies[item.tmdbId]!.title;
            correctPoster = movies[item.tmdbId]!.posterPath;
          }
          
          if (correctTitle != null) {
            groupedHistory[i] = WatchHistoryGroupedItem(
              tmdbId: item.tmdbId,
              mediaType: item.mediaType,
              title: correctTitle,
              posterPath: correctPoster ?? item.posterPath,
              episodeCount: item.episodeCount,
              latestSeason: item.latestSeason,
              latestEpisode: item.latestEpisode,
              latestWatchedAt: item.latestWatchedAt,
            );
          }
        }
      }

      if (isClosed) return;
      emit(WatchHistoryLoaded(
        history: history,
        shows: shows,
        movies: movies,
        groupedHistory: groupedHistory,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(WatchHistoryError('Something went wrong. Please try again.'));
    }
  }
}
