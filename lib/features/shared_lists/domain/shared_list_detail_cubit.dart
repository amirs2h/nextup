import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';

// States
abstract class SharedListDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SharedListDetailInitial extends SharedListDetailState {}

class SharedListDetailLoading extends SharedListDetailState {}

class SharedListDetailLoaded extends SharedListDetailState {
  final Map<String, dynamic> list;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> members;
  SharedListDetailLoaded({required this.list, required this.items, required this.members});

  @override
  List<Object?> get props => [list, items, members];
}

class SharedListDetailError extends SharedListDetailState {
  final String message;
  SharedListDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit — one instance per detail page (NOT singleton)
class SharedListDetailCubit extends Cubit<SharedListDetailState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  SharedListDetailCubit(this._supabaseService, this._tmdbService) : super(SharedListDetailInitial());

  Future<void> loadDetail(String listId) async {
    if (isClosed) return;
    emit(SharedListDetailLoading());
    try {
      final items = await _supabaseService.getSharedListItemsWithWatchStatus(listId);
      final members = await _supabaseService.getSharedListMembers(listId);
      final listData = await _supabaseService.client.from('shared_lists').select().eq('id', listId).maybeSingle();

      final itemsWithTitles = await Future.wait(items.map((item) async {
        final storedTitle = item['title'] as String?;
        final storedPoster = item['poster_path'] as String?;

        if (storedTitle != null && storedTitle.isNotEmpty) {
          return item;
        }

        final tmdbId = item['tmdb_id'] as int;
        final mediaType = item['media_type'] as String;
        String title = storedTitle ?? 'Unknown';
        String? posterPath = storedPoster;

        try {
          if (mediaType == 'tv') {
            final details = await _tmdbService.getShowDetails(tmdbId);
            title = details['name'] ?? title;
            posterPath = details['poster_path'] ?? posterPath;
          } else {
            final details = await _tmdbService.getMovieDetails(tmdbId);
            title = details['title'] ?? title;
            posterPath = details['poster_path'] ?? posterPath;
          }
        } catch (e) {
          // Keep stored/default values
        }

        return {
          ...item,
          'title': title,
          'poster_path': posterPath,
        };
      }));

      if (isClosed) return;
      emit(SharedListDetailLoaded(
        list: listData ?? {'id': listId},
        items: itemsWithTitles,
        members: members,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(SharedListDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> addItem(String listId, int tmdbId, String mediaType, {String? title, String? posterPath}) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(SharedListDetailError('Please login to add items'));
      return;
    }

    try {
      await _supabaseService.addSharedListItem(
        listId: listId,
        tmdbId: tmdbId,
        mediaType: mediaType,
        addedBy: user.id,
        title: title,
        posterPath: posterPath,
      );
      await loadDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> removeItem(String listId, int tmdbId, String mediaType) async {
    try {
      await _supabaseService.removeSharedListItem(
        listId: listId,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      await loadDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> addMember(String listId, String userId) async {
    try {
      await _supabaseService.addSharedListMember(
        listId: listId,
        userId: userId,
      );
      await loadDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> removeMember(String listId, String userId) async {
    try {
      await _supabaseService.removeSharedListMember(
        listId: listId,
        userId: userId,
      );
      await loadDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListDetailError('Something went wrong. Please try again.'));
    }
  }

  Future<void> deleteList(String listId) async {
    try {
      await _supabaseService.deleteSharedList(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListDetailError('Failed to delete list. Please try again.'));
    }
  }

  Future<void> leaveList(String listId) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.leaveSharedList(listId, user.id);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListDetailError('Failed to leave list. Please try again.'));
    }
  }
}
