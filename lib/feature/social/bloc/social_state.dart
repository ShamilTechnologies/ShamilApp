part of 'social_bloc.dart';

// Removed imports as they are moved to the library file

// Enum to represent friendship status relative to the current user
enum FriendshipStatus { none, friends, requestSent, requestReceived }

// Base State
abstract class SocialState extends Equatable {
  const SocialState();
  @override List<Object?> get props => [];
}

// Initial State
class SocialInitial extends SocialState {}

// Loading State
class SocialLoading extends SocialState {
  final bool isLoadingList; // Differentiate list loading vs action loading
  const SocialLoading({this.isLoadingList = true});
   @override List<Object?> get props => [isLoadingList];
}

// --- Family States ---

/// Represents a family request (incoming)
class FamilyRequest extends Equatable {
   final String userId; // The other user's ID (who added you)
   final String name; // Denormalized name
   final String? profilePicUrl; // Denormalized picture
   final String relationship; // Relationship they assigned to you
   final Timestamp requestedAt;

   const FamilyRequest({
      required this.userId, required this.name, this.profilePicUrl,
      required this.relationship, required this.requestedAt
   });

   // Factory from Firestore document in *your* familyMembers subcollection
   factory FamilyRequest.fromFirestore(DocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return FamilyRequest(
         userId: doc.id, // The other user's UID is the document ID
         name: data['name'] as String? ?? 'Unknown', // Their name
         profilePicUrl: data['profilePicUrl'] as String?, // Their pic
         relationship: data['relationship'] as String? ?? 'Unknown', // Relationship they set
         requestedAt: data['addedAt'] as Timestamp? ?? Timestamp.now(), // Use addedAt as request time
      );
   }

   @override List<Object?> get props => [userId, name, profilePicUrl, relationship, requestedAt];
}


/// State holding loaded family members (accepted/external) and incoming requests
class FamilyDataLoaded extends SocialState {
  final List<FamilyMember> familyMembers; // Status 'accepted' or 'external'
  final List<FamilyRequest> incomingRequests; // Status 'pending_received'

  const FamilyDataLoaded({
     required this.familyMembers,
     required this.incomingRequests,
  });

  @override List<Object?> get props => [familyMembers, incomingRequests];
}

// --- Friend States ---

/// Represents a single friend entry (using denormalized data for easy display)
class Friend extends Equatable {
   final String userId;
   final String name; // Denormalized
   final String? profilePicUrl; // Denormalized
   final Timestamp? friendedAt;

   const Friend({required this.userId, required this.name, this.profilePicUrl, this.friendedAt});

   // Factory from Firestore (assuming denormalized data in friends subcollection doc)
   factory Friend.fromFirestore(DocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return Friend(
         userId: doc.id, // The friend's UID is the document ID
         name: data['displayName'] as String? ?? 'Unknown', // Field name in subcollection doc
         profilePicUrl: data['profilePicUrl'] as String?, // Field name in subcollection doc
         friendedAt: data['friendedAt'] as Timestamp?, // Field name in subcollection doc
      );
   }

   @override List<Object?> get props => [userId, name, profilePicUrl, friendedAt];
}

/// Represents a friend request (incoming or outgoing)
class FriendRequest extends Equatable {
   final String userId; // The other user's ID
   final String name; // Denormalized name
   final String? profilePicUrl; // Denormalized picture
   final String status; // 'pending_sent' or 'pending_received'

   const FriendRequest({required this.userId, required this.name, this.profilePicUrl, required this.status});

    // Factory from Firestore (assuming denormalized data in friends subcollection doc)
   factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return FriendRequest(
         userId: doc.id, // The other user's UID is the document ID
         name: data['displayName'] as String? ?? 'Unknown',
         profilePicUrl: data['profilePicUrl'] as String?,
         status: data['status'] as String? ?? 'unknown',
      );
   }

   @override List<Object?> get props => [userId, name, profilePicUrl, status];
}

/// State holding loaded friends and friend requests (incoming and outgoing)
class FriendsAndRequestsLoaded extends SocialState {
   final List<Friend> friends;
   final List<FriendRequest> incomingRequests;
   // *** ADDED: List for outgoing requests ***
   final List<FriendRequest> outgoingRequests;

   const FriendsAndRequestsLoaded({
      required this.friends,
      required this.incomingRequests,
      required this.outgoingRequests, // Add to constructor
   });

    // *** UPDATED: props ***
    @override List<Object?> get props => [friends, incomingRequests, outgoingRequests];
}


// --- User Search States ---

/// Represents a user found in search, including their friendship status relative to the current user.
class UserSearchResultWithStatus extends Equatable {
   final AuthModel user;
   final FriendshipStatus status;

   const UserSearchResultWithStatus({required this.user, required this.status});

   @override List<Object?> get props => [user, status];
}

/// State holding results from searching users (includes friendship status)
class FriendSearchResultsWithStatus extends SocialState {
   final List<UserSearchResultWithStatus> results; // List of users with status
   final String query; // The search query used

   const FriendSearchResultsWithStatus({required this.results, required this.query});
   @override List<Object?> get props => [results, query];
}


/// State indicating a user search result by National ID (for linking family)
class UserSearchResult extends SocialState {
   final AuthModel? foundUser; // Null if not found or self
   final String searchedId; // ID/Query that was searched

   const UserSearchResult({required this.foundUser, required this.searchedId});
    @override List<Object?> get props => [foundUser, searchedId];
}

// Removed old FriendSearchResults state


// --- General Action States ---

/// State indicating successful generic social action
class SocialSuccess extends SocialState {
   final String message;
   const SocialSuccess({this.message = "Success"});
    @override List<Object?> get props => [message];
}

/// State for errors during social operations
class SocialError extends SocialState {
  final String message;
  const SocialError({required this.message});
  @override List<Object?> get props => [message];
}

