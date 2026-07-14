import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

// States
abstract class WatchlistState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WatchlistInitial extends WatchlistState {}

class WatchlistLoading extends WatchlistState {}

class WatchlistItem extends Equatable {
  final dynamic model; // ShowModel or MovieModel
  final String mediaType;
  final String status;

  const WatchlistItem({required this.model, required this.mediaType, required this.status});

  @override
  List<Object?> get props => [model, mediaType, status];
}

class WatchlistLoaded extends WatchlistState {
  final List<WatchlistItem> items;
  final String filter;
  final String mediaType; // 'all', 'tv', 'movie'

  WatchlistLoaded({required this.items, this.filter = 'all', this.mediaType = 'all'});

  List<WatchlistItem> get filteredItems {
    List<WatchlistItem> result = items;

    // Filter by media type
    if (mediaType == 'tv') {
      result = result.where((i) => i.mediaType == 'tv').toList();
    } else if (mediaType == 'movie') {
      result = result.where((i) => i.mediaType == 'movie').toList();
    }

    // Filter by status
    if (filter != 'all') {
      result = result.where((i) => i.status == filter).toList();
    }

    return result;
  }

  List<WatchlistItem> get showItems => filteredItems.where((i) => i.mediaType == 'tv').toList();
  List<WatchlistItem> get movieItems => filteredItems.where((i) => i.mediaType == 'movie').toList();

  @override
  List<Object?> get props => [items, filter, mediaType];
}

class WatchlistError extends WatchlistState {
  final String message;
  WatchlistError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class WatchlistCubit extends Cubit<WatchlistState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;
  bool _isRemoving = false;
  bool _isUpdatingStatus = false;

  WatchlistCubit(this._supabaseService, this._tmdbService) : super(WatchlistInitial());

  Future<void> loadWatchlist({String filter = 'all'}) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(WatchlistLoaded(items: [], filter: filter));
      return;
    }

    if (isClosed) return;
    emit(WatchlistLoading());
    try {
      final watchlistItems = await _supabaseService.getWatchlist(userId: user.id);

      if (watchlistItems.isEmpty) {
        if (isClosed) return;
        emit(WatchlistLoaded(items: [], filter: filter));
        return;
      }

      final futures = watchlistItems.map((item) async {
        try {
          final hasTitle = item['title'] != null && (item['title'] as String).isNotEmpty;
          final hasPoster = item['poster_path'] != null && (item['poster_path'] as String).isNotEmpty;

          if (item['media_type'] == 'tv') {
            if (hasTitle && hasPoster) {
              return WatchlistItem(
                model: ShowModel(
                  id: item['tmdb_id'],
                  name: item['title'],
                  posterPath: item['poster_path'],
                ),
                mediaType: 'tv',
                status: item['status'] ?? 'watchlist',
              );
            }
            final data = await _tmdbService.getShowDetails(item['tmdb_id']);
            return WatchlistItem(
              model: ShowModel.fromJson(data),
              mediaType: 'tv',
              status: item['status'] ?? 'watchlist',
            );
          } else {
            if (hasTitle && hasPoster) {
              return WatchlistItem(
                model: MovieModel(
                  id: item['tmdb_id'],
                  title: item['title'],
                  posterPath: item['poster_path'],
                ),
                mediaType: 'movie',
                status: item['status'] ?? 'watchlist',
              );
            }
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

      if (isClosed) return;
      emit(WatchlistLoaded(items: items, filter: filter));
    } catch (e) {
      if (isClosed) return;
      emit(WatchlistError('Something went wrong. Please try again.'));
    }
  }

  Future<void> removeFromWatchlist(int tmdbId, String mediaType) async {
    if (_isRemoving) return;
    _isRemoving = true;
    try {
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
        if (isClosed) return;
        emit(WatchlistError('Something went wrong. Please try again.'));
      }
    } finally {
      _isRemoving = false;
    }
  }

  Future<void> updateStatus(int tmdbId, String mediaType, String newStatus) async {
    if (_isUpdatingStatus) return;
    _isUpdatingStatus = true;
    try {
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
        if (isClosed) return;
        emit(WatchlistError('Something went wrong. Please try again.'));
      }
    } finally {
      _isUpdatingStatus = false;
    }
  }

  void setFilter(String filter) {
    if (state is WatchlistLoaded) {
      final current = state as WatchlistLoaded;
      if (isClosed) return;
      emit(WatchlistLoaded(items: current.items, filter: filter, mediaType: current.mediaType));
    }
  }

  void setMediaType(String mediaType) {
    if (state is WatchlistLoaded) {
      final current = state as WatchlistLoaded;
      if (isClosed) return;
      emit(WatchlistLoaded(items: current.items, filter: current.filter, mediaType: mediaType));
    }
  }
}