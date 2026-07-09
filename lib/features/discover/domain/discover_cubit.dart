import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/models/genre_model.dart';

// States
abstract class DiscoverState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiscoverInitial extends DiscoverState {}

class DiscoverLoading extends DiscoverState {}

class DiscoverLoaded extends DiscoverState {
  final List<GenreModel> genres;
  final List<ShowModel> shows;
  final List<MovieModel> movies;
  final int? selectedGenreId;
  final String mediaType;
  final String sortBy;
  final int? year;
  final double minRating;
  final int? showStatus;

  DiscoverLoaded({
    required this.genres,
    required this.shows,
    required this.movies,
    this.selectedGenreId,
    this.mediaType = 'tv',
    this.sortBy = 'popularity.desc',
    this.year,
    this.minRating = 0,
    this.showStatus,
  });

  @override
  List<Object?> get props => [genres, shows, movies, selectedGenreId, mediaType, sortBy, year, minRating, showStatus];
}

class DiscoverError extends DiscoverState {
  final String message;
  DiscoverError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class DiscoverCubit extends Cubit<DiscoverState> {
  final TmdbService _tmdbService;

  DiscoverCubit(this._tmdbService) : super(DiscoverInitial()) {
    loadGenres();
  }

  Future<void> loadGenres() async {
    emit(DiscoverLoading());
    try {
      final results = await Future.wait([
        _tmdbService.getShowGenres(),
        _tmdbService.getMovieGenres(),
      ]);

      final showGenres = (results[0]['genres'] as List)
          .map((json) => GenreModel.fromJson(json))
          .toList();

      final movieGenres = (results[1]['genres'] as List)
          .map((json) => GenreModel.fromJson(json))
          .toList();

      final allGenres = [...showGenres];
      for (final genre in movieGenres) {
        if (!allGenres.any((g) => g.id == genre.id)) {
          allGenres.add(genre);
        }
      }

      final showsData = await _tmdbService.discoverShows();
      final moviesData = await _tmdbService.discoverMovies();

      final shows = (showsData['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();
      final movies = (moviesData['results'] as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      emit(DiscoverLoaded(
        genres: allGenres,
        shows: shows,
        movies: movies,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(DiscoverError('Something went wrong. Please try again.'));
    }
  }

  Future<void> applyFilters({
    required String mediaType,
    String? sortBy,
    int? year,
    double? minRating,
    int? genreId,
    int? showStatus,
  }) async {
    if (isClosed) return;
    emit(DiscoverLoading());
    try {
      final genres = state is DiscoverLoaded ? (state as DiscoverLoaded).genres : <GenreModel>[];

      if (mediaType == 'tv') {
        final showsData = await _tmdbService.discoverShows(
          sortBy: sortBy,
          genreIds: genreId != null ? [genreId] : null,
          year: year,
          minRating: minRating,
          showStatus: showStatus,
        );
        final shows = (showsData['results'] as List)
            .map((json) => ShowModel.fromJson(json))
            .toList();
        emit(DiscoverLoaded(
          genres: genres,
          shows: shows,
          movies: [],
          selectedGenreId: genreId,
          mediaType: 'tv',
          sortBy: sortBy ?? 'popularity.desc',
          year: year,
          minRating: minRating ?? 0,
          showStatus: showStatus,
        ));
      } else {
        final moviesData = await _tmdbService.discoverMovies(
          sortBy: sortBy,
          genreIds: genreId != null ? [genreId] : null,
          year: year,
          minRating: minRating,
        );
        final movies = (moviesData['results'] as List)
            .map((json) => MovieModel.fromJson(json))
            .toList();
        emit(DiscoverLoaded(
          genres: genres,
          shows: [],
          movies: movies,
          selectedGenreId: genreId,
          mediaType: 'movie',
          sortBy: sortBy ?? 'popularity.desc',
          year: year,
          minRating: minRating ?? 0,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(DiscoverError('Something went wrong. Please try again.'));
    }
  }

  Future<void> filterByGenre(int genreId, String mediaType) async {
    // Preserve existing filter state
    final currentState = state is DiscoverLoaded ? state as DiscoverLoaded : null;
    final sortBy = currentState?.sortBy;
    final year = currentState?.year;
    final minRating = currentState?.minRating;
    final showStatus = currentState?.showStatus;
    final genres = currentState?.genres ?? <GenreModel>[];

    if (isClosed) return;
    emit(DiscoverLoading());
    try {
      if (mediaType == 'tv') {
        final showsData = await _tmdbService.discoverShows(
          genreIds: [genreId],
          sortBy: sortBy,
          year: year,
          minRating: minRating,
          showStatus: showStatus,
        );
        final shows = (showsData['results'] as List)
            .map((json) => ShowModel.fromJson(json))
            .toList();
        emit(DiscoverLoaded(
          genres: genres,
          shows: shows,
          movies: [],
          selectedGenreId: genreId,
          mediaType: 'tv',
          sortBy: sortBy ?? 'popularity.desc',
          year: year,
          minRating: minRating ?? 0,
          showStatus: showStatus,
        ));
      } else {
        final moviesData = await _tmdbService.discoverMovies(
          genreIds: [genreId],
          sortBy: sortBy,
          year: year,
          minRating: minRating,
        );
        final movies = (moviesData['results'] as List)
            .map((json) => MovieModel.fromJson(json))
            .toList();
        emit(DiscoverLoaded(
          genres: genres,
          shows: [],
          movies: movies,
          selectedGenreId: genreId,
          mediaType: 'movie',
          sortBy: sortBy ?? 'popularity.desc',
          year: year,
          minRating: minRating ?? 0,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(DiscoverError('Something went wrong. Please try again.'));
    }
  }

  void clearFilter() {
    if (state is DiscoverLoaded) {
      final currentState = state as DiscoverLoaded;
      // Re-discover with defaults but preserve genre list
      applyFilters(
        mediaType: currentState.mediaType,
        sortBy: 'popularity.desc',
        year: null,
        minRating: null,
        genreId: null,
        showStatus: null,
      );
    } else {
      loadGenres();
    }
  }
}