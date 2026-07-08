import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class RankingsState {}

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
      emit(RankingsLoaded(rankings: rankings));
    } catch (e) {
      emit(RankingsError(e.toString()));
    }
  }
}
