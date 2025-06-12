import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class ShamIlNotificationService {
  static final ShamIlNotificationService _instance =
      ShamIlNotificationService._internal();
  factory ShamIlNotificationService() => _instance;
  ShamIlNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing notification service: $e');
      }
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    if (status != PermissionStatus.granted) {
      if (kDebugMode) {
        print('⚠️ Notification permission not granted');
      }
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('📱 Notification tapped: ${response.payload}');
    }
  }

  /// Show access granted notification
  static Future<void> showAccessGrantedNotification(String userName) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'shamil_access_granted',
      'Access Granted',
      channelDescription: 'Notifications for successful access requests',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50), // Green
    );

    const darwinDetails = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      1001,
      '✅ Access Granted',
      'Welcome, $userName! Access approved.',
      details,
      payload: 'access_granted',
    );
  }

  /// Show access denied notification
  static Future<void> showAccessDeniedNotification(String reason) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'shamil_access_denied',
      'Access Denied',
      channelDescription: 'Notifications for denied access requests',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFF44336), // Red
    );

    const darwinDetails = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      1002,
      '❌ Access Denied',
      'Access request denied: $reason',
      details,
      payload: 'access_denied',
    );
  }

  /// Show NFC interaction notification
  static Future<void> showNFCInteractionNotification() async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'shamil_nfc_interaction',
      'NFC Interaction',
      channelDescription: 'Notifications for NFC card interactions',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3), // Blue
    );

    const darwinDetails = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      1003,
      '💳 NFC Card Active',
      'Your digital access card is being read...',
      details,
      payload: 'nfc_interaction',
    );
  }

  /// Show NFC service status notification
  static Future<void> showNFCServiceNotification(String status) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'shamil_nfc_service',
      'NFC Service',
      channelDescription: 'Notifications for NFC service status',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF9C27B0), // Purple
      ongoing: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      1004,
      '📱 Shamil NFC Service',
      status,
      details,
      payload: 'nfc_service_status',
    );
  }

  /// Show error notification
  static Future<void> showErrorNotification(String error) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'shamil_errors',
      'System Errors',
      channelDescription: 'Notifications for system errors',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF9800), // Orange
    );

    const darwinDetails = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      1005,
      '⚠️ System Error',
      error,
      details,
      payload: 'error',
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
