import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

abstract class ActivityState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<Map<String, dynamic>> activities;

  ActivityLoaded({required this.activities});

  @override
  List<Object?> get props => [activities];
}

class ActivityError extends ActivityState {
  final String message;
  ActivityError(this.message);

  @override
  List<Object?> get props => [message];
}

class ActivityCubit extends Cubit<ActivityState> {
  final SupabaseService _supabaseService;

  ActivityCubit(this._supabaseService) : super(ActivityInitial());

  Future<void> loadActivity() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(ActivityLoaded(activities: []));
      return;
    }

    if (isClosed) return;
    emit(ActivityLoading());
    try {
      // Get following list
      final following = await _supabaseService.getFollowing(user.id);
      
      if (following.isEmpty) {
        if (isClosed) return;
        emit(ActivityLoaded(activities: []));
        return;
      }

      // Parallel: Get recent activity from all followed users at once
      final historyFutures = following.take(20).map((follow) async {
        final followerId = follow['following_id'];
        final username = follow['profiles']?['username'] ?? 'User';
        final avatarUrl = follow['profiles']?['avatar_url'];
        
        try {
          final history = await _supabaseService.getWatchHistory(userId: followerId);
          return history.take(3).map((item) => {
            ...item,
            'username': username,
            'avatar_url': avatarUrl,
          }).toList();
        } catch (e) {
          return <Map<String, dynamic>>[];
        }
      }).toList();

      final historyResults = await Future.wait(historyFutures);
      
      // Flatten and collect all unique tmdbIds
      List<Map<String, dynamic>> allItems = [];
      for (final items in historyResults) {
        allItems.addAll(items);
      }

      if (allItems.isEmpty) {
        if (isClosed) return;
        emit(ActivityLoaded(activities: []));
        return;
      }

      // Build activity list using title/poster_path already stored in Supabase
      List<Map<String, dynamic>> allActivities = allItems.map((item) {
        return {
          'username': item['username'],
          'avatar_url': item['avatar_url'],
          'tmdb_id': item['tmdb_id'],
          'media_type': item['media_type'],
          'season_number': item['season_number'],
          'episode_number': item['episode_number'],
          'watched_at': item['watched_at'],
          'title': item['title'] ?? (item['media_type'] == 'tv' ? 'Unknown Show' : 'Unknown Movie'),
        };
      }).toList();

      // Sort by date (with null safety)
      allActivities.sort((a, b) {
        final aDate = a['watched_at'] != null ? DateTime.tryParse(a['watched_at']) ?? DateTime.now() : DateTime.now();
        final bDate = b['watched_at'] != null ? DateTime.tryParse(b['watched_at']) ?? DateTime.now() : DateTime.now();
        return bDate.compareTo(aDate);
      });

      if (isClosed) return;
      emit(ActivityLoaded(activities: allActivities.take(50).toList()));
    } catch (e) {
      if (isClosed) return;
      emit(ActivityError('Something went wrong. Please try again.'));
    }
  }
}