import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart'; // Import AuthModel
import 'dart:async'; // Import for Future.wait

part 'social_event.dart';
part 'social_state.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SocialBloc() : super(SocialInitial()) {
    // Family Handlers
    on<LoadFamilyMembers>(_onLoadFamilyMembers);
    on<AddFamilyMember>(_onAddFamilyMember);
    on<RemoveFamilyMember>(_onRemoveFamilyMember);
    on<SearchUserByNationalId>(_onSearchUserByNationalId);
    on<AcceptFamilyRequest>(_onAcceptFamilyRequest);
    on<DeclineFamilyRequest>(_onDeclineFamilyRequest);

    // Friend Event Handlers
    on<LoadFriendsAndRequests>(_onLoadFriendsAndRequests); // Updated below
    on<SearchUsers>(_onSearchUsers);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<DeclineFriendRequest>(_onDeclineFriendRequest);
    on<RemoveFriend>(_onRemoveFriend);
    on<UnsendFriendRequest>(_onUnsendFriendRequest); // Updated below
  }

  // Helper to get current user UID
  String? get _userId => _auth.currentUser?.uid;

  // Helper to get current user details (needed for denormalization)
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


  // Get the family members subcollection reference
  CollectionReference? get _familyCollectionRef {
     final uid = _userId;
     if (uid == null) return null;
     return _firestore.collection('endUsers').doc(uid).collection('familyMembers');
  }

   // Get the friends subcollection reference for the current user
   CollectionReference? get _friendsCollectionRef {
     final uid = _userId;
     if (uid == null) return null;
     return _firestore.collection('endUsers').doc(uid).collection('friends');
   }

   // Get reference to a specific user's friends subcollection
   CollectionReference? _getFriendsRefForUser(String userId) {
      return _firestore.collection('endUsers').doc(userId).collection('friends');
   }

   // Get reference to a specific user's family subcollection
   CollectionReference? _getFamilyRefForUser(String userId) {
      return _firestore.collection('endUsers').doc(userId).collection('familyMembers');
   }


  // --- Family Handlers ---
  Future<void> _onLoadFamilyMembers(LoadFamilyMembers event, Emitter<SocialState> emit) async {
    if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
    if (state is! FamilyDataLoaded) { emit(const SocialLoading(isLoadingList: true)); }
    try {
      final snapshot = await _familyCollectionRef?.orderBy('addedAt', descending: true).get();
      if (snapshot == null) throw Exception("Could not access family data.");
      final List<FamilyMember> members = []; final List<FamilyRequest> requests = [];
      for (var doc in snapshot.docs) {
         final member = FamilyMember.fromFirestore(doc);
         if (member.status == 'pending_received') { requests.add(FamilyRequest.fromFirestore(doc)); }
         else if (member.status == 'accepted' || member.status == 'external') { members.add(member); }
      }
      emit(FamilyDataLoaded(familyMembers: members, incomingRequests: requests));
      print("SocialBloc: Loaded ${members.length} family members and ${requests.length} requests.");
    } catch (e) { print("SocialBloc: Error loading family members: $e"); emit(SocialError(message: "Failed to load family members: ${e.toString()}")); }
  }

  Future<void> _onAddFamilyMember(AddFamilyMember event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false));
     try {
        final dataToAdd = Map<String, dynamic>.from(event.memberData);
        final Timestamp now = Timestamp.now(); dataToAdd['addedAt'] = now;
        if (dataToAdd['name'] == null || dataToAdd['name'].isEmpty || dataToAdd['relationship'] == null || dataToAdd['relationship'].isEmpty) { throw Exception("Name and Relationship are required."); }
        if (event.linkedUserModel == null && (dataToAdd['gender'] == null || dataToAdd['gender'].isEmpty)) { throw Exception("Gender is required when not linking an existing user."); }

        if(event.linkedUserModel != null) { // Send Request Flow
           final linkedUser = event.linkedUserModel!;
           final currentUserModel = await _getCurrentAuthModel(); if (currentUserModel == null) throw Exception("Could not get current user details.");
           final existingLink = await _familyCollectionRef!.doc(linkedUser.uid).get();
           if (existingLink.exists) { final existingStatus = (existingLink.data() as Map<String, dynamic>?)?['status'] as String?; if (existingStatus == 'accepted' || existingStatus == 'pending_sent' || existingStatus == 'pending_received') { throw Exception("${linkedUser.name} is already linked or has a pending request."); } }
           final WriteBatch batch = _firestore.batch();
           final ownFamilyRef = _familyCollectionRef!.doc(linkedUser.uid);
           batch.set(ownFamilyRef, { 'name': linkedUser.name, 'relationship': dataToAdd['relationship'], 'userId': linkedUser.uid, 'profilePicUrl': linkedUser.profilePicUrl ?? linkedUser.image, 'status': 'pending_sent', 'addedAt': now, 'senderName': currentUserModel.name, 'senderProfilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, }, SetOptions(merge: true));
           final targetFamilyRef = _getFamilyRefForUser(linkedUser.uid)?.doc(_userId!); if (targetFamilyRef == null) throw Exception("Could not get target user's family reference.");
           batch.set(targetFamilyRef, { 'name': currentUserModel.name, 'relationship': dataToAdd['relationship'], 'userId': _userId!, 'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, 'status': 'pending_received', 'addedAt': now, }, SetOptions(merge: true));
           print("SocialBloc: WARNING - Attempting client-side cross-user write for family request."); await batch.commit(); print("SocialBloc: Family request sent to ${linkedUser.name}");
           // TODO: Trigger notification via Cloud Function
           emit(const SocialSuccess(message: "Family request sent."));
        } else { // Add External Contact Directly
           dataToAdd['userId'] = null; dataToAdd['status'] = 'external'; dataToAdd['nationalId'] = event.memberData['nationalId']; dataToAdd['gender'] = event.memberData['gender'];
           dataToAdd['phone'] = event.memberData['phone'] == null || event.memberData['phone'].isEmpty ? null : event.memberData['phone']; dataToAdd['email'] = event.memberData['email'] == null || event.memberData['email'].isEmpty ? null : event.memberData['email'];
           dataToAdd['dob'] = event.memberData['dob'] == null || event.memberData['dob'].isEmpty ? null : event.memberData['dob']; // Include dob
           await _familyCollectionRef?.add(dataToAdd); print("SocialBloc: Added external family member: ${dataToAdd['name']}"); emit(const SocialSuccess(message: "Family member added."));
        }
        add(const LoadFamilyMembers());
     } catch (e) { print("SocialBloc: Error adding/requesting family member: $e"); emit(SocialError(message: "Failed to add family member: ${e.toString()}")); }
  }

   Future<void> _onRemoveFamilyMember(RemoveFamilyMember event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false));
     try {
        final docRef = _familyCollectionRef!.doc(event.memberDocId);
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) { print("SocialBloc: Family member document ${event.memberDocId} not found for removal."); emit(const SocialSuccess(message: "Member already removed.")); add(const LoadFamilyMembers()); return; }
        final memberData = FamilyMember.fromFirestore(docSnapshot);
        if (memberData.status == 'accepted' && memberData.userId != null) {
           print("SocialBloc: Removing accepted family link: ${memberData.name}"); final WriteBatch batch = _firestore.batch(); batch.delete(docRef);
           final otherUserFamilyRef = _getFamilyRefForUser(memberData.userId!)?.doc(_userId!);
           if (otherUserFamilyRef == null) { print("SocialBloc: Warning - Could not get other user's family reference for removal."); } else { batch.delete(otherUserFamilyRef); }
           print("SocialBloc: WARNING - Attempting client-side cross-user write for family removal."); await batch.commit(); emit(const SocialSuccess(message: "Family member removed."));
        } else { print("SocialBloc: Removing external/pending family entry: ${memberData.name}"); await docRef.delete(); emit(const SocialSuccess(message: "Family member removed.")); }
        add(const LoadFamilyMembers());
     } catch (e) { print("SocialBloc: Error removing family member: $e"); emit(SocialError(message: "Failed to remove family member: ${e.toString()}")); }
   }

  Future<void> _onSearchUserByNationalId(SearchUserByNationalId event, Emitter<SocialState> emit) async {
    final previousState = state; emit(const SocialLoading(isLoadingList: false));
    try {
      print("SocialBloc: Searching for user with National ID: ${event.nationalId}"); final querySnapshot = await _firestore.collection('endUsers').where('nationalId', isEqualTo: event.nationalId).limit(1).get(); AuthModel? foundUser;
      if (querySnapshot.docs.isNotEmpty) { if (querySnapshot.docs.first.id != _userId) { foundUser = AuthModel.fromFirestore(querySnapshot.docs.first); print("SocialBloc: Found user by ID: ${foundUser.name}"); } else { print("SocialBloc: User tried to link themselves."); emit(const SocialError(message: "You cannot add yourself as a family member.")); emit(UserSearchResult(foundUser: null, searchedId: event.nationalId)); if (previousState is FamilyDataLoaded) emit(previousState); return; } }
      else { print("SocialBloc: No user found with National ID: ${event.nationalId}"); }
      emit(UserSearchResult(foundUser: foundUser, searchedId: event.nationalId));
      if (previousState is FamilyDataLoaded) emit(previousState); else if (previousState is FriendsAndRequestsLoaded) emit(previousState); else if (previousState is SocialInitial || previousState is SocialLoading) { add(const LoadFamilyMembers()); }
    } catch (e) {
      print("SocialBloc: Error searching user by National ID: $e"); String errorMessage = "Error searching user: ${e.toString()}"; if (e is FirebaseException && e.code == 'failed-precondition') { errorMessage = "Database index missing for user search."; } emit(SocialError(message: errorMessage)); emit(UserSearchResult(foundUser: null, searchedId: event.nationalId));
      if (previousState is FamilyDataLoaded) emit(previousState); else if (previousState is FriendsAndRequestsLoaded) emit(previousState); else if (previousState is SocialInitial) emit(SocialInitial());
    }
  }

  Future<void> _onAcceptFamilyRequest(AcceptFamilyRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(SocialLoading(processingUserId: event.requesterUserId)); // Indicate processing this user
     print("SocialBloc: Accepting family request from ${event.requesterUserId} for user $_userId");
     try {
        final currentUserModel = await _getCurrentAuthModel(); if (currentUserModel == null) throw Exception("Could not get current user details.");
        final WriteBatch batch = _firestore.batch(); final Timestamp now = Timestamp.now();
        final ownFamilyRef = _familyCollectionRef!.doc(event.requesterUserId); batch.update(ownFamilyRef, { 'status': 'accepted', 'addedAt': now, 'name': event.requesterName, 'profilePicUrl': event.requesterProfilePicUrl, 'relationship': event.requesterRelationship, 'accepterName': currentUserModel.name, 'accepterProfilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, });
        final requesterFamilyRef = _getFamilyRefForUser(event.requesterUserId)?.doc(_userId!); if (requesterFamilyRef == null) throw Exception("Could not get requester's family reference."); batch.update(requesterFamilyRef, { 'status': 'accepted', 'addedAt': now, 'name': currentUserModel.name, 'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, });
        print("SocialBloc: WARNING - Attempting client-side cross-user write for family acceptance."); await batch.commit(); print("SocialBloc: Family acceptance batch committed.");
        // TODO: Trigger notification via Cloud Function
        emit(const SocialSuccess(message: "Family request accepted.")); add(const LoadFamilyMembers());
     } catch (e) { print("SocialBloc: Error accepting family request: $e"); emit(SocialError(message: "Failed to accept request: ${e.toString()}")); add(const LoadFamilyMembers());} // Reload on error too
  }

  Future<void> _onDeclineFamilyRequest(DeclineFamilyRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(SocialLoading(processingUserId: event.requesterUserId)); // Indicate processing this user
     print("SocialBloc: Declining family request from ${event.requesterUserId} for user $_userId");
     try {
        final WriteBatch batch = _firestore.batch();
        final ownFamilyRef = _familyCollectionRef!.doc(event.requesterUserId); batch.delete(ownFamilyRef);
        final requesterFamilyRef = _getFamilyRefForUser(event.requesterUserId)?.doc(_userId!); if (requesterFamilyRef == null) throw Exception("Could not get requester's family reference."); batch.delete(requesterFamilyRef);
        print("SocialBloc: WARNING - Attempting client-side cross-user write for family decline."); await batch.commit(); print("SocialBloc: Family decline batch committed.");
        emit(const SocialSuccess(message: "Family request declined.")); add(const LoadFamilyMembers());
     } catch (e) { print("SocialBloc: Error declining family request: $e"); emit(SocialError(message: "Failed to decline request: ${e.toString()}")); add(const LoadFamilyMembers());} // Reload on error too
  }


  // --- Friend Handlers ---
  Future<void> _onLoadFriendsAndRequests(LoadFriendsAndRequests event, Emitter<SocialState> emit) async {
    // Logic remains the same - reads current user's data only
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     List<Friend> currentFriends = []; List<FriendRequest> currentIncomingRequests = []; List<FriendRequest> currentOutgoingRequests = [];
     if (state is FriendsAndRequestsLoaded) { currentFriends = (state as FriendsAndRequestsLoaded).friends; currentIncomingRequests = (state as FriendsAndRequestsLoaded).incomingRequests; currentOutgoingRequests = (state as FriendsAndRequestsLoaded).outgoingRequests; }
     if (state is! FriendsAndRequestsLoaded) { emit(const SocialLoading(isLoadingList: true)); } else { print("SocialBloc: LoadFriends - Refreshing list (already loaded)."); }
     try {
        final friendsQuery = _friendsCollectionRef!.where('status', isEqualTo: 'accepted').orderBy('friendedAt', descending: true);
        final incomingRequestsQuery = _friendsCollectionRef!.where('status', isEqualTo: 'pending_received');
        final outgoingRequestsQuery = _friendsCollectionRef!.where('status', isEqualTo: 'pending_sent'); // Added query
        final results = await Future.wait([ friendsQuery.get(), incomingRequestsQuery.get(), outgoingRequestsQuery.get() ]); // Await all three
        final friendsSnapshot = results[0]; final requestsSnapshot = results[1]; final outgoingSnapshot = results[2]; // Get outgoing results
        print("SocialBloc: LoadFriends - Queries completed. Found ${friendsSnapshot.docs.length} friends, ${requestsSnapshot.docs.length} incoming, ${outgoingSnapshot.docs.length} outgoing.");
        final friendsList = friendsSnapshot.docs.map((doc) { try { return Friend.fromFirestore(doc); } catch (e) { print("Error mapping Friend doc ${doc.id}: $e"); return null; } }).whereType<Friend>().toList();
        final incomingRequestsList = requestsSnapshot.docs.map((doc) { try { return FriendRequest.fromFirestore(doc); } catch (e) { print("Error mapping FriendRequest doc ${doc.id}: $e"); return null; } }).whereType<FriendRequest>().toList();
        final outgoingRequestsList = outgoingSnapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList(); // Map outgoing
        emit(FriendsAndRequestsLoaded(friends: friendsList, incomingRequests: incomingRequestsList, outgoingRequests: outgoingRequestsList)); // Emit with outgoing
     } catch (e, s) {
        print("SocialBloc: Error in _onLoadFriendsAndRequests: $e\n$s");
        if (e is FirebaseException && e.code == 'failed-precondition') { emit(const SocialError(message: "Database index missing for friends list. Please check Firebase console.")); }
        else { emit(SocialError(message: "Failed to load friends: ${e.toString()}")); }
        emit(FriendsAndRequestsLoaded(friends: currentFriends, incomingRequests: currentIncomingRequests, outgoingRequests: currentOutgoingRequests)); // Re-emit old data
     }
  }

  Future<void> _onSearchUsers(SearchUsers event, Emitter<SocialState> emit) async {
    // Logic remains the same - reads data and current user's friend status only
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     final query = event.query.trim().toLowerCase(); if (query.isEmpty) { emit(FriendSearchResultsWithStatus(results: const [], query: query)); return; }
     emit(const SocialLoading(isLoadingList: false));
     try {
        print("SocialBloc: Searching users matching '$query' by name/username...");
        // Requires indexes on name_lowercase (Asc) and username (Asc)
        final nameQuery = _firestore.collection('endUsers').where('name_lowercase', isGreaterThanOrEqualTo: query).where('name_lowercase', isLessThanOrEqualTo: '$query\uf8ff').limit(15).get();
        final usernameQuery = _firestore.collection('endUsers').where('username', isEqualTo: query).limit(5).get();
        final results = await Future.wait([nameQuery, usernameQuery]); final nameSnapshot = results[0]; final usernameSnapshot = results[1];
        final Map<String, AuthModel> combinedUserModels = {};
        for (var doc in nameSnapshot.docs) { if (doc.id != _userId) { combinedUserModels[doc.id] = AuthModel.fromFirestore(doc); } }
        for (var doc in usernameSnapshot.docs) { if (doc.id != _userId) { combinedUserModels[doc.id] = AuthModel.fromFirestore(doc); } }

        // Fetch friendship status for each result
        final List<UserSearchResultWithStatus> resultsWithStatus = [];
        for (var userModel in combinedUserModels.values) {
           FriendshipStatus currentStatus = FriendshipStatus.none;
           try {
              final friendDoc = await _friendsCollectionRef?.doc(userModel.uid).get();
              if (friendDoc != null && friendDoc.exists) {
                 final statusString = (friendDoc.data() as Map<String, dynamic>?)?['status'] as String?;
                 switch (statusString) { case 'accepted': currentStatus = FriendshipStatus.friends; break; case 'pending_sent': currentStatus = FriendshipStatus.requestSent; break; case 'pending_received': currentStatus = FriendshipStatus.requestReceived; break; } }
           } catch (e) { print("Error fetching friend status for ${userModel.uid}: $e"); }
           resultsWithStatus.add(UserSearchResultWithStatus(user: userModel, status: currentStatus));
        }
        resultsWithStatus.sort((a, b) => a.user.name.compareTo(b.user.name)); // Sort results
        print("SocialBloc: Found ${resultsWithStatus.length} unique potential users with status.");
        emit(FriendSearchResultsWithStatus(results: resultsWithStatus, query: event.query.trim()));

     } catch (e) {
        print("SocialBloc: Error searching users: $e");
         if (e is FirebaseException && e.code == 'failed-precondition') { emit(const SocialError(message: "Database index missing for user search. Check name and username indexes.")); }
         else { emit(SocialError(message: "Failed to search users: ${e.toString()}")); }
        emit(FriendSearchResultsWithStatus(results: const [], query: event.query.trim())); // Emit empty result on error
     }
  }

  // Includes client-side cross-user write (Needs Cloud Functions ideally)
  Future<void> _onSendFriendRequest(SendFriendRequest event, Emitter<SocialState> emit) async {
     if (_userId == null || _userId == event.targetUserId) { emit(const SocialError(message: "Invalid request.")); return; }
     emit(SocialLoading(processingUserId: event.targetUserId)); // Indicate processing this user
     print("SocialBloc: Sending friend request from $_userId to ${event.targetUserId}");
     try {
        final currentUserModel = await _getCurrentAuthModel(); if (currentUserModel == null) throw Exception("Could not get current user details.");
        final existingLink = await _friendsCollectionRef!.doc(event.targetUserId).get();
        if (existingLink.exists) { final existingStatus = (existingLink.data() as Map<String, dynamic>?)?['status'] as String?; if(existingStatus == 'accepted' || existingStatus == 'pending_sent' || existingStatus == 'pending_received') { throw Exception("You are already friends or a request is pending."); } }
        final WriteBatch batch = _firestore.batch(); final Timestamp now = Timestamp.now();
        final ownFriendRef = _friendsCollectionRef!.doc(event.targetUserId); batch.set(ownFriendRef, { 'status': 'pending_sent', 'userId': event.targetUserId, 'displayName': event.targetUserName, 'profilePicUrl': event.targetUserPicUrl, 'requestSentAt': now, 'senderName': currentUserModel.name, 'senderProfilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, }, SetOptions(merge: true));
        final targetFriendRef = _getFriendsRefForUser(event.targetUserId)?.doc(_userId!); if (targetFriendRef == null) throw Exception("Could not get target user's friend reference."); batch.set(targetFriendRef, { 'status': 'pending_received', 'userId': _userId!, 'displayName': currentUserModel.name, 'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, 'requestReceivedAt': now, }, SetOptions(merge: true));
        print("SocialBloc: WARNING - Attempting client-side cross-user write for friend request."); await batch.commit(); print("SocialBloc: Friend request batch committed.");
        add(const LoadFriendsAndRequests()); // Reload list
        // TODO: Trigger notification via Cloud Function
     } catch (e) { print("SocialBloc: Error sending friend request: $e"); emit(SocialError(message: "Failed to send request: ${e.toString()}")); add(const LoadFriendsAndRequests());} // Reload on error too
  }

  // Includes client-side cross-user write (Needs Cloud Functions ideally)
  Future<void> _onAcceptFriendRequest(AcceptFriendRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(SocialLoading(processingUserId: event.requesterUserId));
     print("SocialBloc: Accepting friend request from ${event.requesterUserId} for user $_userId");
     try {
        final currentUserModel = await _getCurrentAuthModel(); if (currentUserModel == null) throw Exception("Could not get current user details.");
        final WriteBatch batch = _firestore.batch(); final Timestamp now = Timestamp.now();
        final ownFriendRef = _friendsCollectionRef!.doc(event.requesterUserId); batch.update(ownFriendRef, { 'status': 'accepted', 'friendedAt': now, 'displayName': event.requesterUserName, 'profilePicUrl': event.requesterUserPicUrl, 'accepterName': currentUserModel.name, 'accepterProfilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, }); // Added accepter info
        final requesterFriendRef = _getFriendsRefForUser(event.requesterUserId)?.doc(_userId!); if (requesterFriendRef == null) throw Exception("Could not get requester's friend reference."); batch.update(requesterFriendRef, { 'status': 'accepted', 'friendedAt': now, 'displayName': currentUserModel.name, 'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, });
        print("SocialBloc: WARNING - Attempting client-side cross-user write for friend acceptance."); await batch.commit(); print("SocialBloc: Friend acceptance batch committed.");
        emit(const SocialSuccess(message: "Friend request accepted.")); add(const LoadFriendsAndRequests());
        // TODO: Trigger notification via Cloud Function
     } catch (e) { print("SocialBloc: Error accepting friend request: $e"); emit(SocialError(message: "Failed to accept request: ${e.toString()}")); add(const LoadFriendsAndRequests());} // Reload on error too
  }

  // Includes client-side cross-user write (Needs Cloud Functions ideally)
  Future<void> _onDeclineFriendRequest(DeclineFriendRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(SocialLoading(processingUserId: event.requesterUserId));
     print("SocialBloc: Declining friend request from ${event.requesterUserId} for user $_userId");
     try {
        final WriteBatch batch = _firestore.batch();
        final ownFriendRef = _friendsCollectionRef!.doc(event.requesterUserId); batch.delete(ownFriendRef);
        final requesterFriendRef = _getFriendsRefForUser(event.requesterUserId)?.doc(_userId!); if (requesterFriendRef == null) throw Exception("Could not get requester's friend reference."); batch.delete(requesterFriendRef);
        print("SocialBloc: WARNING - Attempting client-side cross-user write for friend decline."); await batch.commit(); print("SocialBloc: Friend decline batch committed.");
        emit(const SocialSuccess(message: "Friend request declined.")); add(const LoadFriendsAndRequests());
     } catch (e) { print("SocialBloc: Error declining friend request: $e"); emit(SocialError(message: "Failed to decline request: ${e.toString()}")); add(const LoadFriendsAndRequests());} // Reload on error too
  }

  // Includes client-side cross-user write (Needs Cloud Functions ideally)
  Future<void> _onRemoveFriend(RemoveFriend event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(SocialLoading(processingUserId: event.friendUserId));
     print("SocialBloc: Removing friend ${event.friendUserId} for user $_userId");
     try {
        final WriteBatch batch = _firestore.batch();
        final ownFriendRef = _friendsCollectionRef!.doc(event.friendUserId); batch.delete(ownFriendRef);
        final friendFriendRef = _getFriendsRefForUser(event.friendUserId)?.doc(_userId!); if (friendFriendRef == null) throw Exception("Could not get friend's friend reference."); batch.delete(friendFriendRef);
        print("SocialBloc: WARNING - Attempting client-side cross-user write for friend removal."); await batch.commit(); print("SocialBloc: Friend removal batch committed.");
        emit(const SocialSuccess(message: "Friend removed.")); add(const LoadFriendsAndRequests());
     } catch (e) { print("SocialBloc: Error removing friend: $e"); emit(SocialError(message: "Failed to remove friend: ${e.toString()}")); add(const LoadFriendsAndRequests());} // Reload on error too
  }

  // Includes client-side cross-user write (Needs Cloud Functions ideally)
  Future<void> _onUnsendFriendRequest(UnsendFriendRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; } // Fixed check
     emit(SocialLoading(processingUserId: event.targetUserId));
     print("SocialBloc: Un-sending friend request from $_userId to ${event.targetUserId}");
     try {
        final WriteBatch batch = _firestore.batch();
        final ownFriendRef = _friendsCollectionRef!.doc(event.targetUserId); batch.delete(ownFriendRef);
        final targetFriendRef = _getFriendsRefForUser(event.targetUserId)?.doc(_userId!); if (targetFriendRef == null) throw Exception("Could not get target user's friend reference."); batch.delete(targetFriendRef);
        print("SocialBloc: WARNING - Attempting client-side cross-user write for unsend request."); await batch.commit(); print("SocialBloc: Unsend request batch committed.");
        add(const LoadFriendsAndRequests()); // Reload lists after cancelling
     } catch (e) { print("SocialBloc: Error un-sending friend request: $e"); emit(SocialError(message: "Failed to cancel request: ${e.toString()}")); add(const LoadFriendsAndRequests());} // Reload on error too
  }

} // End of SocialBloc

