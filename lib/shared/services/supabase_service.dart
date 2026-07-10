import 'dart:typed_data';
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

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.nextup://login-callback/',
    );
  }

  Future<void> deleteAccount(String userId) async {
    // Delete user data from all tables with individual error handling
    final deleteOperations = [
      _client.from('comment_likes').delete().eq('user_id', userId),
      _client.from('comments').delete().eq('user_id', userId),
      _client.from('reactions').delete().eq('user_id', userId),
      _client.from('ratings').delete().eq('user_id', userId),
      _client.from('notifications').delete().eq('user_id', userId),
      _client.from('watch_history').delete().eq('user_id', userId),
      _client.from('favorites').delete().eq('user_id', userId),
      _client.from('watchlist').delete().eq('user_id', userId),
      _client.from('follows').delete().or('follower_id.eq.$userId,following_id.eq.$userId'),
      _client.from('shared_list_members').delete().eq('user_id', userId),
      _client.from('character_votes').delete().eq('user_id', userId),
      _client.from('favorite_actor_votes').delete().eq('user_id', userId),
    ];

    // Execute all deletes, catching individual errors
    for (final op in deleteOperations) {
      try {
        await op;
      } catch (e) {
        // Silently continue deletion
      }
    }

    // Delete custom list items (need to fetch list IDs first)
    try {
      final customLists = await _client.from('custom_lists').select('id').eq('user_id', userId);
      final customListIds = (customLists as List).map((l) => l['id']).toList();
      if (customListIds.isNotEmpty) {
        await _client.from('custom_list_items').delete().inFilter('list_id', customListIds);
      }
    } catch (e) {
      // Silently continue
    }

    // Delete lists owned by user
    try {
      await _client.from('shared_lists').delete().eq('creator_id', userId);
    } catch (e) {
      // Silently continue
    }

    try {
      await _client.from('custom_lists').delete().eq('user_id', userId);
    } catch (e) {
      // Silently continue
    }

    // Delete profile
    try {
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      // Silently continue
    }

    // Delete auth user via Edge Function (requires service_role key)
    try {
      final response = await _client.functions.invoke('delete-user', body: {'user_id': userId});
      if (response.status != 200) {
        // Log but don't throw - data is already deleted
      }
    } catch (e) {
      // Edge Function may not be deployed yet - continue with sign out
    }

    // Sign out
    await _client.auth.signOut();
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
      rethrow;
    }
  }

  Future<String?> uploadAvatar(String userId, Uint8List fileBytes, String fileExt) async {
    try {
      // Normalize extension
      String ext = fileExt.toLowerCase().replaceAll('.', '');
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        ext = 'jpg'; // Default to jpg if unknown
      }
      
      final path = '$userId/avatar.$ext';
      await _client.storage.from('avatars').uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(contentType: 'image/$ext'),
      );
      final url = _client.storage.from('avatars').getPublicUrl(path);
      await updateProfile(userId, {'avatar_url': url});
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAvatar(String userId) async {
    try {
      final profile = await getProfile(userId);
      if (profile != null && profile['avatar_url'] != null) {
        final url = profile['avatar_url'] as String;
        final path = url.split('/').last;
        await _client.storage.from('avatars').remove(['$userId/$path']);
        await updateProfile(userId, {'avatar_url': null});
      }
    } catch (e) {
      // Silently continue
    }
  }

  // Watchlist
  Future<void> addToWatchlist({
    required String userId,
    required int tmdbId,
    required String mediaType,
    String listName = 'default',
    String status = 'watchlist',
    String? title,
    String? posterPath,
  }) async {
    await _client.from('watchlist').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'list_name': listName,
      'status': status,
      'title': title,
      'poster_path': posterPath,
    }, onConflict: 'user_id,tmdb_id,media_type,list_name');
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
    String? title,
    String? posterPath,
  }) async {
    try {
      await _client.from('watch_history').upsert({
        'user_id': userId,
        'tmdb_id': tmdbId,
        'media_type': mediaType,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'title': title,
        'poster_path': posterPath,
      }, onConflict: 'user_id,tmdb_id,media_type,season_number,episode_number');
    } catch (e) {
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
      } else {
        query = query.isFilter('season_number', null);
      }
      if (episodeNumber != null) {
        query = query.eq('episode_number', episodeNumber);
      } else {
        query = query.isFilter('episode_number', null);
      }

      await query;
    } catch (e) {
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
      } else {
        query = query.isFilter('season_number', null);
      }
      if (episodeNumber != null) {
        query = query.eq('episode_number', episodeNumber);
      } else {
        query = query.isFilter('episode_number', null);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
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
    String? title,
    String? posterPath,
  }) async {
    await _client.from('favorites').upsert({
      'user_id': userId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'title': title,
      'poster_path': posterPath,
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
    String? userId,
  }) async {
    try {
      var query = _client.from('comments_with_likes')
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
      final comments = List<Map<String, dynamic>>.from(result);
      
      // Add is_liked_by_me for each comment
      if (userId != null && comments.isNotEmpty) {
        final commentIds = comments.map((c) => c['id']).toList();
        final userLikes = await _client.from('comment_likes')
            .select('comment_id')
            .eq('user_id', userId)
            .inFilter('comment_id', commentIds);
        final likedIds = Set<String>.from((userLikes as List).map((l) => l['comment_id']));
        for (var comment in comments) {
          comment['is_liked_by_me'] = likedIds.contains(comment['id']);
        }
      } else {
        for (var comment in comments) {
          comment['is_liked_by_me'] = false;
        }
      }
      
      return comments;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  // Comment Likes
  Future<void> likeComment(String userId, String commentId) async {
    await _client.from('comment_likes').upsert({
      'user_id': userId,
      'comment_id': commentId,
    }, onConflict: 'user_id,comment_id');
  }

  Future<void> unlikeComment(String userId, String commentId) async {
    await _client.from('comment_likes')
        .delete()
        .eq('user_id', userId)
        .eq('comment_id', commentId);
  }

  // Follows
  Future<void> followUser(String followerId, String followingId) async {
    await _client.from('follows').upsert({
      'follower_id': followerId,
      'following_id': followingId,
    }, onConflict: 'follower_id,following_id');
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

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      // Escape SQL wildcard characters to prevent injection
      final sanitized = query.replaceAll('%', '\\%').replaceAll('_', '\\_');
      final response = await _client
          .from('profiles')
          .select('id, username, avatar_url, bio')
          .ilike('username', '%$sanitized%')
          .limit(20);
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
    }, onConflict: 'user_id,tmdb_id,season_number,episode_number');
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
    // Query-first pattern to avoid race conditions with expression index
    final existing = await _client.from('ratings')
        .select('id')
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', 'tv')
        .isFilter('season_number', null)
        .isFilter('episode_number', null)
        .maybeSingle();
    if (existing != null) {
      await _client.from('ratings').update({'rating': rating}).eq('id', existing['id']);
    } else {
      await _client.from('ratings').insert({
        'user_id': userId,
        'tmdb_id': tmdbId,
        'media_type': 'tv',
        'rating': rating,
      });
    }
  }

  Future<void> rateMovie({
    required String userId,
    required int tmdbId,
    required double rating,
  }) async {
    final existing = await _client.from('ratings')
        .select('id')
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', 'movie')
        .isFilter('season_number', null)
        .isFilter('episode_number', null)
        .maybeSingle();
    if (existing != null) {
      await _client.from('ratings').update({'rating': rating}).eq('id', existing['id']);
    } else {
      await _client.from('ratings').insert({
        'user_id': userId,
        'tmdb_id': tmdbId,
        'media_type': 'movie',
        'rating': rating,
      });
    }
  }

  Future<void> rateEpisode({
    required String userId,
    required int tmdbId,
    required int seasonNumber,
    required int episodeNumber,
    required double rating,
  }) async {
    final existing = await _client.from('ratings')
        .select('id')
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', 'tv')
        .eq('season_number', seasonNumber)
        .eq('episode_number', episodeNumber)
        .maybeSingle();
    if (existing != null) {
      await _client.from('ratings').update({'rating': rating}).eq('id', existing['id']);
    } else {
      await _client.from('ratings').insert({
        'user_id': userId,
        'tmdb_id': tmdbId,
        'media_type': 'tv',
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'rating': rating,
      });
    }
  }

  Future<double?> getUserEpisodeRating({
    required String userId,
    required int tmdbId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    try {
      final response = await _client.from('ratings')
          .select('rating')
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', 'tv')
          .eq('season_number', seasonNumber)
          .eq('episode_number', episodeNumber)
          .maybeSingle();
      return response?['rating']?.toDouble();
    } catch (e) {
      return null;
    }
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
      final result = await _client.rpc('get_average_rating', params: {
        'p_tmdb_id': tmdbId,
        'p_media_type': mediaType,
      });
      return (result as num?)?.toDouble() ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Watchlist Status
  Future<void> updateWatchlistStatus({
    required String userId,
    required int tmdbId,
    required String mediaType,
    required String status,
  }) async {
    await _client.from('watchlist')
        .update({'status': status})
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType);
  }

  Future<List<Map<String, dynamic>>> getWatchlistByStatus({
    required String userId,
    required String status,
  }) async {
    try {
      final response = await _client.from('watchlist')
          .select()
          .eq('user_id', userId)
          .eq('status', status)
          .order('added_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> computeAndSetShowStatus({
    required String userId,
    required int tmdbId,
    required Map<String, dynamic> showDetails,
  }) async {
    try {
      // Check if show is in watchlist
      final watchlistItem = await _client.from('watchlist')
          .select()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', 'tv')
          .maybeSingle();

      if (watchlistItem == null) return; // Not in watchlist

      // Get total watched episodes for this show
      final watchedResponse = await _client.from('watch_history')
          .select()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', 'tv')
          .not('season_number', 'is', null)
          .not('episode_number', 'is', null);
      final watchedCount = (watchedResponse as List).length;

      // Get total episodes from TMDB
      final totalEpisodes = showDetails['number_of_episodes'] ?? 0;
      final showStatus = showDetails['status'] ?? '';

      String newStatus;
      if (watchedCount == 0) {
        newStatus = 'watchlist';
      } else if (watchedCount >= totalEpisodes && totalEpisodes > 0) {
        // Watched all episodes
        if (showStatus == 'Ended' || showStatus == 'Canceled') {
          newStatus = 'completed';
        } else {
          newStatus = 'up_to_date';
        }
      } else {
        // Watched some but not all
        newStatus = 'watching';
      }

      // Update status if different
      final currentStatus = watchlistItem['status'] ?? 'watchlist';
      if (currentStatus != newStatus) {
        await updateWatchlistStatus(
          userId: userId,
          tmdbId: tmdbId,
          mediaType: 'tv',
          status: newStatus,
        );
      }
    } catch (e) {
      // Non-critical
    }
  }

  Future<void> computeAndSetMovieStatus({
    required String userId,
    required int tmdbId,
    required bool isWatched,
  }) async {
    try {
      // Check if movie is in watchlist
      final watchlistItem = await _client.from('watchlist')
          .select()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', 'movie')
          .maybeSingle();

      if (watchlistItem == null) return; // Not in watchlist

      final newStatus = isWatched ? 'completed' : 'watchlist';
      final currentStatus = watchlistItem['status'] ?? 'watchlist';

      if (currentStatus != newStatus) {
        await updateWatchlistStatus(
          userId: userId,
          tmdbId: tmdbId,
          mediaType: 'movie',
          status: newStatus,
        );
      }
    } catch (e) {
      // Non-critical
    }
  }

  Future<int> getWatchedEpisodeCount({
    required String userId,
    required int tmdbId,
  }) async {
    try {
      final response = await _client.from('watch_history')
          .select()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', 'tv');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Shared Lists
  Future<String> createSharedList({
    required String name,
    String? description,
    required String creatorId,
  }) async {
    final response = await _client.from('shared_lists').insert({
      'name': name,
      'description': description,
      'creator_id': creatorId,
    }).select('id').single();
    return response['id'] as String;
  }

  Future<void> addSharedListMember({
    required String listId,
    required String userId,
    String role = 'member',
  }) async {
    await _client.from('shared_list_members').insert({
      'list_id': listId,
      'user_id': userId,
      'role': role,
    });
  }

  Future<void> removeSharedListMember({
    required String listId,
    required String userId,
  }) async {
    await _client.from('shared_list_members')
        .delete()
        .eq('list_id', listId)
        .eq('user_id', userId);
  }

  Future<void> addSharedListItem({
    required String listId,
    required int tmdbId,
    required String mediaType,
    required String addedBy,
  }) async {
    await _client.from('shared_list_items').insert({
      'list_id': listId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'added_by': addedBy,
    });
  }

  Future<void> removeSharedListItem({
    required String listId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _client.from('shared_list_items')
        .delete()
        .eq('list_id', listId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType);
  }

  Future<List<Map<String, dynamic>>> getSharedLists(String userId) async {
    try {
      final response = await _client.from('shared_list_members')
          .select('list_id, shared_lists(id, name, description, creator_id, created_at)')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSharedListItems(String listId) async {
    try {
      final response = await _client.from('shared_list_items')
          .select()
          .eq('list_id', listId)
          .order('added_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSharedListMembers(String listId) async {
    try {
      final response = await _client.from('shared_list_members')
          .select('user_id, role, profiles(username, avatar_url)')
          .eq('list_id', listId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Custom Lists
  Future<String> createCustomList({
    required String name,
    String? description,
    required String userId,
    bool isPublic = false,
  }) async {
    final response = await _client.from('custom_lists').insert({
      'name': name,
      'description': description,
      'user_id': userId,
      'is_public': isPublic,
    }).select('id').single();
    return response['id'] as String;
  }

  Future<void> addCustomListItem({
    required String listId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _client.from('custom_list_items').insert({
      'list_id': listId,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
    });
  }

  Future<void> removeCustomListItem({
    required String listId,
    required int tmdbId,
    required String mediaType,
  }) async {
    await _client.from('custom_list_items')
        .delete()
        .eq('list_id', listId)
        .eq('tmdb_id', tmdbId)
        .eq('media_type', mediaType);
  }

  Future<List<Map<String, dynamic>>> getCustomLists(String userId) async {
    try {
      final response = await _client.from('custom_lists')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCustomListItems(String listId) async {
    try {
      final response = await _client.from('custom_list_items')
          .select()
          .eq('list_id', listId)
          .order('added_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Rankings - Get watch hours for following users (parallel)
  Future<List<Map<String, dynamic>>> getFollowingWatchHours(String userId) async {
    try {
      final result = await _client.rpc('get_following_watch_hours', params: {
        'p_user_id': userId,
      });
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  // Get watch history with watched_at for episodes
  Future<List<Map<String, dynamic>>> getWatchHistoryWithDates({
    required String userId,
    required int tmdbId,
  }) async {
    try {
      final response = await _client.from('watch_history')
          .select('season_number, episode_number, watched_at')
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', 'tv')
          .order('watched_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Update profile header image
  Future<void> updateProfileHeader({
    required String userId,
    required String headerImageUrl,
  }) async {
    await _client.from('profiles')
        .update({'header_image_url': headerImageUrl})
        .eq('id', userId);
  }

  // Upload header image
  Future<String?> uploadHeader(String userId, Uint8List fileBytes, String fileExt) async {
    try {
      // Normalize extension
      String ext = fileExt.toLowerCase().replaceAll('.', '');
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        ext = 'jpg'; // Default to jpg if unknown
      }
      
      final path = '$userId/header.$ext';
      await _client.storage.from('avatars').uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(contentType: 'image/$ext'),
      );
      final url = _client.storage.from('avatars').getPublicUrl(path);
      await updateProfileHeader(userId: userId, headerImageUrl: url);
      return url;
    } catch (e) {
      return null;
    }
  }

  // Character Votes
  Future<void> voteForCharacter({
    required String userId,
    required int personId,
    required int tmdbId,
    required String characterName,
    required String voteType,
  }) async {
    try {
      await _client.from('character_votes').upsert({
        'user_id': userId,
        'person_id': personId,
        'tmdb_id': tmdbId,
        'character_name': characterName,
        'vote_type': voteType,
      }, onConflict: 'user_id,person_id,tmdb_id,character_name');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeCharacterVote({
    required String userId,
    required int personId,
    required int tmdbId,
    required String characterName,
  }) async {
    try {
      await _client.from('character_votes')
          .delete()
          .eq('user_id', userId)
          .eq('person_id', personId)
          .eq('tmdb_id', tmdbId)
          .eq('character_name', characterName);
    } catch (e) {
      // Silently continue
    }
  }

  Future<Map<String, dynamic>> getCharacterVotes({
    required int personId,
    required int tmdbId,
    required String characterName,
  }) async {
    try {
      final response = await _client.from('character_votes')
          .select('vote_type')
          .eq('person_id', personId)
          .eq('tmdb_id', tmdbId)
          .eq('character_name', characterName);

      final votes = List<Map<String, dynamic>>.from(response);
      final upVotes = votes.where((v) => v['vote_type'] == 'up').length;
      final downVotes = votes.where((v) => v['vote_type'] == 'down').length;

      return {
        'up_votes': upVotes,
        'down_votes': downVotes,
        'total': upVotes - downVotes,
      };
    } catch (e) {
      return {'up_votes': 0, 'down_votes': 0, 'total': 0};
    }
  }

  Future<String?> getUserCharacterVote({
    required String userId,
    required int personId,
    required int tmdbId,
    required String characterName,
  }) async {
    try {
      final response = await _client.from('character_votes')
          .select('vote_type')
          .eq('user_id', userId)
          .eq('person_id', personId)
          .eq('tmdb_id', tmdbId)
          .eq('character_name', characterName)
          .maybeSingle();

      return response?['vote_type'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTopCharactersForShow({
    required int tmdbId,
    int limit = 10,
  }) async {
    try {
      final response = await _client.from('character_votes')
          .select('character_name, vote_type')
          .eq('tmdb_id', tmdbId);

      final votes = List<Map<String, dynamic>>.from(response);

      // Group by character and calculate totals
      Map<String, Map<String, int>> characterVotes = {};
      for (final vote in votes) {
        final name = vote['character_name'] as String;
        final type = vote['vote_type'] as String;

        if (!characterVotes.containsKey(name)) {
          characterVotes[name] = {'up': 0, 'down': 0};
        }

        if (type == 'up') {
          characterVotes[name]!['up'] = characterVotes[name]!['up']! + 1;
        } else {
          characterVotes[name]!['down'] = characterVotes[name]!['down']! + 1;
        }
      }

      // Convert to list and sort by total
      final result = characterVotes.entries.map((entry) {
        final upVotes = entry.value['up'] ?? 0;
        final downVotes = entry.value['down'] ?? 0;
        return {
          'character_name': entry.key,
          'up_votes': upVotes,
          'down_votes': downVotes,
          'total': upVotes - downVotes,
        };
      }).toList();

      result.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

      return result.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Favorite Actor Voting
  Future<void> voteFavoriteActor({
    required String userId,
    required int tmdbId,
    required String mediaType,
    required int personId,
    String? characterName,
  }) async {
    try {
      await _client.from('favorite_actor_votes').upsert({
        'user_id': userId,
        'tmdb_id': tmdbId,
        'media_type': mediaType,
        'person_id': personId,
        'character_name': characterName,
      }, onConflict: 'user_id,tmdb_id,media_type');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFavoriteActorVote({
    required String userId,
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      await _client.from('favorite_actor_votes')
          .delete()
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType);
    } catch (e) {
      // Silently continue
    }
  }

  Future<Map<String, dynamic>?> getUserFavoriteActorVote({
    required String userId,
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      final response = await _client.from('favorite_actor_votes')
          .select('person_id, character_name')
          .eq('user_id', userId)
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteActorResults({
    required int tmdbId,
    required String mediaType,
    int limit = 10,
  }) async {
    try {
      final response = await _client.from('favorite_actor_votes')
          .select('person_id, character_name')
          .eq('tmdb_id', tmdbId)
          .eq('media_type', mediaType);

      final votes = List<Map<String, dynamic>>.from(response);
      if (votes.isEmpty) return [];

      // Count votes per person
      Map<int, Map<String, dynamic>> personVotes = {};
      for (final vote in votes) {
        final personId = vote['person_id'] as int;
        final characterName = vote['character_name'] as String? ?? 'Unknown';
        if (!personVotes.containsKey(personId)) {
          personVotes[personId] = {
            'person_id': personId,
            'character_name': characterName,
            'votes': 0,
          };
        }
        personVotes[personId]!['votes'] = (personVotes[personId]!['votes'] as int) + 1;
      }

      // Convert to list and calculate percentages
      final totalVotes = votes.length;
      final result = personVotes.values.map((pv) {
        final voteCount = pv['votes'] as int;
        return {
          'person_id': pv['person_id'],
          'character_name': pv['character_name'],
          'votes': voteCount,
          'percentage': totalVotes > 0 ? (voteCount / totalVotes * 100).round() : 0,
        };
      }).toList();

      // Sort by votes descending
      result.sort((a, b) => (b['votes'] as int).compareTo(a['votes'] as int));

      return result.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}
