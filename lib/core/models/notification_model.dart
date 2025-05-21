import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'reservation', 'subscription', 'friend', 'system'
  final String?
      targetId; // ID of the target (reservation ID, subscription ID, etc.)
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.additionalData,
    required this.timestamp,
    this.isRead = false,
  });

  // Create from Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'system',
      targetId: data['targetId'],
      additionalData: data['additionalData'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  // Create from OneSignal notification
  factory NotificationModel.fromOneSignal(Map<String, dynamic> notification) {
    return NotificationModel(
      id: notification['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification['headings']?['en'] ?? notification['title'] ?? '',
      body: notification['contents']?['en'] ?? notification['body'] ?? '',
      type: notification['data']?['type'] ?? 'system',
      targetId: notification['data']?['id'],
      additionalData: notification['data'],
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'targetId': targetId,
      'additionalData': additionalData,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  // Create a copy with some fields changed
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? targetId,
    Map<String, dynamic>? additionalData,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      additionalData: additionalData ?? this.additionalData,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
