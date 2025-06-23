import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get comprehensive profile data for a user
  Future<UserProfile> getUserProfile(String userId,
      {ProfileViewContext? context}) async {
    try {
      // Get basic user data
      final userDoc = await _firestore.collection('endUsers').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final authModel = AuthModel.fromFirestore(userDoc);

      // Get profile stats
      final stats = await _getProfileStats(userId);

      // Get achievements
      final achievements = await _getUserAchievements(userId);

      // Get friendship status if viewing another user's profile
      FriendshipStatus? friendshipStatus;
      List<MutualFriend> mutualFriends = [];

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null && currentUserId != userId) {
        friendshipStatus = await _getFriendshipStatus(currentUserId, userId);
        mutualFriends = await _getMutualFriends(currentUserId, userId);
      }

      return UserProfile.fromAuthModel(
        authModel,
        stats: stats,
        achievements: achievements,
        friendshipStatus: friendshipStatus,
        mutualFriends: mutualFriends,
      );
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  /// Get current user's own profile
  Future<UserProfile> getCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    return getUserProfile(currentUser.uid,
        context: ProfileViewContext.ownProfile);
  }

  /// Get profile statistics
  Future<ProfileStats> _getProfileStats(String userId) async {
    try {
      // Get friends count
      final friendsSnapshot = await _firestore
          .collection('endUsers')
          .doc(userId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      // Get reservations count
      final reservationsSnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .get();

      // Get achievements count
      final achievementsSnapshot = await _firestore
          .collection('endUsers')
          .doc(userId)
          .collection('achievements')
          .get();

      // Get profile views (if tracking is enabled)
      final profileViewsDoc =
          await _firestore.collection('profileViews').doc(userId).get();

      final profileViews = profileViewsDoc.exists
          ? (profileViewsDoc.data()?['count'] as int? ?? 0)
          : 0;

      // Get user's last activity
      final userDoc = await _firestore.collection('endUsers').doc(userId).get();

      // Handle lastSeen which could be stored as Timestamp or String
      DateTime? lastSeenDate;
      final lastSeenData = userDoc.data()?['lastSeen'];
      if (lastSeenData != null) {
        if (lastSeenData is Timestamp) {
          lastSeenDate = lastSeenData.toDate();
        } else if (lastSeenData is String) {
          try {
            lastSeenDate = DateTime.parse(lastSeenData);
          } catch (e) {
            print('Error parsing lastSeen string: $e');
            lastSeenDate = null;
          }
        }
      }

      return ProfileStats(
        friendsCount: friendsSnapshot.docs.length,
        reservationsCount: reservationsSnapshot.docs.length,
        achievementsCount: achievementsSnapshot.docs.length,
        profileViews: profileViews,
        lastActiveDate: lastSeenDate,
        accountType: userDoc.data()?['accountType'] as String? ?? 'basic',
      );
    } catch (e) {
      print('Error fetching profile stats: $e');
      return ProfileStats.empty();
    }
  }

  /// Get user achievements
  Future<List<Achievement>> _getUserAchievements(String userId) async {
    try {
      final achievementsSnapshot = await _firestore
          .collection('endUsers')
          .doc(userId)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .limit(10) // Limit to recent achievements
          .get();

      return achievementsSnapshot.docs
          .map((doc) => Achievement.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      print('Error fetching achievements: $e');
      return [];
    }
  }

  /// Get friendship status between two users
  Future<FriendshipStatus> _getFriendshipStatus(
      String currentUserId, String targetUserId) async {
    try {
      // Check if they are friends
      final friendDoc = await _firestore
          .collection('endUsers')
          .doc(currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .get();

      if (friendDoc.exists) {
        final status = friendDoc.data()?['status'] as String?;
        if (status == 'accepted') {
          return FriendshipStatus.friends;
        }
      }

      // Check if current user sent a request
      final sentRequestDoc = await _firestore
          .collection('endUsers')
          .doc(currentUserId)
          .collection('friendRequestsSent')
          .doc(targetUserId)
          .get();

      if (sentRequestDoc.exists) {
        return FriendshipStatus.requestSent;
      }

      // Check if current user received a request
      final receivedRequestDoc = await _firestore
          .collection('endUsers')
          .doc(currentUserId)
          .collection('friendRequests')
          .doc(targetUserId)
          .get();

      if (receivedRequestDoc.exists) {
        return FriendshipStatus.requestReceived;
      }

      // Check if blocked
      final blockedDoc = await _firestore
          .collection('endUsers')
          .doc(currentUserId)
          .collection('blocked')
          .doc(targetUserId)
          .get();

      if (blockedDoc.exists) {
        return FriendshipStatus.blocked;
      }

      return FriendshipStatus.none;
    } catch (e) {
      print('Error getting friendship status: $e');
      return FriendshipStatus.none;
    }
  }

  /// Get mutual friends between two users
  Future<List<MutualFriend>> _getMutualFriends(
      String currentUserId, String targetUserId) async {
    try {
      // Get current user's friends
      final currentUserFriendsSnapshot = await _firestore
          .collection('endUsers')
          .doc(currentUserId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      final currentUserFriends =
          currentUserFriendsSnapshot.docs.map((doc) => doc.id).toSet();

      // Get target user's friends
      final targetUserFriendsSnapshot = await _firestore
          .collection('endUsers')
          .doc(targetUserId)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      final targetUserFriends =
          targetUserFriendsSnapshot.docs.map((doc) => doc.id).toSet();

      // Find mutual friends
      final mutualFriendIds =
          currentUserFriends.intersection(targetUserFriends);

      if (mutualFriendIds.isEmpty) {
        return [];
      }

      // Get mutual friends data (limit to 5 for display)
      final mutualFriends = <MutualFriend>[];
      final friendsToFetch = mutualFriendIds.take(5);

      for (final friendId in friendsToFetch) {
        try {
          final friendDoc =
              await _firestore.collection('endUsers').doc(friendId).get();

          if (friendDoc.exists) {
            final data = friendDoc.data()!;
            mutualFriends.add(MutualFriend(
              uid: friendId,
              name: data['name'] as String,
              profilePicUrl: data['profilePicUrl'] as String?,
              username: data['username'] as String,
            ));
          }
        } catch (e) {
          print('Error fetching mutual friend $friendId: $e');
        }
      }

      return mutualFriends;
    } catch (e) {
      print('Error getting mutual friends: $e');
      return [];
    }
  }

  /// Track profile view
  Future<void> trackProfileView(String profileUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId == profileUserId) {
      return; // Don't track own profile views
    }

    try {
      final profileViewsRef =
          _firestore.collection('profileViews').doc(profileUserId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(profileViewsRef);

        if (doc.exists) {
          final currentCount = doc.data()?['count'] as int? ?? 0;
          transaction.update(profileViewsRef, {
            'count': currentCount + 1,
            'lastViewedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(profileViewsRef, {
            'count': 1,
            'lastViewedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Also track in user's profile views history (optional)
      await _firestore
          .collection('endUsers')
          .doc(profileUserId)
          .collection('profileViewHistory')
          .add({
        'viewerId': currentUserId,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking profile view: $e');
      // Non-critical error, don't throw
    }
  }

  /// Update user profile
  Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('endUsers').doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  /// Search users by name or username
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Search by name (case-insensitive partial match)
      final nameQuery = await _firestore
          .collection('endUsers')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + '\uf8ff')
          .where('isBlocked', isEqualTo: false)
          .limit(limit)
          .get();

      // Search by username
      final usernameQuery = await _firestore
          .collection('endUsers')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + '\uf8ff')
          .where('isBlocked', isEqualTo: false)
          .limit(limit)
          .get();

      // Combine and deduplicate results
      final allDocs = <String, QueryDocumentSnapshot>{};

      for (final doc in nameQuery.docs) {
        allDocs[doc.id] = doc;
      }

      for (final doc in usernameQuery.docs) {
        allDocs[doc.id] = doc;
      }

      // Convert to UserProfile objects
      final profiles = <UserProfile>[];
      for (final doc in allDocs.values) {
        try {
          final authModel = AuthModel.fromFirestore(doc);
          final stats = await _getProfileStats(doc.id);

          profiles.add(UserProfile.fromAuthModel(authModel, stats: stats));
        } catch (e) {
          print('Error converting search result: $e');
        }
      }

      return profiles;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
