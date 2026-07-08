import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

// States
abstract class WatchlistState {}

class WatchlistInitial extends WatchlistState {}

class WatchlistLoading extends WatchlistState {}

class WatchlistItem {
  final dynamic model; // ShowModel or MovieModel
  final String mediaType;
  final String status;

  WatchlistItem({required this.model, required this.mediaType, required this.status});
}

class WatchlistLoaded extends WatchlistState {
  final List<WatchlistItem> items;
  final String filter; // 'all', 'shows', 'movies', 'watching', 'completed', 'up_to_date', 'watchlist', 'stopped'

  WatchlistLoaded({required this.items, this.filter = 'all'});

  List<WatchlistItem> get filteredItems {
    switch (filter) {
      case 'shows':
        return items.where((i) => i.mediaType == 'tv').toList();
      case 'movies':
        return items.where((i) => i.mediaType == 'movie').toList();
      case 'watching':
      case 'completed':
      case 'up_to_date':
      case 'watchlist':
      case 'stopped':
        return items.where((i) => i.status == filter).toList();
      default:
        return items;
    }
  }

  List<WatchlistItem> get showItems => filteredItems.where((i) => i.mediaType == 'tv').toList();
  List<WatchlistItem> get movieItems => filteredItems.where((i) => i.mediaType == 'movie').toList();
}

class WatchlistError extends WatchlistState {
  final String message;
  WatchlistError(this.message);
}

// Cubit
class WatchlistCubit extends Cubit<WatchlistState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  WatchlistCubit(this._supabaseService, this._tmdbService) : super(WatchlistInitial());

  Future<void> loadWatchlist({String filter = 'all'}) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      emit(WatchlistLoaded(items: [], filter: filter));
      return;
    }

    emit(WatchlistLoading());
    try {
      final watchlistItems = await _supabaseService.getWatchlist(userId: user.id);

      if (watchlistItems.isEmpty) {
        emit(WatchlistLoaded(items: [], filter: filter));
        return;
      }

      // Parallel TMDB calls for all watchlist items
      final futures = watchlistItems.map((item) async {
        try {
          if (item['media_type'] == 'tv') {
            final data = await _tmdbService.getShowDetails(item['tmdb_id']);
            return WatchlistItem(
              model: ShowModel.fromJson(data),
              mediaType: 'tv',
              status: item['status'] ?? 'watchlist',
            );
          } else {
            final data = await _tmdbService.getMovieDetails(item['tmdb_id']);
            return WatchlistItem(
              model: MovieModel.fromJson(data),
              mediaType: 'movie',
              status: item['status'] ?? 'watchlist',
            );
          }
        } catch (e) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      final items = results.whereType<WatchlistItem>().toList();

      emit(WatchlistLoaded(items: items, filter: filter));
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  Future<void> removeFromWatchlist(int tmdbId, String mediaType) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.removeFromWatchlist(
        userId: user.id,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      // Reload
      await loadWatchlist(filter: state is WatchlistLoaded ? (state as WatchlistLoaded).filter : 'all');
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  Future<void> updateStatus(int tmdbId, String mediaType, String newStatus) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.updateWatchlistStatus(
        userId: user.id,
        tmdbId: tmdbId,
        mediaType: mediaType,
        status: newStatus,
      );
      // Reload
      await loadWatchlist(filter: state is WatchlistLoaded ? (state as WatchlistLoaded).filter : 'all');
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  void setFilter(String filter) {
    if (state is WatchlistLoaded) {
      final current = state as WatchlistLoaded;
      emit(WatchlistLoaded(items: current.items, filter: filter));
    }
  }
}
