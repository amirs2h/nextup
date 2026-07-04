import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/notifications_cubit.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg(context),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const Spacer(),
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context.read<NotificationsCubit>().markAllAsRead(),
                  child: const Text('Mark all read', style: TextStyle(color: Color(0xFF6C63FF))),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        if (state is NotificationsLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
        }

        if (state is NotificationsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF4757)),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: AppColors.textSecondary(context))),
              ],
            ),
          );
        }

        if (state is NotificationsLoaded) {
          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 60, color: AppColors.textMuted(context)),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? '';
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final createdAt = notification['created_at'] != null ? DateTime.parse(notification['created_at']) : DateTime.now();

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'new_episode':
        icon = Icons.new_releases;
        iconColor = const Color(0xFF00FF88);
        break;
      case 'new_movie':
        icon = Icons.movie;
        iconColor = const Color(0xFF6C63FF);
        break;
      case 'new_follower':
        icon = Icons.person_add;
        iconColor = const Color(0xFF00D4FF);
        break;
      case 'comment_like':
        icon = Icons.favorite;
        iconColor = const Color(0xFFE50914);
        break;
      default:
        icon = Icons.notifications;
        iconColor = const Color(0xFFFFD93D);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        borderColor: isRead ? null : const Color(0xFF6C63FF).withOpacity(0.3),
        child: InkWell(
          onTap: () {
            if (!isRead) {
              context.read<NotificationsCubit>().markAsRead(notification['id']);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppColors.text(context), fontWeight: isRead ? FontWeight.normal : FontWeight.w600, fontSize: 14)),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(body, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Text(timeago.format(createdAt), style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6C63FF)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}



