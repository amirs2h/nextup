import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class SearchState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  final List<String> recentSearches;
  SearchInitial({this.recentSearches = const []});

  @override
  List<Object?> get props => [recentSearches];
}

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

// Cache entry
class _CacheEntry {
  final List<ShowModel> shows;
  final List<MovieModel> movies;
  final List<Map<String, dynamic>> users;
  final DateTime timestamp;

  _CacheEntry({
    required this.shows,
    required this.movies,
    required this.users,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inMinutes > 5;
}

// Cubit
class SearchCubit extends Cubit<SearchState> {
  final TmdbService _tmdbService;
  final SupabaseService _supabaseService;
  int _searchId = 0;
  final Map<String, _CacheEntry> _cache = {};
  List<String> _recentSearches = [];

  SearchCubit(this._tmdbService, this._supabaseService) : super(SearchInitial()) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
      if (!isClosed && state is SearchInitial) {
        emit(SearchInitial(recentSearches: _recentSearches));
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    try {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', _recentSearches);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
    } catch (e) {
      // Silently fail
    }
    if (!isClosed) {
      emit(SearchInitial(recentSearches: []));
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchId++;
      if (isClosed) return;
      emit(SearchInitial(recentSearches: _recentSearches));
      return;
    }

    // Check cache first
    final cached = _cache[query];
    if (cached != null && !cached.isExpired) {
      if (isClosed) return;
      emit(SearchLoaded(shows: cached.shows, movies: cached.movies, users: cached.users, query: query));
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

      // Cache the results
      _cache[query] = _CacheEntry(
        shows: shows,
        movies: movies,
        users: users,
        timestamp: DateTime.now(),
      );

      // Save to recent searches
      await _saveRecentSearch(query);

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
    emit(SearchInitial(recentSearches: _recentSearches));
  }
}
