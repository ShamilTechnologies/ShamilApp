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
    on<LoadFriendsAndRequests>(_onLoadFriendsAndRequests);
    on<SearchUsers>(_onSearchUsers);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<DeclineFriendRequest>(_onDeclineFriendRequest);
    on<RemoveFriend>(_onRemoveFriend);
    on<UnsendFriendRequest>(_onUnsendFriendRequest); // Added
  }

  // Helper to get current user UID
  String? get _userId => _auth.currentUser?.uid;

  // Helper to get current user details (needed for denormalization)
  // Note: Fetches every time. Consider caching or getting from AuthBloc state.
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
    // Show loading only if list isn't already loaded.
    if (state is! FamilyDataLoaded) {
       emit(const SocialLoading(isLoadingList: true));
    }
    try {
      // Query to get all documents, order by addedAt
      final snapshot = await _familyCollectionRef?.orderBy('addedAt', descending: true).get();
      if (snapshot == null) throw Exception("Could not access family data.");

      // Separate accepted/external members from incoming requests based on status
      final List<FamilyMember> members = [];
      final List<FamilyRequest> requests = [];

      for (var doc in snapshot.docs) {
         final member = FamilyMember.fromFirestore(doc);
         if (member.status == 'pending_received') {
            requests.add(FamilyRequest.fromFirestore(doc)); // Use factory
         } else if (member.status == 'accepted' || member.status == 'external') {
            members.add(member);
         }
         // Ignore 'pending_sent' or 'declined' statuses for display in these lists
      }

      // Emit the combined state for family data
      emit(FamilyDataLoaded(familyMembers: members, incomingRequests: requests));
      print("SocialBloc: Loaded ${members.length} family members and ${requests.length} requests.");

    } catch (e) {
      print("SocialBloc: Error loading family members: $e");
      emit(SocialError(message: "Failed to load family members: ${e.toString()}"));
    }
  }

  Future<void> _onAddFamilyMember(AddFamilyMember event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false)); // Indicate action loading

     try {
        final dataToAdd = Map<String, dynamic>.from(event.memberData);
        final Timestamp now = Timestamp.now();
        dataToAdd['addedAt'] = now; // Use consistent timestamp

        // Validate required fields from the form/data map
        if (dataToAdd['name'] == null || dataToAdd['name'].isEmpty || dataToAdd['relationship'] == null || dataToAdd['relationship'].isEmpty) {
            throw Exception("Name and Relationship are required.");
        }
        // Gender is required only if NOT linking an existing user (who already has a gender)
        if (event.linkedUserModel == null && (dataToAdd['gender'] == null || dataToAdd['gender'].isEmpty)) {
           throw Exception("Gender is required when not linking an existing user.");
        }

        // Logic for linked user (send request) vs external user (add directly)
        if(event.linkedUserModel != null) {
           // --- Send Request Flow ---
           final linkedUser = event.linkedUserModel!;
           final currentUserModel = await _getCurrentAuthModel();
           if (currentUserModel == null) throw Exception("Could not get current user details.");

           // Check if already linked or request pending in own list
           final existingLink = await _familyCollectionRef!.doc(linkedUser.uid).get();
           if (existingLink.exists) {
              final existingStatus = (existingLink.data() as Map<String, dynamic>?)?['status'] as String?;
              // Prevent sending if already accepted or pending (sent or received)
              if (existingStatus == 'accepted' || existingStatus == 'pending_sent' || existingStatus == 'pending_received') {
                 throw Exception("${linkedUser.name} is already linked or has a pending request.");
              }
              // Allow overwriting if previously declined/removed (optional)
           }

           final WriteBatch batch = _firestore.batch();

           // 1. Add 'pending_sent' to current user's family subcollection (doc ID = linked user's UID)
           final ownFamilyRef = _familyCollectionRef!.doc(linkedUser.uid);
           batch.set(ownFamilyRef, {
              'name': linkedUser.name, // Use linked user's name
              'relationship': dataToAdd['relationship'], // Use relationship from form
              'userId': linkedUser.uid,
              'profilePicUrl': linkedUser.profilePicUrl ?? linkedUser.image,
              'status': 'pending_sent',
              'addedAt': now, // Timestamp of request
              // Store sender info (optional but helpful for recipient)
              'senderName': currentUserModel.name,
              'senderProfilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image,
           }, SetOptions(merge: true)); // Merge in case doc existed but was declined

           // 2. Add 'pending_received' to target user's family subcollection (doc ID = current user's UID)
           final targetFamilyRef = _getFamilyRefForUser(linkedUser.uid)?.doc(_userId!);
           if (targetFamilyRef == null) throw Exception("Could not get target user's family reference.");
           batch.set(targetFamilyRef, {
               'name': currentUserModel.name, // Use current user's name
               'relationship': dataToAdd['relationship'], // Use relationship from form
               'userId': _userId!,
               'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image,
               'status': 'pending_received',
               'addedAt': now, // Timestamp of request
           }, SetOptions(merge: true));

           // *** SECURITY WARNING: Client-side cross-user write. Use Cloud Functions. ***
           print("SocialBloc: WARNING - Attempting client-side cross-user write for family request.");
           await batch.commit();
           print("SocialBloc: Family request sent to ${linkedUser.name}");

           // TODO: Trigger notification via Cloud Function based on targetFamilyRef creation/update

           emit(const SocialSuccess(message: "Family request sent."));

        } else {
           // --- Add External Contact Directly ---
           // dataToAdd['isAppUser'] = false; // Status field replaces this
           dataToAdd['userId'] = null;
           dataToAdd['status'] = 'external'; // Mark as external contact
           dataToAdd['nationalId'] = event.memberData['nationalId']; // Store entered ID if any
           dataToAdd['gender'] = event.memberData['gender']; // Store entered gender
           // Ensure optional fields are null if empty, otherwise store value
           dataToAdd['phone'] = event.memberData['phone'] == null || event.memberData['phone'].isEmpty ? null : event.memberData['phone'];
           dataToAdd['email'] = event.memberData['email'] == null || event.memberData['email'].isEmpty ? null : event.memberData['email'];

           await _familyCollectionRef?.add(dataToAdd); // Add document with Firestore auto-generated ID
           print("SocialBloc: Added external family member: ${dataToAdd['name']}");
           emit(const SocialSuccess(message: "Family member added."));
        }

        add(const LoadFamilyMembers()); // Reload family list after adding/requesting

     } catch (e) {
        print("SocialBloc: Error adding/requesting family member: $e");
        emit(SocialError(message: "Failed to add family member: ${e.toString()}"));
     }
  }

   Future<void> _onRemoveFamilyMember(RemoveFamilyMember event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false)); // Indicate action loading

     try {
        final docRef = _familyCollectionRef!.doc(event.memberDocId);
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
           print("SocialBloc: Family member document ${event.memberDocId} not found for removal.");
           emit(const SocialSuccess(message: "Member already removed."));
           add(const LoadFamilyMembers()); return;
        }
        final memberData = FamilyMember.fromFirestore(docSnapshot);

        // If it was an accepted link ('accepted' status), need to remove from both sides
        if (memberData.status == 'accepted' && memberData.userId != null) {
           print("SocialBloc: Removing accepted family link: ${memberData.name}");
           final WriteBatch batch = _firestore.batch();
           batch.delete(docRef); // Delete from own subcollection

           // Delete corresponding entry from the other user's subcollection
           final otherUserFamilyRef = _getFamilyRefForUser(memberData.userId!)?.doc(_userId!);
           if (otherUserFamilyRef == null) {
              print("SocialBloc: Warning - Could not get other user's family reference for removal. Proceeding with self removal.");
              // Decide if removal should fail or just remove self entry
              // throw Exception("Could not get other user's family reference.");
           } else {
              batch.delete(otherUserFamilyRef); // Add deletion of other user's doc to batch
           }

           // *** SECURITY WARNING: Client-side cross-user write. Use Cloud Functions. ***
           print("SocialBloc: WARNING - Attempting client-side cross-user write for family removal.");
           await batch.commit();
           emit(const SocialSuccess(message: "Family member removed."));
        } else {
           // If external or pending (e.g., pending_sent), just delete this user's doc
           print("SocialBloc: Removing external/pending family entry: ${memberData.name}");
           await docRef.delete();
           emit(const SocialSuccess(message: "Family member removed."));
        }
        add(const LoadFamilyMembers()); // Reload list
     } catch (e) {
        print("SocialBloc: Error removing family member: $e");
        emit(SocialError(message: "Failed to remove family member: ${e.toString()}"));
     }
   }

  Future<void> _onSearchUserByNationalId(SearchUserByNationalId event, Emitter<SocialState> emit) async {
     final previousState = state; // Keep track of previous state
     emit(const SocialLoading(isLoadingList: false)); // Indicate search loading

     try {
        print("SocialBloc: Searching for user with National ID: ${event.nationalId}");
        // *** Firestore Index Required: on 'endUsers' collection for 'nationalId' field ***
        final querySnapshot = await _firestore
           .collection('endUsers')
           .where('nationalId', isEqualTo: event.nationalId)
           .limit(1)
           .get();

        AuthModel? foundUser;
        if (querySnapshot.docs.isNotEmpty) {
           // Ensure we don't link the user to themselves
           if (querySnapshot.docs.first.id != _userId) {
             foundUser = AuthModel.fromFirestore(querySnapshot.docs.first);
             print("SocialBloc: Found user by ID: ${foundUser.name}");
           } else {
             print("SocialBloc: User tried to link themselves.");
             // Emit specific error state instead of just printing
             emit(const SocialError(message: "You cannot add yourself as a family member."));
             // Still emit search result with null user so UI can clear previous result
             emit(UserSearchResult(foundUser: null, searchedId: event.nationalId));
             // Re-emit previous state if needed (e.g., FamilyDataLoaded)
             if (previousState is FamilyDataLoaded) emit(previousState);
             return; // Stop processing
           }
        } else {
           print("SocialBloc: No user found with National ID: ${event.nationalId}");
        }

        // Emit result (foundUser will be null if not found)
        emit(UserSearchResult(foundUser: foundUser, searchedId: event.nationalId));

        // Re-emit previous state if it contained loaded data, so UI doesn't get stuck
        if (previousState is FamilyDataLoaded) {
           emit(previousState);
        } else if (previousState is FriendsAndRequestsLoaded) emit(previousState);
        // If previous state was initial/loading, load family data now after search completes
        else if (previousState is SocialInitial || previousState is SocialLoading) {
           add(const LoadFamilyMembers());
        }

     } catch (e) {
        print("SocialBloc: Error searching user by National ID: $e");
        String errorMessage = "Error searching user: ${e.toString()}";
        if (e is FirebaseException && e.code == 'failed-precondition') {
           errorMessage = "Database index missing for user search.";
        }
        emit(SocialError(message: errorMessage));
        // Emit search result with null user on error too
        emit(UserSearchResult(foundUser: null, searchedId: event.nationalId));
        // Re-emit previous loaded state if available after error
        if (previousState is FamilyDataLoaded) {
           emit(previousState);
        } else if (previousState is FriendsAndRequestsLoaded) emit(previousState);
        else if (previousState is SocialInitial) emit(SocialInitial()); // Revert to initial on error if nothing else loaded
     }
  }

  // Handler for AcceptFamilyRequest event
  Future<void> _onAcceptFamilyRequest(AcceptFamilyRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false));
     print("SocialBloc: Accepting family request from ${event.requesterUserId} for user $_userId");

     try {
        final currentUserModel = await _getCurrentAuthModel();
        if (currentUserModel == null) throw Exception("Could not get current user details.");

        final WriteBatch batch = _firestore.batch();
        final Timestamp now = Timestamp.now();

        // 1. Update own family subcollection doc (requester's ID): change status to 'accepted'
        final ownFamilyRef = _familyCollectionRef!.doc(event.requesterUserId);
        batch.update(ownFamilyRef, {
           'status': 'accepted',
           'addedAt': now, // Update timestamp to acceptance time
           // Update denormalized data from event just in case
           'name': event.requesterName,
           'profilePicUrl': event.requesterProfilePicUrl,
           'relationship': event.requesterRelationship,
        });

        // 2. Update requester's family subcollection doc (current user's ID): change status to 'accepted'
        final requesterFamilyRef = _getFamilyRefForUser(event.requesterUserId)?.doc(_userId!);
         if (requesterFamilyRef == null) throw Exception("Could not get requester's family reference.");
        batch.update(requesterFamilyRef, {
           'status': 'accepted',
           'addedAt': now,
           // Update denormalized data from current user model
           'name': currentUserModel.name,
           'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image,
           // Keep the relationship the requester set for the current user
        });

        // *** SECURITY WARNING: Client-side cross-user write. Use Cloud Functions. ***
        print("SocialBloc: WARNING - Attempting client-side cross-user write for family acceptance.");
        await batch.commit();
        print("SocialBloc: Family acceptance batch committed.");

        // TODO: Trigger notification to requester via Cloud Function

        emit(const SocialSuccess(message: "Family request accepted."));
        add(const LoadFamilyMembers()); // Reload list

     } catch (e) {
        print("SocialBloc: Error accepting family request: $e");
        emit(SocialError(message: "Failed to accept request: ${e.toString()}"));
     }
  }

   // Handler for DeclineFamilyRequest event
  Future<void> _onDeclineFamilyRequest(DeclineFamilyRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false));
      print("SocialBloc: Declining family request from ${event.requesterUserId} for user $_userId");

     try {
        final WriteBatch batch = _firestore.batch();

        // 1. Delete own family subcollection document (the 'pending_received' one)
        final ownFamilyRef = _familyCollectionRef!.doc(event.requesterUserId);
        batch.delete(ownFamilyRef);

        // 2. Delete requester's family subcollection document (the 'pending_sent' one)
        final requesterFamilyRef = _getFamilyRefForUser(event.requesterUserId)?.doc(_userId!);
        if (requesterFamilyRef == null) throw Exception("Could not get requester's family reference.");
        batch.delete(requesterFamilyRef);

        // *** SECURITY WARNING: Client-side cross-user write. Use Cloud Functions. ***
        print("SocialBloc: WARNING - Attempting client-side cross-user write for family decline.");
        await batch.commit();
        print("SocialBloc: Family decline batch committed.");

        // Optional: Send 'request declined' notification via Cloud Function

        emit(const SocialSuccess(message: "Family request declined."));
        add(const LoadFamilyMembers()); // Reload list

     } catch (e) {
        print("SocialBloc: Error declining family request: $e");
        emit(SocialError(message: "Failed to decline request: ${e.toString()}"));
     }
  }


  // --- Friend Handlers ---
  Future<void> _onLoadFriendsAndRequests(LoadFriendsAndRequests event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     List<Friend> currentFriends = []; List<FriendRequest> currentIncomingRequests = []; List<FriendRequest> currentOutgoingRequests = [];
     if (state is FriendsAndRequestsLoaded) { currentFriends = (state as FriendsAndRequestsLoaded).friends; currentIncomingRequests = (state as FriendsAndRequestsLoaded).incomingRequests; currentOutgoingRequests = (state as FriendsAndRequestsLoaded).outgoingRequests; }
     if (state is! FriendsAndRequestsLoaded) { emit(const SocialLoading(isLoadingList: true)); }
     else { print("SocialBloc: LoadFriends - Refreshing list (already loaded)."); }
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

  Future<void> _onSendFriendRequest(SendFriendRequest event, Emitter<SocialState> emit) async {
     if (_userId == null || _userId == event.targetUserId) { /* ... initial checks ... */ return; }
     emit(const SocialLoading(isLoadingList: false)); print("SocialBloc: Sending friend request from $_userId to ${event.targetUserId}");
     try {
        final currentUserModel = await _getCurrentAuthModel(); if (currentUserModel == null) throw Exception("Could not get current user details.");
        final existingLink = await _friendsCollectionRef!.doc(event.targetUserId).get();
        if (existingLink.exists) { final existingStatus = (existingLink.data() as Map<String, dynamic>?)?['status'] as String?; if(existingStatus == 'accepted' || existingStatus == 'pending_sent' || existingStatus == 'pending_received') { throw Exception("You are already friends or a request is pending."); } }
        final WriteBatch batch = _firestore.batch(); final Timestamp now = Timestamp.now();
        final ownFriendRef = _friendsCollectionRef!.doc(event.targetUserId); batch.set(ownFriendRef, { 'status': 'pending_sent', 'userId': event.targetUserId, 'displayName': event.targetUserName, 'profilePicUrl': event.targetUserPicUrl, 'requestSentAt': now, 'senderName': currentUserModel.name, 'senderProfilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, }, SetOptions(merge: true)); // Added sender info
        final targetFriendRef = _getFriendsRefForUser(event.targetUserId)?.doc(_userId!); if (targetFriendRef == null) throw Exception("Could not get target user's friend reference."); batch.set(targetFriendRef, { 'status': 'pending_received', 'userId': _userId!, 'displayName': currentUserModel.name, 'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, 'requestReceivedAt': now, }, SetOptions(merge: true));
        print("SocialBloc: WARNING - Attempting client-side cross-user write for friend request."); await batch.commit(); print("SocialBloc: Friend request batch committed.");
        emit(const SocialSuccess(message: "Friend request sent."));
        add(const LoadFriendsAndRequests()); // Reload list after sending
        // TODO: Trigger notification via Cloud Function
     } catch (e) { print("SocialBloc: Error sending friend request: $e"); emit(SocialError(message: "Failed to send request: ${e.toString()}")); }
  }

  Future<void> _onAcceptFriendRequest(AcceptFriendRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { /* ... check ... */ return; }
     emit(const SocialLoading(isLoadingList: false)); print("SocialBloc: Accepting friend request from ${event.requesterUserId} for user $_userId");
     try {
        final currentUserModel = await _getCurrentAuthModel(); if (currentUserModel == null) throw Exception("Could not get current user details.");
        final WriteBatch batch = _firestore.batch(); final Timestamp now = Timestamp.now();
        final ownFriendRef = _friendsCollectionRef!.doc(event.requesterUserId); batch.update(ownFriendRef, { 'status': 'accepted', 'friendedAt': now, 'displayName': event.requesterUserName, 'profilePicUrl': event.requesterUserPicUrl, });
        final requesterFriendRef = _getFriendsRefForUser(event.requesterUserId)?.doc(_userId!); if (requesterFriendRef == null) throw Exception("Could not get requester's friend reference."); batch.update(requesterFriendRef, { 'status': 'accepted', 'friendedAt': now, 'displayName': currentUserModel.name, 'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image, });
        print("SocialBloc: WARNING - Attempting client-side cross-user write for friend acceptance."); await batch.commit(); print("SocialBloc: Friend acceptance batch committed.");
        emit(const SocialSuccess(message: "Friend request accepted.")); add(const LoadFriendsAndRequests());
        // TODO: Trigger notification via Cloud Function
     } catch (e) { print("SocialBloc: Error accepting friend request: $e"); emit(SocialError(message: "Failed to accept request: ${e.toString()}")); }
  }

  Future<void> _onDeclineFriendRequest(DeclineFriendRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { /* ... check ... */ return; }
     emit(const SocialLoading(isLoadingList: false)); print("SocialBloc: Declining friend request from ${event.requesterUserId} for user $_userId");
     try {
        final WriteBatch batch = _firestore.batch();
        final ownFriendRef = _friendsCollectionRef!.doc(event.requesterUserId); batch.delete(ownFriendRef);
        final requesterFriendRef = _getFriendsRefForUser(event.requesterUserId)?.doc(_userId!); if (requesterFriendRef == null) throw Exception("Could not get requester's friend reference."); batch.delete(requesterFriendRef);
        print("SocialBloc: WARNING - Attempting client-side cross-user write for friend decline."); await batch.commit(); print("SocialBloc: Friend decline batch committed.");
        emit(const SocialSuccess(message: "Friend request declined.")); add(const LoadFriendsAndRequests());
     } catch (e) { print("SocialBloc: Error declining friend request: $e"); emit(SocialError(message: "Failed to decline request: ${e.toString()}")); }
  }

  Future<void> _onRemoveFriend(RemoveFriend event, Emitter<SocialState> emit) async {
     if (_userId == null) { /* ... check ... */ return; }
     emit(const SocialLoading(isLoadingList: false)); print("SocialBloc: Removing friend ${event.friendUserId} for user $_userId");
     try {
        final WriteBatch batch = _firestore.batch();
        final ownFriendRef = _friendsCollectionRef!.doc(event.friendUserId); batch.delete(ownFriendRef);
        final friendFriendRef = _getFriendsRefForUser(event.friendUserId)?.doc(_userId!); if (friendFriendRef == null) throw Exception("Could not get friend's friend reference."); batch.delete(friendFriendRef);
        print("SocialBloc: WARNING - Attempting client-side cross-user write for friend removal."); await batch.commit(); print("SocialBloc: Friend removal batch committed.");
        emit(const SocialSuccess(message: "Friend removed.")); add(const LoadFriendsAndRequests());
     } catch (e) { print("SocialBloc: Error removing friend: $e"); emit(SocialError(message: "Failed to remove friend: ${e.toString()}")); }
  }

  Future<void> _onUnsendFriendRequest(UnsendFriendRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { /* ... check ... */ return; }
     emit(const SocialLoading(isLoadingList: false)); print("SocialBloc: Un-sending friend request from $_userId to ${event.targetUserId}");
     try {
        final WriteBatch batch = _firestore.batch();
        // Delete own pending_sent doc
        final ownFriendRef = _friendsCollectionRef!.doc(event.targetUserId); batch.delete(ownFriendRef);
        // Delete target's pending_received doc
        final targetFriendRef = _getFriendsRefForUser(event.targetUserId)?.doc(_userId!); if (targetFriendRef == null) throw Exception("Could not get target user's friend reference."); batch.delete(targetFriendRef);
        print("SocialBloc: WARNING - Attempting client-side cross-user write for unsend request."); await batch.commit(); print("SocialBloc: Unsend request batch committed.");
        emit(const SocialSuccess(message: "Friend request cancelled."));
        add(const LoadFriendsAndRequests()); // Reload lists after cancelling
     } catch (e) { print("SocialBloc: Error un-sending friend request: $e"); emit(SocialError(message: "Failed to cancel request: ${e.toString()}")); }
  }

}

