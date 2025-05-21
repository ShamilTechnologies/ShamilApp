import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/community/models/community_event_model.dart';
import 'package:shamil_mobile_app/feature/community/models/group_host_model.dart';
import 'package:shamil_mobile_app/feature/community/models/tournament_model.dart';

abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {}

class CommunityLoading extends CommunityState {}

class CommunityLoaded extends CommunityState {
  final List<CommunityEventModel> events;
  final List<GroupHostModel> groupHosts;
  final List<TournamentModel> tournaments;
  final int currentTabIndex;
  final CommunityEventModel? selectedEvent;
  final GroupHostModel? selectedGroupHost;
  final TournamentModel? selectedTournament;
  final String? errorMessage;
  final String? successMessage;
  final bool isRefreshing;

  const CommunityLoaded({
    this.events = const [],
    this.groupHosts = const [],
    this.tournaments = const [],
    this.currentTabIndex = 0,
    this.selectedEvent,
    this.selectedGroupHost,
    this.selectedTournament,
    this.errorMessage,
    this.successMessage,
    this.isRefreshing = false,
  });

  CommunityLoaded copyWith({
    List<CommunityEventModel>? events,
    List<GroupHostModel>? groupHosts,
    List<TournamentModel>? tournaments,
    int? currentTabIndex,
    CommunityEventModel? selectedEvent,
    GroupHostModel? selectedGroupHost,
    TournamentModel? selectedTournament,
    String? errorMessage,
    String? successMessage,
    bool? isRefreshing,
  }) {
    return CommunityLoaded(
      events: events ?? this.events,
      groupHosts: groupHosts ?? this.groupHosts,
      tournaments: tournaments ?? this.tournaments,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      selectedEvent: selectedEvent ?? this.selectedEvent,
      selectedGroupHost: selectedGroupHost ?? this.selectedGroupHost,
      selectedTournament: selectedTournament ?? this.selectedTournament,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  // Helpers to clear messages
  CommunityLoaded clearMessages() {
    return copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  @override
  List<Object?> get props => [
        events,
        groupHosts,
        tournaments,
        currentTabIndex,
        selectedEvent,
        selectedGroupHost,
        selectedTournament,
        errorMessage,
        successMessage,
        isRefreshing,
      ];
}

class CommunityError extends CommunityState {
  final String message;

  const CommunityError(this.message);

  @override
  List<Object> get props => [message];
}

// Events specific states
class EventsLoading extends CommunityState {}

class EventsLoaded extends CommunityState {
  final List<CommunityEventModel> events;

  const EventsLoaded(this.events);

  @override
  List<Object> get props => [events];
}

class EventsError extends CommunityState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object> get props => [message];
}

// Group hosts specific states
class GroupHostsLoading extends CommunityState {}

class GroupHostsLoaded extends CommunityState {
  final List<GroupHostModel> groupHosts;

  const GroupHostsLoaded(this.groupHosts);

  @override
  List<Object> get props => [groupHosts];
}

class GroupHostsError extends CommunityState {
  final String message;

  const GroupHostsError(this.message);

  @override
  List<Object> get props => [message];
}

// Tournament specific states
class TournamentsLoading extends CommunityState {}

class TournamentsLoaded extends CommunityState {
  final List<TournamentModel> tournaments;

  const TournamentsLoaded(this.tournaments);

  @override
  List<Object> get props => [tournaments];
}

class TournamentsError extends CommunityState {
  final String message;

  const TournamentsError(this.message);

  @override
  List<Object> get props => [message];
}

// Action states
class JoiningEvent extends CommunityState {}

class LeavingEvent extends CommunityState {}

class JoiningGroupHost extends CommunityState {}

class LeavingGroupHost extends CommunityState {}

class CreatingGroupHost extends CommunityState {}

class JoiningTournament extends CommunityState {}

class LeavingTournament extends CommunityState {}
