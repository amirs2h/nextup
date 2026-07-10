import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

abstract class FavoritesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<ShowModel> shows;
  final List<MovieModel> movies;

  FavoritesLoaded({required this.shows, required this.movies});

  @override
  List<Object?> get props => [shows, movies];
}

class FavoritesError extends FavoritesState {
  final String message;
  FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  FavoritesCubit(this._supabaseService, this._tmdbService) : super(FavoritesInitial());

  Future<void> loadFavorites() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(FavoritesLoaded(shows: [], movies: []));
      return;
    }

    if (isClosed) return;
    emit(FavoritesLoading());
    try {
      final favorites = await _supabaseService.getFavorites(userId: user.id);

      if (favorites.isEmpty) {
        if (isClosed) return;
        emit(FavoritesLoaded(shows: [], movies: []));
        return;
      }

      final futures = favorites.map((item) async {
        try {
          final hasTitle = item['title'] != null && (item['title'] as String).isNotEmpty;
          final hasPoster = item['poster_path'] != null && (item['poster_path'] as String).isNotEmpty;

          if (item['media_type'] == 'tv') {
            if (hasTitle && hasPoster) {
              return {
                'type': 'tv',
                'model': ShowModel(
                  id: item['tmdb_id'],
                  name: item['title'],
                  posterPath: item['poster_path'],
                ),
              };
            }
            final data = await _tmdbService.getShowDetails(item['tmdb_id']);
            return {'type': 'tv', 'model': ShowModel.fromJson(data)};
          } else {
            if (hasTitle && hasPoster) {
              return {
                'type': 'movie',
                'model': MovieModel(
                  id: item['tmdb_id'],
                  title: item['title'],
                  posterPath: item['poster_path'],
                ),
              };
            }
            final data = await _tmdbService.getMovieDetails(item['tmdb_id']);
            return {'type': 'movie', 'model': MovieModel.fromJson(data)};
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
          shows.add(result['model'] as ShowModel);
        } else {
          movies.add(result['model'] as MovieModel);
        }
      }

      if (isClosed) return;
      emit(FavoritesLoaded(shows: shows, movies: movies));
    } catch (e) {
      if (isClosed) return;
      emit(FavoritesError('Something went wrong. Please try again.'));
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
      if (isClosed) return;
      emit(FavoritesError('Something went wrong. Please try again.'));
    }
  }
}