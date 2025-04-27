import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:meta/meta.dart';
// Import the detailed ServiceProvider model
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

part 'service_provider_detail_event.dart';
part 'service_provider_detail_state.dart';

class ServiceProviderDetailBloc
    extends Bloc<ServiceProviderDetailEvent, ServiceProviderDetailState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ServiceProviderDetailBloc() : super(ServiceProviderDetailInitial()) {
    // Register handlers for events
    on<LoadServiceProviderDetails>(_onLoadDetails);
    on<ToggleFavoriteStatus>(
        _onToggleFavorite); // <<< REGISTER HANDLER FOR NEW EVENT
  }

  // --- Helper to check favorite status ---
  Future<bool> _checkIsFavorite(String providerId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    final userId = currentUser.uid;
    try {
      // *** Ensure Collection Path is Correct ***
      // It was 'users' before, but likely should match your user data collection ('endUsers'?)
      // Or if favorites are top-level: _firestore.collection('usersFavorites').doc(userId)...
      // Assuming 'endUsers' based on AuthBloc:
      final favoriteDocRef = _firestore
          .collection('endUsers') // <<< CHECK/ADJUST THIS COLLECTION NAME
          .doc(userId)
          .collection('favorites') // Ensure this subcollection name is correct
          .doc(providerId);
      final docSnapshot = await favoriteDocRef.get();
      print(
          "ServiceProviderDetailBloc: Favorite check -> Exists: ${docSnapshot.exists}");
      return docSnapshot.exists;
    } catch (e) {
      print("ServiceProviderDetailBloc: Error checking favorite status: $e");
      return false;
    }
  }

  // --- Load Details Event Handler ---
  Future<void> _onLoadDetails(LoadServiceProviderDetails event,
      Emitter<ServiceProviderDetailState> emit) async {
    // Don't emit loading if initial data is already being displayed (Optional refinement)
    // if (state is! ServiceProviderDetailLoaded) { // Only emit loading if not already showing something
    //   emit(ServiceProviderDetailLoading());
    // }
    emit(
        ServiceProviderDetailLoading()); // Keep emitting loading for now for clarity
    print(
        "ServiceProviderDetailBloc: Loading details for ID: ${event.providerId}");
    try {
      // 1. Fetch Provider Details
      final docSnapshot = await _firestore
          .collection(
              'serviceProviders') // Ensure this collection name is correct
          .doc(event.providerId)
          .get();

      if (docSnapshot.exists) {
        print("ServiceProviderDetailBloc: Provider document found.");
        final provider = ServiceProviderModel.fromFirestore(docSnapshot);
        print(
            "ServiceProviderDetailBloc: Provider deserialized: ${provider.businessName}");

        // 2. Fetch Favorite Status
        print("ServiceProviderDetailBloc: Checking favorite status...");
        final bool isFavorite = await _checkIsFavorite(event.providerId);

        // 3. Emit Loaded State with full details
        emit(ServiceProviderDetailLoaded(
          provider: provider,
          isFavorite: isFavorite,
        ));
        print(
            "ServiceProviderDetailBloc: Emitted ServiceProviderDetailLoaded (Favorite: $isFavorite).");
      } else {
        print(
            "ServiceProviderDetailBloc: Error - Provider document not found ID: ${event.providerId}");
        emit(const ServiceProviderDetailError(
            message: "Provider details not found."));
      }
    } catch (e, s) {
      print(
          "ServiceProviderDetailBloc: Error loading provider details: $e\n$s");
      if (e is FirebaseException && e.code == 'permission-denied') {
        emit(const ServiceProviderDetailError(
            message: "Permission denied fetching details."));
      } else {
        emit(ServiceProviderDetailError(
            message: "Failed to load details: ${e.toString()}"));
      }
    }
  }

  // --- Toggle Favorite Event Handler ---
  Future<void> _onToggleFavorite(ToggleFavoriteStatus event,
      Emitter<ServiceProviderDetailState> emit) async {
    final currentState = state;
    final currentUser = _auth.currentUser;

    // Ensure we are in a loaded state and user is logged in
    if (currentState is ServiceProviderDetailLoaded && currentUser != null) {
      final userId = currentUser.uid;
      final providerId = event.providerId;
      final bool currentStatus = event.currentStatus;
      final bool newFavoriteStatus =
          !currentStatus; // The status we want to reach

      print(
          "ServiceProviderDetailBloc: Toggling favorite for $providerId. Current: $currentStatus -> New: $newFavoriteStatus");

      // Optimistically update the UI state immediately
      // Pass the existing provider data along with the new favorite status
      emit(currentState.copyWith(isFavorite: newFavoriteStatus));

      // Get the Firestore document reference (ensure path matches _checkIsFavorite)
      final favoriteDocRef = _firestore
          .collection('endUsers') // <<< CHECK/ADJUST THIS COLLECTION NAME
          .doc(userId)
          .collection('favorites') // Ensure this subcollection name is correct
          .doc(providerId);

      try {
        // Perform Firestore operation based on the desired new status
        if (newFavoriteStatus == true) {
          // Add to favorites: Create the document
          // Consider adding a timestamp if useful: {'addedAt': FieldValue.serverTimestamp()}
          await favoriteDocRef.set({});
          print(
              "ServiceProviderDetailBloc: Added $providerId to favorites for user $userId.");
        } else {
          // Remove from favorites: Delete the document
          await favoriteDocRef.delete();
          print(
              "ServiceProviderDetailBloc: Removed $providerId from favorites for user $userId.");
        }
        // If Firestore succeeded, the optimistic UI update was correct.
        // We might want to also trigger a refresh in HomeBloc here if needed,
        // potentially via a listener or a shared service.
      } catch (e, s) {
        print(
            "ServiceProviderDetailBloc: Error toggling favorite status in Firestore: $e\n$s");
        // Firestore update failed, revert the optimistic UI update
        // Re-emit the *previous* favorite status with the same provider data
        emit(currentState.copyWith(isFavorite: currentStatus)); // Revert back

        // Optional: Emit a specific error state for the UI to show a snackbar
        // emit(ServiceProviderDetailActionError(message: "Could not update favorite status. Please try again."));
      }
    } else {
      print(
          "ServiceProviderDetailBloc: Cannot toggle favorite - State is not Loaded or user is null.");
      // Optionally emit an error or do nothing if toggle attempted in wrong state/logged out
    }
  }
}
