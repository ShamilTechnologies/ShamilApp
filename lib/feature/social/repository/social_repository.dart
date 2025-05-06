  // lib/feature/social/repository/social_repository.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // For AuthModel

/// Abstract interface for social backend operations (Family & Friends).
abstract class SocialRepository {

  // --- Family Actions ---

  /// Calls backend to add a family member (either external or send request).
  Future<Map<String, dynamic>> addOrRequestFamilyMember({
    required String currentUserId,
    required Map<String, dynamic> memberData, // name, relationship, phone, email, gender, nationalId, dob
    AuthModel? linkedUserModel, // If linking an existing app user
  });

  /// Calls backend to remove a family member link/entry.
  Future<Map<String, dynamic>> removeFamilyMember({
    required String currentUserId,
    required String memberDocId, // The ID of the doc in current user's subcollection
    String? linkedUserId, // The UID of the other user if it was an 'accepted' link
  });

  /// Calls backend to accept a family request.
  Future<Map<String, dynamic>> acceptFamilyRequest({
    required String currentUserId,
    required String requesterUserId,
    // Pass denormalized data for the backend function
    required String currentUserName,
    String? currentUserProfilePicUrl,
    required String requesterName,
    String? requesterProfilePicUrl,
    required String requesterRelationship, // Relationship requester assigned to current user
  });

  /// Calls backend to decline a family request.
  Future<Map<String, dynamic>> declineFamilyRequest({
    required String currentUserId,
    required String requesterUserId,
  });


  // --- Friend Actions ---

  /// Calls backend to send a friend request.
  Future<Map<String, dynamic>> sendFriendRequest({
    required String currentUserId,
    required String targetUserId,
    // Pass denormalized data for the backend function
    required String currentUserName,
    String? currentUserProfilePicUrl,
    required String targetUserName,
    String? targetUserProfilePicUrl,
  });

  /// Calls backend to accept a friend request.
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String currentUserId,
    required String requesterUserId,
    // Pass denormalized data
    required String currentUserName,
    String? currentUserProfilePicUrl,
    required String requesterUserName,
    String? requesterProfilePicUrl,
  });

  /// Calls backend to decline a friend request.
  Future<Map<String, dynamic>> declineFriendRequest({
    required String currentUserId,
    required String requesterUserId,
  });

  /// Calls backend to remove a friend.
  Future<Map<String, dynamic>> removeFriend({
    required String currentUserId,
    required String friendUserId,
  });

  /// Calls backend to cancel/unsend a friend request.
  Future<Map<String, dynamic>> unsendFriendRequest({
    required String currentUserId,
    required String targetUserId,
  });

}

/// Firebase implementation of the [SocialRepository] using Cloud Functions.
class FirebaseSocialRepository implements SocialRepository {
  // Explicitly set Cloud Functions region
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1'); // TODO: Adjust region if needed

