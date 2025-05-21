import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/community/models/community_event_model.dart';
import 'package:shamil_mobile_app/feature/community/models/group_host_model.dart';
import 'package:shamil_mobile_app/feature/community/models/tournament_model.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

// General events
class LoadCommunityData extends CommunityEvent {
  final String? governorateId;

  const LoadCommunityData({this.governorateId});

  @override
  List<Object?> get props => [governorateId];
}

class RefreshCommunityData extends CommunityEvent {
  final bool showMessage;
  final String? governorateId;

  const RefreshCommunityData({
    this.showMessage = false,
    this.governorateId,
  });

  @override
  List<Object?> get props => [showMessage, governorateId];
}

// Tab selection events
class ChangeTabEvent extends CommunityEvent {
  final int index;

  const ChangeTabEvent(this.index);

  @override
  List<Object> get props => [index];
}

// Events related events
class LoadCommunityEvents extends CommunityEvent {
  final String? governorateId;

  const LoadCommunityEvents({this.governorateId});

  @override
  List<Object?> get props => [governorateId];
}

class SelectEventEvent extends CommunityEvent {
  final CommunityEventModel event;

  const SelectEventEvent(this.event);

  @override
  List<Object> get props => [event];
}

class JoinEventEvent extends CommunityEvent {
  final String eventId;
  final String userId;
  final String userName;

  const JoinEventEvent({
    required this.eventId,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object> get props => [eventId, userId, userName];
}

class LeaveEventEvent extends CommunityEvent {
  final String eventId;
  final String userId;

  const LeaveEventEvent({
    required this.eventId,
    required this.userId,
  });

  @override
  List<Object> get props => [eventId, userId];
}

// Group hosts related events
class LoadGroupHostsEvent extends CommunityEvent {
  final String? governorateId;

  const LoadGroupHostsEvent({this.governorateId});

  @override
  List<Object?> get props => [governorateId];
}

class SelectGroupHostEvent extends CommunityEvent {
  final GroupHostModel groupHost;

  const SelectGroupHostEvent(this.groupHost);

  @override
  List<Object> get props => [groupHost];
}

class JoinGroupHostEvent extends CommunityEvent {
  final String groupId;
  final String userId;
  final String userName;
  final String imageUrl;

  const JoinGroupHostEvent({
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.imageUrl,
  });

  @override
  List<Object> get props => [groupId, userId, userName, imageUrl];
}

class LeaveGroupHostEvent extends CommunityEvent {
  final String groupId;
  final String userId;

  const LeaveGroupHostEvent({
    required this.groupId,
    required this.userId,
  });

  @override
  List<Object> get props => [groupId, userId];
}

class CreateGroupHostEvent extends CommunityEvent {
  final GroupHostModel groupHost;

  const CreateGroupHostEvent(this.groupHost);

  @override
  List<Object> get props => [groupHost];
}

// Tournament related events
class LoadTournamentsEvent extends CommunityEvent {
  final String? governorateId;

  const LoadTournamentsEvent({this.governorateId});

  @override
  List<Object?> get props => [governorateId];
}

class SelectTournamentEvent extends CommunityEvent {
  final TournamentModel tournament;

  const SelectTournamentEvent(this.tournament);

  @override
  List<Object> get props => [tournament];
}

class JoinTournamentEvent extends CommunityEvent {
  final String tournamentId;
  final String userId;
  final String userName;

  const JoinTournamentEvent({
    required this.tournamentId,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object> get props => [tournamentId, userId, userName];
}

class LeaveTournamentEvent extends CommunityEvent {
  final String tournamentId;
  final String userId;

  const LeaveTournamentEvent({
    required this.tournamentId,
    required this.userId,
  });

  @override
  List<Object> get props => [tournamentId, userId];
}
