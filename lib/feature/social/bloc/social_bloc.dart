import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // Import AuthModel
import 'dart:async'; // Import for Future.wait

// ACTION: Import the repository
import 'package:shamil_mobile_app/feature/social/repository/social_repository.dart';

part 'social_event.dart';
part 'social_state.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ACTION: Inject Repository
  final SocialRepository _socialRepository;

  // ACTION: Update Constructor
  SocialBloc({required SocialRepository socialRepository})
      : _socialRepository = socialRepository, // Assign injected repository
        super(SocialInitial()) {
    // Family Handlers
    on<LoadFamilyMembers>(_onLoadFamilyMembers);
    on<AddFamilyMember>(_onAddFamilyMember); // Updated
    on<RemoveFamilyMember>(_onRemoveFamilyMember); // Updated
    on<SearchUserByNationalId>(_onSearchUserByNationalId);
    on<AcceptFamilyRequest>(_onAcceptFamilyRequest); // Updated
    on<DeclineFamilyRequest>(_onDeclineFamilyRequest); // Updated

    // Friend Event Handlers
    on<LoadFriendsAndRequests>(_onLoadFriendsAndRequests);
    on<SearchUsers>(_onSearchUsers);
    on<SendFriendRequest>(_onSendFriendRequest); // Updated
    on<AcceptFriendRequest>(_onAcceptFriendRequest); // Updated
    on<DeclineFriendRequest>(_onDeclineFriendRequest); // Updated
    on<RemoveFriend>(_onRemoveFriend); // Updated
    on<UnsendFriendRequest>(_onUnsendFriendRequest); // Updated
  }

  // Helper to get current user UID
  String? get _userId => _auth.currentUser?.uid;

  // Helper to get current user details (needed for denormalization in some repository calls)
  Future<AuthModel?> _getCurrentAuthModel() async {
    if (_userId == null) return null;
    try {
      final doc = await _firestore.collection('endUsers').doc(_userId!).get();
      return doc.exists ? AuthModel.fromFirestore(doc) : null;
    } catch (e) {
      print("Error fetching current AuthModel: $e");
      return null;
    }
  }

  // Get the family members subcollection reference (for reads)
  CollectionReference? get _familyCollectionRef {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore
        .collection('endUsers')
        .doc(uid)
        .collection('familyMembers');
  }

  // Get the friends subcollection reference for the current user (for reads)
  CollectionReference? get _friendsCollectionRef {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('endUsers').doc(uid).collection('friends');
  }

  // --- Read Handlers (Remain largely the same) ---

  Future<void> _onLoadFamilyMembers(
      LoadFamilyMembers event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    // Avoid emitting loading if already loaded, just refresh
    bool wasLoaded = state is FamilyDataLoaded;
    if (!wasLoaded) {
      emit(const SocialLoading(isLoadingList: true));
    }
    try {
      final snapshot = await _familyCollectionRef
          ?.orderBy('addedAt', descending: true)
          .get();
      if (snapshot == null) throw Exception("Could not access family data.");
      final List<FamilyMember> members = [];
      final List<FamilyRequest> requests = [];
      for (var doc in snapshot.docs) {
        try {
          final member = FamilyMember.fromFirestore(doc);
          if (member.status == 'pending_received') {
            requests.add(FamilyRequest.fromFirestore(doc));
          } else if (member.status == 'accepted' ||
              member.status == 'external') {
            members.add(member);
          }
        } catch (e) {
          print("Error parsing family doc ${doc.id}: $e");
        }
      }
      emit(
          FamilyDataLoaded(familyMembers: members, incomingRequests: requests));
      print(
          "SocialBloc: Loaded ${members.length} family members and ${requests.length} requests.");
    } catch (e) {
      print("SocialBloc: Error loading family members: $e");
      emit(SocialError(
          message: "Failed to load family members: ${e.toString()}"));
    }
  }

  Future<void> _onLoadFriendsAndRequests(
      LoadFriendsAndRequests event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    bool wasLoaded = state is FriendsAndRequestsLoaded;
    if (!wasLoaded) {
      emit(const SocialLoading(isLoadingList: true));
    }
    try {
      final friendsQuery = _friendsCollectionRef!
          .where('status', isEqualTo: 'accepted')
          .orderBy('friendedAt', descending: true);
      final incomingRequestsQuery =
          _friendsCollectionRef!.where('status', isEqualTo: 'pending_received');
      final outgoingRequestsQuery =
          _friendsCollectionRef!.where('status', isEqualTo: 'pending_sent');
      final results = await Future.wait([
        friendsQuery.get(),
        incomingRequestsQuery.get(),
        outgoingRequestsQuery.get()
      ]);
      final friendsSnapshot = results[0];
      final requestsSnapshot = results[1];
      final outgoingSnapshot = results[2];
      print(
          "SocialBloc: LoadFriends - Queries completed. Found ${friendsSnapshot.docs.length} friends, ${requestsSnapshot.docs.length} incoming, ${outgoingSnapshot.docs.length} outgoing.");
      final friendsList = friendsSnapshot.docs
          .map((doc) {
            try {
              return Friend.fromFirestore(doc);
            } catch (e) {
              print("Error mapping Friend doc ${doc.id}: $e");
              return null;
            }
          })
          .whereType<Friend>()
          .toList();
      final incomingRequestsList = requestsSnapshot.docs
          .map((doc) {
            try {
              return FriendRequest.fromFirestore(doc);
            } catch (e) {
              print("Error mapping FriendRequest doc ${doc.id}: $e");
              return null;
            }
          })
          .whereType<FriendRequest>()
          .toList();
      final outgoingRequestsList = outgoingSnapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
      emit(FriendsAndRequestsLoaded(
          friends: friendsList,
          incomingRequests: incomingRequestsList,
          outgoingRequests: outgoingRequestsList));
    } catch (e, s) {
      print("SocialBloc: Error in _onLoadFriendsAndRequests: $e\n$s");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        emit(const SocialError(
            message:
                "Database index missing for friends list. Please check Firebase console."));
      } else {
        emit(SocialError(message: "Failed to load friends: ${e.toString()}"));
      }
      // Optionally re-emit previous state on error?
      // if (wasLoaded) emit(state);
    }
  }

  Future<void> _onSearchUsers(
      SearchUsers event, Emitter<SocialState> emit) async {
    // Logic remains the same - reads data and current user's friend status only
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(FriendSearchResultsWithStatus(results: const [], query: query));
      return;
    }
    emit(const SocialLoading(
        isLoadingList: false)); // Indicate search is happening
    try {
      print(
          "SocialBloc: Searching users matching '$query' by name/username...");
      // Requires indexes on name_lowercase (Asc) and username (Asc)
      final nameQuery = _firestore
          .collection('endUsers')
          .where('name_lowercase', isGreaterThanOrEqualTo: query)
          .where('name_lowercase', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(15)
          .get();
      final usernameQuery = _firestore
          .collection('endUsers')
          .where('username', isEqualTo: query)
          .limit(5)
          .get();
      final results = await Future.wait([nameQuery, usernameQuery]);
      final nameSnapshot = results[0];
      final usernameSnapshot = results[1];
      final Map<String, AuthModel> combinedUserModels = {};
      for (var doc in nameSnapshot.docs) {
        if (doc.id != _userId) {
          combinedUserModels[doc.id] = AuthModel.fromFirestore(doc);
        }
      }
      for (var doc in usernameSnapshot.docs) {
        if (doc.id != _userId) {
          combinedUserModels[doc.id] = AuthModel.fromFirestore(doc);
        }
      }

      // Fetch friendship status for each result
      final List<UserSearchResultWithStatus> resultsWithStatus = [];
      if (_friendsCollectionRef != null) {
        // Check if friends ref is available
        for (var userModel in combinedUserModels.values) {
          FriendshipStatus currentStatus = FriendshipStatus.none;
          try {
            final friendDoc =
                await _friendsCollectionRef!.doc(userModel.uid).get();
            if (friendDoc.exists) {
              final statusString = (friendDoc.data()
                  as Map<String, dynamic>?)?['status'] as String?;
              switch (statusString) {
                case 'accepted':
                  currentStatus = FriendshipStatus.friends;
                  break;
                case 'pending_sent':
                  currentStatus = FriendshipStatus.requestSent;
                  break;
                case 'pending_received':
                  currentStatus = FriendshipStatus.requestReceived;
                  break;
              }
            }
          } catch (e) {
            print("Error fetching friend status for ${userModel.uid}: $e");
          }
          resultsWithStatus.add(UserSearchResultWithStatus(
              user: userModel, status: currentStatus));
        }
      } else {
        // Handle case where user isn't logged in properly (friends ref is null)
        for (var userModel in combinedUserModels.values) {
          resultsWithStatus.add(UserSearchResultWithStatus(
              user: userModel, status: FriendshipStatus.none));
        }
      }

      resultsWithStatus
          .sort((a, b) => a.user.name.compareTo(b.user.name)); // Sort results
      print(
          "SocialBloc: Found ${resultsWithStatus.length} unique potential users with status.");
      emit(FriendSearchResultsWithStatus(
          results: resultsWithStatus, query: event.query.trim()));
    } catch (e) {
      print("SocialBloc: Error searching users: $e");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        emit(const SocialError(
            message:
                "Database index missing for user search. Check name and username indexes."));
      } else {
        emit(SocialError(message: "Failed to search users: ${e.toString()}"));
      }
      emit(FriendSearchResultsWithStatus(
          results: const [],
          query: event.query.trim())); // Emit empty result on error
    }
  }

  Future<void> _onSearchUserByNationalId(
      SearchUserByNationalId event, Emitter<SocialState> emit) async {
    // This reads public data, so can remain in Bloc
    emit(const SocialLoading(isLoadingList: false)); // Indicate checking
    try {
      print(
          "SocialBloc: Searching for user with National ID: ${event.nationalId}");
      final querySnapshot = await _firestore
          .collection('endUsers')
          .where('nationalId', isEqualTo: event.nationalId)
          .limit(1)
          .get();
      AuthModel? foundUser;
      if (querySnapshot.docs.isNotEmpty) {
        if (querySnapshot.docs.first.id != _userId) {
          foundUser = AuthModel.fromFirestore(querySnapshot.docs.first);
          print("SocialBloc: Found user by ID: ${foundUser.name}");
        } else {
          print("SocialBloc: User tried to link themselves.");
          // Emit specific state or message for UI
          emit(UserSearchResult(
              foundUser: null,
              searchedId: event.nationalId)); // Indicate self-found
          return; // Stop further processing
        }
      } else {
        print(
            "SocialBloc: No user found with National ID: ${event.nationalId}");
      }
      // Emit result (foundUser will be null if not found or self)
      emit(
          UserSearchResult(foundUser: foundUser, searchedId: event.nationalId));
    } catch (e) {
      print("SocialBloc: Error searching user by National ID: $e");
      String errorMessage = "Error searching user: ${e.toString()}";
      if (e is FirebaseException && e.code == 'failed-precondition') {
        errorMessage = "Database index missing for National ID search.";
      }
      emit(SocialError(message: errorMessage));
      // Optionally emit UserSearchResult with null user on error too
      emit(UserSearchResult(foundUser: null, searchedId: event.nationalId));
    }
  }

  // --- Write Handlers (Use Repository) ---

  Future<void> _onAddFamilyMember(
      AddFamilyMember event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(const SocialLoading(
        isLoadingList: false)); // Indicate action in progress
    try {
      // ACTION: Call repository method
      final result = await _socialRepository.addOrRequestFamilyMember(
        currentUserId: _userId!,
        memberData: event.memberData,
        linkedUserModel: event.linkedUserModel,
      );

      if (result['success'] == true) {
        emit(SocialSuccess(
            message: result['message'] ?? "Family member action successful."));
        add(const LoadFamilyMembers()); // Reload list on success
      } else {
        emit(SocialError(
            message: result['error'] ?? "Failed to add family member."));
      }
    } catch (e) {
      print(
          "SocialBloc: Error calling repository for add/request family member: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
    }
  }

  Future<void> _onRemoveFamilyMember(
      RemoveFamilyMember event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(const SocialLoading(isLoadingList: false)); // Indicate action
    try {
      // Need to fetch the member first to know if it's a linked user
      FamilyMember? memberToRemove;
      try {
        final doc = await _familyCollectionRef?.doc(event.memberDocId).get();
        if (doc != null && doc.exists) {
          memberToRemove = FamilyMember.fromFirestore(doc);
        }
      } catch (e) {
        print("Error fetching member details before removal: $e");
      }

      // ACTION: Call repository method
      final result = await _socialRepository.removeFamilyMember(
        currentUserId: _userId!,
        memberDocId: event.memberDocId,
        linkedUserId: (memberToRemove?.status == 'accepted')
            ? memberToRemove?.userId
            : null,
      );

      if (result['success'] == true) {
        emit(SocialSuccess(
            message: result['message'] ?? "Family member removed."));
        add(const LoadFamilyMembers()); // Reload list
      } else {
        emit(SocialError(
            message: result['error'] ?? "Failed to remove family member."));
      }
    } catch (e) {
      print(
          "SocialBloc: Error calling repository for remove family member: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
    }
  }

  Future<void> _onAcceptFamilyRequest(
      AcceptFamilyRequest event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(SocialLoading(
        processingUserId:
            event.requesterUserId)); // Indicate processing this user
    try {
      final currentUserModel = await _getCurrentAuthModel();
      if (currentUserModel == null)
        throw Exception("Could not get current user details.");

      // ACTION: Call repository method
      final result = await _socialRepository.acceptFamilyRequest(
        currentUserId: _userId!,
        requesterUserId: event.requesterUserId,
        currentUserName: currentUserModel.name,
        currentUserProfilePicUrl:
            currentUserModel.profilePicUrl ?? currentUserModel.image,
        requesterName: event.requesterName,
        requesterProfilePicUrl: event.requesterProfilePicUrl,
        requesterRelationship: event.requesterRelationship,
      );

      if (result['success'] == true) {
        emit(SocialSuccess(
            message: result['message'] ?? "Family request accepted."));
        add(const LoadFamilyMembers()); // Reload list
      } else {
        emit(SocialError(
            message: result['error'] ?? "Failed to accept request."));
        add(const LoadFamilyMembers()); // Reload list even on error to clear loading state
      }
    } catch (e) {
      print(
          "SocialBloc: Error calling repository for accept family request: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
      add(const LoadFamilyMembers()); // Reload list on error
    }
  }

  Future<void> _onDeclineFamilyRequest(
      DeclineFamilyRequest event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(SocialLoading(
        processingUserId:
            event.requesterUserId)); // Indicate processing this user
    try {
      // ACTION: Call repository method
      final result = await _socialRepository.declineFamilyRequest(
        currentUserId: _userId!,
        requesterUserId: event.requesterUserId,
      );

      if (result['success'] == true) {
        emit(SocialSuccess(
            message: result['message'] ?? "Family request declined."));
        add(const LoadFamilyMembers()); // Reload list
      } else {
        emit(SocialError(
            message: result['error'] ?? "Failed to decline request."));
        add(const LoadFamilyMembers()); // Reload list even on error
      }
    } catch (e) {
      print(
          "SocialBloc: Error calling repository for decline family request: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
      add(const LoadFamilyMembers()); // Reload list on error
    }
  }

  Future<void> _onSendFriendRequest(
      SendFriendRequest event, Emitter<SocialState> emit) async {
    if (_userId == null || _userId == event.targetUserId) {
      emit(const SocialError(message: "Invalid request."));
      return;
    }
    emit(SocialLoading(
        processingUserId: event.targetUserId)); // Indicate processing this user
    try {
      final currentUserModel = await _getCurrentAuthModel();
      if (currentUserModel == null)
        throw Exception("Could not get current user details.");

      // ACTION: Call repository method
      final result = await _socialRepository.sendFriendRequest(
        currentUserId: _userId!,
        targetUserId: event.targetUserId,
        currentUserName: currentUserModel.name,
        currentUserProfilePicUrl:
            currentUserModel.profilePicUrl ?? currentUserModel.image,
        targetUserName: event.targetUserName,
        targetUserProfilePicUrl: event.targetUserPicUrl,
      );

      if (result['success'] == true) {
        // Don't emit SocialSuccess here, rely on the local UI update in FindFriendsView
        // and let LoadFriendsAndRequests update the main list later.
        // emit(SocialSuccess(message: result['message'] ?? "Friend request sent."));
        // Instead, just reload the search results state if applicable, or the main list silently
        if (state is FriendSearchResultsWithStatus) {
          add(SearchUsers(
              query: (state as FriendSearchResultsWithStatus)
                  .query)); // Refresh search results
        } else {
          add(const LoadFriendsAndRequests()); // Refresh main list
        }
      } else {
        emit(
            SocialError(message: result['error'] ?? "Failed to send request."));
        // Reload relevant list on error
        if (state is FriendSearchResultsWithStatus) {
          add(SearchUsers(
              query: (state as FriendSearchResultsWithStatus).query));
        } else {
          add(const LoadFriendsAndRequests());
        }
      }
    } catch (e) {
      print("SocialBloc: Error calling repository for send friend request: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
      if (state is FriendSearchResultsWithStatus) {
        add(SearchUsers(query: (state as FriendSearchResultsWithStatus).query));
      } else {
        add(const LoadFriendsAndRequests());
      }
    }
  }

  Future<void> _onAcceptFriendRequest(
      AcceptFriendRequest event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(SocialLoading(processingUserId: event.requesterUserId));
    try {
      final currentUserModel = await _getCurrentAuthModel();
      if (currentUserModel == null)
        throw Exception("Could not get current user details.");

      // ACTION: Call repository method
      final result = await _socialRepository.acceptFriendRequest(
        currentUserId: _userId!,
        requesterUserId: event.requesterUserId,
        currentUserName: currentUserModel.name,
        currentUserProfilePicUrl:
            currentUserModel.profilePicUrl ?? currentUserModel.image,
        requesterUserName: event.requesterUserName,
        requesterProfilePicUrl: event.requesterUserPicUrl,
      );

      if (result['success'] == true) {
        emit(SocialSuccess(
            message: result['message'] ?? "Friend request accepted."));
        add(const LoadFriendsAndRequests()); // Reload list
      } else {
        emit(SocialError(
            message: result['error'] ?? "Failed to accept request."));
        add(const LoadFriendsAndRequests()); // Reload list even on error
      }
    } catch (e) {
      print(
          "SocialBloc: Error calling repository for accept friend request: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
      add(const LoadFriendsAndRequests()); // Reload list on error
    }
  }

  Future<void> _onDeclineFriendRequest(
      DeclineFriendRequest event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(SocialLoading(processingUserId: event.requesterUserId));
    try {
      // ACTION: Call repository method
      final result = await _socialRepository.declineFriendRequest(
        currentUserId: _userId!,
        requesterUserId: event.requesterUserId,
      );

      if (result['success'] == true) {
        emit(SocialSuccess(
            message: result['message'] ?? "Friend request declined."));
        add(const LoadFriendsAndRequests()); // Reload list
      } else {
        emit(SocialError(
            message: result['error'] ?? "Failed to decline request."));
        add(const LoadFriendsAndRequests()); // Reload list even on error
      }
    } catch (e) {
      print(
          "SocialBloc: Error calling repository for decline friend request: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
      add(const LoadFriendsAndRequests()); // Reload list on error
    }
  }

  Future<void> _onRemoveFriend(
      RemoveFriend event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(SocialLoading(processingUserId: event.friendUserId));
    try {
      // ACTION: Call repository method
      final result = await _socialRepository.removeFriend(
        currentUserId: _userId!,
        friendUserId: event.friendUserId,
      );

      if (result['success'] == true) {
        emit(SocialSuccess(message: result['message'] ?? "Friend removed."));
        add(const LoadFriendsAndRequests()); // Reload list
      } else {
        emit(SocialError(
            message: result['error'] ?? "Failed to remove friend."));
        add(const LoadFriendsAndRequests()); // Reload list even on error
      }
    } catch (e) {
      print("SocialBloc: Error calling repository for remove friend: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
      add(const LoadFriendsAndRequests()); // Reload list on error
    }
  }

  Future<void> _onUnsendFriendRequest(
      UnsendFriendRequest event, Emitter<SocialState> emit) async {
    if (_userId == null) {
      emit(const SocialError(message: "User not logged in."));
      return;
    }
    emit(SocialLoading(processingUserId: event.targetUserId));
    try {
      // ACTION: Call repository method
      final result = await _socialRepository.unsendFriendRequest(
        currentUserId: _userId!,
        targetUserId: event.targetUserId,
      );

      if (result['success'] == true) {
        // Don't emit SocialSuccess, rely on local UI update and list reload
        // emit(SocialSuccess(message: result['message'] ?? "Friend request cancelled."));
        // Reload relevant list
        if (state is FriendSearchResultsWithStatus) {
          add(SearchUsers(
              query: (state as FriendSearchResultsWithStatus).query));
        } else {
          add(const LoadFriendsAndRequests());
        }
      } else {
        emit(SocialError(
            message: result['error'] ?? "Failed to cancel request."));
        // Reload relevant list on error
        if (state is FriendSearchResultsWithStatus) {
          add(SearchUsers(
              query: (state as FriendSearchResultsWithStatus).query));
        } else {
          add(const LoadFriendsAndRequests());
        }
      }
    } catch (e) {
      print(
          "SocialBloc: Error calling repository for unsend friend request: $e");
      emit(SocialError(message: "Operation failed: ${e.toString()}"));
      if (state is FriendSearchResultsWithStatus) {
        add(SearchUsers(query: (state as FriendSearchResultsWithStatus).query));
      } else {
        add(const LoadFriendsAndRequests());
      }
    }
  }
} // End of SocialBloc
