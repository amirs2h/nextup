import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/person_model.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class ShowDetailState {}

class ShowDetailInitial extends ShowDetailState {}

class ShowDetailLoading extends ShowDetailState {}

class ShowDetailLoaded extends ShowDetailState {
  final ShowModel show;
  final List<PersonModel> cast;
  final List<ShowModel> similarShows;
  final bool isInWatchlist;
  final bool isFavorite;
  final Map<int, bool> watchedEpisodes;
  final List<Map<String, dynamic>> videos;
  final Map<String, dynamic>? watchProviders;

  ShowDetailLoaded({
    required this.show,
    required this.cast,
    required this.similarShows,
    this.isInWatchlist = false,
    this.isFavorite = false,
    this.watchedEpisodes = const {},
    this.videos = const [],
    this.watchProviders,
  });
}

class ShowDetailError extends ShowDetailState {
  final String message;
  ShowDetailError(this.message);
}

// Cubit
class ShowDetailCubit extends Cubit<ShowDetailState> {
  final TmdbService _tmdbService;
  final SupabaseService _supabaseService;
  final int showId;

  ShowDetailCubit(this._tmdbService, this._supabaseService, this.showId)
      : super(ShowDetailInitial()) {
    loadShowDetails();
  }

  Future<void> loadShowDetails() async {
    emit(ShowDetailLoading());
    try {
      final detailsData = await _tmdbService.getShowDetails(showId);
      final creditsData = await _tmdbService.getShowCredits(showId);
      final similarData = await _tmdbService.getSimilarShows(showId);
      final videosData = await _tmdbService.getShowVideos(showId);
      final providersData = await _tmdbService.getShowWatchProviders(showId);

      final show = ShowModel.fromJson(detailsData);
      final cast = (creditsData['cast'] as List)
          .take(20)
          .map((json) => PersonModel.fromJson(json))
          .toList();
      final similarShows = (similarData['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();
      final videos = List<Map<String, dynamic>>.from(videosData);
      final watchProviders = providersData;

      // Check watchlist and favorites
      bool isInWatchlist = false;
      bool isFavorite = false;
      Map<int, bool> watchedEpisodes = {};

      final user = _supabaseService.currentUser;
      if (user != null) {
        final watchlistFuture = _supabaseService.isInWatchlist(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
        );
        final favoriteFuture = _supabaseService.isFavorite(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
        );

        final results = await Future.wait([watchlistFuture, favoriteFuture]);
        isInWatchlist = results[0];
        isFavorite = results[1];
      }

      emit(ShowDetailLoaded(
        show: show,
        cast: cast,
        similarShows: similarShows,
        isInWatchlist: isInWatchlist,
        isFavorite: isFavorite,
        watchedEpisodes: watchedEpisodes,
        videos: videos,
        watchProviders: watchProviders,
      ));
    } catch (e) {
      emit(ShowDetailError(e.toString()));
    }
  }

  Future<void> toggleWatchlist() async {
    final currentState = state;
    if (currentState is! ShowDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      if (currentState.isInWatchlist) {
        await _supabaseService.removeFromWatchlist(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
        );
      } else {
        await _supabaseService.addToWatchlist(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
        );
      }

      emit(ShowDetailLoaded(
        show: currentState.show,
        cast: currentState.cast,
        similarShows: currentState.similarShows,
        isInWatchlist: !currentState.isInWatchlist,
        isFavorite: currentState.isFavorite,
        watchedEpisodes: currentState.watchedEpisodes,
        videos: currentState.videos,
        watchProviders: currentState.watchProviders,
      ));
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is! ShowDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      if (currentState.isFavorite) {
        await _supabaseService.removeFromFavorites(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
        );
      } else {
        await _supabaseService.addToFavorites(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
        );
      }

      emit(ShowDetailLoaded(
        show: currentState.show,
        cast: currentState.cast,
        similarShows: currentState.similarShows,
        isInWatchlist: currentState.isInWatchlist,
        isFavorite: !currentState.isFavorite,
        watchedEpisodes: currentState.watchedEpisodes,
        videos: currentState.videos,
        watchProviders: currentState.watchProviders,
      ));
    } catch (e) {
      emit(currentState);
    }
  }

  Future<void> toggleEpisodeWatched(int seasonNumber, int episodeNumber) async {
    final currentState = state;
    if (currentState is! ShowDetailLoaded) return;

    final user = _supabaseService.currentUser;
    if (user == null) return;

    final key = seasonNumber * 1000 + episodeNumber;
    final isWatched = currentState.watchedEpisodes[key] ?? false;

    try {
      if (isWatched) {
        await _supabaseService.unmarkAsWatched(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
        );
      } else {
        await _supabaseService.markAsWatched(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
        );
      }

      final newWatched = Map<int, bool>.from(currentState.watchedEpisodes);
      newWatched[key] = !isWatched;

      emit(ShowDetailLoaded(
        show: currentState.show,
        cast: currentState.cast,
        similarShows: currentState.similarShows,
        isInWatchlist: currentState.isInWatchlist,
        isFavorite: currentState.isFavorite,
        watchedEpisodes: newWatched,
        videos: currentState.videos,
        watchProviders: currentState.watchProviders,
      ));
    } catch (e) {
      emit(currentState);
    }
  }
}
