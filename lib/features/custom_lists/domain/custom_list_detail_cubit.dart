import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

// States
abstract class CustomListDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CustomListDetailInitial extends CustomListDetailState {}

class CustomListDetailLoading extends CustomListDetailState {}

class CustomListDetailLoaded extends CustomListDetailState {
  final Map<String, dynamic> list;
  final List<ShowModel> shows;
  final List<MovieModel> movies;
  CustomListDetailLoaded({required this.list, required this.shows, required this.movies});

  @override
  List<Object?> get props => [list, shows, movies];
}

class CustomListDetailError extends CustomListDetailState {
  final String message;
  CustomListDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit — one instance per detail page (NOT singleton)
class CustomListDetailCubit extends Cubit<CustomListDetailState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  CustomListDetailCubit(this._supabaseService, this._tmdbService) : super(CustomListDetailInitial());

  Future<void> loadDetail(String listId) async {
    if (isClosed) return;
    emit(CustomListDetailLoading());
    try {
      final items = await _supabaseService.getCustomListItems(listId);
      final listData = await _supabaseService.client.from('custom_lists').select().eq('id', listId).maybeSingle();

      List<ShowModel> shows = [];
      List<MovieModel> movies = [];

      if (items.isNotEmpty) {
        final futures = items.map((item) async {
          final storedTitle = item['title'] as String?;
          final storedPoster = item['poster_path'] as String?;
          final tmdbId = item['tmdb_id'] as int;
          final mediaType = item['media_type'] as String?;

          // Use stored title/poster if available (no API call needed)
          if (storedTitle != null && storedTitle.isNotEmpty) {
            if (mediaType == 'tv') {
              return {'type': 'tv', 'model': ShowModel(id: tmdbId, name: storedTitle, posterPath: storedPoster)};
            } else {
              return {'type': 'movie', 'model': MovieModel(id: tmdbId, title: storedTitle, posterPath: storedPoster)};
            }
          }

          // Fallback: fetch from TMDB for old items without stored data
          try {
            if (mediaType == 'tv') {
              final data = await _tmdbService.getShowDetails(tmdbId);
              return {'type': 'tv', 'model': ShowModel.fromJson(data)};
            } else {
              final data = await _tmdbService.getMovieDetails(tmdbId);
              return {'type': 'movie', 'model': MovieModel.fromJson(data)};
            }
          } catch (e) {
            return null;
          }
        }).toList();

        final results = await Future.wait(futures);
        for (final result in results) {
          if (result == null) continue;
          if (result['type'] == 'tv') {
            shows.add(result['model'] as ShowModel);
          } else {
            movies.add(result['model'] as MovieModel);
          }
        }
      }

      if (isClosed) return;
      emit(CustomListDetailLoaded(
        list: listData ?? {'id': listId},
        shows: shows,
        movies: movies,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(CustomListDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> addItem(String listId, int tmdbId, String mediaType, {String? title, String? posterPath}) async {
    try {
      await _supabaseService.addCustomListItem(
        listId: listId,
        tmdbId: tmdbId,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
      );
      await loadDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(CustomListDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> removeItem(String listId, int tmdbId, String mediaType) async {
    try {
      await _supabaseService.removeCustomListItem(
        listId: listId,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      await loadDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(CustomListDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> deleteList(String listId) async {
    try {
      await _supabaseService.deleteCustomList(listId);
    } catch (e) {
      if (isClosed) return;
      emit(CustomListDetailError('Failed to delete list. Please try again.'));
    }
  }
}
