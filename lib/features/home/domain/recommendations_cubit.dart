import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

abstract class RecommendationsState {}

class RecommendationsInitial extends RecommendationsState {}

class RecommendationsLoading extends RecommendationsState {}

class RecommendationsLoaded extends RecommendationsState {
  final List<ShowModel> shows;
  final List<MovieModel> movies;

  RecommendationsLoaded({required this.shows, required this.movies});
}

class RecommendationsError extends RecommendationsState {
  final String message;
  RecommendationsError(this.message);
}

class RecommendationsCubit extends Cubit<RecommendationsState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  RecommendationsCubit(this._supabaseService, this._tmdbService) : super(RecommendationsInitial());

  Future<void> loadRecommendations() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      await _loadDefaultRecommendations();
      return;
    }

    emit(RecommendationsLoading());
    try {
      // Get user's watch history to find favorite genres
      final history = await _supabaseService.getWatchHistory(userId: user.id);
      final watchlist = await _supabaseService.getWatchlist(userId: user.id);
      
      Set<int> watchedShowIds = {};
      Set<int> watchedMovieIds = {};
      
      for (final item in history) {
        if (item['media_type'] == 'tv') {
          watchedShowIds.add(item['tmdb_id']);
        } else {
          watchedMovieIds.add(item['tmdb_id']);
        }
      }
      
      for (final item in watchlist) {
        if (item['media_type'] == 'tv') {
          watchedShowIds.add(item['tmdb_id']);
        } else {
          watchedMovieIds.add(item['tmdb_id']);
        }
      }

      // Get similar shows based on what user has watched
      List<ShowModel> recommendedShows = [];
      List<MovieModel> recommendedMovies = [];

      // Get trending and filter out already watched
      final trendingShows = await _tmdbService.getTrendingShows();
      final trendingMovies = await _tmdbService.getTrendingMovies();

      for (final showData in (trendingShows['results'] as List)) {
        final show = ShowModel.fromJson(showData);
        if (!watchedShowIds.contains(show.id)) {
          recommendedShows.add(show);
        }
      }

      for (final movieData in (trendingMovies['results'] as List)) {
        final movie = MovieModel.fromJson(movieData);
        if (!watchedMovieIds.contains(movie.id)) {
          recommendedMovies.add(movie);
        }
      }

      emit(RecommendationsLoaded(
        shows: recommendedShows.take(20).toList(),
        movies: recommendedMovies.take(20).toList(),
      ));
    } catch (e) {
      await _loadDefaultRecommendations();
    }
  }

  Future<void> _loadDefaultRecommendations() async {
    emit(RecommendationsLoading());
    try {
      final results = await Future.wait([
        _tmdbService.getTrendingShows(),
        _tmdbService.getTrendingMovies(),
      ]);

      final shows = (results[0]['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();
      final movies = (results[1]['results'] as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      emit(RecommendationsLoaded(shows: shows, movies: movies));
    } catch (e) {
      emit(RecommendationsError(e.toString()));
    }
  }
}
