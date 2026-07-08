import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/services/tmdb_service.dart';

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
  final TmdbService _tmdbService;

  ActivityCubit(this._supabaseService, this._tmdbService) : super(ActivityInitial());

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
        emit(ActivityLoaded(activities: []));
        return;
      }

      // Collect unique tmdbIds for batch title fetching
      final uniqueShowIds = allItems
          .where((i) => i['media_type'] == 'tv')
          .map((i) => i['tmdb_id'] as int)
          .toSet()
          .toList();
      final uniqueMovieIds = allItems
          .where((i) => i['media_type'] == 'movie')
          .map((i) => i['tmdb_id'] as int)
          .toSet()
          .toList();

      // Parallel: Fetch all show/movie titles at once
      Map<int, String> titles = {};
      
      final showFutures = uniqueShowIds.map((id) async {
        try {
          final details = await _tmdbService.getShowDetails(id);
          return MapEntry(id, details['name'] ?? 'Unknown Show');
        } catch (e) {
          return MapEntry(id, 'Unknown Show');
        }
      }).toList();
      
      final movieFutures = uniqueMovieIds.map((id) async {
        try {
          final details = await _tmdbService.getMovieDetails(id);
          return MapEntry(id, details['title'] ?? 'Unknown Movie');
        } catch (e) {
          return MapEntry(id, 'Unknown Movie');
        }
      }).toList();

      final showResults = await Future.wait(showFutures);
      final movieResults = await Future.wait(movieFutures);
      
      for (final entry in showResults) {
        titles[entry.key] = entry.value;
      }
      for (final entry in movieResults) {
        titles[entry.key] = entry.value;
      }

      // Build activity list with titles
      List<Map<String, dynamic>> allActivities = allItems.map((item) {
        final tmdbId = item['tmdb_id'] as int;
        return {
          'username': item['username'],
          'avatar_url': item['avatar_url'],
          'tmdb_id': tmdbId,
          'media_type': item['media_type'],
          'season_number': item['season_number'],
          'episode_number': item['episode_number'],
          'watched_at': item['watched_at'],
          'title': titles[tmdbId] ?? 'Unknown',
        };
      }).toList();

      // Sort by date (with null safety)
      allActivities.sort((a, b) {
        final aDate = a['watched_at'] != null ? DateTime.tryParse(a['watched_at']) ?? DateTime.now() : DateTime.now();
        final bDate = b['watched_at'] != null ? DateTime.tryParse(b['watched_at']) ?? DateTime.now() : DateTime.now();
        return bDate.compareTo(aDate);
      });

      emit(ActivityLoaded(activities: allActivities.take(50).toList()));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }
}
