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
      newWatched[episodeNumber] = !isWatched;

      emit(SeasonDetailLoaded(
        season: currentState.season,
        watchedEpisodes: newWatched,
      ));

      // Auto-compute status after toggling episode
      await _autoComputeStatus(user.id);
    } catch (e) {
// Reload to get actual state from DB
      await loadSeasonDetails();
    }
  }

  Future<void> markAllEpisodes() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    final currentState = state;
    if (currentState is! SeasonDetailLoaded) return;
    if (currentState.season.episodes == null) return;

    try {
      final successfullyMarked = <int>{};
      for (final episode in currentState.season.episodes!) {
        try {
          await _supabaseService.markAsWatched(
            userId: user.id,
            tmdbId: showId,
            mediaType: 'tv',
            seasonNumber: seasonNumber,
            episodeNumber: episode.episodeNumber,
          );
          successfullyMarked.add(episode.episodeNumber);
        } catch (e) {
          // Continue with other episodes even if one fails
        }
      }

      final newWatched = <int, bool>{};
      for (final episode in currentState.season.episodes!) {
        newWatched[episode.episodeNumber] = successfullyMarked.contains(episode.episodeNumber);
      }

      if (isClosed) return;
      emit(SeasonDetailLoaded(
        season: currentState.season,
        watchedEpisodes: newWatched,
      ));

      // Auto-compute status after marking all episodes
      await _autoComputeStatus(user.id);
    } catch (e) {
await loadSeasonDetails();
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