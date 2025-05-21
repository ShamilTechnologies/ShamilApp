import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamil_mobile_app/feature/community/models/community_event_model.dart';
import 'package:shamil_mobile_app/feature/community/models/group_host_model.dart';
import 'package:shamil_mobile_app/feature/community/models/tournament_model.dart';

abstract class CommunityRepository {
  // Events methods
  Future<List<CommunityEventModel>> getEvents({String? governorateId});
  Future<CommunityEventModel?> getEventById(String eventId);
  Future<bool> joinEvent(String eventId, String userId, String userName);
  Future<bool> leaveEvent(String eventId, String userId);

  // Group Hosts methods
  Future<List<GroupHostModel>> getGroupHosts({String? governorateId});
  Future<GroupHostModel?> getGroupHostById(String groupId);
  Future<bool> joinGroupHost(
      String groupId, String userId, String userName, String imageUrl);
  Future<bool> leaveGroupHost(String groupId, String userId);
  Future<String?> createGroupHost(GroupHostModel group);

  // Tournament methods
  Future<List<TournamentModel>> getTournaments({String? governorateId});
  Future<TournamentModel?> getTournamentById(String tournamentId);
  Future<bool> joinTournament(
      String tournamentId, String userId, String userName);
  Future<bool> leaveTournament(String tournamentId, String userId);
}

