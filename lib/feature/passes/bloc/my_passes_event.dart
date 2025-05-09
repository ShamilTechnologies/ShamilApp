 // lib/feature/passes/bloc/my_passes_event.dart

 part of 'my_passes_bloc.dart'; // Link to the Bloc file


@immutable
 abstract class MyPassesEvent extends Equatable {
   const MyPassesEvent();

   @override
   List<Object?> get props => [];
 }

 /// Event to trigger loading the user's reservations and subscriptions.
 class LoadMyPasses extends MyPassesEvent {
   const LoadMyPasses();
 }

 // Add other events later if needed (e.g., CancelReservation, ViewDetails)
 