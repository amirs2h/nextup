import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/supabase_service.dart';

// Grouped notification model
class GroupedNotification {
  final String type;
  final List<Map<String, dynamic>> notifications;
  final String? posterPath;
  final String? contentTitle;
  final int? tmdbId;
  final String? mediaType;
  final String? commentId;
  final String? parentId;
  final DateTime latestAt;
  final bool isRead;
  final List<String> avatarUrls;
  final List<String> usernames;

  GroupedNotification({
    required this.type,
    required this.notifications,
    this.posterPath,
    this.contentTitle,
    this.tmdbId,
    this.mediaType,
    this.commentId,
    this.parentId,
    required this.latestAt,
    required this.isRead,
    this.avatarUrls = const [],
    this.usernames = const [],
  });
}

// States
abstract class NotificationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Map<String, dynamic>> notifications;
  final List<GroupedNotification> grouped;
  final int unreadCount;

  NotificationsLoaded({
    required this.notifications,
    this.grouped = const [],
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [notifications, grouped, unreadCount];
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final SupabaseService _supabaseService;
  RealtimeChannel? _channel;
  bool _isSubscribing = false;

  NotificationsCubit(this._supabaseService) : super(NotificationsInitial()) {
    if (_supabaseService.isLoggedIn) {
      loadNotifications();
    }
  }

  Future<void> loadNotifications() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(NotificationsLoaded(notifications: [], grouped: []));
      return;
    }

    if (isClosed) return;
    emit(NotificationsLoading());
    try {
      final data = await _supabaseService.getNotifications(user.id);
      final unreadCount = data.where((n) => n['is_read'] == false).length;
      final grouped = _groupNotifications(data);
      if (isClosed) return;
      emit(NotificationsLoaded(notifications: data, grouped: grouped, unreadCount: unreadCount));
    } catch (e) {
      if (isClosed) return;
      emit(NotificationsError('Something went wrong. Please try again.'));
    }
  }

  List<GroupedNotification> _groupNotifications(List<Map<String, dynamic>> notifications) {
    final groups = <String, List<Map<String, dynamic>>>{};
    final groupKeys = <String, String>{};

    for (final n in notifications) {
      final type = n['type'] ?? '';
      final data = n['data'] as Map<String, dynamic>? ?? {};
      final commentId = data['comment_id'] as String?;
      final parentId = data['parent_id'] as String?;
      final tmdbId = data['tmdb_id'];

      String key;
      switch (type) {
        case 'comment_like':
          // Group likes on the same comment
          key = commentId != null ? 'like_$commentId' : 'like_${n['id']}';
          break;
        case 'comment_reply':
          // Group replies to the same parent comment
          key = parentId != null ? 'reply_$parentId' : 'reply_${n['id']}';
          break;
        case 'new_comment':
          // Group comments on the same content
          key = tmdbId != null ? 'comment_${tmdbId}_$type' : 'comment_${n['id']}';
          break;
        case 'follow':
        case 'new_follower':
          // Don't group follows - each is separate
          key = 'follow_${n['id']}';
          break;
        default:
          key = '${type}_${n['id']}';
      }

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(n);
      groupKeys[key] = type;
    }

    final result = <GroupedNotification>[];
    for (final entry in groups.entries) {
      final group = entry.value;
      final type = groupKeys[entry.key] ?? '';

      // Extract unique avatars (max 3)
      final avatarUrls = <String>[];
      final usernames = <String>[];
      for (final n in group) {
        final data = n['data'] as Map<String, dynamic>? ?? {};
        final avatar = data['avatar_url'] as String?;
        final title = n['title'] as String? ?? '';
        if (avatar != null && avatar.isNotEmpty && !avatarUrls.contains(avatar)) {
          avatarUrls.add(avatar);
          // Extract username from title (before " commented on" / " liked" / etc.)
          final username = _extractUsername(title);
          if (username != null && !usernames.contains(username)) {
            usernames.add(username);
          }
        }
        if (avatarUrls.length >= 3) break;
      }

      // Get metadata from first notification
      final firstData = group.first['data'] as Map<String, dynamic>? ?? {};
      final posterPath = firstData['poster_path'] as String?;
      final contentTitle = firstData['title'] as String?;
      final tmdbId = firstData['tmdb_id'];
      final mediaType = firstData['media_type'] ?? 'tv';
      final commentId = firstData['comment_id'] as String?;
      final parentId = firstData['parent_id'] as String?;

      final latestAt = group.map((n) {
        return n['created_at'] != null ? DateTime.tryParse(n['created_at']) ?? DateTime.now() : DateTime.now();
      }).reduce((a, b) => a.isAfter(b) ? a : b);

      final isRead = group.every((n) => n['is_read'] == true);

      result.add(GroupedNotification(
        type: type,
        notifications: group,
        posterPath: posterPath,
        contentTitle: contentTitle,
        tmdbId: tmdbId != null ? (tmdbId is int ? tmdbId : int.tryParse(tmdbId.toString())) : null,
        mediaType: mediaType,
        commentId: commentId,
        parentId: parentId,
        latestAt: latestAt,
        isRead: isRead,
        avatarUrls: avatarUrls,
        usernames: usernames,
      ));
    }

    // Sort by latest notification time
    result.sort((a, b) => b.latestAt.compareTo(a.latestAt));
    return result;
  }

  String? _extractUsername(String title) {
    // "علی commented on Breaking Bad" → "علی"
    // "سارا liked your comment" → "سارا"
    // "محمد replied to your comment on Breaking Bad" → "محمد"
    final idx = title.indexOf(' ');
    if (idx > 0) return title.substring(0, idx);
    return null;
  }

  void subscribeToRealtime() {
    final user = _supabaseService.currentUser;
    if (user == null) return;
    if (_isSubscribing) return;

    _isSubscribing = true;
    _channel?.unsubscribe();
    _channel = null;

    _channel = _supabaseService.client
        .channel('notifications:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (!isClosed) {
              loadNotifications();
            }
          },
        )
        .subscribe();

    _isSubscribing = false;
  }

  void unsubscribeFromRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseService.markNotificationAsRead(notificationId);
      await loadNotifications();
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> markGroupAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    try {
      await _supabaseService.markNotificationsAsRead(notificationIds);
      await loadNotifications();
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> markAllAsRead() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.markAllNotificationsAsRead(user.id);
      await loadNotifications();
    } catch (e) {
      // Error handled silently
    }
  }

  @override
  Future<void> close() {
    unsubscribeFromRealtime();
    return super.close();
  }
}
