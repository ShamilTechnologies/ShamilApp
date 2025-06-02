import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shamil_mobile_app/core/constants/app_constants.dart'
    as AppConstants;
import 'package:shamil_mobile_app/core/models/notification_model.dart';
import 'package:shamil_mobile_app/core/repository/notification_repository.dart';

/// A comprehensive notification service that handles all types of notifications
/// using OneSignal as the backend service
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  bool _isInitialized = false;
  final _notificationController = StreamController<OSNotification>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();

  // Stream getters
  Stream<OSNotification> get notificationStream =>
      _notificationController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // Repository for storing notifications
  final NotificationRepository _repository = NotificationRepository();

  // Current user ID
  String? _currentUserId;

  // Notification types
  static const String TYPE_RESERVATION = 'reservation';
  static const String TYPE_SUBSCRIPTION = 'subscription';
  static const String TYPE_FRIEND = 'friend';
  static const String TYPE_SYSTEM = 'system';

  NotificationService._();

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Enable verbose logging for debugging (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize OneSignal
    OneSignal.initialize(AppConstants.oneSignalAppId);

    // Request notification permission
    await OneSignal.Notifications.requestPermission(true);

    // Configure external notification appearance
    await _configureExternalNotifications();

    // Set up notification handlers
    _setupNotificationHandlers();

    _isInitialized = true;
    debugPrint('Notification service initialized successfully');

    // Initial unread count update
    _updateUnreadCount();
  }

  /// Configure how notifications appear when app is in background/closed
  Future<void> _configureExternalNotifications() async {
    try {
      // Enable notification display
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint(
            'NOTIFICATION RECEIVED IN FOREGROUND: ${event.notification.title}');

        // Store notification in the background
        _storeNotification(event.notification);

        // Always display the notification
        event.notification.display();

        // Add to stream for UI updates
        _notificationController.add(event.notification);

        // Update unread count
        _updateUnreadCount();
      });

      // Set the in-app focus behavior to show alerts even when the app is active
      await OneSignal.InAppMessages.paused(false);

      debugPrint('External notifications configured successfully');
    } catch (e) {
      debugPrint('Error configuring external notifications: $e');
    }
  }

  /// Set up notification handlers
  void _setupNotificationHandlers() {
    // Handle notification opened
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('NOTIFICATION CLICKED: ${event.notification.title}');

      // Mark as read when clicked
      _markNotificationAsRead(event.notification);

      // Handle navigation
      _handleNotificationClick(event.notification);
    });

    // Handle notification permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      debugPrint('PERMISSION STATE CHANGED: ${state.toString()}');
    });
  }

  /// Store a notification
  Future<void> _storeNotification(OSNotification notification) async {
    if (_currentUserId == null) return;

    try {
      // Convert OneSignal notification to our model
      final notificationData = notification.additionalData ?? {};
      final notificationModel = NotificationModel(
        id: notification.notificationId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification.title ?? '',
        body: notification.body ?? '',
        type: notificationData['type'] ?? TYPE_SYSTEM,
        targetId: notificationData['id'],
        additionalData: notificationData,
        timestamp: DateTime.now(),
      );

      // Store in repository
      await _repository.addNotificationToFirestore(
          _currentUserId!, notificationModel);
    } catch (e) {
      debugPrint('Error storing notification: $e');
    }
  }

  /// Mark a notification as read
  Future<void> _markNotificationAsRead(OSNotification notification) async {
    if (_currentUserId == null) return;

    try {
      final notificationId = notification.notificationId;
      await _repository.markNotificationAsReadInFirestore(
          _currentUserId!, notificationId);
      _updateUnreadCount();
        } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Get all notifications for the current user
  Future<List<NotificationModel>> getNotifications() async {
    if (_currentUserId == null) return [];
    return _repository.getNotificationsFromFirestore(_currentUserId!);
  }

  /// Mark a notification as read by ID
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_currentUserId == null) return;
    await _repository.markNotificationAsReadInFirestore(
        _currentUserId!, notificationId);
    _updateUnreadCount();
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (_currentUserId == null) return;

    final notifications = await getNotifications();
    for (final notification in notifications.where((n) => !n.isRead)) {
      await _repository.markNotificationAsReadInFirestore(
          _currentUserId!, notification.id);
    }

    _updateUnreadCount();
  }

  /// Get the unread notification count
  Future<int> getUnreadCount() async {
    if (_currentUserId == null) return 0;
    return _repository.getUnreadNotificationCountFromFirestore(_currentUserId!);
  }

  /// Update the unread count and broadcast to listeners
  Future<void> _updateUnreadCount() async {
    if (_currentUserId == null) return;

    final count = await getUnreadCount();
    _unreadCountController.add(count);
  }

  /// Handle notification click based on type
  void _handleNotificationClick(OSNotification notification) {
    final data = notification.additionalData;
    if (data == null) return;

    final type = data['type'] as String?;
    final id = data['id'] as String?;

    switch (type) {
      case TYPE_RESERVATION:
        // Navigate to reservation details
        _navigateToReservation(id);
        break;
      case TYPE_SUBSCRIPTION:
        // Navigate to subscription details
        _navigateToSubscription(id);
        break;
      case TYPE_FRIEND:
        // Navigate to friend profile
        _navigateToFriendProfile(id);
        break;
      case TYPE_SYSTEM:
        // Handle system notification
        _handleSystemNotification(data);
        break;
    }
  }

  /// Set the user's ID for targeting notifications
  Future<void> setUserId(String userId) async {
    _currentUserId = userId;
    await OneSignal.login(userId);

    // Enable external user ID for targeting
    await OneSignal.User.addEmail(userId);
    await OneSignal.User.addSms(userId);

    debugPrint('OneSignal user ID set: $userId');

    // Update unread count when user ID changes
    _updateUnreadCount();
  }

  /// Remove the user's ID
  Future<void> removeUserId() async {
    _currentUserId = null;
    await OneSignal.logout();
    debugPrint('OneSignal user ID removed');

    // Reset unread count
    _unreadCountController.add(0);
  }

  /// Navigation handlers
  void _navigateToReservation(String? id) {
    if (id == null) return;
    // TODO: Implement navigation to reservation details
    debugPrint('Navigate to reservation: $id');
  }

  void _navigateToSubscription(String? id) {
    if (id == null) return;
    // TODO: Implement navigation to subscription details
    debugPrint('Navigate to subscription: $id');
  }

  void _navigateToFriendProfile(String? id) {
    if (id == null) return;
    // TODO: Implement navigation to friend profile
    debugPrint('Navigate to friend profile: $id');
  }

  void _handleSystemNotification(Map<String, dynamic> data) {
    // TODO: Implement system notification handling
    debugPrint('Handle system notification: $data');
  }

  /// Send a reservation notification
  Future<void> sendReservationNotification({
    required String userId,
    required String reservationId,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // For client-side notifications, we'll use tag-based notifications
      // as direct API sends are typically handled server-side
      await sendLocalNotification(
        title: title,
        body: body,
        type: TYPE_RESERVATION,
        id: reservationId,
        additionalData: additionalData,
      );
      debugPrint('Reservation notification prepared: $title');
    } catch (e) {
      debugPrint('Error preparing reservation notification: $e');
    }
  }

  /// Send a subscription notification
  Future<void> sendSubscriptionNotification({
    required String userId,
    required String subscriptionId,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await sendLocalNotification(
        title: title,
        body: body,
        type: TYPE_SUBSCRIPTION,
        id: subscriptionId,
        additionalData: additionalData,
      );
      debugPrint('Subscription notification prepared: $title');
    } catch (e) {
      debugPrint('Error preparing subscription notification: $e');
    }
  }

  /// Send a friend notification
  Future<void> sendFriendNotification({
    required String userId,
    required String friendId,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await sendLocalNotification(
        title: title,
        body: body,
        type: TYPE_FRIEND,
        id: friendId,
        additionalData: additionalData,
      );
      debugPrint('Friend notification prepared: $title');
    } catch (e) {
      debugPrint('Error preparing friend notification: $e');
    }
  }

  /// Send a system notification
  Future<void> sendSystemNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await sendLocalNotification(
        title: title,
        body: body,
        type: TYPE_SYSTEM,
        additionalData: additionalData,
      );
      debugPrint('System notification prepared: $title');
    } catch (e) {
      debugPrint('Error preparing system notification: $e');
    }
  }

  /// Send a local notification using OneSignal
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    required String type,
    String? id,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Map<String, dynamic> data = {
        'type': type,
        if (id != null) 'id': id,
        if (additionalData != null) ...additionalData,
      };

      // For OneSignal 5.3.2, we use the in-app messaging
      await OneSignal.InAppMessages.addTrigger('notification_type', type);

      // Add other triggers for the specific notification data
      if (id != null) {
        await OneSignal.InAppMessages.addTrigger('notification_id', id);
      }

      debugPrint('In-app notification triggered: $title');
    } catch (e) {
      debugPrint('Error triggering notification: $e');
    }
  }

  /// Dispose the notification service
  void dispose() {
    _notificationController.close();
    _unreadCountController.close();
  }
}
