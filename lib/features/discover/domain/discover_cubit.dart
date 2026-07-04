import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/models/genre_model.dart';

// States
abstract class DiscoverState {}

class DiscoverInitial extends DiscoverState {}

class DiscoverLoading extends DiscoverState {}

class DiscoverLoaded extends DiscoverState {
  final List<GenreModel> genres;
  final List<ShowModel> shows;
  final List<MovieModel> movies;
  final int? selectedGenreId;
  final String mediaType; // 'tv' or 'movie'

  DiscoverLoaded({
    required this.genres,
    required this.shows,
    required this.movies,
    this.selectedGenreId,
    this.mediaType = 'tv',
  });
}

class DiscoverError extends DiscoverState {
  final String message;
  DiscoverError(this.message);
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

      // Combine and deduplicate
      final allGenres = [...showGenres];
      for (final genre in movieGenres) {
        if (!allGenres.any((g) => g.id == genre.id)) {
          allGenres.add(genre);
        }
      }

      // Load initial content
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
      emit(DiscoverError(e.toString()));
    }
  }

  Future<void> filterByGenre(int genreId, String mediaType) async {
    emit(DiscoverLoading());
    try {
      final genres = state is DiscoverLoaded ? (state as DiscoverLoaded).genres : <GenreModel>[];

      if (mediaType == 'tv') {
        final showsData = await _tmdbService.discoverShows(genreIds: [genreId]);
        final shows = (showsData['results'] as List)
            .map((json) => ShowModel.fromJson(json))
            .toList();
        emit(DiscoverLoaded(
          genres: genres,
          shows: shows,
          movies: [],
          selectedGenreId: genreId,
          mediaType: 'tv',
        ));
      } else {
        final moviesData = await _tmdbService.discoverMovies(genreIds: [genreId]);
        final movies = (moviesData['results'] as List)
            .map((json) => MovieModel.fromJson(json))
            .toList();
        emit(DiscoverLoaded(
          genres: genres,
          shows: [],
          movies: movies,
          selectedGenreId: genreId,
          mediaType: 'movie',
        ));
      }
    } catch (e) {
      emit(DiscoverError(e.toString()));
    }
  }

  void clearFilter() {
    loadGenres();
  }
}
