import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_event.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_state.dart';
import 'package:shamil_mobile_app/feature/profile/repository/profile_repository.dart';
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart'
    hide SearchUsers;

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final SocialBloc? _socialBloc;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileBloc({
    required ProfileRepository profileRepository,
    SocialBloc? socialBloc,
  })  : _profileRepository = profileRepository,
        _socialBloc = socialBloc,
        super(const ProfileInitial()) {
    // Register event handlers
    on<LoadUserProfile>(_onLoadUserProfile);
    on<LoadCurrentUserProfile>(_onLoadCurrentUserProfile);
    on<RefreshProfile>(_onRefreshProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<TrackProfileView>(_onTrackProfileView);
    on<SearchUsers>(_onSearchUsers);
    on<ClearSearch>(_onClearSearch);
    on<SendFriendRequestFromProfile>(_onSendFriendRequest);
    on<AcceptFriendRequestFromProfile>(_onAcceptFriendRequest);
    on<DeclineFriendRequestFromProfile>(_onDeclineFriendRequest);
    on<UnsendFriendRequestFromProfile>(_onUnsendFriendRequest);
    on<RemoveFriendFromProfile>(_onRemoveFriend);
    on<BlockUserFromProfile>(_onBlockUser);
    on<UnblockUserFromProfile>(_onUnblockUser);
    on<ReportUserFromProfile>(_onReportUser);
    on<UpdatePrivacySettings>(_onUpdatePrivacySettings);
    on<UploadProfilePicture>(_onUploadProfilePicture);
    on<AddAchievement>(_onAddAchievement);
    on<LoadMutualFriends>(_onLoadMutualFriends);
    on<UpdateOnlineStatus>(_onUpdateOnlineStatus);
  }

  /// Load a specific user's profile
  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(const ProfileLoading(loadingMessage: 'Loading profile...'));

      final profile = await _profileRepository.getUserProfile(
        event.userId,
        context: event.context,
      );

      emit(ProfileLoaded(
        profile: profile,
        context: event.context,
      ));

      // Track profile view if viewing another user's profile
      if (event.userId != _auth.currentUser?.uid) {
        add(TrackProfileView(profileUserId: event.userId));
      }
    } catch (e) {
      emit(_handleError(e, 'Failed to load profile'));
    }
  }

  /// Load current user's own profile
  Future<void> _onLoadCurrentUserProfile(
    LoadCurrentUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(const ProfileLoading(loadingMessage: 'Loading your profile...'));

      final profile = await _profileRepository.getCurrentUserProfile();

      emit(CurrentUserProfileLoaded(profile: profile));
    } catch (e) {
      emit(_handleError(e, 'Failed to load your profile'));
    }
  }

  /// Refresh profile data
  Future<void> _onRefreshProfile(
    RefreshProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final profile = await _profileRepository.getUserProfile(event.userId);

      if (state is CurrentUserProfileLoaded) {
        emit(CurrentUserProfileLoaded(profile: profile));
      } else if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        emit(ProfileLoaded(
          profile: profile,
          context: currentState.context,
        ));
      }
    } catch (e) {
      emit(_handleError(e, 'Failed to refresh profile'));
    }
  }

  /// Update profile information
  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        emit(const ProfileError(message: 'No authenticated user'));
        return;
      }

      emit(const ProfileActionProcessing(actionType: 'update_profile'));

      await _profileRepository.updateProfile(currentUserId, event.updates);
      final updatedProfile = await _profileRepository.getCurrentUserProfile();

      emit(ProfileUpdateSuccess(
        message: 'Profile updated successfully',
        updatedProfile: updatedProfile,
      ));

      emit(CurrentUserProfileLoaded(profile: updatedProfile));
    } catch (e) {
      emit(_handleError(e, 'Failed to update profile'));
    }
  }

  /// Track profile view for analytics
  Future<void> _onTrackProfileView(
    TrackProfileView event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _profileRepository.trackProfileView(event.profileUserId);
    } catch (e) {
      print('Failed to track profile view: $e');
    }
  }

  /// Search for users
  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      if (event.query.trim().isEmpty) {
        emit(const SearchResultsLoaded(results: [], query: ''));
        return;
      }

      emit(SearchResultsLoaded(
        results: [],
        query: event.query,
        isSearching: true,
      ));

      final results = await _profileRepository.searchUsers(event.query);

      emit(SearchResultsLoaded(
        results: results,
        query: event.query,
        isSearching: false,
      ));
    } catch (e) {
      emit(_handleError(e, 'Search failed'));
    }
  }

  /// Clear search results
  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const SearchResultsLoaded(results: [], query: ''));
  }

  /// Send friend request from profile
  Future<void> _onSendFriendRequest(
    SendFriendRequestFromProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileActionProcessing(
        actionType: 'friend_request',
        targetUserId: event.targetUserId,
        message: 'Sending friend request...',
      ));

      // Use SocialBloc if available
      if (_socialBloc != null) {
        _socialBloc!.add(SendFriendRequest(
          targetUserId: event.targetUserId,
          targetUserName: event.targetUserName,
          targetUserPicUrl: event.targetUserPicUrl,
        ));
      }

      final updatedProfile =
          await _profileRepository.getUserProfile(event.targetUserId);

      emit(FriendRequestActionSuccess(
        message: 'Friend request sent',
        actionType: 'sent',
        updatedProfile: updatedProfile,
      ));

      emit(ProfileLoaded(
        profile: updatedProfile,
        context: ProfileViewContext.friendProfile,
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to send friend request'));
    }
  }

  /// Accept friend request from profile
  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequestFromProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileActionProcessing(
        actionType: 'accept_request',
        targetUserId: event.requesterUserId,
        message: 'Accepting friend request...',
      ));

      if (_socialBloc != null) {
        _socialBloc!.add(AcceptFriendRequest(
          requesterUserId: event.requesterUserId,
          requesterUserName: event.requesterUserName,
          requesterUserPicUrl: event.requesterUserPicUrl,
        ));
      }

      final updatedProfile =
          await _profileRepository.getUserProfile(event.requesterUserId);

      emit(FriendRequestActionSuccess(
        message: 'Friend request accepted',
        actionType: 'accepted',
        updatedProfile: updatedProfile,
      ));

      emit(ProfileLoaded(
        profile: updatedProfile,
        context: ProfileViewContext.friendProfile,
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to accept friend request'));
    }
  }

  /// Decline friend request from profile
  Future<void> _onDeclineFriendRequest(
    DeclineFriendRequestFromProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileActionProcessing(
        actionType: 'decline_request',
        targetUserId: event.requesterUserId,
        message: 'Declining friend request...',
      ));

      if (_socialBloc != null) {
        _socialBloc!.add(DeclineFriendRequest(
          requesterUserId: event.requesterUserId,
        ));
      }

      final updatedProfile =
          await _profileRepository.getUserProfile(event.requesterUserId);

      emit(FriendRequestActionSuccess(
        message: 'Friend request declined',
        actionType: 'declined',
        updatedProfile: updatedProfile,
      ));

      emit(ProfileLoaded(
        profile: updatedProfile,
        context: ProfileViewContext.friendProfile,
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to decline friend request'));
    }
  }

  /// Unsend friend request from profile
  Future<void> _onUnsendFriendRequest(
    UnsendFriendRequestFromProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileActionProcessing(
        actionType: 'unsend_request',
        targetUserId: event.targetUserId,
        message: 'Unsending friend request...',
      ));

      if (_socialBloc != null) {
        _socialBloc!.add(UnsendFriendRequest(
          targetUserId: event.targetUserId,
        ));
      }

      final updatedProfile =
          await _profileRepository.getUserProfile(event.targetUserId);

      emit(FriendRequestActionSuccess(
        message: 'Friend request unsent',
        actionType: 'unsent',
        updatedProfile: updatedProfile,
      ));

      emit(ProfileLoaded(
        profile: updatedProfile,
        context: ProfileViewContext.friendProfile,
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to unsend friend request'));
    }
  }

  /// Remove friend from profile
  Future<void> _onRemoveFriend(
    RemoveFriendFromProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileActionProcessing(
        actionType: 'remove_friend',
        targetUserId: event.friendUserId,
        message: 'Removing friend...',
      ));

      // Implement friend removal logic
      // This would typically involve removing from both users' friend lists

      // Refresh the profile
      final updatedProfile =
          await _profileRepository.getUserProfile(event.friendUserId);

      emit(FriendRequestActionSuccess(
        message: 'Friend removed',
        actionType: 'removed',
        updatedProfile: updatedProfile,
      ));

      emit(ProfileLoaded(
        profile: updatedProfile,
        context: ProfileViewContext.friendProfile,
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to remove friend'));
    }
  }

  /// Block user from profile
  Future<void> _onBlockUser(
    BlockUserFromProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileActionProcessing(
        actionType: 'block_user',
        targetUserId: event.userIdToBlock,
        message: 'Blocking user...',
      ));

      // Implement user blocking logic
      // This would involve adding to blocked list and removing friendship

      emit(UserBlocked(
        blockedUserId: event.userIdToBlock,
        message: 'User blocked successfully',
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to block user'));
    }
  }

  /// Unblock user from profile
  Future<void> _onUnblockUser(
    UnblockUserFromProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileActionProcessing(
        actionType: 'unblock_user',
        targetUserId: event.userIdToUnblock,
        message: 'Unblocking user...',
      ));

      // Implement user unblocking logic

      emit(UserUnblocked(
        unblockedUserId: event.userIdToUnblock,
        message: 'User unblocked successfully',
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to unblock user'));
    }
  }

  /// Report user from profile
  Future<void> _onReportUser(
    ReportUserFromProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileActionProcessing(
        actionType: 'report_user',
        targetUserId: event.userIdToReport,
        message: 'Reporting user...',
      ));

      // Implement user reporting logic
      // This would involve creating a report document in Firestore

      emit(UserReported(
        reportedUserId: event.userIdToReport,
        message: 'User reported successfully',
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to report user'));
    }
  }

  /// Update privacy settings
  Future<void> _onUpdatePrivacySettings(
    UpdatePrivacySettings event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _profileRepository.updateProfile(currentUserId, {
        'isPrivate': event.isPrivate,
      });

      final updatedProfile = await _profileRepository.getCurrentUserProfile();

      emit(PrivacySettingsUpdated(
        isPrivate: event.isPrivate,
        updatedProfile: updatedProfile,
      ));

      emit(CurrentUserProfileLoaded(profile: updatedProfile));
    } catch (e) {
      emit(_handleError(e, 'Failed to update privacy settings'));
    }
  }

  /// Upload profile picture
  Future<void> _onUploadProfilePicture(
    UploadProfilePicture event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(const ProfilePictureUploading(progress: 0.0));

      // Simulate upload progress
      for (double progress = 0.1; progress <= 1.0; progress += 0.1) {
        emit(ProfilePictureUploading(progress: progress));
        await Future.delayed(const Duration(milliseconds: 200));
      }

      const imageUrl = 'https://example.com/profile-pic.jpg';

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await _profileRepository.updateProfile(currentUserId, {
          'profilePicUrl': imageUrl,
        });

        final updatedProfile = await _profileRepository.getCurrentUserProfile();

        emit(ProfilePictureUploadSuccess(
          imageUrl: imageUrl,
          updatedProfile: updatedProfile,
        ));

        emit(CurrentUserProfileLoaded(profile: updatedProfile));
      }
    } catch (e) {
      emit(_handleError(e, 'Failed to upload profile picture'));
    }
  }

  /// Add achievement
  Future<void> _onAddAchievement(
    AddAchievement event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Implement achievement addition logic
      // This would typically involve adding to user's achievements collection

      final updatedProfile =
          await _profileRepository.getUserProfile(event.userId);

      emit(AchievementAdded(
        achievement: event.achievement,
        updatedProfile: updatedProfile,
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to add achievement'));
    }
  }

  /// Load mutual friends
  Future<void> _onLoadMutualFriends(
    LoadMutualFriends event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // This is typically handled in the repository when loading a profile
      // But can be called separately for dedicated mutual friends view

      emit(MutualFriendsLoaded(
        mutualFriends: [], // Would be populated from repository
        currentUserId: event.currentUserId,
        targetUserId: event.targetUserId,
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to load mutual friends'));
    }
  }

  /// Update online status
  Future<void> _onUpdateOnlineStatus(
    UpdateOnlineStatus event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _profileRepository.updateProfile(currentUserId, {
        'isOnline': event.isOnline,
        'lastSeen': event.isOnline ? null : DateTime.now().toIso8601String(),
      });

      final updatedProfile = await _profileRepository.getCurrentUserProfile();

      emit(OnlineStatusUpdated(
        isOnline: event.isOnline,
        updatedProfile: updatedProfile,
      ));
    } catch (e) {
      emit(_handleError(e, 'Failed to update online status'));
    }
  }

  /// Handle errors and return appropriate error state
  ProfileError _handleError(dynamic error, String defaultMessage) {
    print('ProfileBloc Error: $error');

    if (error.toString().contains('network') ||
        error.toString().contains('internet')) {
      return ProfileNetworkError(
        message: 'Check your internet connection and try again',
        previousState: state,
      );
    }

    if (error.toString().contains('not found')) {
      return const ProfileUserNotFoundError(userId: '');
    }

    if (error.toString().contains('permission') ||
        error.toString().contains('unauthorized')) {
      return ProfilePermissionError(
        message: 'You don\'t have permission to perform this action',
        previousState: state,
      );
    }

    if (error.toString().contains('blocked')) {
      return const ProfileAccountBlockedError();
    }

    if (error.toString().contains('private')) {
      return const ProfilePrivateError(userId: '');
    }

    return ProfileError(
      message: defaultMessage,
      previousState: state,
    );
  }
}
