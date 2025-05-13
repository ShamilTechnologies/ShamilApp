// lib/feature/social/repository/social_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
 

abstract class SocialRepository {
  Future<Map<String, dynamic>> addOrRequestFamilyMember({
    required String currentUserId,
    required AuthModel currentUserData, // Denormalized data of the user initiating
    required Map<String, dynamic> memberData, // Data of the member being added
    AuthModel? linkedUserModel, // If linking an existing app user
  });

  Future<Map<String, dynamic>> removeFamilyMember({
    required String currentUserId,
    required String memberDocId, // Doc ID in current user's familyMembers subcollection
    String? linkedUserId, // UID of the other user if it's an 'accepted' link
  });

  Future<Map<String, dynamic>> acceptFamilyRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String requesterUserId, // UID of the user who sent the request
    required String requesterName,
    String? requesterProfilePicUrl,
    required String requesterRelationship, // Relationship requester assigned to current user
  });

  Future<Map<String, dynamic>> declineFamilyRequest({
    required String currentUserId,
    required String requesterUserId,
  });

  Future<Map<String, dynamic>> sendFriendRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String targetUserId,
    required String targetUserName,
    String? targetUserProfilePicUrl,
  });

  Future<Map<String, dynamic>> acceptFriendRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String requesterUserId,
    required String requesterUserName,
    String? requesterProfilePicUrl,
  });

  Future<Map<String, dynamic>> declineFriendRequest({
    required String currentUserId,
    required String requesterUserId,
  });

  Future<Map<String, dynamic>> removeFriend({
    required String currentUserId,
    required String friendUserId,
  });

  Future<Map<String, dynamic>> unsendFriendRequest({
    required String currentUserId,
    required String targetUserId,
  });

  // Read operations
  Future<List<FamilyMember>> fetchFamilyMembers(String userId);
  Future<List<FamilyRequest>> fetchIncomingFamilyRequests(String userId);
  Future<List<Friend>> fetchFriends(String userId);
  Future<List<FriendRequest>> fetchIncomingFriendRequests(String userId);
  Future<List<FriendRequest>> fetchOutgoingFriendRequests(String userId);
  Future<List<UserSearchResultWithStatus>> searchUsersByNameOrUsername(String currentUserId, String query);
  Future<AuthModel?> searchUserByNationalId(String nationalId, String currentUserId);
}

