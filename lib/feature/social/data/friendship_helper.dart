import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';

/// Helper class for friendship status utilities
class FriendshipHelper {
  /// Get the appropriate action text based on friendship status
  static String getActionText(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.none:
        return 'Add Friend';
      case FriendshipStatus.requestSent:
        return 'Request Sent';
      case FriendshipStatus.requestReceived:
        return 'Accept Request';
      case FriendshipStatus.friends:
        return 'Friends';
    }
  }

  /// Get the appropriate icon based on friendship status
  static IconData getActionIcon(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.none:
        return Icons.person_add_outlined;
      case FriendshipStatus.requestSent:
        return Icons.schedule_outlined;
      case FriendshipStatus.requestReceived:
        return Icons.person_add_alt_1_outlined;
      case FriendshipStatus.friends:
        return Icons.people_outlined;
    }
  }

  /// Get the appropriate color based on friendship status
  static Color getActionColor(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.none:
        return Colors.blue;
      case FriendshipStatus.requestSent:
        return Colors.orange;
      case FriendshipStatus.requestReceived:
        return Colors.green;
      case FriendshipStatus.friends:
        return Colors.grey;
    }
  }

  /// Check if action button should be enabled
  static bool isActionEnabled(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.none:
      case FriendshipStatus.requestReceived:
        return true;
      case FriendshipStatus.requestSent:
      case FriendshipStatus.friends:
        return false;
    }
  }

  /// Get appropriate tooltip text
  static String getTooltipText(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.none:
        return 'Send friend request';
      case FriendshipStatus.requestSent:
        return 'Friend request already sent';
      case FriendshipStatus.requestReceived:
        return 'Accept incoming friend request';
      case FriendshipStatus.friends:
        return 'Already friends';
    }
  }

  /// Get status message for user feedback
  static String getStatusMessage(FriendshipStatus status, String userName) {
    switch (status) {
      case FriendshipStatus.none:
        return 'You can send a friend request to $userName';
      case FriendshipStatus.requestSent:
        return 'Friend request sent to $userName - waiting for response ⏳';
      case FriendshipStatus.requestReceived:
        return '$userName has sent you a friend request! You can accept it 📥';
      case FriendshipStatus.friends:
        return 'You and $userName are already friends 👥';
    }
  }

  /// Convert error type to user-friendly message
  static String getErrorMessage(String? errorType, String? defaultMessage) {
    switch (errorType) {
      case 'already_friends':
        return 'You are already friends with this user! 👥';
      case 'already_requested':
        return 'Friend request already sent! ⏳';
      case 'incoming_request':
        return 'This user has already sent you a friend request! Check your requests 📥';
      case 'firestore_error':
        return 'Something went wrong. Please try again. ⚠️';
      default:
        return defaultMessage ?? 'An error occurred';
    }
  }

  /// Get success message based on operation type
  static String getSuccessMessage(String? operationType, String? targetUser) {
    switch (operationType) {
      case 'friend_request_sent':
        return 'Friend request sent${targetUser != null ? ' to $targetUser' : ''}! 🎉';
      case 'friend_request_accepted':
        return 'Friend request accepted${targetUser != null ? ' from $targetUser' : ''}! 🤝';
      case 'friend_request_declined':
        return 'Friend request declined${targetUser != null ? ' from $targetUser' : ''}';
      case 'friend_removed':
        return 'Friend removed${targetUser != null ? ' ($targetUser)' : ''}';
      case 'friend_request_cancelled':
        return 'Friend request cancelled${targetUser != null ? ' to $targetUser' : ''}';
      default:
        return 'Operation completed successfully!';
    }
  }
}
