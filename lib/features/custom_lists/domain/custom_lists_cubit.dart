import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';
import '../../../shared/models/show_model.dart';
import '../../../shared/models/movie_model.dart';

// States
abstract class CustomListsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CustomListsInitial extends CustomListsState {}

class CustomListsLoading extends CustomListsState {}

class CustomListsLoaded extends CustomListsState {
  final List<Map<String, dynamic>> lists;
  CustomListsLoaded({required this.lists});

  @override
  List<Object?> get props => [lists];
}

class CustomListDetailLoaded extends CustomListsState {
  final Map<String, dynamic> list;
  final List<ShowModel> shows;
  final List<MovieModel> movies;
  CustomListDetailLoaded({required this.list, required this.shows, required this.movies});

  @override
  List<Object?> get props => [list, shows, movies];
}

class CustomListsError extends CustomListsState {
  final String message;
  CustomListsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class CustomListsCubit extends Cubit<CustomListsState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  CustomListsCubit(this._supabaseService, this._tmdbService) : super(CustomListsInitial());

  Future<void> loadCustomLists() async {
    if (isClosed) return;
    emit(CustomListsLoading());
    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        if (isClosed) return;
        emit(CustomListsError('Please login to view your lists'));
        return;
      }

      final lists = await _supabaseService.getCustomLists(user.id);
      if (!isClosed) emit(CustomListsLoaded(lists: lists));
    } catch (e) {
      if (isClosed) return;
      emit(CustomListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> loadCustomListDetail(String listId) async {
    if (isClosed) return;
    emit(CustomListsLoading());
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
      emit(CustomListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> createCustomList({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(CustomListsError('Please login to create a list'));
      return;
    }

    try {
      await _supabaseService.createCustomList(
        name: name,
        description: description,
        userId: user.id,
        isPublic: isPublic,
      );

      await loadCustomLists();
    } catch (e) {
      if (isClosed) return;
      emit(CustomListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> addItemToList(String listId, int tmdbId, String mediaType, {String? title, String? posterPath}) async {
    try {
      await _supabaseService.addCustomListItem(
        listId: listId,
        tmdbId: tmdbId,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
      );
      await loadCustomListDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(CustomListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> removeItemFromList(String listId, int tmdbId, String mediaType) async {
    try {
      await _supabaseService.removeCustomListItem(
        listId: listId,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      await loadCustomListDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(CustomListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> deleteList(String listId) async {
    try {
      await _supabaseService.deleteCustomList(listId);
      await loadCustomLists();
    } catch (e) {
      if (isClosed) return;
      emit(CustomListsError('Failed to delete list. Please try again.'));
    }
  }
}