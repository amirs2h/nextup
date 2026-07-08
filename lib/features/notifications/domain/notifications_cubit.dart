import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;

  NotificationsLoaded({required this.notifications, this.unreadCount = 0});

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}

// Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final SupabaseService _supabaseService;
  RealtimeChannel? _channel;

  NotificationsCubit(this._supabaseService) : super(NotificationsInitial());

  Future<void> loadNotifications() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      emit(NotificationsLoaded(notifications: []));
      return;
    }

    emit(NotificationsLoading());
    try {
      final data = await _supabaseService.getNotifications(user.id);
      final unreadCount = data.where((n) => n['is_read'] == false).length;
      emit(NotificationsLoaded(notifications: data, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  void subscribeToRealtime() {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    // Unsubscribe from previous channel if exists
    _channel?.unsubscribe();

    // Subscribe to notifications table changes
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
            // Reload notifications when new one arrives
            loadNotifications();
          },
        )
        .subscribe();
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
      // Handle error
    }
  }

  Future<void> markAllAsRead() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    try {
      await _supabaseService.markAllNotificationsAsRead(user.id);
      await loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Future<void> close() {
    unsubscribeFromRealtime();
    return super.close();
  }
}
