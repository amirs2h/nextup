import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

abstract class RecommendationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RecommendationsInitial extends RecommendationsState {}

class RecommendationsLoading extends RecommendationsState {}

class RecommendationsLoaded extends RecommendationsState {
  final List<ShowModel> shows;
  final List<MovieModel> movies;

  RecommendationsLoaded({required this.shows, required this.movies});

  @override
  List<Object?> get props => [shows, movies];
}

class RecommendationsError extends RecommendationsState {
  final String message;
  RecommendationsError(this.message);

  @override
  List<Object?> get props => [message];
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

    if (isClosed) return;
    emit(RecommendationsLoading());
    try {
      // Get user's watch history and watchlist
      final results = await Future.wait([
        _supabaseService.getWatchHistory(userId: user.id),
        _supabaseService.getWatchlist(userId: user.id),
      ]);

      final history = results[0];
      final watchlist = results[1];
      
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
        // Get recommendations for the first 5 watched shows (increased from 3)
        final showIdsToRecommend = watchedShowIds.take(5).toList();
        final recommendationFutures = showIdsToRecommend.map((id) async {
          try {
            final data = await _tmdbService.getShowRecommendations(id);
            return (data['results'] as List).map((json) => json as Map<String, dynamic>).toList();
          } catch (e) {
            return <Map<String, dynamic>>[];
          }
        }).toList();
        
        final recommendationResults = await Future.wait(recommendationFutures);
        final seenIds = <int>{};
        for (final shows in recommendationResults) {
          for (final json in shows) {
            final id = json['id'] as int?;
            final voteCount = (json['vote_count'] ?? 0) as int;
            final posterPath = json['poster_path'] as String?;
            if (id != null && !seenIds.contains(id) && !watchedShowIds.contains(id) && voteCount >= 50 && posterPath != null && posterPath.isNotEmpty) {
              seenIds.add(id);
              recommendedShows.add(ShowModel.fromJson(json));
            }
          }
        }
      }

      if (watchedMovieIds.isNotEmpty) {
        // Get recommendations for the first 5 watched movies (increased from 3)
        final movieIdsToRecommend = watchedMovieIds.take(5).toList();
        final recommendationFutures = movieIdsToRecommend.map((id) async {
          try {
            final data = await _tmdbService.getMovieRecommendations(id);
            return (data['results'] as List).map((json) => json as Map<String, dynamic>).toList();
          } catch (e) {
            return <Map<String, dynamic>>[];
          }
        }).toList();
        
        final recommendationResults = await Future.wait(recommendationFutures);
        final seenIds = <int>{};
        for (final movies in recommendationResults) {
          for (final json in movies) {
            final id = json['id'] as int?;
            final voteCount = (json['vote_count'] ?? 0) as int;
            final posterPath = json['poster_path'] as String?;
            if (id != null && !seenIds.contains(id) && !watchedMovieIds.contains(id) && voteCount >= 50 && posterPath != null && posterPath.isNotEmpty) {
              seenIds.add(id);
              recommendedMovies.add(MovieModel.fromJson(json));
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

      if (isClosed) return;
      emit(RecommendationsLoaded(
        shows: recommendedShows.take(20).toList(),
        movies: recommendedMovies.take(20).toList(),
      ));
    } catch (e) {
      await _loadDefaultRecommendations();
    }
  }

  Future<void> _loadDefaultRecommendations() async {
    if (isClosed) return;
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

      if (isClosed) return;
      emit(RecommendationsLoaded(shows: shows, movies: movies));
    } catch (e) {
      if (isClosed) return;
      emit(RecommendationsError('Something went wrong. Please try again.'));
    }
  }
}