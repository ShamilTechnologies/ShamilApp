// lib/feature/passes/bloc/my_passes_state.dart

part of 'my_passes_bloc.dart'; // Link to the Bloc file



@immutable
abstract class MyPassesState extends Equatable {
  const MyPassesState();

  @override
  List<Object?> get props => [];
}

/// Initial state before data is loaded.
class MyPassesInitial extends MyPassesState {}

/// State indicating data is being loaded.
class MyPassesLoading extends MyPassesState {}

/// State indicating data has been successfully loaded.
class MyPassesLoaded extends MyPassesState {
  // Reservations categorized by status/time
  final List<ReservationModel> upcomingReservations;
  final List<ReservationModel> pastReservations;
  final List<ReservationModel> cancelledReservations;

  // Subscriptions categorized by status/time
  final List<SubscriptionModel> activeSubscriptions;
  final List<SubscriptionModel> expiredSubscriptions; // Includes cancelled/failed etc.

  const MyPassesLoaded({
    this.upcomingReservations = const [],
    this.pastReservations = const [],
    this.cancelledReservations = const [],
    this.activeSubscriptions = const [],
    this.expiredSubscriptions = const [],
  });

  @override
  List<Object?> get props => [
        upcomingReservations,
        pastReservations,
        cancelledReservations,
        activeSubscriptions,
        expiredSubscriptions,
      ];

  // Helper to check if there's any data to display at all
  bool get isEmpty =>
      upcomingReservations.isEmpty &&
      pastReservations.isEmpty &&
      cancelledReservations.isEmpty &&
      activeSubscriptions.isEmpty &&
      expiredSubscriptions.isEmpty;
}

/// State indicating an error occurred while loading data.
class MyPassesError extends MyPassesState {
  final String message;

  const MyPassesError({required this.message});

  @override
  List<Object?> get props => [message];
}