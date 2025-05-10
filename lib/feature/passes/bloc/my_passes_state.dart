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

/// State indicating data has been successfully loaded.
class MyPassesLoaded extends MyPassesState {
  final List<ReservationModel> reservations;
  final List<SubscriptionModel> subscriptions;
  final String? errorMessage;
  final String? successMessage;

  const MyPassesLoaded({
    required this.reservations,
    required this.subscriptions,
    this.errorMessage,
    this.successMessage,
  });

  @override
  List<Object?> get props =>
      [reservations, subscriptions, errorMessage, successMessage];

  MyPassesLoaded copyWith({
    List<ReservationModel>? reservations,
    List<SubscriptionModel>? subscriptions,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return MyPassesLoaded(
      reservations: reservations ?? this.reservations,
      subscriptions: subscriptions ?? this.subscriptions,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// State indicating an error occurred while loading data.
class MyPassesError extends MyPassesState {
  final String message;

  const MyPassesError({required this.message});

  @override
  List<Object?> get props => [message];
}
