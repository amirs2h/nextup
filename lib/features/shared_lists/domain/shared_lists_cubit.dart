import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';

// States
abstract class SharedListsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SharedListsInitial extends SharedListsState {}

class SharedListsLoading extends SharedListsState {}

class SharedListsLoaded extends SharedListsState {
  final List<Map<String, dynamic>> lists;
  SharedListsLoaded({required this.lists});

  @override
  List<Object?> get props => [lists];
}

class SharedListDetailLoaded extends SharedListsState {
  final Map<String, dynamic> list;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> members;
  SharedListDetailLoaded({required this.list, required this.items, required this.members});

  @override
  List<Object?> get props => [list, items, members];
}

class SharedListsError extends SharedListsState {
  final String message;
  SharedListsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SharedListsCubit extends Cubit<SharedListsState> {
  final SupabaseService _supabaseService;
  final TmdbService _tmdbService;

  SharedListsCubit(this._supabaseService, this._tmdbService) : super(SharedListsInitial());

  Future<void> loadSharedLists() async {
    if (isClosed) return;
    emit(SharedListsLoading());
    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        if (isClosed) return;
        emit(SharedListsError('Please login to view shared lists'));
        return;
      }

      final lists = await _supabaseService.getSharedLists(user.id);
      if (!isClosed) emit(SharedListsLoaded(lists: lists));
    } catch (e) {
      if (isClosed) return;
      emit(SharedListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> loadSharedListDetail(String listId) async {
    if (isClosed) return;
    emit(SharedListsLoading());
    try {
      final items = await _supabaseService.getSharedListItems(listId);
      final members = await _supabaseService.getSharedListMembers(listId);
      final listData = await _supabaseService.client.from('shared_lists').select().eq('id', listId).maybeSingle();
      
      // Fetch TMDB titles for items in parallel
      final itemsWithTitles = await Future.wait(items.map((item) async {
        final tmdbId = item['tmdb_id'] as int;
        final mediaType = item['media_type'] as String;
        String title = 'Unknown';
        String? posterPath;
        
        try {
          if (mediaType == 'tv') {
            final details = await _tmdbService.getShowDetails(tmdbId);
            title = details['name'] ?? 'Unknown Show';
            posterPath = details['poster_path'];
          } else {
            final details = await _tmdbService.getMovieDetails(tmdbId);
            title = details['title'] ?? 'Unknown Movie';
            posterPath = details['poster_path'];
          }
        } catch (e) {
          // Keep default title
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
      emit(SharedListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> createSharedList({
    required String name,
    String? description,
    required List<String> memberIds,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(SharedListsError('Please login to create a list'));
      return;
    }

    try {
      final listId = await _supabaseService.createSharedList(
        name: name,
        description: description,
        creatorId: user.id,
      );

      await _supabaseService.addSharedListMember(
        listId: listId,
        userId: user.id,
        role: 'admin',
      );

      for (final memberId in memberIds) {
        await _supabaseService.addSharedListMember(
          listId: listId,
          userId: memberId,
        );
      }

      await loadSharedLists();
    } catch (e) {
      if (isClosed) return;
      emit(SharedListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> addItemToList(String listId, int tmdbId, String mediaType) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(SharedListsError('Please login to add items'));
      return;
    }

    try {
      await _supabaseService.addSharedListItem(
        listId: listId,
        tmdbId: tmdbId,
        mediaType: mediaType,
        addedBy: user.id,
      );
      await loadSharedListDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> removeItemFromList(String listId, int tmdbId, String mediaType) async {
    try {
      await _supabaseService.removeSharedListItem(
        listId: listId,
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      await loadSharedListDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> addMember(String listId, String userId) async {
    try {
      await _supabaseService.addSharedListMember(
        listId: listId,
        userId: userId,
      );
      await loadSharedListDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListsError('Something went wrong. Please try again.'));
    }
  }

  Future<void> removeMember(String listId, String userId) async {
    try {
      await _supabaseService.removeSharedListMember(
        listId: listId,
        userId: userId,
      );
      await loadSharedListDetail(listId);
    } catch (e) {
      if (isClosed) return;
      emit(SharedListsError('Something went wrong. Please try again.'));
    }
  }
}