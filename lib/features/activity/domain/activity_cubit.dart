import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

abstract class ActivityState {}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<Map<String, dynamic>> activities;

  ActivityLoaded({required this.activities});
}

class ActivityError extends ActivityState {
  final String message;
  ActivityError(this.message);
}

class ActivityCubit extends Cubit<ActivityState> {
  final SupabaseService _supabaseService;

  ActivityCubit(this._supabaseService) : super(ActivityInitial());

  Future<void> loadActivity() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      emit(ActivityLoaded(activities: []));
      return;
    }

    emit(ActivityLoading());
    try {
      // Get following list
      final following = await _supabaseService.getFollowing(user.id);
      
      if (following.isEmpty) {
        emit(ActivityLoaded(activities: []));
        return;
      }

      // Get recent activity from followers
      List<Map<String, dynamic>> allActivities = [];

      for (final follow in following.take(20)) {
        final followerId = follow['following_id'];
        final username = follow['profiles']?['username'] ?? 'User';
        
        final history = await _supabaseService.getWatchHistory(userId: followerId);
        
        for (final item in history.take(3)) {
          allActivities.add({
            'username': username,
            'tmdb_id': item['tmdb_id'],
            'media_type': item['media_type'],
            'season_number': item['season_number'],
            'episode_number': item['episode_number'],
            'watched_at': item['watched_at'],
          });
        }
      }

      // Sort by date
      allActivities.sort((a, b) => 
        DateTime.parse(b['watched_at']).compareTo(DateTime.parse(a['watched_at'])));

      emit(ActivityLoaded(activities: allActivities.take(50).toList()));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }
}
