// lib/feature/social/bloc/social_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/social/data/suggestion_models.dart';
import 'package:shamil_mobile_app/feature/social/services/suggestion_engine.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/feature/profile/repository/profile_repository.dart';
import 'package:shamil_mobile_app/feature/profile/data/profile_models.dart'
    as profile_models;
import 'dart:async';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';

part 'social_event.dart';
part 'social_state.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final FirebaseDataOrchestrator _dataOrchestrator;
  final ProfileRepository _profileRepository;
  final SuggestionEngine _suggestionEngine = SuggestionEngine();
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  SocialBloc({
    required FirebaseDataOrchestrator dataOrchestrator,
    required ProfileRepository profileRepository,
  })  : _dataOrchestrator = dataOrchestrator,
        _profileRepository = profileRepository,
        super(SocialInitial()) {
    on<LoadFamilyMembers>(_onLoadFamilyMembers);
    on<AddFamilyMember>(_onAddFamilyMember);
    on<RemoveFamilyMember>(_onRemoveFamilyMember);
    on<SearchUserByNationalId>(_onSearchUserByNationalId);
    on<AcceptFamilyRequest>(_onAcceptFamilyRequest);
    on<DeclineFamilyRequest>(_onDeclineFamilyRequest);

    on<LoadFriendsAndRequests>(_onLoadFriendsAndRequests);
    on<SearchUsers>(_onSearchUsers);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<DeclineFriendRequest>(_onDeclineFriendRequest);
    on<RemoveFriend>(_onRemoveFriend);
    on<UnsendFriendRequest>(_onUnsendFriendRequest);
    on<RefreshSocialSection>(_onRefreshSocialSection);

    // Suggestion event handlers
    on<LoadSuggestions>(_onLoadSuggestions);
    on<RefreshSuggestions>(_onRefreshSuggestions);
    on<InteractWithSuggestion>(_onInteractWithSuggestion);
    on<DismissSuggestion>(_onDismissSuggestion);

    // Debug event handler
    on<TestFirebaseAuth>(_onTestFirebaseAuth);
  }

  Future<void> _onTestFirebaseAuth(
      TestFirebaseAuth event, Emitter<SocialState> emit) async {
    emit(const SocialLoading(isLoadingList: false));

    try {
      final result = await _dataOrchestrator.testFirebaseFunctionsAuth();

      // Show detailed test results
      final results = result['results'] as Map<String, dynamic>?;
      String detailedMessage = result['message'] ?? 'Test completed';

      if (results != null) {
        detailedMessage += '\n\nDetailed Results:';
        results.forEach((test, result) {
          final status = result.toString().contains('SUCCESS') ? '✅' : '❌';
          detailedMessage += '\n$status $test: $result';
        });
      }

      if (result['success'] == true) {
        // Check if any of the specific tests passed
        bool anyTestPassed = false;
        if (results != null) {
          anyTestPassed = results.values
              .any((result) => result.toString().contains('SUCCESS'));
        }

        if (anyTestPassed) {
          emit(SocialSuccess(message: detailedMessage));
        } else {
          emit(SocialError(message: 'All tests failed:\n$detailedMessage'));
        }
      } else {
        emit(SocialError(message: result['error'] ?? 'Test failed'));
      }
    } catch (e) {
      emit(SocialError(message: 'Test error: $e'));
    }
  }

  Future<AuthModel?> _getCurrentAuthModel() async {
    return await _dataOrchestrator.getCurrentUserProfile();
  }

  Future<void> _onRefreshSocialSection(
      RefreshSocialSection event, Emitter<SocialState> emit) async {
    if (event.section == SocialSection.family) {
      add(const LoadFamilyMembers());
    } else if (event.section == SocialSection.friends) {
      add(const LoadFriendsAndRequests());
    }
  }

  Future<void> _onLoadFamilyMembers(
      LoadFamilyMembers event, Emitter<SocialState> emit) async {
    if (_currentUserId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    if (state is! FamilyDataLoaded) {
      // Avoid full loading if data already present, allow refresh
      emit(const SocialLoading(isLoadingList: true));
    }
    try {
      // Note: Family members functionality needs to be implemented in the orchestrator
      // For now, emit empty data
      emit(const FamilyDataLoaded(familyMembers: [], incomingRequests: []));
    } catch (e) {
      emit(SocialError(message: "Failed to load family data: ${e.toString()}"));
    }
  }

  Future<void> _onLoadFriendsAndRequests(
      LoadFriendsAndRequests event, Emitter<SocialState> emit) async {
    if (_currentUserId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    if (state is! FriendsAndRequestsLoaded) {
      // Avoid full loading if data already present
      emit(const SocialLoading(isLoadingList: true));
    }
    try {
      // Use the data orchestrator's friends stream
      final friends = await _dataOrchestrator.getFriendsStream().first;
      // Note: Friend requests functionality needs to be implemented in the orchestrator
      // For now, emit with empty requests
      emit(FriendsAndRequestsLoaded(
          friends: friends
              .map((friend) => Friend(
                    userId: friend.uid ?? '',
                    name: friend.name ?? '',
                    profilePicUrl: friend.profilePicUrl,
                  ))
              .toList(),
          incomingRequests: [],
          outgoingRequests: []));
    } catch (e) {
      emit(SocialError(
          message: "Failed to load friends and requests: ${e.toString()}"));
    }
  }

  Future<void> _onSearchUserByNationalId(
      SearchUserByNationalId event, Emitter<SocialState> emit) async {
    if (_currentUserId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(const SocialLoading(isLoadingList: false));
    try {
      // Note: Search by national ID functionality needs to be implemented in the orchestrator
      emit(UserNationalIdSearchResult(
          foundUser: null, searchedNationalId: event.nationalId));
    } catch (e) {
      emit(SocialError(
          message: "Error searching by National ID: ${e.toString()}"));
      // Ensure to emit the search result state even on error to clear loading
      emit(UserNationalIdSearchResult(
          foundUser: null, searchedNationalId: event.nationalId));
    }
  }

  Future<void> _onSearchUsers(
      SearchUsers event, Emitter<SocialState> emit) async {
    if (_currentUserId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    if (event.query.trim().isEmpty) {
      emit(FriendSearchResultsLoaded(results: const [], query: event.query));
      return;
    }
    emit(const SocialLoading(isLoadingList: false)); // Not a full list load
    try {
      // Use ProfileRepository for search
      final profiles = await _profileRepository.searchUsers(event.query.trim());

      // Convert UserProfile list to UserSearchResultWithStatus
      final results = <UserSearchResultWithStatus>[];

      for (final profile in profiles) {
        // Convert UserProfile to AuthModel for compatibility
        final authModel = AuthModel(
          uid: profile.uid,
          name: profile.name,
          username: profile.username,
          email: profile.email,
          profilePicUrl: profile.profilePicUrl,
          phone: profile.phone,
          gender: profile.gender,
          dob: profile.dateOfBirth?.toIso8601String(),
          isVerified: profile.isVerified,
          isBlocked: profile.isBlocked,
          createdAt: Timestamp.fromDate(profile.createdAt),
          lastSeen: profile.lastSeen != null
              ? Timestamp.fromDate(profile.lastSeen!)
              : null,
        );

        // Determine friendship status (convert from profile to social enum)
        FriendshipStatus status = FriendshipStatus.none;
        if (profile.friendshipStatus != null) {
          switch (profile.friendshipStatus!) {
            case profile_models.FriendshipStatus.friends:
              status = FriendshipStatus.friends;
              break;
            case profile_models.FriendshipStatus.requestSent:
              status = FriendshipStatus.requestSent;
              break;
            case profile_models.FriendshipStatus.requestReceived:
              status = FriendshipStatus.requestReceived;
              break;
            case profile_models.FriendshipStatus.blocked:
              // Social enum doesn't have blocked, treat as none
              status = FriendshipStatus.none;
              break;
            default:
              status = FriendshipStatus.none;
          }
        }

        results.add(UserSearchResultWithStatus(
          user: authModel,
          status: status,
        ));
      }

      emit(FriendSearchResultsLoaded(
          results: results, query: event.query.trim()));
    } catch (e) {
      emit(SocialError(message: "Failed to search users: ${e.toString()}"));
      emit(FriendSearchResultsLoaded(
          results: const [], query: event.query.trim()));
    }
  }

  Future<void> _handleRepositoryCall(
    Future<Map<String, dynamic>> Function(AuthModel currentUserData)
        repositoryCallWithUser, // Pass current user data
    Emitter<SocialState> emit, {
    String? processingId,
    SocialSection? sectionToRefresh,
    String? successMessageOverride,
  }) async {
    emit(SocialLoading(processingUserId: processingId, isLoadingList: false));
    try {
      final AuthModel? currentUserModel = await _getCurrentAuthModel();
      if (_currentUserId == null || currentUserModel == null) {
        emit(const SocialError(
            message: "User not authenticated or details missing."));
        // Refresh section even on auth error to clear processing state
        if (sectionToRefresh != null) {
          add(RefreshSocialSection(sectionToRefresh));
        }
        return;
      }

      final result = await repositoryCallWithUser(
          currentUserModel); // Execute call with current user data

      if (result['success'] == true) {
        String successMessage = successMessageOverride ??
            result['message'] as String? ??
            "Operation successful.";

        // Handle specific success types
        final type = result['type'] as String?;
        if (type == 'friend_request_sent') {
          final targetUser = result['targetUser'] as String?;
          if (targetUser != null) {
            successMessage = "Friend request sent to $targetUser! 🎉";
          }
        }

        emit(SocialSuccess(message: successMessage));
        if (sectionToRefresh != null) {
          add(RefreshSocialSection(sectionToRefresh));
        }
      } else {
        // Handle specific error types with appropriate messages
        final errorType = result['errorType'] as String?;
        final userMessage = result['message'] as String?;
        String errorMessage;

        switch (errorType) {
          case 'already_friends':
            errorMessage =
                userMessage ?? "You are already friends with this user! 👥";
            break;
          case 'already_requested':
            errorMessage = userMessage ?? "Friend request already sent! ⏳";
            break;
          case 'incoming_request':
            errorMessage = userMessage ??
                "This user has already sent you a friend request! Check your requests 📥";
            break;
          case 'firestore_error':
            errorMessage =
                userMessage ?? "Something went wrong. Please try again. ⚠️";
            break;
          default:
            errorMessage = userMessage ??
                result['error'] as String? ??
                "An unknown error occurred.";
        }

        emit(SocialError(message: errorMessage));
        if (sectionToRefresh != null) {
          add(RefreshSocialSection(sectionToRefresh));
        }
      }
    } catch (e) {
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
      if (sectionToRefresh != null) {
        add(RefreshSocialSection(sectionToRefresh));
      }
    }
  }

  Future<void> _onAddFamilyMember(
      AddFamilyMember event, Emitter<SocialState> emit) async {
    await _handleRepositoryCall(
      (currentUserData) => _dataOrchestrator.addOrRequestFamilyMember(
        currentUserId: _currentUserId!,
        currentUserData: currentUserData,
        memberData: event.memberData,
        linkedUserModel: event.linkedUserModel,
      ),
      emit,
      sectionToRefresh: SocialSection.family,
    );
  }

  Future<void> _onRemoveFamilyMember(
      RemoveFamilyMember event, Emitter<SocialState> emit) async {
    // For remove, we don't necessarily need full currentUserData for the repo call itself,
    // but _handleRepositoryCall expects it. We can simplify if not needed by the repo.
    await _handleRepositoryCall(
      (currentUserData) => _dataOrchestrator.removeFamilyMember(
        // currentUserData might be unused here
        currentUserId: _currentUserId!,
        memberDocId: event.memberDocId,
        // linkedUserId can be determined by the Cloud Function or passed if known
      ),
      emit,
      processingId: event.memberDocId,
      sectionToRefresh: SocialSection.family,
    );
  }

  Future<void> _onAcceptFamilyRequest(
      AcceptFamilyRequest event, Emitter<SocialState> emit) async {
    await _handleRepositoryCall(
      (currentUserData) => _dataOrchestrator.acceptFamilyRequest(
        currentUserId: _currentUserId!,
        currentUserData: currentUserData,
        requesterUserId: event.requesterUserId,
        requesterName: event.requesterName,
        requesterProfilePicUrl: event.requesterProfilePicUrl,
        requesterRelationship: event.requesterRelationship,
      ),
      emit,
      processingId: event.requesterUserId,
      sectionToRefresh: SocialSection.family,
    );
  }

  Future<void> _onDeclineFamilyRequest(
      DeclineFamilyRequest event, Emitter<SocialState> emit) async {
    await _handleRepositoryCall(
      (currentUserData) => _dataOrchestrator.declineFamilyRequest(
        currentUserId: _currentUserId!,
        requesterUserId: event.requesterUserId,
      ),
      emit,
      processingId: event.requesterUserId,
      sectionToRefresh: SocialSection.family,
    );
  }

  Future<void> _onSendFriendRequest(
      SendFriendRequest event, Emitter<SocialState> emit) async {
    if (_currentUserId == event.targetUserId) {
      emit(const SocialError(
          message: "You cannot send a friend request to yourself."));
      return;
    }
    await _handleRepositoryCall(
        (currentUserData) => _dataOrchestrator.sendFriendRequest(
              currentUserId: _currentUserId!,
              currentUserData: currentUserData,
              targetUserId: event.targetUserId,
              targetUserName: event.targetUserName,
              targetUserProfilePicUrl: event.targetUserPicUrl,
            ),
        emit,
        processingId: event.targetUserId,
        successMessageOverride: "Friend request sent.");
    if (state is FriendSearchResultsLoaded) {
      add(SearchUsers(query: (state as FriendSearchResultsLoaded).query));
    } else {
      add(const LoadFriendsAndRequests()); // Refresh main list as a fallback
    }
  }

  Future<void> _onAcceptFriendRequest(
      AcceptFriendRequest event, Emitter<SocialState> emit) async {
    await _handleRepositoryCall(
      (currentUserData) => _dataOrchestrator.acceptFriendRequest(
        currentUserId: _currentUserId!,
        currentUserData: currentUserData,
        requesterUserId: event.requesterUserId,
        requesterUserName: event.requesterUserName,
        requesterProfilePicUrl: event.requesterUserPicUrl,
      ),
      emit,
      processingId: event.requesterUserId,
      sectionToRefresh: SocialSection.friends,
    );
  }

  Future<void> _onDeclineFriendRequest(
      DeclineFriendRequest event, Emitter<SocialState> emit) async {
    await _handleRepositoryCall(
      (currentUserData) => _dataOrchestrator.declineFriendRequest(
        currentUserId: _currentUserId!,
        requesterUserId: event.requesterUserId,
      ),
      emit,
      processingId: event.requesterUserId,
      sectionToRefresh: SocialSection.friends,
    );
  }

  Future<void> _onRemoveFriend(
      RemoveFriend event, Emitter<SocialState> emit) async {
    await _handleRepositoryCall(
      (currentUserData) => _dataOrchestrator.removeFriend(
        currentUserId: _currentUserId!,
        friendUserId: event.friendUserId,
      ),
      emit,
      processingId: event.friendUserId,
      sectionToRefresh: SocialSection.friends,
    );
  }

  Future<void> _onUnsendFriendRequest(
      UnsendFriendRequest event, Emitter<SocialState> emit) async {
    await _handleRepositoryCall(
        (currentUserData) => _dataOrchestrator.unsendFriendRequest(
              currentUserId: _currentUserId!,
              targetUserId: event.targetUserId,
            ),
        emit,
        processingId: event.targetUserId,
        successMessageOverride: "Friend request cancelled.");
    if (state is FriendSearchResultsLoaded) {
      add(SearchUsers(query: (state as FriendSearchResultsLoaded).query));
    } else {
      add(const LoadFriendsAndRequests());
    }
  }

  // --- Suggestion Event Handlers ---

  Future<void> _onLoadSuggestions(
      LoadSuggestions event, Emitter<SocialState> emit) async {
    if (_currentUserId == null) {
      emit(SuggestionsError(
        message: "User not logged in.",
        context: event.context,
      ));
      return;
    }

    emit(SuggestionsLoading(context: event.context));

    try {
      final config = event.config ?? _getDefaultConfig(event.context);
      final batch = await _suggestionEngine.generateSuggestions(config);

      emit(SuggestionsLoaded(
        batch: batch,
        context: event.context,
      ));
    } catch (e) {
      emit(SuggestionsError(
        message: "Failed to load suggestions: ${e.toString()}",
        context: event.context,
      ));
    }
  }

  Future<void> _onRefreshSuggestions(
      RefreshSuggestions event, Emitter<SocialState> emit) async {
    // Clear cache and reload suggestions
    final config = _getDefaultConfig(event.context);
    add(LoadSuggestions(context: event.context, config: config));
  }

  Future<void> _onInteractWithSuggestion(
      InteractWithSuggestion event, Emitter<SocialState> emit) async {
    if (_currentUserId == null) return;

    try {
      // Log the interaction for analytics/ML
      // This would typically be sent to a analytics service or stored in Firestore

      String message;
      switch (event.interactionType) {
        case SuggestionInteractionType.connected:
          // Send friend request
          add(SendFriendRequest(
            targetUserId: event.suggestedUserId,
            targetUserName: event.metadata?['userName'] ?? 'User',
            targetUserPicUrl: event.metadata?['profilePicUrl'],
          ));
          message = "Friend request sent!";
          break;
        case SuggestionInteractionType.dismissed:
          message = "Suggestion dismissed";
          break;
        case SuggestionInteractionType.viewed:
          message = "Suggestion viewed";
          break;
        default:
          message = "Interaction recorded";
      }

      emit(SuggestionInteractionProcessed(
        suggestionId: event.suggestionId,
        interactionType: event.interactionType,
        message: message,
      ));
    } catch (e) {
      emit(SocialError(
          message: "Failed to process interaction: ${e.toString()}"));
    }
  }

  Future<void> _onDismissSuggestion(
      DismissSuggestion event, Emitter<SocialState> emit) async {
    // Record dismissal and remove from current suggestions
    add(InteractWithSuggestion(
      suggestionId: event.suggestionId,
      suggestedUserId: event.suggestedUserId,
      interactionType: SuggestionInteractionType.dismissed,
    ));
  }

  /// Get default suggestion config for different contexts
  SuggestionConfig _getDefaultConfig(SuggestionContext context) {
    switch (context) {
      case SuggestionContext.homeQuickAccess:
        return SuggestionConfig.homeQuickAccess;
      case SuggestionContext.socialHub:
        return SuggestionConfig.socialHub;
      default:
        return SuggestionConfig.socialHub;
    }
  }
}