  /// Helper to call a Cloud Function and handle common errors.
  Future<Map<String, dynamic>> _callFunction(String functionName, Map<String, dynamic> payload) async {
    debugPrint("FirebaseSocialRepository: Calling '$functionName' Cloud Function...");
    try {
      final HttpsCallable callable = _functions.httpsCallable(functionName);
      final result = await callable.call(payload);
      debugPrint("Cloud Function '$functionName' result data: ${result.data}");
      // Return the data map from the function result, default to success: false if data is null/invalid
      return Map<String, dynamic>.from(result.data ?? {'success': false, 'error': 'Invalid response from server.'});
    } on FirebaseFunctionsException catch (e) {
       debugPrint("FirebaseSocialRepository: FirebaseFunctionsException calling $functionName - Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
       // Return a structured error map
       return {'success': false, 'error': "Cloud Function Error (${e.code}): ${e.message ?? 'Failed operation.'}"};
    } catch (e) {
      debugPrint("FirebaseSocialRepository: Generic error calling $functionName Cloud Function: $e");
      return {'success': false, 'error': "Failed to perform action: ${e.toString()}"};
    }
  }

  // --- Family Implementations ---

  @override
  Future<Map<String, dynamic>> addOrRequestFamilyMember({
    required String currentUserId,
    required Map<String, dynamic> memberData,
    AuthModel? linkedUserModel,
  }) async {
    final payload = {
      'currentUserId': currentUserId,
      'memberData': memberData, // Pass the map directly
      if (linkedUserModel != null) 'linkedUserId': linkedUserModel.uid,
      // Backend function needs current user's denormalized data if sending request
      // Ideally, the function gets this via context.auth, but pass if needed:
      // 'currentUserName': '...',
      // 'currentUserProfilePicUrl': '...',
    };
    // TODO: Create 'addFamilyMember' Cloud Function
    return await _callFunction('addFamilyMember', payload);
  }

  @override
  Future<Map<String, dynamic>> removeFamilyMember({
    required String currentUserId,
    required String memberDocId,
    String? linkedUserId,
  }) async {
    final payload = {
      'currentUserId': currentUserId,
      'memberDocId': memberDocId, // ID of the doc in *current user's* subcollection
      if (linkedUserId != null) 'linkedUserId': linkedUserId, // Pass if removing an accepted link
    };
     // TODO: Create 'removeFamilyMember' Cloud Function
    return await _callFunction('removeFamilyMember', payload);
  }

  @override
  Future<Map<String, dynamic>> acceptFamilyRequest({
    required String currentUserId,
    required String requesterUserId,
    required String currentUserName,
    String? currentUserProfilePicUrl,
    required String requesterName,
    String? requesterProfilePicUrl,
    required String requesterRelationship,
  }) async {
     final payload = {
      'currentUserId': currentUserId,
      'requesterUserId': requesterUserId,
      // Pass denormalized data needed by the function
      'currentUserName': currentUserName,
      'currentUserProfilePicUrl': currentUserProfilePicUrl,
      'requesterName': requesterName,
      'requesterProfilePicUrl': requesterProfilePicUrl,
      'requesterRelationship': requesterRelationship,
    };
     // TODO: Create 'acceptFamilyRequest' Cloud Function
    return await _callFunction('acceptFamilyRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> declineFamilyRequest({
    required String currentUserId,
    required String requesterUserId,
  }) async {
     final payload = {
      'currentUserId': currentUserId,
      'requesterUserId': requesterUserId,
    };
     // TODO: Create 'declineFamilyRequest' Cloud Function
    return await _callFunction('declineFamilyRequest', payload);
  }


  // --- Friend Implementations ---

  @override
  Future<Map<String, dynamic>> sendFriendRequest({
    required String currentUserId,
    required String targetUserId,
    required String currentUserName,
    String? currentUserProfilePicUrl,
    required String targetUserName,
    String? targetUserProfilePicUrl,
  }) async {
     final payload = {
      'currentUserId': currentUserId,
      'targetUserId': targetUserId,
      // Pass denormalized data
      'currentUserName': currentUserName,
      'currentUserProfilePicUrl': currentUserProfilePicUrl,
      'targetUserName': targetUserName,
      'targetUserProfilePicUrl': targetUserProfilePicUrl,
    };
     // TODO: Create 'sendFriendRequest' Cloud Function
    return await _callFunction('sendFriendRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String currentUserId,
    required String requesterUserId,
    required String currentUserName,
    String? currentUserProfilePicUrl,
    required String requesterUserName,
    String? requesterProfilePicUrl,
  }) async {
     final payload = {
      'currentUserId': currentUserId,
      'requesterUserId': requesterUserId,
      // Pass denormalized data
      'currentUserName': currentUserName,
      'currentUserProfilePicUrl': currentUserProfilePicUrl,
      'requesterUserName': requesterUserName,
      'requesterProfilePicUrl': requesterProfilePicUrl,
    };
     // TODO: Create 'acceptFriendRequest' Cloud Function
    return await _callFunction('acceptFriendRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> declineFriendRequest({
    required String currentUserId,
    required String requesterUserId,
  }) async {
     final payload = {
      'currentUserId': currentUserId,
      'requesterUserId': requesterUserId,
    };
     // TODO: Create 'declineFriendRequest' Cloud Function
    return await _callFunction('declineFriendRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) async {
     final payload = {
      'currentUserId': currentUserId,
      'friendUserId': friendUserId,
    };
     // TODO: Create 'removeFriend' Cloud Function
    return await _callFunction('removeFriend', payload);
  }

  @override
  Future<Map<String, dynamic>> unsendFriendRequest({
    required String currentUserId,
    required String targetUserId,
  }) async {
     final payload = {
      'currentUserId': currentUserId,
      'targetUserId': targetUserId,
    };
     // TODO: Create 'unsendFriendRequest' Cloud Function
    return await _callFunction('unsendFriendRequest', payload);
  }

}