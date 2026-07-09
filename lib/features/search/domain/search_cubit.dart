import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class SearchState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<ShowModel> shows;
  final List<MovieModel> movies;
  final List<Map<String, dynamic>> users;
  final String query;

  SearchLoaded({
    required this.shows,
    required this.movies,
    required this.users,
    required this.query,
  });

  @override
  List<Object?> get props => [shows, movies, users, query];
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SearchCubit extends Cubit<SearchState> {
  final TmdbService _tmdbService;
  final SupabaseService _supabaseService;
  int _searchId = 0;

  SearchCubit(this._tmdbService, this._supabaseService) : super(SearchInitial());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchId++;
      if (isClosed) return;
      emit(SearchInitial());
      return;
    }

    final currentSearchId = ++_searchId;
    if (isClosed) return;
    emit(SearchLoading());
    try {
      final showsData = _tmdbService.searchShows(query);
      final moviesData = _tmdbService.searchMovies(query);
      final usersData = _supabaseService.searchUsers(query);

      final results = await Future.wait([showsData, moviesData, usersData]);

      // Check if a newer search has started
      if (currentSearchId != _searchId || isClosed) return;

      final shows = ((results[0] as Map)['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();

      final movies = ((results[1] as Map)['results'] as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      final users = List<Map<String, dynamic>>.from(results[2] as List);

      emit(SearchLoaded(shows: shows, movies: movies, users: users, query: query));
    } catch (e) {
      // Check if a newer search has started
      if (currentSearchId != _searchId || isClosed) return;
      emit(SearchError('Something went wrong. Please try again.'));
    }
  }

  void clear() {
    _searchId++;
    if (isClosed) return;
    emit(SearchInitial());
  }
}