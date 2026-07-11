import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class SeasonDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SeasonDetailInitial extends SeasonDetailState {}

class SeasonDetailLoading extends SeasonDetailState {}

class SeasonDetailLoaded extends SeasonDetailState {
  final SeasonModel season;
  final Map<int, bool> watchedEpisodes;

  SeasonDetailLoaded({
    required this.season,
    this.watchedEpisodes = const {},
  });

  @override
  List<Object?> get props => [season, watchedEpisodes];
}

class SeasonDetailError extends SeasonDetailState {
  final String message;
  SeasonDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SeasonDetailCubit extends Cubit<SeasonDetailState> {
  final TmdbService _tmdbService;
  final SupabaseService _supabaseService;
  final int showId;
  final int seasonNumber;

  SeasonDetailCubit(
    this._tmdbService,
    this._supabaseService,
    this.showId,
    this.seasonNumber,
  ) : super(SeasonDetailInitial()) {
    loadSeasonDetails();
  }

  Future<void> loadSeasonDetails() async {
    if (isClosed) return;
    emit(SeasonDetailLoading());
    try {
      final data = await _tmdbService.getShowSeasonDetails(showId, seasonNumber);
      final season = SeasonModel.fromJson(data);

      // Load watched episodes with single query
      Map<int, bool> watchedEpisodes = {};
      final user = _supabaseService.currentUser;
      if (user != null && season.episodes != null) {
        final watchedSet = await _supabaseService.getWatchedEpisodes(
          userId: user.id,
          tmdbId: showId,
          seasonNumber: seasonNumber,
        );
        for (final episode in season.episodes!) {
          watchedEpisodes[episode.episodeNumber] = watchedSet[episode.episodeNumber] ?? false;
        }
      }

      if (isClosed) return;
      emit(SeasonDetailLoaded(season: season, watchedEpisodes: watchedEpisodes));
    } catch (e) {
      if (isClosed) return;
      emit(SeasonDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> toggleEpisodeWatched(int episodeNumber) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    final currentState = state;
    if (currentState is! SeasonDetailLoaded) return;

    final isWatched = currentState.watchedEpisodes[episodeNumber] ?? false;

    final newWatched = Map<int, bool>.from(currentState.watchedEpisodes);
    newWatched[episodeNumber] = !isWatched;
    emit(SeasonDetailLoaded(
      season: currentState.season,
      watchedEpisodes: newWatched,
    ));

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
          title: currentState.season.name,
          posterPath: currentState.season.posterPath,
        );
      }

      await _autoComputeStatus(user.id);
    } catch (e) {
      if (!isClosed) emit(currentState);
    }
  }

  Future<void> markAllEpisodes() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    final currentState = state;
    if (currentState is! SeasonDetailLoaded) return;

    List<EpisodeModel> episodes;
    if (currentState.season.episodes != null) {
      episodes = currentState.season.episodes!;
    } else {
      try {
        final seasonData = await _tmdbService.getShowSeasonDetails(showId, seasonNumber);
        final fetchedSeason = SeasonModel.fromJson(seasonData);
        episodes = fetchedSeason.episodes ?? [];
        if (episodes.isEmpty) return;
        if (!isClosed) {
          emit(SeasonDetailLoaded(
            season: fetchedSeason,
            watchedEpisodes: currentState.watchedEpisodes,
          ));
        }
      } catch (_) {
        return;
      }
    }

    final optimisticWatched = Map<int, bool>.from(currentState.watchedEpisodes);
    for (final episode in episodes) {
      optimisticWatched[episode.episodeNumber] = true;
    }
    emit(SeasonDetailLoaded(
      season: currentState.season,
      watchedEpisodes: optimisticWatched,
    ));

    try {
      final List<List<dynamic>> batches = [];
      List<dynamic> currentBatch = [];

      for (final episode in episodes) {
        currentBatch.add(episode.episodeNumber);
        if (currentBatch.length >= 10) {
          batches.add(currentBatch);
          currentBatch = [];
        }
      }
      if (currentBatch.isNotEmpty) batches.add(currentBatch);

      for (int i = 0; i < batches.length; i++) {
        if (i > 0) await Future.delayed(const Duration(milliseconds: 100));
        await Future.wait(batches[i].map((epNum) async {
          try {
            await _supabaseService.markAsWatched(
              userId: user.id,
              tmdbId: showId,
              mediaType: 'tv',
              seasonNumber: seasonNumber,
              episodeNumber: epNum as int,
              title: currentState.season.name,
              posterPath: currentState.season.posterPath,
            );
          } catch (_) {}
        }));
      }

      await _autoComputeStatus(user.id);
    } catch (e) {
      if (!isClosed) emit(currentState);
    }
  }

  Future<void> _autoComputeStatus(String userId) async {
    try {
      // Get show details to check status and total episodes
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