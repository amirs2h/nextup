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

  ShowDetailLoaded copyWith({
    ShowModel? show,
    List<PersonModel>? cast,
    List<ShowModel>? similarShows,
    bool? isInWatchlist,
    bool? isFavorite,
    Map<int, bool>? watchedEpisodes,
    List<Map<String, dynamic>>? videos,
    Map<String, dynamic>? watchProviders,
    String? imdbId,
    String? contentRating,
    int? rottenTomatoesScore,
    String? imdbRating,
    double? userRating,
    double? averageRating,
  }) {
    return ShowDetailLoaded(
      show: show ?? this.show,
      cast: cast ?? this.cast,
      similarShows: similarShows ?? this.similarShows,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
      isFavorite: isFavorite ?? this.isFavorite,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      videos: videos ?? this.videos,
      watchProviders: watchProviders ?? this.watchProviders,
      imdbId: imdbId ?? this.imdbId,
      contentRating: contentRating ?? this.contentRating,
      rottenTomatoesScore: rottenTomatoesScore ?? this.rottenTomatoesScore,
      imdbRating: imdbRating ?? this.imdbRating,
      userRating: userRating ?? this.userRating,
      averageRating: averageRating ?? this.averageRating,
    );
  }

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
  bool _isTogglingEpisode = false;
  bool _isTogglingWatchlist = false;
  bool _isTogglingFavorite = false;
  bool _isMarkingAll = false;

  ShowDetailCubit(this._tmdbService, this._supabaseService, this._omdbService, this.showId)
      : super(ShowDetailInitial()) {
    loadShowDetails();
  }

  Future<void> loadShowDetails() async {
    if (isClosed) return;
    emit(ShowDetailLoading());
    try {
      // Parallel TMDB calls (8 calls in parallel)
      final tmdbResults = await Future.wait([
        _tmdbService.getShowDetails(showId),
        _tmdbService.getShowCredits(showId),
        _tmdbService.getSimilarShows(showId),
        _tmdbService.getShowVideos(showId),
        _tmdbService.getShowWatchProviders(showId),
        _tmdbService.getShowExternalIds(showId),
        _tmdbService.getShowContentRatings(showId),
        _tmdbService.getShowRecommendations(showId),
      ]);

      final detailsData = tmdbResults[0] as Map<String, dynamic>;
      final creditsData = tmdbResults[1] as Map<String, dynamic>;
      final similarData = tmdbResults[2] as Map<String, dynamic>;
      final videosData = tmdbResults[3] as List<Map<String, dynamic>>;
      final providersData = tmdbResults[4] as Map<String, dynamic>;
      final externalIdsData = tmdbResults[5] as Map<String, dynamic>;
      final contentRatingsData = tmdbResults[6] as Map<String, dynamic>;
      final recommendationsData = tmdbResults[7] as Map<String, dynamic>;

      final show = ShowModel.fromJson(detailsData);
      final cast = (creditsData['cast'] as List)
          .take(20)
          .map((json) => PersonModel.fromJson(json))
          .toList();

      // Merge + filter + sort similar shows and recommendations
      final allSimilarRaw = <Map<String, dynamic>>[];
      final seenIds = <int>{};
      for (final json in (similarData['results'] as List? ?? [])) {
        final id = (json as Map<String, dynamic>)['id'] as int?;
        if (id != null && !seenIds.contains(id) && id != showId) {
          final voteCount = (json['vote_count'] ?? 0) as int;
          final posterPath = json['poster_path'] as String?;
          if (voteCount >= 50 && posterPath != null && posterPath.isNotEmpty) {
            allSimilarRaw.add(json);
            seenIds.add(id);
          }
        }
      }
      for (final json in (recommendationsData['results'] as List? ?? [])) {
        final id = (json as Map<String, dynamic>)['id'] as int?;
        if (id != null && !seenIds.contains(id) && id != showId) {
          final voteCount = (json['vote_count'] ?? 0) as int;
          final posterPath = json['poster_path'] as String?;
          if (voteCount >= 50 && posterPath != null && posterPath.isNotEmpty) {
            allSimilarRaw.add(json);
            seenIds.add(id);
          }
        }
      }
      // Sort by vote_count descending (most popular first)
      allSimilarRaw.sort((a, b) {
        final aVotes = (a['vote_count'] ?? 0) as int;
        final bVotes = (b['vote_count'] ?? 0) as int;
        return bVotes.compareTo(aVotes);
      });
      final similarShows = allSimilarRaw.take(20).map((json) => ShowModel.fromJson(json)).toList();
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
            watchedEpisodes[sn * 10000 + entry.key] = entry.value;
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
    if (_isTogglingWatchlist) return;
    _isTogglingWatchlist = true;
    try {
      final currentState = state;
      if (currentState is! ShowDetailLoaded) return;

      final user = _supabaseService.currentUser;
      if (user == null) return;

      final newValue = !currentState.isInWatchlist;
      if (isClosed) return;
      emit(currentState.copyWith(isInWatchlist: newValue));

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
          try {
            final showDetails = await _tmdbService.getShowDetails(showId);
            await _supabaseService.computeAndSetShowStatus(
              userId: user.id,
              tmdbId: showId,
              showDetails: showDetails,
            );
            final newStatus = await _supabaseService.getWatchlistStatus(
              userId: user.id,
              tmdbId: showId,
              mediaType: 'tv',
            );
            if (!isClosed && newStatus != null) {
              emit((state as ShowDetailLoaded).copyWith(isInWatchlist: true));
            }
          } catch (_) {}
        }
      } catch (e) {
        if (!isClosed) emit(currentState);
      }
    } finally {
      _isTogglingWatchlist = false;
    }
  }

  Future<void> toggleFavorite() async {
    if (_isTogglingFavorite) return;
    _isTogglingFavorite = true;
    try {
      final currentState = state;
      if (currentState is! ShowDetailLoaded) return;

      final user = _supabaseService.currentUser;
      if (user == null) return;

      final newValue = !currentState.isFavorite;
      if (isClosed) return;
      emit(currentState.copyWith(isFavorite: newValue));

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
      } catch (e) {
        if (!isClosed) emit(currentState);
      }
    } finally {
      _isTogglingFavorite = false;
    }
  }

  Future<void> toggleEpisodeWatched(int seasonNumber, int episodeNumber) async {
    if (_isTogglingEpisode) return;
    _isTogglingEpisode = true;
    try {
      final currentState = state;
      if (currentState is! ShowDetailLoaded) return;

      final user = _supabaseService.currentUser;
      if (user == null) return;

      final key = seasonNumber * 10000 + episodeNumber;
      final isWatched = currentState.watchedEpisodes[key] ?? false;

      final newWatched = Map<int, bool>.from(currentState.watchedEpisodes);
      newWatched[key] = !isWatched;
      if (isClosed) return;
      emit(currentState.copyWith(watchedEpisodes: newWatched));

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
            title: currentState.show.name,
            posterPath: currentState.show.posterPath,
          );
        }
        try {
          final showDetails = await _tmdbService.getShowDetails(showId);
          await _supabaseService.computeAndSetShowStatus(
            userId: user.id,
            tmdbId: showId,
            showDetails: showDetails,
          );
          final newIsInWatchlist = await _supabaseService.isInWatchlist(
            userId: user.id,
            tmdbId: showId,
            mediaType: 'tv',
          );
          if (!isClosed) emit((state as ShowDetailLoaded).copyWith(isInWatchlist: newIsInWatchlist));
        } catch (_) {}
      } catch (e) {
        if (!isClosed) emit(currentState);
      }
    } finally {
      _isTogglingEpisode = false;
    }
  }

  Future<void> markAllAsWatched() async {
    if (_isMarkingAll) return;
    _isMarkingAll = true;
    Map<int, bool>? originalWatched;
    try {
      final currentState = state;
      if (currentState is! ShowDetailLoaded) {
        _isMarkingAll = false;
        return;
      }

      final user = _supabaseService.currentUser;
      if (user == null) {
        _isMarkingAll = false;
        return;
      }

      final seasons = currentState.show.seasons;
      if (seasons == null || seasons.isEmpty) {
        _isMarkingAll = false;
        return;
      }

      // Save original state for revert on failure
      originalWatched = Map<int, bool>.from(currentState.watchedEpisodes);

      // Optimistic update
      final optimisticWatched = Map<int, bool>.from(currentState.watchedEpisodes);
      for (final season in seasons) {
        if (season.seasonNumber <= 0) continue;
        if (season.episodes != null) {
          for (final episode in season.episodes!) {
            optimisticWatched[season.seasonNumber * 10000 + episode.episodeNumber] = true;
          }
        } else {
          try {
            final seasonData = await _tmdbService.getShowSeasonDetails(showId, season.seasonNumber);
            final episodes = seasonData['episodes'] as List? ?? [];
            for (final ep in episodes) {
              final epNum = ep['episode_number'] as int? ?? 0;
              if (epNum > 0) optimisticWatched[season.seasonNumber * 10000 + epNum] = true;
            }
          } catch (_) {}
        }
      }
      if (isClosed) return;
      emit(currentState.copyWith(watchedEpisodes: optimisticWatched));

      // Batch processing
      final List<List<dynamic>> batches = [];
      List<dynamic> currentBatch = [];

      for (final season in seasons) {
        if (season.seasonNumber <= 0) continue;
        if (season.episodes != null) {
          for (final episode in season.episodes!) {
            currentBatch.add([season.seasonNumber, episode.episodeNumber]);
            if (currentBatch.length >= 10) {
              batches.add(currentBatch);
              currentBatch = [];
            }
          }
        } else {
          try {
            final seasonData = await _tmdbService.getShowSeasonDetails(showId, season.seasonNumber);
            final episodes = seasonData['episodes'] as List? ?? [];
            for (final ep in episodes) {
              final epNum = ep['episode_number'] as int? ?? 0;
              if (epNum > 0) currentBatch.add([season.seasonNumber, epNum]);
              if (currentBatch.length >= 10) {
                batches.add(currentBatch);
                currentBatch = [];
              }
            }
          } catch (_) {}
        }
      }
      if (currentBatch.isNotEmpty) batches.add(currentBatch);

      for (int i = 0; i < batches.length; i++) {
        if (i > 0) await Future.delayed(const Duration(milliseconds: 100));
        await Future.wait(batches[i].map((task) async {
          try {
            await _supabaseService.markAsWatched(
              userId: user.id,
              tmdbId: showId,
              mediaType: 'tv',
              seasonNumber: task[0] as int,
              episodeNumber: task[1] as int,
              title: currentState.show.name,
              posterPath: currentState.show.posterPath,
            );
          } catch (_) {}
        }));
      }

      // Auto-compute status
      try {
        final showDetails = await _tmdbService.getShowDetails(showId);
        await _supabaseService.computeAndSetShowStatus(
          userId: user.id,
          tmdbId: showId,
          showDetails: showDetails,
        );
        final newIsInWatchlist = await _supabaseService.isInWatchlist(
          userId: user.id,
          tmdbId: showId,
          mediaType: 'tv',
        );
        if (!isClosed) emit((state as ShowDetailLoaded).copyWith(isInWatchlist: newIsInWatchlist));
      } catch (_) {}
    } catch (e) {
      // Revert optimistic update on failure
      final currentState = state;
      if (!isClosed && currentState is ShowDetailLoaded) {
        emit(currentState.copyWith(watchedEpisodes: originalWatched));
      }
    } finally {
      _isMarkingAll = false;
    }
  }
}