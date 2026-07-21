import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

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

class SharedListsError extends SharedListsState {
  final String message;
  SharedListsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit — singleton, only manages list of shared lists
class SharedListsCubit extends Cubit<SharedListsState> {
  final SupabaseService _supabaseService;

  SharedListsCubit(this._supabaseService) : super(SharedListsInitial());

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
        if (memberId == user.id) continue;
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

  Future<void> deleteList(String listId) async {
    try {
      await _supabaseService.deleteSharedList(listId);
      await loadSharedLists();
    } catch (e) {
      if (isClosed) return;
      emit(SharedListsError('Failed to delete list. Please try again.'));
    }
  }

  Future<void> leaveList(String listId) async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.leaveSharedList(listId, user.id);
      await loadSharedLists();
    } catch (e) {
      if (isClosed) return;
      emit(SharedListsError('Failed to leave list. Please try again.'));
    }
  }
}
