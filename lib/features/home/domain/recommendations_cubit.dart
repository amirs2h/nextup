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
      // Get user's watch history and watchlist
      final results = await Future.wait([
        _supabaseService.getWatchHistory(userId: user.id),
        _supabaseService.getWatchlist(userId: user.id),
      ]);

      final history = results[0] as List<Map<String, dynamic>>;
      final watchlist = results[1] as List<Map<String, dynamic>>;
      
      Set<int> watchedShowIds = {};
      Set<int> watchedMovieIds = {};
      
      // Exclude actually watched items
      for (final item in history) {
        if (item['media_type'] == 'tv') {
          watchedShowIds.add(item['tmdb_id']);
        } else {
          watchedMovieIds.add(item['tmdb_id']);
        }
      }

      // Get recommendations based on watch history
      List<ShowModel> recommendedShows = [];
      List<MovieModel> recommendedMovies = [];

      // If user has watched shows, get recommendations based on them
      if (watchedShowIds.isNotEmpty) {
        // Get recommendations for the first few watched shows
        final showIdsToRecommend = watchedShowIds.take(3).toList();
        final recommendationFutures = showIdsToRecommend.map((id) async {
          try {
            final data = await _tmdbService.getShowRecommendations(id);
            return (data['results'] as List).map((json) => ShowModel.fromJson(json)).toList();
          } catch (e) {
            return <ShowModel>[];
          }
        }).toList();
        
        final recommendationResults = await Future.wait(recommendationFutures);
        for (final shows in recommendationResults) {
          for (final show in shows) {
            if (!watchedShowIds.contains(show.id) && !recommendedShows.any((s) => s.id == show.id)) {
              recommendedShows.add(show);
            }
          }
        }
      }

      // If user has watched movies, get recommendations based on them
      if (watchedMovieIds.isNotEmpty) {
        final movieIdsToRecommend = watchedMovieIds.take(3).toList();
        final recommendationFutures = movieIdsToRecommend.map((id) async {
          try {
            final data = await _tmdbService.getMovieRecommendations(id);
            return (data['results'] as List).map((json) => MovieModel.fromJson(json)).toList();
          } catch (e) {
            return <MovieModel>[];
          }
        }).toList();
        
        final recommendationResults = await Future.wait(recommendationFutures);
        for (final movies in recommendationResults) {
          for (final movie in movies) {
            if (!watchedMovieIds.contains(movie.id) && !recommendedMovies.any((m) => m.id == movie.id)) {
              recommendedMovies.add(movie);
            }
          }
        }
      }

      // If no recommendations from history, fall back to trending
      if (recommendedShows.isEmpty && recommendedMovies.isEmpty) {
        await _loadDefaultRecommendations();
        return;
      }

      // Prioritize watchlist items at the top
      final watchlistShowIds = watchlist.where((w) => w['media_type'] == 'tv').map((w) => w['tmdb_id'] as int).toSet();
      final watchlistMovieIds = watchlist.where((w) => w['media_type'] == 'movie').map((w) => w['tmdb_id'] as int).toSet();
      
      recommendedShows.sort((a, b) {
        final aInWatchlist = watchlistShowIds.contains(a.id) ? 0 : 1;
        final bInWatchlist = watchlistShowIds.contains(b.id) ? 0 : 1;
        return aInWatchlist.compareTo(bInWatchlist);
      });
      
      recommendedMovies.sort((a, b) {
        final aInWatchlist = watchlistMovieIds.contains(a.id) ? 0 : 1;
        final bInWatchlist = watchlistMovieIds.contains(b.id) ? 0 : 1;
        return aInWatchlist.compareTo(bInWatchlist);
      });

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