class CommunityRepositoryImpl implements CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Events Collection Reference
  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('community_events');

  // Group Hosts Collection Reference
  CollectionReference<Map<String, dynamic>> get _groupHostsCollection =>
      _firestore.collection('group_hosts');

  // Tournaments Collection Reference
  CollectionReference<Map<String, dynamic>> get _tournamentsCollection =>
      _firestore.collection('tournaments');

  @override
  Future<List<CommunityEventModel>> getEvents({String? governorateId}) async {
    try {
      Query<Map<String, dynamic>> query = _eventsCollection
          .orderBy('date', descending: false)
          .where('status', whereIn: ['upcoming', 'ongoing']);

      if (governorateId != null) {
        query = query.where('governorateId', isEqualTo: governorateId);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CommunityEventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  @override
  Future<CommunityEventModel?> getEventById(String eventId) async {
    try {
      final docSnapshot = await _eventsCollection.doc(eventId).get();

      if (docSnapshot.exists) {
        return CommunityEventModel.fromFirestore(docSnapshot);
      }

      return null;
    } catch (e) {
      print('Error fetching event by ID: $e');
      return null;
    }
  }

  @override
  Future<bool> joinEvent(String eventId, String userId, String userName) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final eventRef = _eventsCollection.doc(eventId);
        final eventSnapshot = await transaction.get(eventRef);

        if (!eventSnapshot.exists) {
          throw Exception('Event does not exist');
        }

        final currentEvent = CommunityEventModel.fromFirestore(eventSnapshot);

        if (currentEvent.participantIds.contains(userId)) {
          throw Exception('User already joined this event');
        }

        if (currentEvent.participantsCount >= currentEvent.maxParticipants) {
          throw Exception('Event is full');
        }

        // Add user to participants
        final newParticipantIds = List<String>.from(currentEvent.participantIds)
          ..add(userId);

        transaction.update(eventRef, {
          'participantIds': newParticipantIds,
          'participantsCount': currentEvent.participantsCount + 1,
        });
      });

      return true;
    } catch (e) {
      print('Error joining event: $e');
      return false;
    }
  }

  @override
  Future<bool> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final eventRef = _eventsCollection.doc(eventId);
        final eventSnapshot = await transaction.get(eventRef);

        if (!eventSnapshot.exists) {
          throw Exception('Event does not exist');
        }

        final currentEvent = CommunityEventModel.fromFirestore(eventSnapshot);

        if (!currentEvent.participantIds.contains(userId)) {
          throw Exception('User is not part of this event');
        }

        // Remove user from participants
        final newParticipantIds = List<String>.from(currentEvent.participantIds)
          ..removeWhere((id) => id == userId);

        transaction.update(eventRef, {
          'participantIds': newParticipantIds,
          'participantsCount': currentEvent.participantsCount - 1,
        });
      });

      return true;
    } catch (e) {
      print('Error leaving event: $e');
      return false;
    }
  }

  @override
  Future<List<GroupHostModel>> getGroupHosts({String? governorateId}) async {
    try {
      Query<Map<String, dynamic>> query = _groupHostsCollection
          .orderBy('dateTime', descending: false)
          .where('status', isEqualTo: 'open');

      if (governorateId != null) {
        query = query.where('governorateId', isEqualTo: governorateId);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => GroupHostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching group hosts: $e');
      return [];
    }
  }

  @override
  Future<GroupHostModel?> getGroupHostById(String groupId) async {
    try {
      final docSnapshot = await _groupHostsCollection.doc(groupId).get();

      if (docSnapshot.exists) {
        return GroupHostModel.fromFirestore(docSnapshot);
      }

      return null;
    } catch (e) {
      print('Error fetching group host by ID: $e');
      return null;
    }
  }

  @override
  Future<bool> joinGroupHost(
      String groupId, String userId, String userName, String imageUrl) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _groupHostsCollection.doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception('Group does not exist');
        }

        final currentGroup = GroupHostModel.fromFirestore(groupSnapshot);

        // Check if the user is already a participant
        if (currentGroup.participants.any((p) => p.userId == userId)) {
          throw Exception('User already joined this group');
        }

        if (currentGroup.currentParticipants >= currentGroup.maxParticipants) {
          throw Exception('Group is full');
        }

        // Create new participant
        final newParticipant = ParticipantModel(
          userId: userId,
          name: userName,
          imageUrl: imageUrl,
          joinedAt: DateTime.now(),
          status: 'pending',
        );

        // Add participant to the list
        final newParticipants =
            List<ParticipantModel>.from(currentGroup.participants)
              ..add(newParticipant);

        transaction.update(groupRef, {
          'participants': newParticipants.map((p) => p.toMap()).toList(),
          'currentParticipants': currentGroup.currentParticipants + 1,
          'status': currentGroup.currentParticipants + 1 >=
                  currentGroup.maxParticipants
              ? 'full'
              : 'open',
        });
      });

      return true;
    } catch (e) {
      print('Error joining group host: $e');
      return false;
    }
  }

  @override
  Future<bool> leaveGroupHost(String groupId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _groupHostsCollection.doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception('Group does not exist');
        }

        final currentGroup = GroupHostModel.fromFirestore(groupSnapshot);

        // Check if the user is a participant
        if (!currentGroup.participants.any((p) => p.userId == userId)) {
          throw Exception('User is not part of this group');
        }

        // Remove participant from the list
        final newParticipants =
            List<ParticipantModel>.from(currentGroup.participants)
              ..removeWhere((p) => p.userId == userId);

        transaction.update(groupRef, {
          'participants': newParticipants.map((p) => p.toMap()).toList(),
          'currentParticipants': currentGroup.currentParticipants - 1,
          'status': 'open', // Set back to open if a participant leaves
        });
      });

      return true;
    } catch (e) {
      print('Error leaving group host: $e');
      return false;
    }
  }

  @override
  Future<String?> createGroupHost(GroupHostModel group) async {
    try {
      final docRef = await _groupHostsCollection.add(group.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating group host: $e');
      return null;
    }
  }

  @override
  Future<List<TournamentModel>> getTournaments({String? governorateId}) async {
    try {
      Query<Map<String, dynamic>> query = _tournamentsCollection
          .orderBy('startDate', descending: false)
          .where('status', whereIn: ['registration', 'upcoming', 'ongoing']);

      if (governorateId != null) {
        query = query.where('governorateId', isEqualTo: governorateId);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => TournamentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching tournaments: $e');
      return [];
    }
  }

  @override
  Future<TournamentModel?> getTournamentById(String tournamentId) async {
    try {
      final docSnapshot = await _tournamentsCollection.doc(tournamentId).get();

      if (docSnapshot.exists) {
        return TournamentModel.fromFirestore(docSnapshot);
      }

      return null;
    } catch (e) {
      print('Error fetching tournament by ID: $e');
      return null;
    }
  }

  @override
  Future<bool> joinTournament(
      String tournamentId, String userId, String userName) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final tournamentRef = _tournamentsCollection.doc(tournamentId);
        final tournamentSnapshot = await transaction.get(tournamentRef);

        if (!tournamentSnapshot.exists) {
          throw Exception('Tournament does not exist');
        }

        final currentTournament =
            TournamentModel.fromFirestore(tournamentSnapshot);

        if (currentTournament.status != 'registration') {
          throw Exception('Tournament registration is closed');
        }

        if (currentTournament.participantIds.contains(userId)) {
          throw Exception('User already joined this tournament');
        }

        if (currentTournament.participantsCount >=
            currentTournament.maxParticipants) {
          throw Exception('Tournament is full');
        }

        // Add user to participants
        final newParticipantIds =
            List<String>.from(currentTournament.participantIds)..add(userId);

        transaction.update(tournamentRef, {
          'participantIds': newParticipantIds,
          'participantsCount': currentTournament.participantsCount + 1,
        });
      });

      return true;
    } catch (e) {
      print('Error joining tournament: $e');
      return false;
    }
  }

  @override
  Future<bool> leaveTournament(String tournamentId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final tournamentRef = _tournamentsCollection.doc(tournamentId);
        final tournamentSnapshot = await transaction.get(tournamentRef);

        if (!tournamentSnapshot.exists) {
          throw Exception('Tournament does not exist');
        }

        final currentTournament =
            TournamentModel.fromFirestore(tournamentSnapshot);

        if (currentTournament.status != 'registration') {
          throw Exception('Tournament has already started, cannot leave');
        }

        if (!currentTournament.participantIds.contains(userId)) {
          throw Exception('User is not part of this tournament');
        }

        // Remove user from participants
        final newParticipantIds =
            List<String>.from(currentTournament.participantIds)
              ..removeWhere((id) => id == userId);

        transaction.update(tournamentRef, {
          'participantIds': newParticipantIds,
          'participantsCount': currentTournament.participantsCount - 1,
        });
      });

      return true;
    } catch (e) {
      print('Error leaving tournament: $e');
      return false;
    }
  }
}
