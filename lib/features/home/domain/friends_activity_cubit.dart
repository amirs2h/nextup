import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/services/supabase_service.dart';

class FriendActivity extends Equatable {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String activityType; // 'watching', 'finished', 'started', 'rated', 'added'
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterPath;
  final double? rating;
  final DateTime timestamp;

  const FriendActivity({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.activityType,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    this.rating,
    required this.timestamp,
  });

  IconData get activityIcon {
    switch (activityType) {
      case 'watching': return Icons.play_circle_rounded;
      case 'finished': return Icons.check_circle_rounded;
      case 'started': return Icons.play_arrow_rounded;
      case 'rated': return Icons.star_rounded;
      case 'added': return Icons.bookmark_rounded;
      default: return Icons.movie_rounded;
    }
  }

  Color get activityColor {
    switch (activityType) {
      case 'watching': return const Color(0xFF00D4FF);
      case 'finished': return const Color(0xFF00FF88);
      case 'started': return const Color(0xFF6C63FF);
      case 'rated': return const Color(0xFFFFD93D);
      case 'added': return const Color(0xFFE50914);
      default: return const Color(0xFF6C63FF);
    }
  }

  String get activityLabel {
    switch (activityType) {
      case 'watching': return 'Watching';
      case 'finished': return 'Finished';
      case 'started': return 'Started';
      case 'rated': return 'Rated';
      case 'added': return 'Added';
      default: return 'Watching';
    }
  }

  @override
  List<Object?> get props => [userId, username, avatarUrl, activityType, tmdbId, mediaType, title, posterPath, rating, timestamp];
}

abstract class FriendsActivityState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FriendsActivityInitial extends FriendsActivityState {}
class FriendsActivityLoading extends FriendsActivityState {}

class FriendsActivityLoaded extends FriendsActivityState {
  final List<FriendActivity> activities;
  
  FriendsActivityLoaded({required this.activities});

  @override
  List<Object?> get props => [activities];
}

class FriendsActivityError extends FriendsActivityState {
  final String message;
  FriendsActivityError(this.message);

  @override
  List<Object?> get props => [message];
}

class FriendsActivityEmpty extends FriendsActivityState {}

class FriendsActivityCubit extends Cubit<FriendsActivityState> {
  final SupabaseService _supabaseService;

  FriendsActivityCubit(this._supabaseService) : super(FriendsActivityInitial());

  Future<void> loadFriendsActivity() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(FriendsActivityEmpty());
      return;
    }

    if (isClosed) return;
    emit(FriendsActivityLoading());
    try {
      final following = await _supabaseService.getFollowing(user.id);
      if (following.isEmpty) {
        if (isClosed) return;
        emit(FriendsActivityEmpty());
        return;
      }

      final activities = <FriendActivity>[];
      final recentUsers = following.take(10).toList();
      
      for (final follow in recentUsers) {
        final friendId = follow['following_id'] as String;
        final friendName = follow['profiles']?['username'] ?? 'User';
        final friendAvatar = follow['profiles']?['avatar_url'] as String?;
        
        try {
          final history = await _supabaseService.getWatchHistory(userId: friendId);
          
          // Deduplicate by tmdb_id - keep the most recent entry per show/movie
          final Map<int, Map<String, dynamic>> uniqueByTmdbId = {};
          for (final item in history) {
            final tmdbId = item['tmdb_id'] as int;
            if (!uniqueByTmdbId.containsKey(tmdbId)) {
              uniqueByTmdbId[tmdbId] = item;
            }
          }
          
          final uniqueItems = uniqueByTmdbId.values.take(3).toList();
          
          for (final item in uniqueItems) {
            final tmdbId = item['tmdb_id'] as int;
            
            final mediaType = item['media_type'] as String? ?? 'tv';
            final title = item['title'] as String? ?? 'Unknown';
            final posterPath = item['poster_path'] as String?;
            final watchedAt = item['watched_at'] != null ? DateTime.tryParse(item['watched_at']) ?? DateTime.now() : DateTime.now();
            
            // Fetch user rating for this item
            double? userRating;
            try {
              userRating = await _supabaseService.getUserRating(
                userId: friendId,
                tmdbId: tmdbId,
                mediaType: mediaType,
              );
            } catch (_) {}

            String activityType = 'watching';
            if (mediaType == 'movie') {
              activityType = 'finished';
            }
            if (userRating != null && userRating > 0) {
              activityType = 'rated';
            }
            
            activities.add(FriendActivity(
              userId: friendId,
              username: friendName,
              avatarUrl: friendAvatar,
              activityType: activityType,
              tmdbId: tmdbId,
              mediaType: mediaType,
              title: title,
              posterPath: posterPath,
              rating: userRating,
              timestamp: watchedAt,
            ));
          }
        } catch (e) {
          // Skip failed friend
        }
      }

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (isClosed) return;
      if (activities.isEmpty) {
        emit(FriendsActivityEmpty());
      } else {
        emit(FriendsActivityLoaded(activities: activities.take(20).toList()));
      }
    } catch (e) {
      if (isClosed) return;
      emit(FriendsActivityError('Something went wrong. Please try again.'));
    }
  }
}
