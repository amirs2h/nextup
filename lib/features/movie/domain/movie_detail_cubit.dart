import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/models/person_model.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/omdb_service.dart';

// States
abstract class MovieDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

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
  final String? imdbId;
  final String? contentRating;
  final int? rottenTomatoesScore;
  final String? imdbRating;
  final double? userRating;
  final double averageRating;

  MovieDetailLoaded({
    required this.movie,
    required this.cast,
    required this.similarMovies,
    this.isInWatchlist = false,
    this.isFavorite = false,
    this.isWatched = false,
    this.videos = const [],
    this.watchProviders,
    this.imdbId,
    this.contentRating,
    this.rottenTomatoesScore,
    this.imdbRating,
    this.userRating,
    this.averageRating = 0,
  });

  MovieDetailLoaded copyWith({
    MovieModel? movie,
    List<PersonModel>? cast,
    List<MovieModel>? similarMovies,
    bool? isInWatchlist,
    bool? isFavorite,
    bool? isWatched,
    List<Map<String, dynamic>>? videos,
    Map<String, dynamic>? watchProviders,
    String? imdbId,
    String? contentRating,
    int? rottenTomatoesScore,
    String? imdbRating,
    double? userRating,
    double? averageRating,
  }) {
    return MovieDetailLoaded(
      movie: movie ?? this.movie,
      cast: cast ?? this.cast,
      similarMovies: similarMovies ?? this.similarMovies,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
      isFavorite: isFavorite ?? this.isFavorite,
      isWatched: isWatched ?? this.isWatched,
      videos: videos ?? this.videos,
      watchProviders: watchProviders ?? this.watchProviders,
      imdbId: imdbId ?? this.imdbId,
      contentRating: contentRating ?? this.contentRating,
      rottenTomatoesScore: rottenTomatoesScore ?? this.rottenTomatoesScore,
      imdbRating: imdbRating ?? this.imdbRating,
      userRating: userRating ?? this.userRating,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  @override
  List<Object?> get props => [movie, cast, similarMovies, isInWatchlist, isFavorite, isWatched, videos, watchProviders, imdbId, contentRating, rottenTomatoesScore, imdbRating, userRating, averageRating];
}

class MovieDetailError extends MovieDetailState {
  final String message;
  MovieDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class MovieDetailCubit extends Cubit<MovieDetailState> {
  final TmdbService _tmdbService;
  final SupabaseService _supabaseService;
  final OmdbService _omdbService;
  final int movieId;

  MovieDetailCubit(this._tmdbService, this._supabaseService, this._omdbService, this.movieId)
      : super(MovieDetailInitial()) {
    loadMovieDetails();
  }

  Future<void> loadMovieDetails() async {
    if (isClosed) return;
    emit(MovieDetailLoading());
    try {
      // Parallel TMDB calls (7 calls in parallel)
      final tmdbResults = await Future.wait([
        _tmdbService.getMovieDetails(movieId),
        _tmdbService.getMovieCredits(movieId),
        _tmdbService.getSimilarMovies(movieId),
        _tmdbService.getMovieVideos(movieId),
        _tmdbService.getMovieWatchProviders(movieId),
        _tmdbService.getMovieExternalIds(movieId),
        _tmdbService.getMovieReleaseDates(movieId),
      ]);

      final detailsData = tmdbResults[0] as Map<String, dynamic>;
      final creditsData = tmdbResults[1] as Map<String, dynamic>;
      final similarData = tmdbResults[2] as Map<String, dynamic>;
      final videosData = tmdbResults[3] as List<Map<String, dynamic>>;
      final providersData = tmdbResults[4] as Map<String, dynamic>;
      final externalIdsData = tmdbResults[5] as Map<String, dynamic>;
      final releaseDatesData = tmdbResults[6] as Map<String, dynamic>;

      final movie = MovieModel.fromJson(detailsData);
      final cast = (creditsData['cast'] as List)
          .take(20)
          .map((json) => PersonModel.fromJson(json))
          .toList();
      final similarMovies = (similarData['results'] as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();
      final videos = videosData;
      final watchProviders = providersData;
      final imdbId = externalIdsData['imdb_id'] as String?;

      // Get content rating (US preferred)
      String? contentRating;
      final releaseDates = releaseDatesData['results'] as List?;
      if (releaseDates != null) {
        for (final r in releaseDates) {
          if (r['iso_3166_1'] == 'US') {
            final dates = r['release_dates'] as List?;
            if (dates != null && dates.isNotEmpty) {
              contentRating = dates.first['certification'];
            }
            break;
          }
        }
        if (contentRating == null && releaseDates.isNotEmpty) {
          final firstResult = releaseDates.first;
          final dates = firstResult['release_dates'] as List?;
          if (dates != null && dates.isNotEmpty) {
            contentRating = dates.first['certification'];
          }
        }
      }

      // Get OMDB ratings (depends on imdbId from external_ids)
      int? rottenTomatoesScore;
      String? imdbRating;
      if (imdbId != null) {
        final omdbData = await _omdbService.getRatings(imdbId);
        if (omdbData != null) {
          rottenTomatoesScore = _omdbService.getRottenTomatoesScore(omdbData);
          imdbRating = _omdbService.getImdbRating(omdbData);
        }
      }

      // Parallel Supabase calls (5 calls in parallel)
      final user = _supabaseService.currentUser;
      bool isInWatchlist = false;
      bool isFavorite = false;
      bool isWatched = false;
      double? userRating;
      double averageRating = 0;

      if (user != null) {
        final supabaseResults = await Future.wait([
          _supabaseService.isInWatchlist(userId: user.id, tmdbId: movieId, mediaType: 'movie'),
          _supabaseService.isFavorite(userId: user.id, tmdbId: movieId, mediaType: 'movie'),
          _supabaseService.isWatched(userId: user.id, tmdbId: movieId, mediaType: 'movie'),
          _supabaseService.getUserRating(userId: user.id, tmdbId: movieId, mediaType: 'movie'),
          _supabaseService.getAverageRating(tmdbId: movieId, mediaType: 'movie'),
        ]);
        isInWatchlist = supabaseResults[0] as bool;
        isFavorite = supabaseResults[1] as bool;
        isWatched = supabaseResults[2] as bool;
        userRating = supabaseResults[3] as double?;
        averageRating = supabaseResults[4] as double;
      } else {
        averageRating = await _supabaseService.getAverageRating(tmdbId: movieId, mediaType: 'movie');
      }

      if (isClosed) return;
      emit(MovieDetailLoaded(
        movie: movie,
        cast: cast,
        similarMovies: similarMovies,
        isInWatchlist: isInWatchlist,
        isFavorite: isFavorite,
        isWatched: isWatched,
        videos: videos,
        watchProviders: watchProviders,
        imdbId: imdbId,
        contentRating: contentRating,
        rottenTomatoesScore: rottenTomatoesScore,
        imdbRating: imdbRating,
        userRating: userRating,
        averageRating: averageRating,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(MovieDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> toggleWatchlist({String status = 'watchlist'}) async {
    final currentState = state;
    if (currentState is! MovieDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    final newValue = !currentState.isInWatchlist;
    emit(currentState.copyWith(isInWatchlist: newValue));

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
          status: status,
        );
      }
    } catch (e) {
      if (!isClosed) emit(currentState);
    }
  }

  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is! MovieDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    final newValue = !currentState.isFavorite;
    emit(currentState.copyWith(isFavorite: newValue));

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
    } catch (e) {
      if (!isClosed) emit(currentState);
    }
  }

  Future<void> toggleWatched() async {
    final currentState = state;
    if (currentState is! MovieDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    final newIsWatched = !currentState.isWatched;
    emit(currentState.copyWith(isWatched: newIsWatched));

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
          title: currentState.movie.title,
          posterPath: currentState.movie.posterPath,
        );
      }

      try {
        await _supabaseService.computeAndSetMovieStatus(
          userId: user.id,
          tmdbId: movieId,
          isWatched: newIsWatched,
        );
        final newIsInWatchlist = await _supabaseService.isInWatchlist(
          userId: user.id,
          tmdbId: movieId,
          mediaType: 'movie',
        );
        if (!isClosed) emit((state as MovieDetailLoaded).copyWith(isInWatchlist: newIsInWatchlist));
      } catch (_) {}
    } catch (e) {
      if (!isClosed) emit(currentState);
    }
  }
}