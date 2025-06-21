import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load profile for a specific user
class LoadUserProfile extends ProfileEvent {
  final String userId;
  final ProfileViewContext context;

  const LoadUserProfile({
    required this.userId,
    this.context = ProfileViewContext.friendProfile,
  });

  @override
  List<Object?> get props => [userId, context];
}

/// Load current user's own profile
class LoadCurrentUserProfile extends ProfileEvent {
  const LoadCurrentUserProfile();
}

/// Refresh profile data
class RefreshProfile extends ProfileEvent {
  final String userId;

  const RefreshProfile({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Update profile information
class UpdateProfile extends ProfileEvent {
  final Map<String, dynamic> updates;

  const UpdateProfile({required this.updates});

  @override
  List<Object?> get props => [updates];
}

/// Track profile view (analytics)
class TrackProfileView extends ProfileEvent {
  final String profileUserId;

  const TrackProfileView({required this.profileUserId});

  @override
  List<Object?> get props => [profileUserId];
}

/// Search for users
class SearchUsers extends ProfileEvent {
  final String query;

  const SearchUsers({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Clear search results
class ClearSearch extends ProfileEvent {
  const ClearSearch();
}

/// Send friend request from profile
class SendFriendRequestFromProfile extends ProfileEvent {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserPicUrl;

  const SendFriendRequestFromProfile({
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserPicUrl,
  });

  @override
  List<Object?> get props => [targetUserId, targetUserName, targetUserPicUrl];
}

/// Accept friend request from profile
class AcceptFriendRequestFromProfile extends ProfileEvent {
  final String requesterUserId;
  final String requesterUserName;
  final String? requesterUserPicUrl;

  const AcceptFriendRequestFromProfile({
    required this.requesterUserId,
    required this.requesterUserName,
    this.requesterUserPicUrl,
  });

  @override
  List<Object?> get props =>
      [requesterUserId, requesterUserName, requesterUserPicUrl];
}

/// Decline friend request from profile
class DeclineFriendRequestFromProfile extends ProfileEvent {
  final String requesterUserId;

  const DeclineFriendRequestFromProfile({required this.requesterUserId});

  @override
  List<Object?> get props => [requesterUserId];
}

/// Unsend friend request from profile
class UnsendFriendRequestFromProfile extends ProfileEvent {
  final String targetUserId;

  const UnsendFriendRequestFromProfile({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}

/// Remove friend from profile
class RemoveFriendFromProfile extends ProfileEvent {
  final String friendUserId;

  const RemoveFriendFromProfile({required this.friendUserId});

  @override
  List<Object?> get props => [friendUserId];
}

/// Block user from profile
class BlockUserFromProfile extends ProfileEvent {
  final String userIdToBlock;

  const BlockUserFromProfile({required this.userIdToBlock});

  @override
  List<Object?> get props => [userIdToBlock];
}

/// Unblock user from profile
class UnblockUserFromProfile extends ProfileEvent {
  final String userIdToUnblock;

  const UnblockUserFromProfile({required this.userIdToUnblock});

  @override
  List<Object?> get props => [userIdToUnblock];
}

/// Report user from profile
class ReportUserFromProfile extends ProfileEvent {
  final String userIdToReport;
  final String reason;
  final String? additionalDetails;

  const ReportUserFromProfile({
    required this.userIdToReport,
    required this.reason,
    this.additionalDetails,
  });

  @override
  List<Object?> get props => [userIdToReport, reason, additionalDetails];
}

/// Update profile privacy settings
class UpdatePrivacySettings extends ProfileEvent {
  final bool isPrivate;

  const UpdatePrivacySettings({required this.isPrivate});

  @override
  List<Object?> get props => [isPrivate];
}

/// Upload profile picture
class UploadProfilePicture extends ProfileEvent {
  final String imagePath;

  const UploadProfilePicture({required this.imagePath});

  @override
  List<Object?> get props => [imagePath];
}

/// Add achievement
class AddAchievement extends ProfileEvent {
  final String userId;
  final Achievement achievement;

  const AddAchievement({
    required this.userId,
    required this.achievement,
  });

  @override
  List<Object?> get props => [userId, achievement];
}

/// Load mutual friends
class LoadMutualFriends extends ProfileEvent {
  final String currentUserId;
  final String targetUserId;

  const LoadMutualFriends({
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  List<Object?> get props => [currentUserId, targetUserId];
}

/// Update online status
class UpdateOnlineStatus extends ProfileEvent {
  final bool isOnline;

  const UpdateOnlineStatus({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}
