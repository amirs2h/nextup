import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class StatsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final int totalShows;
  final int totalMovies;
  final int totalEpisodes;
  final int totalHours;
  final Map<String, int> monthlyWatched;
  final List<Map<String, dynamic>> topGenres;

  StatsLoaded({
    this.totalShows = 0,
    this.totalMovies = 0,
    this.totalEpisodes = 0,
    this.totalHours = 0,
    this.monthlyWatched = const {},
    this.topGenres = const [],
  });

  @override
  List<Object?> get props => [totalShows, totalMovies, totalEpisodes, totalHours, monthlyWatched, topGenres];
}

class StatsError extends StatsState {
  final String message;
  StatsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class StatsCubit extends Cubit<StatsState> {
  final SupabaseService _supabaseService;

  StatsCubit(this._supabaseService) : super(StatsInitial());

  Future<void> loadStats() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      emit(StatsLoaded());
      return;
    }

    emit(StatsLoading());
    try {
      final history = await _supabaseService.getWatchHistory(userId: user.id);

      int totalShows = 0;
      int totalMovies = 0;
      int totalEpisodes = 0;
      Set<String> showIds = {};
      Set<String> movieIds = {};
      Map<String, int> monthlyWatched = {};

      for (final item in history) {
        if (item['media_type'] == 'tv') {
          showIds.add(item['tmdb_id'].toString());
          if (item['episode_number'] != null) {
            totalEpisodes++;
          }
        } else {
          movieIds.add(item['tmdb_id'].toString());
        }

        // Calculate monthly watched
        if (item['watched_at'] != null) {
          final date = DateTime.tryParse(item['watched_at']);
          if (date != null) {
            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            monthlyWatched[monthKey] = (monthlyWatched[monthKey] ?? 0) + 1;
          }
        }
      }

      totalShows = showIds.length;
      totalMovies = movieIds.length;

      // Estimate hours (assuming 45 min per episode, 2 hours per movie)
      final totalHours = (totalEpisodes * 45 + totalMovies * 120) ~/ 60;

      // Sort monthly data by date
      final sortedMonthly = Map.fromEntries(
        monthlyWatched.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      emit(StatsLoaded(
        totalShows: totalShows,
        totalMovies: totalMovies,
        totalEpisodes: totalEpisodes,
        totalHours: totalHours,
        monthlyWatched: sortedMonthly,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(StatsError('Something went wrong. Please try again.'));
    }
  }
}