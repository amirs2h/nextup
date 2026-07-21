import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

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

class CustomListsError extends CustomListsState {
  final String message;
  CustomListsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit — singleton, only manages list of custom lists
class CustomListsCubit extends Cubit<CustomListsState> {
  final SupabaseService _supabaseService;

  CustomListsCubit(this._supabaseService) : super(CustomListsInitial());

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
