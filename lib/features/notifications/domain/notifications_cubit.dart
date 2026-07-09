import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/supabase_service.dart';

// States
abstract class NotificationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

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

  @override
  List<Object?> get props => [message];
}

// Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final SupabaseService _supabaseService;
  RealtimeChannel? _channel;

  NotificationsCubit(this._supabaseService) : super(NotificationsInitial());

  Future<void> loadNotifications() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (isClosed) return;
      emit(NotificationsLoaded(notifications: []));
      return;
    }

    if (isClosed) return;
    emit(NotificationsLoading());
    try {
      final data = await _supabaseService.getNotifications(user.id);
      final unreadCount = data.where((n) => n['is_read'] == false).length;
      if (isClosed) return;
      emit(NotificationsLoaded(notifications: data, unreadCount: unreadCount));
    } catch (e) {
      if (isClosed) return;
      emit(NotificationsError('Something went wrong. Please try again.'));
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
            // Reload notifications when new one arrives (check if cubit is still open)
            if (!isClosed) {
              loadNotifications();
            }
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