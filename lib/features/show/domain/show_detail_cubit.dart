import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/person_model.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/omdb_service.dart';

// States
abstract class ShowDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

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
  final String? imdbId;
  final String? contentRating;
  final int? rottenTomatoesScore;
  final String? imdbRating;
  final double? userRating;
  final double averageRating;

  ShowDetailLoaded({
    required this.show,
    required this.cast,
    required this.similarShows,
    this.isInWatchlist = false,
    this.isFavorite = false,
    this.watchedEpisodes = const {},
    this.videos = const [],
    this.watchProviders,
    this.imdbId,
    this.contentRating,
    this.rottenTomatoesScore,
    this.imdbRating,
    this.userRating,
    this.averageRating = 0,
  });

  @override
  List<Object?> get props => [show, cast, similarShows, isInWatchlist, isFavorite, watchedEpisodes, videos, watchProviders, imdbId, contentRating, rottenTomatoesScore, imdbRating, userRating, averageRating];
}

class ShowDetailError extends ShowDetailState {
  final String message;
  ShowDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ShowDetailCubit extends Cubit<ShowDetailState> {
  final TmdbService _tmdbService;
  final SupabaseService _supabaseService;
  final OmdbService _omdbService;
  final int showId;

  ShowDetailCubit(this._tmdbService, this._supabaseService, this._omdbService, this.showId)
      : super(ShowDetailInitial()) {
    loadShowDetails();
  }

  Future<void> loadShowDetails() async {
    emit(ShowDetailLoading());
    try {
      // Parallel TMDB calls (7 calls in parallel)
      final tmdbResults = await Future.wait([
        _tmdbService.getShowDetails(showId),
        _tmdbService.getShowCredits(showId),
        _tmdbService.getSimilarShows(showId),
        _tmdbService.getShowVideos(showId),
        _tmdbService.getShowWatchProviders(showId),
        _tmdbService.getShowExternalIds(showId),
        _tmdbService.getShowContentRatings(showId),
      ]);

      final detailsData = tmdbResults[0] as Map<String, dynamic>;
      final creditsData = tmdbResults[1] as Map<String, dynamic>;
      final similarData = tmdbResults[2] as Map<String, dynamic>;
      final videosData = tmdbResults[3] as List<Map<String, dynamic>>;
      final providersData = tmdbResults[4] as Map<String, dynamic>;
      final externalIdsData = tmdbResults[5] as Map<String, dynamic>;
      final contentRatingsData = tmdbResults[6] as Map<String, dynamic>;

      final show = ShowModel.fromJson(detailsData);
      final cast = (creditsData['cast'] as List)
          .take(20)
          .map((json) => PersonModel.fromJson(json))
          .toList();
      final similarShows = (similarData['results'] as List)
          .map((json) => ShowModel.fromJson(json))
          .toList();
      final videos = videosData;
      final watchProviders = providersData;
      final imdbId = externalIdsData['imdb_id'] as String?;

      // Get content rating (US preferred)
      String? contentRating;
      final ratings = contentRatingsData['results'] as List?;
      if (ratings != null) {
        for (final r in ratings) {
          if (r['iso_3166_1'] == 'US') {
            contentRating = r['rating'];
            break;
          }
        }
        if (contentRating == null && ratings.isNotEmpty) {
          contentRating = ratings.first['rating'];
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

      final seasons = detailsData['seasons'] as List? ?? [];
      final seasonNumbers = seasons
          .map((s) => s['season_number'] as int?)
          .where((s) => s != null && s > 0)
          .cast<int>()
          .toList();

      // Parallel Supabase calls (4+N calls in parallel, N = number of seasons)
      final user = _supabaseService.currentUser;
      bool isInWatchlist = false;
      bool isFavorite = false;
      Map<int, bool> watchedEpisodes = {};
      double? userRating;
      double averageRating = 0;

      if (user != null) {
        final futures = [
          _supabaseService.isInWatchlist(userId: user.id, tmdbId: showId, mediaType: 'tv'),
          _supabaseService.isFavorite(userId: user.id, tmdbId: showId, mediaType: 'tv'),
          _supabaseService.getUserRating(userId: user.id, tmdbId: showId, mediaType: 'tv'),
          _supabaseService.getAverageRating(tmdbId: showId, mediaType: 'tv'),
          ...seasonNumbers.map((sn) => _supabaseService.getWatchedEpisodes(
            userId: user.id,
            tmdbId: showId,
            seasonNumber: sn,
          )),
        ];
        final supabaseResults = await Future.wait(futures);
        isInWatchlist = supabaseResults[0] as bool;
        isFavorite = supabaseResults[1] as bool;
        userRating = supabaseResults[2] as double?;
        averageRating = supabaseResults[3] as double;
        for (int i = 4; i < supabaseResults.length; i++) {
          final seasonIdx = i - 4;
          final sn = seasonNumbers[seasonIdx];
          final seasonMap = supabaseResults[i] as Map<int, bool>;
          for (final entry in seasonMap.entries) {
            watchedEpisodes[sn * 1000 + entry.key] = entry.value;
          }
        }
      } else {
        averageRating = await _supabaseService.getAverageRating(tmdbId: showId, mediaType: 'tv');
      }

      if (isClosed) return;
      emit(ShowDetailLoaded(
        show: show,
        cast: cast,
        similarShows: similarShows,
        isInWatchlist: isInWatchlist,
        isFavorite: isFavorite,
        watchedEpisodes: watchedEpisodes,
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
      emit(ShowDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> toggleWatchlist({String status = 'watchlist'}) async {
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
          status: status,
        );
      }

      if (isClosed) return;
      emit(ShowDetailLoaded(
        show: currentState.show,
        cast: currentState.cast,
        similarShows: currentState.similarShows,
        isInWatchlist: !currentState.isInWatchlist,
        isFavorite: currentState.isFavorite,
        watchedEpisodes: currentState.watchedEpisodes,
        videos: currentState.videos,
        watchProviders: currentState.watchProviders,
        imdbId: currentState.imdbId,
        contentRating: currentState.contentRating,
        rottenTomatoesScore: currentState.rottenTomatoesScore,
        imdbRating: currentState.imdbRating,
        userRating: currentState.userRating,
        averageRating: currentState.averageRating,
      ));
    } catch (e) {
      if (isClosed) return;
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

      if (isClosed) return;
      emit(ShowDetailLoaded(
        show: currentState.show,
        cast: currentState.cast,
        similarShows: currentState.similarShows,
        isInWatchlist: currentState.isInWatchlist,
        isFavorite: !currentState.isFavorite,
        watchedEpisodes: currentState.watchedEpisodes,
        videos: currentState.videos,
        watchProviders: currentState.watchProviders,
        imdbId: currentState.imdbId,
        contentRating: currentState.contentRating,
        rottenTomatoesScore: currentState.rottenTomatoesScore,
        imdbRating: currentState.imdbRating,
        userRating: currentState.userRating,
        averageRating: currentState.averageRating,
      ));
    } catch (e) {
      if (isClosed) return;
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
        imdbId: currentState.imdbId,
        contentRating: currentState.contentRating,
        rottenTomatoesScore: currentState.rottenTomatoesScore,
        imdbRating: currentState.imdbRating,
        userRating: currentState.userRating,
        averageRating: currentState.averageRating,
      ));

      // Auto-compute status after toggling episode
      await _autoComputeStatus(user.id);
    } catch (e) {
      if (isClosed) return;
      emit(currentState);
    }
  }

  Future<void> _autoComputeStatus(String userId) async {
    try {
      final showDetails = await _tmdbService.getShowDetails(showId);
      await _supabaseService.computeAndSetShowStatus(
        userId: userId,
        tmdbId: showId,
        showDetails: showDetails,
      );
    } catch (e) {
      // Non-critical: auto-compute status failure should not affect user experience
    }
  }
}