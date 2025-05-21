import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shamil_mobile_app/core/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _localNotificationsKey = 'local_notifications';

  // Firestore collection reference for notifications
  CollectionReference<Map<String, dynamic>> _notificationsCollection(
      String userId) {
    return _firestore.collection('users/$userId/notifications');
  }

  // Store a notification in Firestore
  Future<void> addNotificationToFirestore(
      String userId, NotificationModel notification) async {
    try {
      await _notificationsCollection(userId)
          .doc(notification.id)
          .set(notification.toFirestore());
    } catch (e) {
      debugPrint('Error adding notification to Firestore: $e');
      // Fallback to local storage if Firestore fails
      await addNotificationToLocal(notification);
    }
  }

  // Get notifications from Firestore
  Future<List<NotificationModel>> getNotificationsFromFirestore(
      String userId) async {
    try {
      final QuerySnapshot snapshot = await _notificationsCollection(userId)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to recent notifications
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications from Firestore: $e');
      // Fallback to local storage if Firestore fails
      return getNotificationsFromLocal();
    }
  }

  // Mark a notification as read in Firestore
  Future<void> markNotificationAsReadInFirestore(
      String userId, String notificationId) async {
    try {
      await _notificationsCollection(userId)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read in Firestore: $e');
      // Fallback to local storage
      await markNotificationAsReadInLocal(notificationId);
    }
  }

  // Get unread notification count from Firestore
  Future<int> getUnreadNotificationCountFromFirestore(String userId) async {
    try {
      final QuerySnapshot snapshot = await _notificationsCollection(userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread notification count from Firestore: $e');
      // Fallback to local storage
      return getUnreadNotificationCountFromLocal();
    }
  }

  // Local storage operations (fallback when offline)

  // Store notifications locally
  Future<void> addNotificationToLocal(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<NotificationModel> notifications = await getNotificationsFromLocal();

      // Add the new notification
      notifications.insert(0, notification);

      // Limit stored notifications to prevent excessive storage use
      if (notifications.length > 50) {
        notifications = notifications.sublist(0, 50);
      }

      // Save to SharedPreferences
      final notificationsJson =
          notifications.map((n) => jsonEncode(n.toFirestore())).toList();
      await prefs.setStringList(_localNotificationsKey, notificationsJson);
    } catch (e) {
      debugPrint('Error adding notification to local storage: $e');
    }
  }

  // Get notifications from local storage
  Future<List<NotificationModel>> getNotificationsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          prefs.getStringList(_localNotificationsKey) ?? [];

      return notificationsJson.map((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        final DocumentSnapshot mockDoc = MockDocumentSnapshot(data);
        return NotificationModel.fromFirestore(mockDoc);
      }).toList();
    } catch (e) {
      debugPrint('Error getting notifications from local storage: $e');
      return [];
    }
  }

  // Mark notification as read locally
  Future<void> markNotificationAsReadInLocal(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<NotificationModel> notifications = await getNotificationsFromLocal();

      // Find and update the notification
      final int index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);

        // Save updated notifications
        final notificationsJson =
            notifications.map((n) => jsonEncode(n.toFirestore())).toList();
        await prefs.setStringList(_localNotificationsKey, notificationsJson);
      }
    } catch (e) {
      debugPrint('Error marking notification as read in local storage: $e');
    }
  }

  // Get unread notification count locally
  Future<int> getUnreadNotificationCountFromLocal() async {
    try {
      List<NotificationModel> notifications = await getNotificationsFromLocal();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint(
          'Error getting unread notification count from local storage: $e');
      return 0;
    }
  }
}

// Mock DocumentSnapshot for local storage use
class MockDocumentSnapshot implements DocumentSnapshot {
  final Map<String, dynamic> _data;
  final String _id;

  MockDocumentSnapshot(this._data)
      : _id = _data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Map<String, dynamic> data() => _data;

  @override
  String get id => _id;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
