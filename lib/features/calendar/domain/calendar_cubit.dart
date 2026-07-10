import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';

class CalendarEvent extends Equatable {
  final ShowModel show;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeName;
  final DateTime airDate;

  const CalendarEvent({
    required this.show,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeName,
    required this.airDate,
  });

  @override
  List<Object?> get props => [show, seasonNumber, episodeNumber, episodeName, airDate];
}

abstract class CalendarState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<CalendarEvent> events;
  final DateTime selectedMonth;

  CalendarLoaded({
    required this.events,
    required this.selectedMonth,
  });

  @override
  List<Object?> get props => [events, selectedMonth];
}

class CalendarError extends CalendarState {
  final String message;
  CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}

class CalendarCubit extends Cubit<CalendarState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  CalendarCubit(this._supabaseService, this._tmdbService) : super(CalendarInitial());

  Future<void> loadCalendar(DateTime month) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(CalendarLoaded(events: [], selectedMonth: month));
      return;
    }

    if (isClosed) return;
    emit(CalendarLoading());
    try {
      // Get user's watchlist shows
      final watchlist = await _supabaseService.getWatchlist(
        userId: user.id,
        mediaType: 'tv',
      );

      // Build ShowModel from Supabase data (title/poster_path already available),
      // then fetch full show details only for season data
      final showDetailFutures = watchlist.map((item) async {
        try {
          final showData = await _tmdbService.getShowDetails(item['tmdb_id']);
          return ShowModel.fromJson(showData);
        } catch (e) {
          // Fall back to constructing a minimal ShowModel from Supabase data
          return ShowModel(
            id: item['tmdb_id'] as int,
            name: item['title'] ?? 'Unknown Show',
            posterPath: item['poster_path'],
          );
        }
      }).toList();

      final shows = (await Future.wait(showDetailFutures)).whereType<ShowModel>().toList();

      // Parallel: Fetch season details for all shows
      List<CalendarEvent> events = [];
      
      for (final show in shows) {
        if (show.seasons == null) continue;
        
        // Filter to only seasons that might have episodes in this month
        final seasonFutures = show.seasons!
            .where((s) => s.seasonNumber > 0)
            .map((season) async {
          try {
            final seasonData = await _tmdbService.getShowSeasonDetails(
              show.id,
              season.seasonNumber,
            );
            return seasonData;
          } catch (e) {
            return null;
          }
        }).toList();

        final seasonResults = await Future.wait(seasonFutures);
        
        for (final seasonData in seasonResults) {
          if (seasonData == null) continue;
          final episodes = seasonData['episodes'] as List? ?? [];
          
          for (final episode in episodes) {
            if (episode['air_date'] != null) {
              final airDate = DateTime.tryParse(episode['air_date']);
              if (airDate != null &&
                  airDate.year == month.year &&
                  airDate.month == month.month) {
                events.add(CalendarEvent(
                  show: show,
                  seasonNumber: seasonData['season_number'] ?? 0,
                  episodeNumber: episode['episode_number'] ?? 0,
                  episodeName: episode['name'] ?? '',
                  airDate: airDate,
                ));
              }
            }
          }
        }
      }

      // Sort by air date
      events.sort((a, b) => a.airDate.compareTo(b.airDate));

      if (isClosed) return;
      emit(CalendarLoaded(events: events, selectedMonth: month));
    } catch (e) {
      if (isClosed) return;
      emit(CalendarError('Something went wrong. Please try again.'));
    }
  }
}