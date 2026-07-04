import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  late final SupabaseClient _client;

  SupabaseService._();

  static Future<SupabaseService> initialize() async {
    if (_instance == null) {
      _instance = SupabaseService._();
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      _instance!._client = Supabase.instance.client;
    }
    return _instance!;
  }

  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Auth
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Profile - Trigger handles creation, we just read
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _client.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Watchlist
  Future<void> addToWatchlist({
    required String userId,
    required int tmdbId,
    required String mediaType,
    String listName = 'default',
  }) async {
    await _client.from('watchlist').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'list_name': listName,
    });
  }

  Future<void> removeFromWatchlist({
    required String userId,
    required int tmdbId,
    required String mediaType,
    String listName = 'default',
  }) async {
    await _client.from('watchlist')
        .delete()
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType)
        .eq('list_name', listName);
  }

  Future<bool> isInWatchlist({
    required String userId,
    required int tmdbId,
    required String mediaType,
    String listName = 'default',
  }) async {
    try {
      final response = await _client.from('watchlist')
          .select()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType)
          .eq('list_name', listName)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getWatchlist({
    required String userId,
    String? mediaType,
    String listName = 'default',
  }) async {
    try {
      final query = _client.from('watchlist')
          .select()
          .eq('user_id', userId)
          .eq('list_name', listName);

      if (mediaType != null) {
        final result = await query.eq('media_type', mediaType).order('added_at', ascending: false);
        return List<Map<String, dynamic>>.from(result);
      }

      final result = await query.order('added_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  // Watch History
  Future<void> markAsWatched({
    required String userId,
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    try {
      // First check if already watched
      final existing = await isWatched(
        userId: userId,
        tmdbId: tmdbId,
        mediaType: mediaType,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      );

      if (existing) return; // Already marked

      await _client.from('watch_history').insert({
        'user_id': userId,
        'tmdb_id': tmdbId,
        'media_type': mediaType,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
      });
    } catch (e) {
      print('Error marking as watched: $e');
      rethrow;
    }
  }

  Future<void> unmarkAsWatched({
    required String userId,
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    try {
      var query = _client.from('watch_history')
          .delete()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType);

      if (seasonNumber != null) {
        query = query.eq('season_number', seasonNumber);
      }
      if (episodeNumber != null) {
        query = query.eq('episode_number', episodeNumber);
      }

      await query;
    } catch (e) {
      print('Error unmarking as watched: $e');
      rethrow;
    }
  }

  Future<bool> isWatched({
    required String userId,
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    try {
      var query = _client.from('watch_history')
          .select()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType);

      if (seasonNumber != null) {
        query = query.eq('season_number', seasonNumber);
      }
      if (episodeNumber != null) {
        query = query.eq('episode_number', episodeNumber);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking if watched: $e');
      return false;
    }
  }

  Future<Map<int, bool>> getWatchedEpisodes({
    required String userId,
    required int tmdbId,
    required int seasonNumber,
  }) async {
    try {
      final response = await _client.from('watch_history')
          .select('episode_number')
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', 'tv')
          .eq('season_number', seasonNumber);

      final watchedMap = <int, bool>{};
      for (final r in response as List) {
        watchedMap[r['episode_number'] as int] = true;
      }
      return watchedMap;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getWatchHistory({
    required String userId,
    String? mediaType,
  }) async {
    try {
      final query = _client.from('watch_history')
          .select()
          .eq('user_id', userId);

      if (mediaType != null) {
        final result = await query.eq('media_type', mediaType).order('watched_at', ascending: false);
        return List<Map<String, dynamic>>.from(result);
      }

      final result = await query.order('watched_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  // Favorites
  Future<void> addToFavorites({
    required String userId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _client.from('favorites').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
    });
  }

  Future<void> removeFromFavorites({
    required String userId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _client.from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType);
  }

  Future<bool> isFavorite({
    required String userId,
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      final response = await _client.from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites({
    required String userId,
  }) async {
    try {
      final response = await _client.from('favorites')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Comments
  Future<void> addComment({
    required String userId,
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
    required String content,
  }) async {
    await _client.from('comments').insert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> getComments({
    required int tmdbId,
    required String mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    try {
      var query = _client.from('comments')
          .select('*, profiles(username, avatar_url)')
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType);

      if (seasonNumber != null) {
        query = query.eq('season_number', seasonNumber);
      }
      if (episodeNumber != null) {
        query = query.eq('episode_number', episodeNumber);
      }

      final result = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  // Comment Likes
  Future<void> likeComment(String userId, String commentId) async {
    await _client.from('comment_likes').insert({
      'user_id': userId,
      'comment_id': commentId,
    });
  }

  Future<void> unlikeComment(String userId, String commentId) async {
    await _client.from('comment_likes')
        .delete()
        .eq('user_id', userId)
        .eq('comment_id', commentId);
  }

  // Follows
  Future<void> followUser(String followerId, String followingId) async {
    await _client.from('follows').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    await _client.from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final response = await _client.from('follows')
          .select()
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _client.from('follows')
          .select('follower_id, profiles!follower_id(username, avatar_url)')
          .eq('following_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _client.from('follows')
          .select('following_id, profiles!following_id(username, avatar_url)')
          .eq('follower_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Reactions
  Future<void> addReaction({
    required String userId,
    required int tmdbId,
    required int seasonNumber,
    required int episodeNumber,
    required String emoji,
  }) async {
    await _client.from('reactions').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'emoji': emoji,
    });
  }

  Future<List<Map<String, dynamic>>> getReactions({
    required int tmdbId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    try {
      return await _client.from('reactions')
          .select()
          .eq('tmdb_id', tmdbId)
          .eq('season_number', seasonNumber)
          .eq('episode_number', episodeNumber);
    } catch (e) {
      return [];
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await _client.from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _client.from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _client.from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
    });
  }

  // Ratings
  Future<void> rateShow({
    required String userId,
    required int tmdbId,
    required double rating,
  }) async {
    await _client.from('ratings').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': 'tv',
      'rating': rating,
    });
  }

  Future<void> rateMovie({
    required String userId,
    required int tmdbId,
    required double rating,
  }) async {
    await _client.from('ratings').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': 'movie',
      'rating': rating,
    });
  }

  Future<double?> getUserRating({
    required String userId,
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      final response = await _client.from('ratings')
          .select('rating')
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType)
          .maybeSingle();
      return response?['rating']?.toDouble();
    } catch (e) {
      return null;
    }
  }

  Future<double> getAverageRating({
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      final response = await _client.from('ratings')
          .select('rating')
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType);
      
      if (response.isEmpty) return 0;
      
      final ratings = response.map((r) => r['rating'] as num).toList();
      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      return 0;
    }
  }
}
