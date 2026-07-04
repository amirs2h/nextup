import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

abstract class FavoritesState {}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<ShowModel> shows;
  final List<MovieModel> movies;

  FavoritesLoaded({required this.shows, required this.movies});
}

class FavoritesError extends FavoritesState {
  final String message;
  FavoritesError(this.message);
}

class FavoritesCubit extends Cubit<FavoritesState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  FavoritesCubit(this._supabaseService, this._tmdbService) : super(FavoritesInitial());

  Future<void> loadFavorites() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      emit(FavoritesLoaded(shows: [], movies: []));
      return;
    }

    emit(FavoritesLoading());
    try {
      final favorites = await _supabaseService.getFavorites(userId: user.id);

      List<ShowModel> shows = [];
      List<MovieModel> movies = [];

      for (final item in favorites) {
        try {
          if (item['media_type'] == 'tv') {
            final showData = await _tmdbService.getShowDetails(item['tmdb_id']);
            shows.add(ShowModel.fromJson(showData));
          } else if (item['media_type'] == 'movie') {
            final movieData = await _tmdbService.getMovieDetails(item['tmdb_id']);
            movies.add(MovieModel.fromJson(movieData));
          }
        } catch (e) {
          continue;
        }
      }

      emit(FavoritesLoaded(shows: shows, movies: movies));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> removeFromFavorites(int tmdbId, String mediaType) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.removeFromFavorites(
        userId: user.id,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      await loadFavorites();
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }
}
