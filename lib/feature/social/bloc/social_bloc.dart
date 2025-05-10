// lib/feature/social/bloc/social_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'dart:async';
import 'package:shamil_mobile_app/feature/social/repository/social_repository.dart';

part 'social_event.dart';
part 'social_state.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final SocialRepository _socialRepository;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  SocialBloc({required SocialRepository socialRepository})
      : _socialRepository = socialRepository,
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
  }

  Future<AuthModel?> _getCurrentAuthModel() async {
    if (_currentUserId == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('endUsers')
          .doc(_currentUserId!)
          .get();
      return doc.exists ? AuthModel.fromFirestore(doc) : null;
    } catch (e) {
      print("SocialBloc: Error fetching current AuthModel: $e");
      return null;
    }
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
      final members =
          await _socialRepository.fetchFamilyMembers(_currentUserId!);
      final requests =
          await _socialRepository.fetchIncomingFamilyRequests(_currentUserId!);
      emit(
          FamilyDataLoaded(familyMembers: members, incomingRequests: requests));
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
      final friends = await _socialRepository.fetchFriends(_currentUserId!);
      final incoming =
          await _socialRepository.fetchIncomingFriendRequests(_currentUserId!);
      final outgoing =
          await _socialRepository.fetchOutgoingFriendRequests(_currentUserId!);
      emit(FriendsAndRequestsLoaded(
          friends: friends,
          incomingRequests: incoming,
          outgoingRequests: outgoing));
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
      final foundUser = await _socialRepository.searchUserByNationalId(
          event.nationalId, _currentUserId!);
      emit(UserNationalIdSearchResult(
          foundUser: foundUser, searchedNationalId: event.nationalId));
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
      final results = await _socialRepository.searchUsersByNameOrUsername(
          _currentUserId!, event.query.trim());
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
        if (sectionToRefresh != null)
          add(RefreshSocialSection(sectionToRefresh));
        return;
      }

      final result = await repositoryCallWithUser(
          currentUserModel); // Execute call with current user data

      if (result['success'] == true) {
        emit(SocialSuccess(
            message: successMessageOverride ??
                result['message'] as String? ??
                "Operation successful."));
        if (sectionToRefresh != null) {
          add(RefreshSocialSection(sectionToRefresh));
        }
      } else {
        emit(SocialError(
            message:
                result['error'] as String? ?? "An unknown error occurred."));
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
      (currentUserData) => _socialRepository.addOrRequestFamilyMember(
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
      (currentUserData) => _socialRepository.removeFamilyMember(
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
      (currentUserData) => _socialRepository.acceptFamilyRequest(
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
      (currentUserData) => _socialRepository.declineFamilyRequest(
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
        (currentUserData) => _socialRepository.sendFriendRequest(
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
      (currentUserData) => _socialRepository.acceptFriendRequest(
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
      (currentUserData) => _socialRepository.declineFriendRequest(
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
      (currentUserData) => _socialRepository.removeFriend(
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
        (currentUserData) => _socialRepository.unsendFriendRequest(
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
}
