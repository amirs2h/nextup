import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

// States
abstract class WatchlistState {}

class WatchlistInitial extends WatchlistState {}

class WatchlistLoading extends WatchlistState {}

class WatchlistLoaded extends WatchlistState {
  final List<ShowModel> shows;
  final List<MovieModel> movies;
  final String filter; // 'all', 'shows', 'movies'

  WatchlistLoaded({
    required this.shows,
    required this.movies,
    this.filter = 'all',
  });
}

class WatchlistError extends WatchlistState {
  final String message;
  WatchlistError(this.message);
}

// Cubit
class WatchlistCubit extends Cubit<WatchlistState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  WatchlistCubit(this._supabaseService, this._tmdbService) : super(WatchlistInitial());

  Future<void> loadWatchlist({String filter = 'all'}) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      emit(WatchlistLoaded(shows: [], movies: [], filter: filter));
      return;
    }

    emit(WatchlistLoading());
    try {
      final watchlistItems = await _supabaseService.getWatchlist(userId: user.id);

      List<ShowModel> shows = [];
      List<MovieModel> movies = [];

      for (final item in watchlistItems) {
        try {
          if (item['media_type'] == 'tv') {
            final showData = await _tmdbService.getShowDetails(item['tmdb_id']);
            shows.add(ShowModel.fromJson(showData));
          } else if (item['media_type'] == 'movie') {
            final movieData = await _tmdbService.getMovieDetails(item['tmdb_id']);
            movies.add(MovieModel.fromJson(movieData));
          }
        } catch (e) {
          // Skip items that fail to load
          continue;
        }
      }

      emit(WatchlistLoaded(shows: shows, movies: movies, filter: filter));
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  Future<void> removeFromWatchlist(int tmdbId, String mediaType) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.removeFromWatchlist(
        userId: user.id,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      // Reload
      await loadWatchlist(filter: state is WatchlistLoaded ? (state as WatchlistLoaded).filter : 'all');
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  void setFilter(String filter) {
    if (state is WatchlistLoaded) {
      final current = state as WatchlistLoaded;
      emit(WatchlistLoaded(
        shows: current.shows,
        movies: current.movies,
        filter: filter,
      ));
    }
  }
}
