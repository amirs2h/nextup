import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/models/person_model.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class MovieDetailState {}

class MovieDetailInitial extends MovieDetailState {}

class MovieDetailLoading extends MovieDetailState {}

class MovieDetailLoaded extends MovieDetailState {
  final MovieModel movie;
  final List<PersonModel> cast;
  final List<MovieModel> similarMovies;
  final bool isInWatchlist;
  final bool isFavorite;
  final bool isWatched;
  final List<Map<String, dynamic>> videos;
  final Map<String, dynamic>? watchProviders;

  MovieDetailLoaded({
    required this.movie,
    required this.cast,
    required this.similarMovies,
    this.isInWatchlist = false,
    this.isFavorite = false,
    this.isWatched = false,
    this.videos = const [],
    this.watchProviders,
  });
}

class MovieDetailError extends MovieDetailState {
  final String message;
  MovieDetailError(this.message);
}

// Cubit
class MovieDetailCubit extends Cubit<MovieDetailState> {
  final TmdbService _tmdbService;
  final SupabaseService _supabaseService;
  final int movieId;

  MovieDetailCubit(this._tmdbService, this._supabaseService, this.movieId)
      : super(MovieDetailInitial()) {
    loadMovieDetails();
  }

  Future<void> loadMovieDetails() async {
    emit(MovieDetailLoading());
    try {
      final detailsData = await _tmdbService.getMovieDetails(movieId);
      final creditsData = await _tmdbService.getMovieCredits(movieId);
      final similarData = await _tmdbService.getSimilarMovies(movieId);
      final videosData = await _tmdbService.getMovieVideos(movieId);
      final providersData = await _tmdbService.getMovieWatchProviders(movieId);

      final movie = MovieModel.fromJson(detailsData);
      final cast = (creditsData['cast'] as List)
          .take(20)
          .map((json) => PersonModel.fromJson(json))
          .toList();
      final similarMovies = (similarData['results'] as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();
      final videos = List<Map<String, dynamic>>.from(videosData);
      final watchProviders = providersData;

      // Check watchlist, favorites, and watched status
      bool isInWatchlist = false;
      bool isFavorite = false;
      bool isWatched = false;

      final user = _supabaseService.currentUser;
      if (user != null) {
        final dbResults = await Future.wait([
          _supabaseService.isInWatchlist(
            userId: user.id,
            tmdbId: movieId,
            mediaType: 'movie',
          ),
          _supabaseService.isFavorite(
            userId: user.id,
            tmdbId: movieId,
            mediaType: 'movie',
          ),
          _supabaseService.isWatched(
            userId: user.id,
            tmdbId: movieId,
            mediaType: 'movie',
          ),
        ]);
        isInWatchlist = dbResults[0];
        isFavorite = dbResults[1];
        isWatched = dbResults[2];
      }

      emit(MovieDetailLoaded(
        movie: movie,
        cast: cast,
        similarMovies: similarMovies,
        isInWatchlist: isInWatchlist,
        isFavorite: isFavorite,
        isWatched: isWatched,
        videos: videos,
        watchProviders: watchProviders,
      ));
    } catch (e) {
      emit(MovieDetailError(e.toString()));
    }
  }

  Future<void> toggleWatchlist() async {
    final currentState = state;
    if (currentState is! MovieDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      if (currentState.isInWatchlist) {
        await _supabaseService.removeFromWatchlist(
          userId: user.id,
          tmdbId: movieId,
          mediaType: 'movie',
        );
      } else {
        await _supabaseService.addToWatchlist(
          userId: user.id,
          tmdbId: movieId,
          mediaType: 'movie',
        );
      }

      emit(MovieDetailLoaded(
        movie: currentState.movie,
        cast: currentState.cast,
        similarMovies: currentState.similarMovies,
        isInWatchlist: !currentState.isInWatchlist,
        isFavorite: currentState.isFavorite,
        isWatched: currentState.isWatched,
        videos: currentState.videos,
        watchProviders: currentState.watchProviders,
      ));
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is! MovieDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      if (currentState.isFavorite) {
        await _supabaseService.removeFromFavorites(
          userId: user.id,
          tmdbId: movieId,
          mediaType: 'movie',
        );
      } else {
        await _supabaseService.addToFavorites(
          userId: user.id,
          tmdbId: movieId,
          mediaType: 'movie',
        );
      }

      emit(MovieDetailLoaded(
        movie: currentState.movie,
        cast: currentState.cast,
        similarMovies: currentState.similarMovies,
        isInWatchlist: currentState.isInWatchlist,
        isFavorite: !currentState.isFavorite,
        isWatched: currentState.isWatched,
        videos: currentState.videos,
        watchProviders: currentState.watchProviders,
      ));
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> toggleWatched() async {
    final currentState = state;
    if (currentState is! MovieDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      if (currentState.isWatched) {
        await _supabaseService.unmarkAsWatched(
          userId: user.id,
          tmdbId: movieId,
          mediaType: 'movie',
        );
      } else {
        await _supabaseService.markAsWatched(
          userId: user.id,
          tmdbId: movieId,
          mediaType: 'movie',
        );
      }

      emit(MovieDetailLoaded(
        movie: currentState.movie,
        cast: currentState.cast,
        similarMovies: currentState.similarMovies,
        isInWatchlist: currentState.isInWatchlist,
        isFavorite: currentState.isFavorite,
        isWatched: !currentState.isWatched,
        videos: currentState.videos,
        watchProviders: currentState.watchProviders,
      ));
    } catch (e) {
      emit(currentState);
    }
  }
}
