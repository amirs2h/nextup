import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class RankingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RankingsInitial extends RankingsState {}

class RankingsLoading extends RankingsState {}

class RankingsLoaded extends RankingsState {
  final List<Map<String, dynamic>> rankings;
  RankingsLoaded({required this.rankings});

  @override
  List<Object?> get props => [rankings];
}

class RankingsError extends RankingsState {
  final String message;
  RankingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class RankingsCubit extends Cubit<RankingsState> {
  final SupabaseService _supabaseService;

  RankingsCubit(this._supabaseService) : super(RankingsInitial());

  Future<void> loadRankings() async {
    emit(RankingsLoading());
    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        emit(RankingsLoaded(rankings: []));
        return;
      }

      final rankings = await _supabaseService.getFollowingWatchHours(user.id);
      if (!isClosed) emit(RankingsLoaded(rankings: rankings));
    } catch (e) {
      if (isClosed) return;
      emit(RankingsError('Something went wrong. Please try again.'));
    }
  }
}