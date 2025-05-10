// lib/feature/social/bloc/social_event.dart
part of 'social_bloc.dart';

abstract class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => [];
}

// --- Family Events ---
class LoadFamilyMembers extends SocialEvent {
  const LoadFamilyMembers();
}

class AddFamilyMember extends SocialEvent {
  final Map<String, dynamic> memberData;
  final AuthModel? linkedUserModel;

  const AddFamilyMember({required this.memberData, this.linkedUserModel});

  @override
  List<Object?> get props => [memberData, linkedUserModel];
}

class RemoveFamilyMember extends SocialEvent {
  final String memberDocId;
  const RemoveFamilyMember({required this.memberDocId});
  @override
  List<Object?> get props => [memberDocId];
}

class SearchUserByNationalId extends SocialEvent {
  final String nationalId;
  const SearchUserByNationalId({required this.nationalId});
  @override
  List<Object?> get props => [nationalId];
}

class AcceptFamilyRequest extends SocialEvent {
  final String requesterUserId;
  final String requesterName;
  final String? requesterProfilePicUrl;
  final String requesterRelationship;

  const AcceptFamilyRequest({
    required this.requesterUserId,
    required this.requesterName,
    this.requesterProfilePicUrl,
    required this.requesterRelationship,
  });
  @override
  List<Object?> get props => [
        requesterUserId,
        requesterName,
        requesterProfilePicUrl,
        requesterRelationship
      ];
}

class DeclineFamilyRequest extends SocialEvent {
  final String requesterUserId;
  const DeclineFamilyRequest({required this.requesterUserId});
  @override
  List<Object?> get props => [requesterUserId];
}

// --- Friend Events ---
class LoadFriendsAndRequests extends SocialEvent {
  const LoadFriendsAndRequests();
}

class SearchUsers extends SocialEvent {
  final String query;
  const SearchUsers({required this.query});
  @override
  List<Object?> get props => [query];
}

class SendFriendRequest extends SocialEvent {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserPicUrl;

  const SendFriendRequest(
      {required this.targetUserId,
      required this.targetUserName,
      this.targetUserPicUrl});
  @override
  List<Object?> get props => [targetUserId, targetUserName, targetUserPicUrl];
}

class AcceptFriendRequest extends SocialEvent {
  final String requesterUserId;
  final String requesterUserName;
  final String? requesterUserPicUrl;

  const AcceptFriendRequest(
      {required this.requesterUserId,
      required this.requesterUserName,
      this.requesterUserPicUrl});
  @override
  List<Object?> get props =>
      [requesterUserId, requesterUserName, requesterUserPicUrl];
}

class DeclineFriendRequest extends SocialEvent {
  final String requesterUserId;
  const DeclineFriendRequest({required this.requesterUserId});
  @override
  List<Object?> get props => [requesterUserId];
}

class RemoveFriend extends SocialEvent {
  final String friendUserId;
  const RemoveFriend({required this.friendUserId});
  @override
  List<Object?> get props => [friendUserId];
}

class UnsendFriendRequest extends SocialEvent {
  final String targetUserId;
  const UnsendFriendRequest({required this.targetUserId});
  @override
  List<Object?> get props => [targetUserId];
}

class RefreshSocialSection extends SocialEvent {
  final SocialSection section;
  const RefreshSocialSection(this.section);
  @override
  List<Object> get props => [section];
}

enum SocialSection { family, friends }