class FirebaseSocialRepository implements SocialRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1'); // Ensure your region is correct
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _usersCollectionRef() => _firestore.collection('endUsers'); // Standardized collection name

  Future<Map<String, dynamic>> _callFunction(String functionName, Map<String, dynamic> payload) async {
    debugPrint("FirebaseSocialRepository: Calling '$functionName' with payload: $payload");
    try {
      final HttpsCallable callable = _functions.httpsCallable(functionName);
      final result = await callable.call(payload);
      debugPrint("Cloud Function '$functionName' raw result: ${result.data}");
      if (result.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(result.data);
      }
      return {'success': false, 'error': 'Invalid response type from server.'};
    } on FirebaseFunctionsException catch (e) {
       debugPrint("FirebaseSocialRepository: FirebaseFunctionsException for $functionName - Code: ${e.code}, Msg: ${e.message}, Details: ${e.details}");
       return {'success': false, 'error': "Server Error (${e.code}): ${e.message ?? 'Operation failed.'}"};
    } catch (e) {
      debugPrint("FirebaseSocialRepository: Generic error for $functionName: $e");
      return {'success': false, 'error': "An unexpected error occurred: ${e.toString()}"};
    }
  }

  @override
  Future<Map<String, dynamic>> addOrRequestFamilyMember({
    required String currentUserId, // currentUserId is often implicit in callable functions via context.auth.uid
    required AuthModel currentUserData,
    required Map<String, dynamic> memberData,
    AuthModel? linkedUserModel,
  }) async {
    final payload = {
      'memberData': memberData, // Contains name, relationship, phone, email, etc.
      'currentUserData': { // For creating the reciprocal entry if a request is sent
        'name': currentUserData.name,
        'profilePicUrl': currentUserData.profilePicUrl ?? currentUserData.image,
        'uid': currentUserId,
      },
      if (linkedUserModel != null) 'linkedUserId': linkedUserModel.uid,
      if (linkedUserModel != null) 'linkedUserName': linkedUserModel.name,
      if (linkedUserModel != null) 'linkedUserProfilePicUrl': linkedUserModel.profilePicUrl ?? linkedUserModel.image,
    };
    // Ensure Cloud Function 'social-addFamilyMember' is deployed and handles these params
    return await _callFunction('social-addFamilyMember', payload);
  }

  @override
  Future<Map<String, dynamic>> removeFamilyMember({
    required String currentUserId,
    required String memberDocId, // Doc ID of the family member in current user's subcollection
    String? linkedUserId, // UID of the linked user if applicable (for reciprocal removal)
  }) async {
    final payload = {
      'memberDocId': memberDocId,
      if (linkedUserId != null) 'linkedUserId': linkedUserId,
    };
    return await _callFunction('social-removeFamilyMember', payload);
  }

  @override
  Future<Map<String, dynamic>> acceptFamilyRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String requesterUserId,
    required String requesterName,
    String? requesterProfilePicUrl,
    required String requesterRelationship,
  }) async {
     final payload = {
      'requesterUserId': requesterUserId,
      'currentUserData': {
        'name': currentUserData.name,
        'profilePicUrl': currentUserData.profilePicUrl ?? currentUserData.image,
        'uid': currentUserId,
      },
      'requesterName': requesterName,
      'requesterProfilePicUrl': requesterProfilePicUrl,
      'relationshipProvidedByRequester': requesterRelationship,
    };
    return await _callFunction('social-acceptFamilyRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> declineFamilyRequest({
    required String currentUserId,
    required String requesterUserId,
  }) async {
     final payload = { 'requesterUserId': requesterUserId };
    return await _callFunction('social-declineFamilyRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> sendFriendRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String targetUserId,
    required String targetUserName,
    String? targetUserProfilePicUrl,
  }) async {
     final payload = {
      'targetUserId': targetUserId,
      'currentUserData': {
        'name': currentUserData.name,
        'username': currentUserData.username,
        'profilePicUrl': currentUserData.profilePicUrl ?? currentUserData.image,
        'uid': currentUserId,
      },
      'targetUserName': targetUserName, // Denormalized for target's incoming request view
      'targetUserProfilePicUrl': targetUserProfilePicUrl,
    };
    return await _callFunction('social-sendFriendRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String currentUserId,
    required AuthModel currentUserData,
    required String requesterUserId,
    required String requesterUserName,
    String? requesterProfilePicUrl,
  }) async {
     final payload = {
      'requesterUserId': requesterUserId,
      'currentUserData': {
        'name': currentUserData.name,
        'username': currentUserData.username,
        'profilePicUrl': currentUserData.profilePicUrl ?? currentUserData.image,
        'uid': currentUserId,
      },
      'requesterUserName': requesterUserName,
      'requesterProfilePicUrl': requesterProfilePicUrl,
    };
    return await _callFunction('social-acceptFriendRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> declineFriendRequest({
    required String currentUserId,
    required String requesterUserId,
  }) async {
     final payload = { 'requesterUserId': requesterUserId };
    return await _callFunction('social-declineFriendRequest', payload);
  }

  @override
  Future<Map<String, dynamic>> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) async {
     final payload = { 'friendUserId': friendUserId };
    return await _callFunction('social-removeFriend', payload);
  }

  @override
  Future<Map<String, dynamic>> unsendFriendRequest({
    required String currentUserId,
    required String targetUserId,
  }) async {
     final payload = { 'targetUserId': targetUserId };
    return await _callFunction('social-unsendFriendRequest', payload);
  }

  // Read Implementations
  @override
  Future<List<FamilyMember>> fetchFamilyMembers(String userId) async {
    final snapshot = await _usersCollectionRef().doc(userId).collection('familyMembers')
        .where('status', whereIn: ['accepted', 'external'])
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => FamilyMember.fromFirestore(doc)).toList();
  }

  @override
  Future<List<FamilyRequest>> fetchIncomingFamilyRequests(String userId) async {
    final snapshot = await _usersCollectionRef().doc(userId).collection('familyMembers')
        .where('status', isEqualTo: 'pending_received')
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => FamilyRequest.fromFirestore(doc)).toList();
  }

  @override
  Future<List<Friend>> fetchFriends(String userId) async {
    final snapshot = await _usersCollectionRef().doc(userId).collection('friends')
        .where('status', isEqualTo: 'accepted')
        .orderBy('friendedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Friend.fromFirestore(doc)).toList();
  }

  @override
  Future<List<FriendRequest>> fetchIncomingFriendRequests(String userId) async {
     final snapshot = await _usersCollectionRef().doc(userId).collection('friends')
        .where('status', isEqualTo: 'pending_received')
        // Consider ordering by request time if available, or by denormalized name
        .get();
    return snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList();
  }

  @override
  Future<List<FriendRequest>> fetchOutgoingFriendRequests(String userId) async {
    final snapshot = await _usersCollectionRef().doc(userId).collection('friends')
        .where('status', isEqualTo: 'pending_sent')
        .get();
    return snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList();
  }

  @override
  Future<List<UserSearchResultWithStatus>> searchUsersByNameOrUsername(String currentUserId, String query) async {
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.isEmpty) return [];

    // Search by name (prefix)
    final nameSnapshot = await _usersCollectionRef()
        .where('name_lowercase', isGreaterThanOrEqualTo: lowerQuery)
        .where('name_lowercase', isLessThanOrEqualTo: '$lowerQuery\uf8ff') // Standard pattern for prefix match
        .limit(10)
        .get();

    // Search by username (prefix)
    final usernameSnapshot = await _usersCollectionRef()
        .where('username', isGreaterThanOrEqualTo: lowerQuery)
        .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(10)
        .get();

    final Map<String, AuthModel> combinedResults = {};
    for (var doc in nameSnapshot.docs) {
      if (doc.id != currentUserId) combinedResults[doc.id] = AuthModel.fromFirestore(doc);
    }
    for (var doc in usernameSnapshot.docs) {
      if (doc.id != currentUserId) combinedResults[doc.id] = AuthModel.fromFirestore(doc);
    }

    final List<UserSearchResultWithStatus> resultsWithStatus = [];
    for (var userModel in combinedResults.values) {
      FriendshipStatus currentStatus = FriendshipStatus.none;
      try {
        final friendDoc = await _usersCollectionRef().doc(currentUserId).collection('friends').doc(userModel.uid).get();
        if (friendDoc.exists) {
          final statusString = (friendDoc.data())?['status'] as String?;
          switch (statusString) {
            case 'accepted': currentStatus = FriendshipStatus.friends; break;
            case 'pending_sent': currentStatus = FriendshipStatus.requestSent; break;
            case 'pending_received': currentStatus = FriendshipStatus.requestReceived; break;
          }
        }
      } catch (e) { /* Ignore errors fetching status, default to none */ }
      resultsWithStatus.add(UserSearchResultWithStatus(user: userModel, status: currentStatus));
    }
    resultsWithStatus.sort((a, b) => (a.user.name).compareTo(b.user.name));
    return resultsWithStatus;
  }

  @override
  Future<AuthModel?> searchUserByNationalId(String nationalId, String currentUserId) async {
    final querySnapshot = await _usersCollectionRef()
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      if (doc.id != currentUserId) { // Ensure not to return the current user
        return AuthModel.fromFirestore(doc);
      }
    }
    return null;
  }
}