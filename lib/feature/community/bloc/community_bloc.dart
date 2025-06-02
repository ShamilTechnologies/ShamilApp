import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_event.dart';
import 'package:shamil_mobile_app/feature/community/bloc/community_state.dart';
import 'package:shamil_mobile_app/feature/community/repository/community_repository.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _communityRepository;

  CommunityBloc({required CommunityRepository communityRepository})
      : _communityRepository = communityRepository,
        super(CommunityInitial()) {
    // General events
    on<LoadCommunityData>(_onLoadCommunityData);
    on<RefreshCommunityData>(_onRefreshCommunityData);
    on<ChangeTabEvent>(_onChangeTab);

    // Events related events
    on<LoadCommunityEvents>(_onLoadEvents);
    on<SelectEventEvent>(_onSelectEvent);
    on<JoinEventEvent>(_onJoinEvent);
    on<LeaveEventEvent>(_onLeaveEvent);

    // Group hosts related events
    on<LoadGroupHostsEvent>(_onLoadGroupHosts);
    on<SelectGroupHostEvent>(_onSelectGroupHost);
    on<JoinGroupHostEvent>(_onJoinGroupHost);
    on<LeaveGroupHostEvent>(_onLeaveGroupHost);
    on<CreateGroupHostEvent>(_onCreateGroupHost);

    // Tournament related events
    on<LoadTournamentsEvent>(_onLoadTournaments);
    on<SelectTournamentEvent>(_onSelectTournament);
    on<JoinTournamentEvent>(_onJoinTournament);
    on<LeaveTournamentEvent>(_onLeaveTournament);
  }

  // General event handlers
  Future<void> _onLoadCommunityData(
    LoadCommunityData event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommunityLoading());

    try {
      // Load all data in parallel
      final events = await _communityRepository.getEvents(
        governorateId: event.governorateId,
      );
      final groupHosts = await _communityRepository.getGroupHosts(
        governorateId: event.governorateId,
      );
      final tournaments = await _communityRepository.getTournaments(
        governorateId: event.governorateId,
      );

      emit(CommunityLoaded(
        events: events,
        groupHosts: groupHosts,
        tournaments: tournaments,
      ));
    } catch (e) {
      emit(CommunityError(e.toString()));
    }
  }

  Future<void> _onRefreshCommunityData(
    RefreshCommunityData event,
    Emitter<CommunityState> emit,
  ) async {
    // If we have existing data, mark as refreshing but keep showing it
    if (state is CommunityLoaded) {
      emit((state as CommunityLoaded).copyWith(isRefreshing: true));
    } else {
      emit(CommunityLoading());
    }

    try {
      // Load all data in parallel
      final events = await _communityRepository.getEvents(
        governorateId: event.governorateId,
      );
      final groupHosts = await _communityRepository.getGroupHosts(
        governorateId: event.governorateId,
      );
      final tournaments = await _communityRepository.getTournaments(
        governorateId: event.governorateId,
      );

      final currentState = state;
      if (currentState is CommunityLoaded) {
        emit(currentState.copyWith(
          events: events,
          groupHosts: groupHosts,
          tournaments: tournaments,
          isRefreshing: false,
          successMessage: event.showMessage ? 'Community data refreshed' : null,
        ));
      } else {
        emit(CommunityLoaded(
          events: events,
          groupHosts: groupHosts,
          tournaments: tournaments,
          successMessage: event.showMessage ? 'Community data refreshed' : null,
        ));
      }
    } catch (e) {
      if (state is CommunityLoaded) {
        emit((state as CommunityLoaded).copyWith(
          isRefreshing: false,
          errorMessage: e.toString(),
        ));
      } else {
        emit(CommunityError(e.toString()));
      }
    }
  }

  void _onChangeTab(
    ChangeTabEvent event,
    Emitter<CommunityState> emit,
  ) {
    if (state is CommunityLoaded) {
      emit((state as CommunityLoaded).copyWith(
        currentTabIndex: event.index,
      ));
    }
  }

  // Events related event handlers
  Future<void> _onLoadEvents(
    LoadCommunityEvents event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      // Keep existing state but update events
      final currentState = state as CommunityLoaded;

      try {
        final events = await _communityRepository.getEvents(
          governorateId: event.governorateId,
        );

        emit(currentState.copyWith(events: events));
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to load events: ${e.toString()}',
        ));
      }
    } else {
      // If we don't have a loaded state, use the general load method
      add(LoadCommunityData(governorateId: event.governorateId));
    }
  }

  void _onSelectEvent(
    SelectEventEvent event,
    Emitter<CommunityState> emit,
  ) {
    if (state is CommunityLoaded) {
      emit((state as CommunityLoaded).copyWith(
        selectedEvent: event.event,
      ));
    }
  }

  Future<void> _onJoinEvent(
    JoinEventEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      final currentState = state as CommunityLoaded;

      try {
        final success = await _communityRepository.joinEvent(
          event.eventId,
          event.userId,
          event.userName,
        );

        if (success) {
          // Refresh the event list if successful
          final events = await _communityRepository.getEvents();

          emit(currentState.copyWith(
            events: events,
            successMessage: 'Successfully joined event',
          ));
        } else {
          emit(currentState.copyWith(
            errorMessage: 'Failed to join event',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to join event: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onLeaveEvent(
    LeaveEventEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      final currentState = state as CommunityLoaded;

      try {
        final success = await _communityRepository.leaveEvent(
          event.eventId,
          event.userId,
        );

        if (success) {
          // Refresh the event list if successful
          final events = await _communityRepository.getEvents();

          emit(currentState.copyWith(
            events: events,
            successMessage: 'Successfully left event',
          ));
        } else {
          emit(currentState.copyWith(
            errorMessage: 'Failed to leave event',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to leave event: ${e.toString()}',
        ));
      }
    }
  }

  // Group hosts related event handlers
  Future<void> _onLoadGroupHosts(
    LoadGroupHostsEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      // Keep existing state but update group hosts
      final currentState = state as CommunityLoaded;

      try {
        final groupHosts = await _communityRepository.getGroupHosts(
          governorateId: event.governorateId,
        );

        emit(currentState.copyWith(groupHosts: groupHosts));
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to load group hosts: ${e.toString()}',
        ));
      }
    } else {
      // If we don't have a loaded state, use the general load method
      add(LoadCommunityData(governorateId: event.governorateId));
    }
  }

  void _onSelectGroupHost(
    SelectGroupHostEvent event,
    Emitter<CommunityState> emit,
  ) {
    if (state is CommunityLoaded) {
      emit((state as CommunityLoaded).copyWith(
        selectedGroupHost: event.groupHost,
      ));
    }
  }

  Future<void> _onJoinGroupHost(
    JoinGroupHostEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      final currentState = state as CommunityLoaded;

      try {
        final success = await _communityRepository.joinGroupHost(
          event.groupId,
          event.userId,
          event.userName,
          event.imageUrl,
        );

        if (success) {
          // Refresh the group hosts list if successful
          final groupHosts = await _communityRepository.getGroupHosts();

          emit(currentState.copyWith(
            groupHosts: groupHosts,
            successMessage: 'Successfully joined group',
          ));
        } else {
          emit(currentState.copyWith(
            errorMessage: 'Failed to join group',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to join group: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onLeaveGroupHost(
    LeaveGroupHostEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      final currentState = state as CommunityLoaded;

      try {
        final success = await _communityRepository.leaveGroupHost(
          event.groupId,
          event.userId,
        );

        if (success) {
          // Refresh the group hosts list if successful
          final groupHosts = await _communityRepository.getGroupHosts();

          emit(currentState.copyWith(
            groupHosts: groupHosts,
            successMessage: 'Successfully left group',
          ));
        } else {
          emit(currentState.copyWith(
            errorMessage: 'Failed to leave group',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to leave group: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onCreateGroupHost(
    CreateGroupHostEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      final currentState = state as CommunityLoaded;

      try {
        final groupId = await _communityRepository.createGroupHost(
          event.groupHost,
        );

        if (groupId != null) {
          // Refresh the group hosts list if successful
          final groupHosts = await _communityRepository.getGroupHosts();

          emit(currentState.copyWith(
            groupHosts: groupHosts,
            successMessage: 'Successfully created group',
          ));
        } else {
          emit(currentState.copyWith(
            errorMessage: 'Failed to create group',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to create group: ${e.toString()}',
        ));
      }
    }
  }

  // Tournament related event handlers
  Future<void> _onLoadTournaments(
    LoadTournamentsEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      // Keep existing state but update tournaments
      final currentState = state as CommunityLoaded;

      try {
        final tournaments = await _communityRepository.getTournaments(
          governorateId: event.governorateId,
        );

        emit(currentState.copyWith(tournaments: tournaments));
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to load tournaments: ${e.toString()}',
        ));
      }
    } else {
      // If we don't have a loaded state, use the general load method
      add(LoadCommunityData(governorateId: event.governorateId));
    }
  }

  void _onSelectTournament(
    SelectTournamentEvent event,
    Emitter<CommunityState> emit,
  ) {
    if (state is CommunityLoaded) {
      emit((state as CommunityLoaded).copyWith(
        selectedTournament: event.tournament,
      ));
    }
  }

  Future<void> _onJoinTournament(
    JoinTournamentEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      final currentState = state as CommunityLoaded;

      try {
        final success = await _communityRepository.joinTournament(
          event.tournamentId,
          event.userId,
          event.userName,
        );

        if (success) {
          // Refresh the tournaments list if successful
          final tournaments = await _communityRepository.getTournaments();

          emit(currentState.copyWith(
            tournaments: tournaments,
            successMessage: 'Successfully joined tournament',
          ));
        } else {
          emit(currentState.copyWith(
            errorMessage: 'Failed to join tournament',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to join tournament: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onLeaveTournament(
    LeaveTournamentEvent event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is CommunityLoaded) {
      final currentState = state as CommunityLoaded;

      try {
        final success = await _communityRepository.leaveTournament(
          event.tournamentId,
          event.userId,
        );

        if (success) {
          // Refresh the tournaments list if successful
          final tournaments = await _communityRepository.getTournaments();

          emit(currentState.copyWith(
            tournaments: tournaments,
            successMessage: 'Successfully left tournament',
          ));
        } else {
          emit(currentState.copyWith(
            errorMessage: 'Failed to leave tournament',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to leave tournament: ${e.toString()}',
        ));
      }
    }
  }
}
