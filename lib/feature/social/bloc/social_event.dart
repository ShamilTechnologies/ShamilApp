part of 'social_bloc.dart';

abstract class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => [];
}

// --- Family Events ---

/// Event to load family members for the current user
class LoadFamilyMembers extends SocialEvent {
  const LoadFamilyMembers();
}

/// Event to add a new family member (or send request if linked)
class AddFamilyMember extends SocialEvent {
  final Map<String, dynamic> memberData; // name, relationship, phone, email, gender, nationalId
  final AuthModel? linkedUserModel; // If user was found via ID check

  const AddFamilyMember({required this.memberData, this.linkedUserModel});

  @override
  List<Object?> get props => [memberData, linkedUserModel];
}

/// Event to remove a family member (external or accepted link)
class RemoveFamilyMember extends SocialEvent {
  final String memberDocId; // Firestore document ID of the member in the subcollection

  const RemoveFamilyMember({required this.memberDocId});

   @override
  List<Object?> get props => [memberDocId];
}

/// Event to search for users by National ID (for linking family)
class SearchUserByNationalId extends SocialEvent {
   final String nationalId;
   const SearchUserByNationalId({required this.nationalId});
   @override List<Object?> get props => [nationalId];
}

/// Event to accept an incoming family connection request
class AcceptFamilyRequest extends SocialEvent {
   final String requesterUserId; // UID of the person who added you
   // Pass denormalized data for updating your own record easily
   final String requesterName;
   final String? requesterProfilePicUrl;
   final String requesterRelationship; // The relationship they assigned to you

   const AcceptFamilyRequest({
      required this.requesterUserId,
      required this.requesterName,
      this.requesterProfilePicUrl,
      required this.requesterRelationship,
   });
    @override List<Object?> get props => [requesterUserId, requesterName, requesterProfilePicUrl, requesterRelationship];
}

/// Event to decline an incoming family connection request
class DeclineFamilyRequest extends SocialEvent {
   final String requesterUserId; // UID of the person who added you
   const DeclineFamilyRequest({required this.requesterUserId});
    @override List<Object?> get props => [requesterUserId];
}


// --- Friend Events ---

/// Event to load both accepted friends and pending friend requests
class LoadFriendsAndRequests extends SocialEvent {
   const LoadFriendsAndRequests();
}

/// Event to search for users to add as friends (e.g., by name or email)
class SearchUsers extends SocialEvent {
  final String query;
  const SearchUsers({required this.query});
  @override List<Object?> get props => [query];
}

/// Event to send a friend request to another user
class SendFriendRequest extends SocialEvent {
  final String targetUserId;
  final String targetUserName; // Denormalized data for target user
  final String? targetUserPicUrl; // Denormalized data for target user

  const SendFriendRequest({
     required this.targetUserId,
     required this.targetUserName,
     this.targetUserPicUrl
  });
  @override List<Object?> get props => [targetUserId, targetUserName, targetUserPicUrl];
}

/// Event to accept an incoming friend request
class AcceptFriendRequest extends SocialEvent {
  final String requesterUserId;
  final String requesterUserName; // Denormalized data for requester
  final String? requesterUserPicUrl; // Denormalized data for requester

  const AcceptFriendRequest({
     required this.requesterUserId,
     required this.requesterUserName,
     this.requesterUserPicUrl
  });
  @override List<Object?> get props => [requesterUserId, requesterUserName, requesterUserPicUrl];
}

/// Event to decline/ignore an incoming friend request
class DeclineFriendRequest extends SocialEvent {
  final String requesterUserId;
  const DeclineFriendRequest({required this.requesterUserId});
  @override List<Object?> get props => [requesterUserId];
}

/// Event to remove an existing friend
class RemoveFriend extends SocialEvent {
  final String friendUserId;
  const RemoveFriend({required this.friendUserId});
  @override List<Object?> get props => [friendUserId];
}
