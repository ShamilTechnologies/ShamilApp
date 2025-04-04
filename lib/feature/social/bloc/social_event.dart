part of 'social_bloc.dart';

// Base class for all social-related events, uses Equatable for comparison
abstract class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => []; // Helps Equatable compare event instances
}

// --- Family Events ---

/// Event to trigger loading the current user's family members list
/// and any incoming family connection requests.
class LoadFamilyMembers extends SocialEvent {
  const LoadFamilyMembers();
}

/// Event to add a new family member.
/// Can either add an external contact directly or initiate a connection
/// request if an existing app user is linked via `linkedUserModel`.
class AddFamilyMember extends SocialEvent {
  // Data collected from the AddFamilyMemberView form
  final Map<String, dynamic> memberData; // (name, relationship, phone, email, gender, nationalId)
  // Optional: If an existing app user was found via ID check
  final AuthModel? linkedUserModel;

  const AddFamilyMember({required this.memberData, this.linkedUserModel});

  @override
  List<Object?> get props => [memberData, linkedUserModel];
}

/// Event to remove a family member entry from the user's list.
/// This handles removing both external contacts and accepted linked users.
class RemoveFamilyMember extends SocialEvent {
  // The Firestore document ID of the family member entry within the user's
  // 'familyMembers' subcollection.
  final String memberDocId;

  const RemoveFamilyMember({required this.memberDocId});

   @override
  List<Object?> get props => [memberDocId];
}

/// Event to search for an existing app user by their National ID.
/// Used in the AddFamilyMemberView to potentially link an app user.
class SearchUserByNationalId extends SocialEvent {
   final String nationalId;
   const SearchUserByNationalId({required this.nationalId});
   @override List<Object?> get props => [nationalId];
}

/// Event triggered when the current user accepts a family connection request
/// received from another user.
class AcceptFamilyRequest extends SocialEvent {
   final String requesterUserId; // UID of the person who sent the request
   // Denormalized data passed from the request object for easier processing
   final String requesterName;
   final String? requesterProfilePicUrl;
   final String requesterRelationship; // The relationship they assigned to the current user

   const AcceptFamilyRequest({
      required this.requesterUserId,
      required this.requesterName,
      this.requesterProfilePicUrl,
      required this.requesterRelationship,
   });
    @override List<Object?> get props => [requesterUserId, requesterName, requesterProfilePicUrl, requesterRelationship];
}

/// Event triggered when the current user declines a family connection request
/// received from another user.
class DeclineFamilyRequest extends SocialEvent {
   final String requesterUserId; // UID of the person who sent the request
   const DeclineFamilyRequest({required this.requesterUserId});
    @override List<Object?> get props => [requesterUserId];
}


// --- Friend Events ---

/// Event to load the current user's accepted friends list
/// and any incoming friend requests.
class LoadFriendsAndRequests extends SocialEvent {
   const LoadFriendsAndRequests();
}

/// Event to search for potential friends by name or username.
class SearchUsers extends SocialEvent {
  final String query; // The search term entered by the user
  const SearchUsers({required this.query});
  @override List<Object?> get props => [query];
}

/// Event to send a friend request to another app user.
class SendFriendRequest extends SocialEvent {
  final String targetUserId; // UID of the user to send the request to
  // Denormalized data of the target user (for display if needed)
  final String targetUserName;
  final String? targetUserPicUrl;

  const SendFriendRequest({
     required this.targetUserId,
     required this.targetUserName,
     this.targetUserPicUrl
  });
  @override List<Object?> get props => [targetUserId, targetUserName, targetUserPicUrl];
}

/// Event triggered when the current user accepts a friend request
/// received from another user.
class AcceptFriendRequest extends SocialEvent {
  final String requesterUserId; // UID of the user who sent the request
  // Denormalized data of the requester
  final String requesterUserName;
  final String? requesterUserPicUrl;

  const AcceptFriendRequest({
     required this.requesterUserId,
     required this.requesterUserName,
     this.requesterUserPicUrl
  });
  @override List<Object?> get props => [requesterUserId, requesterUserName, requesterUserPicUrl];
}

/// Event triggered when the current user declines a friend request
/// received from another user.
class DeclineFriendRequest extends SocialEvent {
  final String requesterUserId; // UID of the user who sent the request
  const DeclineFriendRequest({required this.requesterUserId});
  @override List<Object?> get props => [requesterUserId];
}

/// Event to remove an existing friend connection.
class RemoveFriend extends SocialEvent {
  final String friendUserId; // UID of the friend to remove
  const RemoveFriend({required this.friendUserId});
  @override List<Object?> get props => [friendUserId];
}

/// Event to cancel/unsend a friend request that the current user previously sent.
class UnsendFriendRequest extends SocialEvent {
   final String targetUserId; // UID of the user the request was sent to
   const UnsendFriendRequest({required this.targetUserId});
   @override List<Object?> get props => [targetUserId];
}

