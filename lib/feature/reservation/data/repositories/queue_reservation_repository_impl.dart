import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/shared/utils/logger.dart';

/// Repository implementation for queue-based reservations
class QueueReservationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final Logger _logger;

  QueueReservationRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _logger = logger ?? Logger('QueueReservationRepository');

  /// Join a queue for a specific time slot
  Future<Map<String, dynamic>> joinQueue({
    required String userId,
    required String providerId,
    required String? governorateId,
    String? serviceId,
    String? serviceName,
    required List<AttendeeModel> attendees,
    required DateTime preferredDate,
    required TimeOfDay preferredHour,
    String? notes,
  }) async {
    try {
      // Call the cloud function to join the queue
      final callable = _functions.httpsCallable('joinQueue');
      final result = await callable.call({
        'userId': userId,
        'providerId': providerId,
        'governorateId': governorateId,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'preferredDate': preferredDate.toIso8601String(),
        'preferredHour': preferredHour.hour,
        'attendees': attendees.map((a) => a.toMap()).toList(),
        'notes': notes,
      });

      _logger.info('Joined queue: ${result.data}');
      return result.data;
    } catch (e) {
      _logger.error('Error joining queue: $e');
      return {
        'success': false,
        'error': 'Failed to join queue: ${e.toString()}',
      };
    }
  }

  /// Check the current status of a queue entry
  Future<Map<String, dynamic>> checkQueueStatus({
    required String queueReservationId,
  }) async {
    try {
      final callable = _functions.httpsCallable('checkQueueStatus');
      final result = await callable.call({
        'queueReservationId': queueReservationId,
      });

      _logger.info('Checked queue status: ${result.data}');
      return result.data;
    } catch (e) {
      _logger.error('Error checking queue status: $e');
      return {
        'success': false,
        'error': 'Failed to check queue status: ${e.toString()}',
      };
    }
  }

  /// Leave a queue
  Future<Map<String, dynamic>> leaveQueue({
    required String queueReservationId,
  }) async {
    try {
      final callable = _functions.httpsCallable('leaveQueue');
      final result = await callable.call({
        'queueReservationId': queueReservationId,
      });

      _logger.info('Left queue: ${result.data}');
      return result.data;
    } catch (e) {
      _logger.error('Error leaving queue: $e');
      return {
        'success': false,
        'error': 'Failed to leave queue: ${e.toString()}',
      };
    }
  }

  /// Get all active queue entries for a user
  Future<List<Map<String, dynamic>>> getUserQueueEntries(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('queueReservations')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['waiting', 'processing']).get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.error('Error getting user queue entries: $e');
      return [];
    }
  }

  /// Update user's reminder settings
  Future<Map<String, dynamic>> updateReminderSettings({
    required bool generalReminders,
    List<int>? reminderTimes,
    bool? notifyOnQueueUpdates,
    int? dailyReminderTime,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateReminderSettings');
      final result = await callable.call({
        'generalReminders': generalReminders,
        'reminderTimes': reminderTimes,
        'notifyOnQueueUpdates': notifyOnQueueUpdates,
        'dailyReminderTime': dailyReminderTime,
      });

      _logger.info('Updated reminder settings: ${result.data}');
      return result.data;
    } catch (e) {
      _logger.error('Error updating reminder settings: $e');
      return {
        'success': false,
        'error': 'Failed to update reminder settings: ${e.toString()}',
      };
    }
  }

  /// Get user's reminder settings
  Future<Map<String, dynamic>> getReminderSettings() async {
    try {
      final callable = _functions.httpsCallable('getReminderSettings');
      final result = await callable.call({});

      _logger.info('Got reminder settings: ${result.data}');
      return result.data;
    } catch (e) {
      _logger.error('Error getting reminder settings: $e');
      return {
        'success': false,
        'error': 'Failed to get reminder settings: ${e.toString()}',
      };
    }
  }
}
