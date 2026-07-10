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

class WatchHistoryLoaded extends WatchHistoryState {
  final List<Map<String, dynamic>> history;
  final Map<int, ShowModel> shows;
  final Map<int, MovieModel> movies;

  WatchHistoryLoaded({
    required this.history,
    required this.shows,
    required this.movies,
  });

  @override
  List<Object?> get props => [history, shows, movies];
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
      emit(WatchHistoryLoaded(history: [], shows: {}, movies: {}));
      return;
    }

    if (isClosed) return;
    emit(WatchHistoryLoading());
    try {
      final history = await _supabaseService.getWatchHistory(userId: user.id);

      if (history.isEmpty) {
        if (isClosed) return;
        emit(WatchHistoryLoaded(history: [], shows: {}, movies: {}));
        return;
      }

      // Deduplicate by tmdb_id
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

      if (isClosed) return;
      emit(WatchHistoryLoaded(history: history, shows: shows, movies: movies));
    } catch (e) {
      if (isClosed) return;
      emit(WatchHistoryError('Something went wrong. Please try again.'));
    }
  }
}