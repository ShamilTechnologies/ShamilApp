import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading states
class ProfileLoading extends ProfileState {
  final String? loadingMessage;
  final bool showSpinner;

  const ProfileLoading({
    this.loadingMessage,
    this.showSpinner = true,
  });

  @override
  List<Object?> get props => [loadingMessage, showSpinner];
}

/// Profile successfully loaded
class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final ProfileViewContext context;
  final bool isRefreshing;

  const ProfileLoaded({
    required this.profile,
    required this.context,
    this.isRefreshing = false,
  });

  ProfileLoaded copyWith({
    UserProfile? profile,
    ProfileViewContext? context,
    bool? isRefreshing,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      context: context ?? this.context,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [profile, context, isRefreshing];
}

/// Current user's profile loaded
class CurrentUserProfileLoaded extends ProfileState {
  final UserProfile profile;
  final bool isRefreshing;

  const CurrentUserProfileLoaded({
    required this.profile,
    this.isRefreshing = false,
  });

  CurrentUserProfileLoaded copyWith({
    UserProfile? profile,
    bool? isRefreshing,
  }) {
    return CurrentUserProfileLoaded(
      profile: profile ?? this.profile,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [profile, isRefreshing];
}

/// Search results loaded
class SearchResultsLoaded extends ProfileState {
  final List<UserProfile> results;
  final String query;
  final bool isSearching;

  const SearchResultsLoaded({
    required this.results,
    required this.query,
    this.isSearching = false,
  });

  SearchResultsLoaded copyWith({
    List<UserProfile>? results,
    String? query,
    bool? isSearching,
  }) {
    return SearchResultsLoaded(
      results: results ?? this.results,
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [results, query, isSearching];
}

/// Mutual friends loaded
class MutualFriendsLoaded extends ProfileState {
  final List<MutualFriend> mutualFriends;
  final String currentUserId;
  final String targetUserId;

  const MutualFriendsLoaded({
    required this.mutualFriends,
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  List<Object?> get props => [mutualFriends, currentUserId, targetUserId];
}

/// Profile update success
class ProfileUpdateSuccess extends ProfileState {
  final String message;
  final UserProfile updatedProfile;

  const ProfileUpdateSuccess({
    required this.message,
    required this.updatedProfile,
  });

  @override
  List<Object?> get props => [message, updatedProfile];
}

/// Friend request action success
class FriendRequestActionSuccess extends ProfileState {
  final String message;
  final String
      actionType; // 'sent', 'accepted', 'declined', 'unsent', 'removed'
  final UserProfile updatedProfile;

  const FriendRequestActionSuccess({
    required this.message,
    required this.actionType,
    required this.updatedProfile,
  });

  @override
  List<Object?> get props => [message, actionType, updatedProfile];
}

/// Profile picture upload progress
class ProfilePictureUploading extends ProfileState {
  final double progress; // 0.0 to 1.0

  const ProfilePictureUploading({required this.progress});

  @override
  List<Object?> get props => [progress];
}

/// Profile picture upload success
class ProfilePictureUploadSuccess extends ProfileState {
  final String imageUrl;
  final UserProfile updatedProfile;

  const ProfilePictureUploadSuccess({
    required this.imageUrl,
    required this.updatedProfile,
  });

  @override
  List<Object?> get props => [imageUrl, updatedProfile];
}

/// Achievement added
class AchievementAdded extends ProfileState {
  final Achievement achievement;
  final UserProfile updatedProfile;

  const AchievementAdded({
    required this.achievement,
    required this.updatedProfile,
  });

  @override
  List<Object?> get props => [achievement, updatedProfile];
}

/// Privacy settings updated
class PrivacySettingsUpdated extends ProfileState {
  final bool isPrivate;
  final UserProfile updatedProfile;

  const PrivacySettingsUpdated({
    required this.isPrivate,
    required this.updatedProfile,
  });

  @override
  List<Object?> get props => [isPrivate, updatedProfile];
}

/// Online status updated
class OnlineStatusUpdated extends ProfileState {
  final bool isOnline;
  final UserProfile updatedProfile;

  const OnlineStatusUpdated({
    required this.isOnline,
    required this.updatedProfile,
  });

  @override
  List<Object?> get props => [isOnline, updatedProfile];
}

/// User blocked successfully
class UserBlocked extends ProfileState {
  final String blockedUserId;
  final String message;

  const UserBlocked({
    required this.blockedUserId,
    required this.message,
  });

  @override
  List<Object?> get props => [blockedUserId, message];
}

/// User unblocked successfully
class UserUnblocked extends ProfileState {
  final String unblockedUserId;
  final String message;

  const UserUnblocked({
    required this.unblockedUserId,
    required this.message,
  });

  @override
  List<Object?> get props => [unblockedUserId, message];
}

/// User reported successfully
class UserReported extends ProfileState {
  final String reportedUserId;
  final String message;

  const UserReported({
    required this.reportedUserId,
    required this.message,
  });

  @override
  List<Object?> get props => [reportedUserId, message];
}

/// Profile view tracked
class ProfileViewTracked extends ProfileState {
  final String profileUserId;

  const ProfileViewTracked({required this.profileUserId});

  @override
  List<Object?> get props => [profileUserId];
}

/// Processing action (for specific user interactions)
class ProfileActionProcessing extends ProfileState {
  final String actionType; // 'friend_request', 'block', 'report', etc.
  final String? targetUserId;
  final String? message;

  const ProfileActionProcessing({
    required this.actionType,
    this.targetUserId,
    this.message,
  });

  @override
  List<Object?> get props => [actionType, targetUserId, message];
}

/// Error states
class ProfileError extends ProfileState {
  final String message;
  final String? errorCode;
  final ProfileState? previousState;

  const ProfileError({
    required this.message,
    this.errorCode,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, errorCode, previousState];
}

/// Network error
class ProfileNetworkError extends ProfileError {
  const ProfileNetworkError({
    required String message,
    ProfileState? previousState,
  }) : super(
          message: message,
          errorCode: 'NETWORK_ERROR',
          previousState: previousState,
        );
}

/// Permission error
class ProfilePermissionError extends ProfileError {
  const ProfilePermissionError({
    required String message,
    ProfileState? previousState,
  }) : super(
          message: message,
          errorCode: 'PERMISSION_ERROR',
          previousState: previousState,
        );
}

/// User not found error
class ProfileUserNotFoundError extends ProfileError {
  final String userId;

  const ProfileUserNotFoundError({
    required this.userId,
    ProfileState? previousState,
  }) : super(
          message: 'User not found',
          errorCode: 'USER_NOT_FOUND',
          previousState: previousState,
        );

  @override
  List<Object?> get props => [userId, message, errorCode, previousState];
}

/// Account blocked error
class ProfileAccountBlockedError extends ProfileError {
  const ProfileAccountBlockedError({
    ProfileState? previousState,
  }) : super(
          message: 'This account has been blocked',
          errorCode: 'ACCOUNT_BLOCKED',
          previousState: previousState,
        );
}

/// Private profile error
class ProfilePrivateError extends ProfileError {
  final String userId;

  const ProfilePrivateError({
    required this.userId,
    ProfileState? previousState,
  }) : super(
          message: 'This profile is private',
          errorCode: 'PRIVATE_PROFILE',
          previousState: previousState,
        );

  @override
  List<Object?> get props => [userId, message, errorCode, previousState];
}
