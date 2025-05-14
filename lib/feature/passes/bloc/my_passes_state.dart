// lib/feature/passes/bloc/my_passes_state.dart

part of 'my_passes_bloc.dart'; // Link to the Bloc file

abstract class MyPassesState extends Equatable {
  const MyPassesState();

  @override
  List<Object?> get props => [];
}

/// Initial state before data is loaded.
class MyPassesInitial extends MyPassesState {}

/// State indicating data is being loaded.
class MyPassesLoading extends MyPassesState {}

enum PassFilter { all, upcoming, active, completed, expired, cancelled }

/// State indicating data has been successfully loaded.
class MyPassesLoaded extends MyPassesState {
  final List<ReservationModel> reservations;
  final List<SubscriptionModel> subscriptions;
  final String? errorMessage;
  final String? successMessage;
  final PassFilter currentFilter;

  const MyPassesLoaded({
    required this.reservations,
    required this.subscriptions,
    this.errorMessage,
    this.successMessage,
    PassFilter? currentFilter,
  }) : currentFilter = currentFilter ?? PassFilter.all;

  // Get filtered reservations based on the current filter
  List<ReservationModel> get filteredReservations {
    switch (currentFilter) {
      case PassFilter.all:
        return reservations;
      case PassFilter.upcoming:
        return reservations
            .where((r) =>
                r.status == ReservationStatus.confirmed ||
                r.status == ReservationStatus.pending)
            .toList();
      case PassFilter.completed:
        return reservations
            .where((r) => r.status == ReservationStatus.completed)
            .toList();
      case PassFilter.cancelled:
        return reservations
            .where((r) =>
                r.status == ReservationStatus.cancelledByUser ||
                r.status == ReservationStatus.cancelledByProvider)
            .toList();
      default:
        return reservations;
    }
  }

  // Get filtered subscriptions based on the current filter
  List<SubscriptionModel> get filteredSubscriptions {
    if (subscriptions.isEmpty) {
      return [];
    }

    switch (currentFilter) {
      case PassFilter.all:
        return subscriptions;
      case PassFilter.active:
        return subscriptions
            .where((s) =>
                s.status.toLowerCase() == 'active' ||
                s.status.toLowerCase() == 'pending')
            .toList();
      case PassFilter.expired:
        return subscriptions
            .where((s) => s.status.toLowerCase() == 'expired')
            .toList();
      case PassFilter.cancelled:
        return subscriptions
            .where((s) => s.status.toLowerCase() == 'cancelled')
            .toList();
      default:
        return subscriptions;
    }
  }

  MyPassesLoaded copyWith({
    List<ReservationModel>? reservations,
    List<SubscriptionModel>? subscriptions,
    String? errorMessage,
    String? successMessage,
    PassFilter? currentFilter,
    bool clearCurrentFilter = false,
  }) {
    return MyPassesLoaded(
      reservations: reservations ?? this.reservations,
      subscriptions: subscriptions ?? this.subscriptions,
      errorMessage: errorMessage,
      successMessage: successMessage,
      currentFilter: clearCurrentFilter
          ? PassFilter.all
          : (currentFilter ?? this.currentFilter),
    );
  }

  @override
  List<Object?> get props => [
        reservations,
        subscriptions,
        errorMessage,
        successMessage,
        currentFilter,
      ];
}

/// State indicating an error occurred while loading data.
class MyPassesError extends MyPassesState {
  final String message;

  const MyPassesError({required this.message});

  @override
  List<Object?> get props => [message];
}
