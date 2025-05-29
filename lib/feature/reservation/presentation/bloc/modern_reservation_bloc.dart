import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/reservation/data/models/reservation_model.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';

// Events
abstract class ModernReservationEvent extends Equatable {
  const ModernReservationEvent();

  @override
  List<Object?> get props => [];
}

class LoadReservations extends ModernReservationEvent {
  const LoadReservations();
}

class CreateReservation extends ModernReservationEvent {
  final ReservationModel reservation;

  const CreateReservation(this.reservation);

  @override
  List<Object?> get props => [reservation];
}

class CancelReservation extends ModernReservationEvent {
  final String reservationId;

  const CancelReservation(this.reservationId);

  @override
  List<Object?> get props => [reservationId];
}

class RefreshReservations extends ModernReservationEvent {
  const RefreshReservations();
}

// States
abstract class ModernReservationState extends Equatable {
  const ModernReservationState();

  @override
  List<Object?> get props => [];
}

class ReservationInitial extends ModernReservationState {}

class ReservationLoading extends ModernReservationState {
  final bool isInitialLoad;

  const ReservationLoading({this.isInitialLoad = true});

  @override
  List<Object?> get props => [isInitialLoad];
}

class ReservationLoaded extends ModernReservationState {
  final List<ReservationModel> reservations;
  final String? message;

  const ReservationLoaded({
    required this.reservations,
    this.message,
  });

  @override
  List<Object?> get props => [reservations, message];
}

class ReservationOperationInProgress extends ModernReservationState {
  final List<ReservationModel> reservations;
  final String operationType; // 'creating', 'cancelling'
  final String? targetReservationId;

  const ReservationOperationInProgress({
    required this.reservations,
    required this.operationType,
    this.targetReservationId,
  });

  @override
  List<Object?> get props => [reservations, operationType, targetReservationId];
}

class ReservationError extends ModernReservationState {
  final String message;
  final List<ReservationModel>? reservations; // Keep existing data on error

  const ReservationError({
    required this.message,
    this.reservations,
  });

  @override
  List<Object?> get props => [message, reservations];
}

// BLoC
class ModernReservationBloc
    extends Bloc<ModernReservationEvent, ModernReservationState> {
  final FirebaseDataOrchestrator _dataOrchestrator;
  StreamSubscription? _reservationsSubscription;

  ModernReservationBloc({required FirebaseDataOrchestrator dataOrchestrator})
      : _dataOrchestrator = dataOrchestrator,
        super(ReservationInitial()) {
    on<LoadReservations>(_onLoadReservations);
    on<CreateReservation>(_onCreateReservation);
    on<CancelReservation>(_onCancelReservation);
    on<RefreshReservations>(_onRefreshReservations);
  }

  Future<void> _onLoadReservations(
    LoadReservations event,
    Emitter<ModernReservationState> emit,
  ) async {
    if (!_dataOrchestrator.isAuthenticated) {
      emit(const ReservationError(message: 'User must be logged in'));
      return;
    }

    emit(const ReservationLoading(isInitialLoad: true));

    try {
      // Cancel any existing subscription
      await _reservationsSubscription?.cancel();

      // Set up real-time stream
      _reservationsSubscription =
          _dataOrchestrator.getUserReservationsStream().listen(
        (reservations) {
          if (!isClosed) {
            emit(ReservationLoaded(reservations: reservations));
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(ReservationError(
              message: 'Failed to load reservations: $error',
              reservations: state is ReservationLoaded
                  ? (state as ReservationLoaded).reservations
                  : null,
            ));
          }
        },
      );
    } catch (e) {
      emit(ReservationError(
          message: 'Failed to initialize reservations stream: $e'));
    }
  }

  Future<void> _onCreateReservation(
    CreateReservation event,
    Emitter<ModernReservationState> emit,
  ) async {
    if (!_dataOrchestrator.isAuthenticated) {
      emit(const ReservationError(message: 'User must be logged in'));
      return;
    }

    // Show operation in progress
    final currentReservations = state is ReservationLoaded
        ? (state as ReservationLoaded).reservations
        : <ReservationModel>[];

    emit(ReservationOperationInProgress(
      reservations: currentReservations,
      operationType: 'creating',
    ));

    try {
      final reservationId =
          await _dataOrchestrator.createReservation(event.reservation);

      // Success message will be shown when stream updates
      // The stream will automatically provide the updated list
      print('Reservation created successfully: $reservationId');
    } catch (e) {
      emit(ReservationError(
        message: 'Failed to create reservation: $e',
        reservations: currentReservations,
      ));
    }
  }

  Future<void> _onCancelReservation(
    CancelReservation event,
    Emitter<ModernReservationState> emit,
  ) async {
    if (!_dataOrchestrator.isAuthenticated) {
      emit(const ReservationError(message: 'User must be logged in'));
      return;
    }

    // Show operation in progress
    final currentReservations = state is ReservationLoaded
        ? (state as ReservationLoaded).reservations
        : <ReservationModel>[];

    emit(ReservationOperationInProgress(
      reservations: currentReservations,
      operationType: 'cancelling',
      targetReservationId: event.reservationId,
    ));

    try {
      await _dataOrchestrator.cancelReservation(event.reservationId);

      // Success message will be shown when stream updates
      print('Reservation cancelled successfully: ${event.reservationId}');
    } catch (e) {
      emit(ReservationError(
        message: 'Failed to cancel reservation: $e',
        reservations: currentReservations,
      ));
    }
  }

  Future<void> _onRefreshReservations(
    RefreshReservations event,
    Emitter<ModernReservationState> emit,
  ) async {
    // For refresh, we don't need to do anything special
    // The stream will automatically provide fresh data
    // We could add a refresh indicator if needed
    if (state is ReservationLoaded) {
      emit(const ReservationLoading(isInitialLoad: false));
    }

    // The stream subscription will handle the rest
  }

  @override
  Future<void> close() {
    _reservationsSubscription?.cancel();
    return super.close();
  }
}
