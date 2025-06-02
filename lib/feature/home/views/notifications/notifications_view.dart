import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shamil_mobile_app/core/models/notification_model.dart';
import 'package:shamil_mobile_app/core/services/notification_service.dart';
import 'package:shamil_mobile_app/core/utils/colors.dart';
import 'package:shamil_mobile_app/core/utils/text_style.dart' as app_text_style;
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      _loadNotifications();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markNotificationAsRead(notification.id);
      _loadNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: app_text_style.getHeadlineTextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? _buildLoadingState()
            : _notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.bell_slash,
            size: 64,
            color: Colors.grey[400],
          ),
          const Gap(16),
          Text(
            'No Notifications',
            style: app_text_style.getHeadlineTextStyle(
              fontSize: 18,
              color: Colors.grey[700]!,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'You don\'t have any notifications yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    // Get icon and color based on notification type
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationService.TYPE_RESERVATION:
        icon = CupertinoIcons.calendar;
        iconColor = Colors.blue;
        break;
      case NotificationService.TYPE_SUBSCRIPTION:
        icon = CupertinoIcons.creditcard;
        iconColor = Colors.purple;
        break;
      case NotificationService.TYPE_FRIEND:
        icon = CupertinoIcons.person_2;
        iconColor = Colors.green;
        break;
      case NotificationService.TYPE_SYSTEM:
      default:
        icon = CupertinoIcons.info;
        iconColor = Colors.orange;
        break;
    }

    // Format the notification time
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final notificationDate = DateTime(
      notification.timestamp.year,
      notification.timestamp.month,
      notification.timestamp.day,
    );

    String formattedTime;
    if (notificationDate == today) {
      formattedTime =
          'Today, ${DateFormat('h:mm a').format(notification.timestamp)}';
    } else if (notificationDate == yesterday) {
      formattedTime =
          'Yesterday, ${DateFormat('h:mm a').format(notification.timestamp)}';
    } else {
      formattedTime =
          DateFormat('MMM d, h:mm a').format(notification.timestamp);
    }

    return InkWell(
      onTap: () {
        _markAsRead(notification);

        // Navigate based on notification type
        // We'll use a simpler approach instead of calling private methods
        if (notification.additionalData != null) {
          final data = notification.additionalData!;

          // Handle the notification click using the standard OneSignal pattern
          if (notification.type == NotificationService.TYPE_RESERVATION &&
              notification.targetId != null) {
            // Navigate to reservation details
            debugPrint('Navigate to reservation: ${notification.targetId}');
            // TODO: Implement actual navigation
          } else if (notification.type ==
                  NotificationService.TYPE_SUBSCRIPTION &&
              notification.targetId != null) {
            // Navigate to subscription details
            debugPrint('Navigate to subscription: ${notification.targetId}');
            // TODO: Implement actual navigation
          } else if (notification.type == NotificationService.TYPE_FRIEND &&
              notification.targetId != null) {
            // Navigate to friend profile
            debugPrint('Navigate to friend profile: ${notification.targetId}');
            // TODO: Implement actual navigation
          } else if (notification.type == NotificationService.TYPE_SYSTEM) {
            // Handle system notification
            debugPrint('Handle system notification: $data');
            // TODO: Implement actual navigation
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.primaryColor.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const Gap(16),

            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Unread indicator
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),

                      // Title
                      Expanded(
                        child: Text(
                          notification.title,
                          style: app_text_style.getHeadlineTextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Time
                      const Gap(8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const Gap(4),

                  // Body
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
