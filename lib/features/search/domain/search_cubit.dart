import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/services/tmdb_service.dart';

// States
abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<ShowModel> shows;
  final List<MovieModel> movies;
  final String query;

  SearchLoaded({
    required this.shows,
    required this.movies,
    required this.query,
  });
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

// Cubit
class SearchCubit extends Cubit<SearchState> {
  final TmdbService _tmdbService;

  SearchCubit(this._tmdbService) : super(SearchInitial());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    try {
      final results = await Future.wait([
        _tmdbService.searchShows(query),
        _tmdbService.searchMovies(query),
      ]);

      final shows = (results[0]['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();

      final movies = (results[1]['results'] as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      emit(SearchLoaded(shows: shows, movies: movies, query: query));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  void clear() {
    emit(SearchInitial());
  }
}
