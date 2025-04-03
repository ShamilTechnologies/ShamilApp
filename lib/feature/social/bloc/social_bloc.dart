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
    // Register Family Request Handlers (Add these)
    on<AcceptFamilyRequest>(_onAcceptFamilyRequest);
    on<DeclineFamilyRequest>(_onDeclineFamilyRequest);


    // Friend Event Handlers
    on<LoadFriendsAndRequests>(_onLoadFriendsAndRequests);
    on<SearchUsers>(_onSearchUsers);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<DeclineFriendRequest>(_onDeclineFriendRequest);
    on<RemoveFriend>(_onRemoveFriend);
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

   // *** ADDED: Get reference to a specific user's family subcollection ***
   CollectionReference? _getFamilyRefForUser(String userId) {
      return _firestore.collection('endUsers').doc(userId).collection('familyMembers');
   }


  // --- Family Handlers ---
  Future<void> _onLoadFamilyMembers(LoadFamilyMembers event, Emitter<SocialState> emit) async {
    if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
    // Use 'is!' check for type safety
    // Show loading only if list not already loaded.
    if (state is! FamilyDataLoaded) {
       emit(const SocialLoading(isLoadingList: true));
    }
    try {
      final snapshot = await _familyCollectionRef?.orderBy('addedAt', descending: true).get();
      if (snapshot == null) throw Exception("Could not access family data.");

      // Separate accepted/external members from incoming requests based on status
      final List<FamilyMember> members = [];
      final List<FamilyRequest> requests = [];

      for (var doc in snapshot.docs) {
         final member = FamilyMember.fromFirestore(doc);
         if (member.status == 'pending_received') {
            // Create request object
            requests.add(FamilyRequest.fromFirestore(doc));
         } else if (member.status == 'accepted' || member.status == 'external') {
            members.add(member);
         }
         // Ignore 'pending_sent' or 'declined' for display in main lists
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
        dataToAdd['addedAt'] = now;

        // Validate required fields
        if (dataToAdd['name'] == null || dataToAdd['name'].isEmpty || dataToAdd['relationship'] == null || dataToAdd['relationship'].isEmpty) {
            throw Exception("Name and Relationship are required.");
        }
        if (event.linkedUserModel == null && (dataToAdd['gender'] == null || dataToAdd['gender'].isEmpty)) {
           throw Exception("Gender is required when not linking an existing user.");
        }

        // Logic for linked user (send request) vs external user (add directly)
        if(event.linkedUserModel != null) {
           // --- Send Request Flow ---
           final linkedUser = event.linkedUserModel!;
           final currentUserModel = await _getCurrentAuthModel();
           if (currentUserModel == null) throw Exception("Could not get current user details.");

           // Check if already linked or request pending
           final existingLink = await _familyCollectionRef!.doc(linkedUser.uid).get();
           if (existingLink.exists && (existingLink.data() as Map)['status'] != 'declined') {
              throw Exception("${linkedUser.name} is already linked or has a pending request.");
           }

           final WriteBatch batch = _firestore.batch();

           // 1. Add 'pending_sent' to current user's family subcollection
           final ownFamilyRef = _familyCollectionRef!.doc(linkedUser.uid);
           batch.set(ownFamilyRef, {
              'name': linkedUser.name, 'relationship': dataToAdd['relationship'],
              'userId': linkedUser.uid, 'profilePicUrl': linkedUser.profilePicUrl ?? linkedUser.image,
              'status': 'pending_sent', 'addedAt': now,
              'senderName': currentUserModel.name, // Keep sender info
              'senderProfilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image,
           }, SetOptions(merge: true));

           // 2. Add 'pending_received' to target user's family subcollection
           final targetFamilyRef = _getFamilyRefForUser(linkedUser.uid)?.doc(_userId!);
           if (targetFamilyRef == null) throw Exception("Could not get target user's family reference.");
           batch.set(targetFamilyRef, {
               'name': currentUserModel.name, 'relationship': dataToAdd['relationship'],
               'userId': _userId!, 'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image,
               'status': 'pending_received', 'addedAt': now,
           }, SetOptions(merge: true));

           // *** SECURITY WARNING: Client-side cross-user write. Use Cloud Functions. ***
           print("SocialBloc: WARNING - Attempting client-side cross-user write for family request.");
           await batch.commit();
           print("SocialBloc: Family request sent to ${linkedUser.name}");

           // TODO: Trigger notification via Cloud Function

           emit(const SocialSuccess(message: "Family request sent."));

        } else {
           // --- Add External Contact Directly ---
           // dataToAdd['isAppUser'] = false; // No longer needed
           dataToAdd['userId'] = null;
           dataToAdd['status'] = 'external'; // Mark as external contact
           dataToAdd['nationalId'] = event.memberData['nationalId'];
           dataToAdd['gender'] = event.memberData['gender'];
           dataToAdd['phone'] = event.memberData['phone'] == null || event.memberData['phone'].isEmpty ? null : event.memberData['phone'];
           dataToAdd['email'] = event.memberData['email'] == null || event.memberData['email'].isEmpty ? null : event.memberData['email'];

           await _familyCollectionRef?.add(dataToAdd); // Add document with auto-ID
           print("SocialBloc: Added external family member: ${dataToAdd['name']}");
           emit(const SocialSuccess(message: "Family member added."));
        }

        add(const LoadFamilyMembers()); // Reload list in both cases

     } catch (e) {
        print("SocialBloc: Error adding/requesting family member: $e");
        emit(SocialError(message: "Failed to add family member: ${e.toString()}"));
     }
  }

   Future<void> _onRemoveFamilyMember(RemoveFamilyMember event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false));

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
           if (otherUserFamilyRef == null) throw Exception("Could not get other user's family reference.");
           batch.delete(otherUserFamilyRef);
           // *** SECURITY WARNING: Client-side cross-user write. Use Cloud Functions. ***
           print("SocialBloc: WARNING - Attempting client-side cross-user write for family removal.");
           await batch.commit();
           emit(const SocialSuccess(message: "Family member removed."));
        } else {
           // If external or pending, just delete this doc
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
     final previousState = state;
     emit(const SocialLoading(isLoadingList: false));
     try {
        print("SocialBloc: Searching for user with National ID: ${event.nationalId}");
        final querySnapshot = await _firestore.collection('endUsers').where('nationalId', isEqualTo: event.nationalId).limit(1).get();
        AuthModel? foundUser;
        if (querySnapshot.docs.isNotEmpty) {
           if (querySnapshot.docs.first.id != _userId) { foundUser = AuthModel.fromFirestore(querySnapshot.docs.first); print("SocialBloc: Found user by ID: ${foundUser.name}"); }
           else { print("SocialBloc: User tried to link themselves."); emit(const SocialError(message: "You cannot add yourself as a family member.")); }
        } else { print("SocialBloc: No user found with National ID: ${event.nationalId}"); }

        if (state is! SocialError) { emit(UserSearchResult(foundUser: foundUser, searchedId: event.nationalId)); }
        // Re-emit previous state if it contained loaded data
        if (previousState is FamilyDataLoaded) {
          emit(previousState);
        } else if (previousState is FriendsAndRequestsLoaded) emit(previousState);
        else if (previousState is SocialInitial) add(const LoadFamilyMembers());

     } catch (e) {
        print("SocialBloc: Error searching user by National ID: $e");
        String errorMessage = "Error searching user: ${e.toString()}";
        if (e is FirebaseException && e.code == 'failed-precondition') { errorMessage = "Database index missing for user search."; }
        emit(SocialError(message: errorMessage));
        emit(UserSearchResult(foundUser: null, searchedId: event.nationalId));
        if (previousState is FamilyDataLoaded) {
          emit(previousState);
        } else if (previousState is FriendsAndRequestsLoaded) emit(previousState);
        else if (previousState is SocialInitial) emit(SocialInitial());
     }
  }

  // *** ADDED: Handler for AcceptFamilyRequest event ***
  Future<void> _onAcceptFamilyRequest(AcceptFamilyRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false));
     print("SocialBloc: Accepting family request from ${event.requesterUserId} for user $_userId");

     try {
        final currentUserModel = await _getCurrentAuthModel();
        if (currentUserModel == null) throw Exception("Could not get current user details.");

        final WriteBatch batch = _firestore.batch();
        final Timestamp now = Timestamp.now();

        // 1. Update own family subcollection: change status to 'accepted'
        final ownFamilyRef = _familyCollectionRef!.doc(event.requesterUserId);
        batch.update(ownFamilyRef, {
           'status': 'accepted',
           'addedAt': now, // Update timestamp to acceptance time
           // Update denormalized data just in case
           'name': event.requesterName,
           'profilePicUrl': event.requesterProfilePicUrl,
           'relationship': event.requesterRelationship, // Keep relationship set by requester
        });

        // 2. Update requester's family subcollection: change status to 'accepted'
        final requesterFamilyRef = _getFamilyRefForUser(event.requesterUserId)?.doc(_userId!);
         if (requesterFamilyRef == null) throw Exception("Could not get requester's family reference.");
        batch.update(requesterFamilyRef, {
           'status': 'accepted',
           'addedAt': now,
           // Update denormalized data just in case
           'name': currentUserModel.name,
           'profilePicUrl': currentUserModel.profilePicUrl ?? currentUserModel.image,
           // Relationship here reflects what the *requester* set for *you* - might need adjustment
        });

        // *** SECURITY WARNING: Client-side cross-user write. Use Cloud Functions. ***
        print("SocialBloc: WARNING - Attempting client-side cross-user write for family acceptance.");
        await batch.commit();
        print("SocialBloc: Family acceptance batch committed.");

        emit(const SocialSuccess(message: "Family request accepted."));
        add(const LoadFamilyMembers()); // Reload list

     } catch (e) {
        print("SocialBloc: Error accepting family request: $e");
        emit(SocialError(message: "Failed to accept request: ${e.toString()}"));
     }
  }

   // *** ADDED: Handler for DeclineFamilyRequest event ***
  Future<void> _onDeclineFamilyRequest(DeclineFamilyRequest event, Emitter<SocialState> emit) async {
     if (_userId == null) { emit(const SocialError(message: "User not logged in.")); return; }
     emit(const SocialLoading(isLoadingList: false));
      print("SocialBloc: Declining family request from ${event.requesterUserId} for user $_userId");

     try {
        final WriteBatch batch = _firestore.batch();

        // 1. Delete own family subcollection document (remove 'pending_received')
        final ownFamilyRef = _familyCollectionRef!.doc(event.requesterUserId);
        batch.delete(ownFamilyRef);

        // 2. Delete requester's family subcollection document (remove 'pending_sent')
        final requesterFamilyRef = _getFamilyRefForUser(event.requesterUserId)?.doc(_userId!);
        if (requesterFamilyRef == null) throw Exception("Could not get requester's family reference.");
        batch.delete(requesterFamilyRef);

        // *** SECURITY WARNING: Client-side cross-user write. Use Cloud Functions. ***
        print("SocialBloc: WARNING - Attempting client-side cross-user write for family decline.");
        await batch.commit();
        print("SocialBloc: Family decline batch committed.");

        emit(const SocialSuccess(message: "Family request declined."));
        add(const LoadFamilyMembers()); // Reload list

     } catch (e) {
        print("SocialBloc: Error declining family request: $e");
        emit(SocialError(message: "Failed to decline request: ${e.toString()}"));
     }
  }


  // --- Friend Handlers ---
  Future<void> _onLoadFriendsAndRequests(LoadFriendsAndRequests event, Emitter<SocialState> emit) async { /* ... as before ... */ }
  Future<void> _onSearchUsers(SearchUsers event, Emitter<SocialState> emit) async { /* ... as before ... */ }
  Future<void> _onSendFriendRequest(SendFriendRequest event, Emitter<SocialState> emit) async { /* ... as before ... */ }
  Future<void> _onAcceptFriendRequest(AcceptFriendRequest event, Emitter<SocialState> emit) async { /* ... as before ... */ }
  Future<void> _onDeclineFriendRequest(DeclineFriendRequest event, Emitter<SocialState> emit) async { /* ... as before ... */ }
  Future<void> _onRemoveFriend(RemoveFriend event, Emitter<SocialState> emit) async { /* ... as before ... */ }

}

