import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class SeasonDetailState {}

class SeasonDetailInitial extends SeasonDetailState {}

class SeasonDetailLoading extends SeasonDetailState {}

class SeasonDetailLoaded extends SeasonDetailState {
  final SeasonModel season;
  final Map<int, bool> watchedEpisodes;

  SeasonDetailLoaded({
    required this.season,
    this.watchedEpisodes = const {},
  });
}

class SeasonDetailError extends SeasonDetailState {
  final String message;
  SeasonDetailError(this.message);
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
      emit(SeasonDetailError(e.toString()));
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
    } catch (e) {
      print('Error toggling episode: $e');
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
      for (final episode in currentState.season.episodes!) {
        try {
          await _supabaseService.markAsWatched(
            userId: user.id,
            tmdbId: showId,
            mediaType: 'tv',
            seasonNumber: seasonNumber,
            episodeNumber: episode.episodeNumber,
          );
        } catch (e) {
          print('Error marking episode ${episode.episodeNumber}: $e');
        }
      }

      final newWatched = <int, bool>{};
      for (final episode in currentState.season.episodes!) {
        newWatched[episode.episodeNumber] = true;
      }

      emit(SeasonDetailLoaded(
        season: currentState.season,
        watchedEpisodes: newWatched,
      ));
    } catch (e) {
      print('Error marking all episodes: $e');
      await loadSeasonDetails();
    }
  }
}
