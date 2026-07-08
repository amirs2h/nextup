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

      if (favorites.isEmpty) {
        emit(FavoritesLoaded(shows: [], movies: []));
        return;
      }

      // Parallel TMDB calls for all favorites
      final futures = favorites.map((item) async {
        try {
          if (item['media_type'] == 'tv') {
            final data = await _tmdbService.getShowDetails(item['tmdb_id']);
            return {'type': 'tv', 'data': data};
          } else {
            final data = await _tmdbService.getMovieDetails(item['tmdb_id']);
            return {'type': 'movie', 'data': data};
          }
        } catch (e) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);

      List<ShowModel> shows = [];
      List<MovieModel> movies = [];

      for (final result in results) {
        if (result == null) continue;
        if (result['type'] == 'tv') {
          shows.add(ShowModel.fromJson(result['data'] as Map<String, dynamic>));
        } else {
          movies.add(MovieModel.fromJson(result['data'] as Map<String, dynamic>));
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
