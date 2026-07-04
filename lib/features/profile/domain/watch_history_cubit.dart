import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

abstract class WatchHistoryState {}

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
}

class WatchHistoryError extends WatchHistoryState {
  final String message;
  WatchHistoryError(this.message);
}

class WatchHistoryCubit extends Cubit<WatchHistoryState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  WatchHistoryCubit(this._supabaseService, this._tmdbService) : super(WatchHistoryInitial());

  Future<void> loadHistory() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      emit(WatchHistoryLoaded(history: [], shows: {}, movies: {}));
      return;
    }

    emit(WatchHistoryLoading());
    try {
      final history = await _supabaseService.getWatchHistory(userId: user.id);

      Map<int, ShowModel> shows = {};
      Map<int, MovieModel> movies = {};

      for (final item in history) {
        final tmdbId = item['tmdb_id'] as int;
        try {
          if (item['media_type'] == 'tv' && !shows.containsKey(tmdbId)) {
            final showData = await _tmdbService.getShowDetails(tmdbId);
            shows[tmdbId] = ShowModel.fromJson(showData);
          } else if (item['media_type'] == 'movie' && !movies.containsKey(tmdbId)) {
            final movieData = await _tmdbService.getMovieDetails(tmdbId);
            movies[tmdbId] = MovieModel.fromJson(movieData);
          }
        } catch (e) {
          continue;
        }
      }

      emit(WatchHistoryLoaded(history: history, shows: shows, movies: movies));
    } catch (e) {
      emit(WatchHistoryError(e.toString()));
    }
  }
}
