
// Modify: lib/feature/details/views/bloc/service_provider_detail_bloc.dart
// Update imports, add repository, modify Load event handler

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Keep for Timestamp if used directly
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

// Use the enhanced ServiceProviderModel
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';
// Import the NEW Repository
import 'package:shamil_mobile_app/feature/details/repository/service_provider_detail_repository.dart';
// Import Favorites Repository/Bloc IF favorite logic is centralized (Recommended)
// import 'package:shamil_mobile_app/feature/favorites/repository/favorites_repository.dart';

part 'service_provider_detail_event.dart'; // Ensure this uses the correct BLoC name
part 'service_provider_detail_state.dart'; // Ensure this uses the enhanced model

class ServiceProviderDetailBloc
    extends Bloc<ServiceProviderDetailEvent, ServiceProviderDetailState> {
  // Remove direct Firestore/Auth access if handled solely by repositories
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Keep for userId

  // Inject the NEW Repository
  final ServiceProviderDetailRepository _detailRepository;
  // Inject Favorites Repository if managing favorites here (Alternative: use a dedicated FavoritesBloc)
  // final FavoritesRepository _favoritesRepository;

  // Define collection names if still needed for favorites logic within this Bloc
  static const String _usersCollection = 'endUsers';
  static const String _favoritesSubCollection = 'favorites';

  String? get _userId => _auth.currentUser?.uid;

  // Update constructor to accept repository
  ServiceProviderDetailBloc({
    required ServiceProviderDetailRepository detailRepository,
    // required FavoritesRepository favoritesRepository, // If managing favorites here
  }) : _detailRepository = detailRepository,
      //  _favoritesRepository = favoritesRepository,
       super(ServiceProviderDetailInitial()) {
    on<LoadServiceProviderDetails>(_onLoadDetails);
    on<ToggleFavoriteStatus>(_onToggleFavorite); // Keep for now, consider moving
    // Add handlers for review/report events later
  }

  // Helper to check favorite status (Consider moving to FavoritesRepository)
  Future<bool> _checkIsFavorite(String providerId) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      // *** This logic BELONGS in a FavoritesRepository ideally ***
      final favoriteDocRef = FirebaseFirestore.instance // Temp direct access
          .collection(_usersCollection)
          .doc(userId)
          .collection(_favoritesSubCollection)
          .doc(providerId);
      final docSnapshot = await favoriteDocRef.get();
      return docSnapshot.exists;
    } catch (e) {
      print("ServiceProviderDetailBloc: Error checking favorite status for $providerId: $e");
      return false;
    }
  }

  // --- Load Details Event Handler ---
  Future<void> _onLoadDetails(LoadServiceProviderDetails event,
      Emitter<ServiceProviderDetailState> emit) async {
    emit(ServiceProviderDetailLoading());
    print("ServiceProviderDetailBloc: Loading details for ID: ${event.providerId}");
    try {
      // 1. Fetch Provider Details using the Repository
      final ServiceProviderModel provider =
          await _detailRepository.fetchServiceProviderDetails(event.providerId);
      print("ServiceProviderDetailBloc: Details fetched via repository for ${provider.businessName}.");

      // 2. Fetch Favorite Status (Ideally via FavoritesRepository)
      final bool isFavorite = await _checkIsFavorite(event.providerId);
      print("ServiceProviderDetailBloc: Favorite status checked: $isFavorite");

      // 3. Emit Loaded State with the full, enhanced model
      emit(ServiceProviderDetailLoaded(
        provider: provider, // Pass the enhanced model instance
        isFavorite: isFavorite,
      ));
      print("ServiceProviderDetailBloc: Emitted ServiceProviderDetailLoaded.");
    } catch (e) {
      print("ServiceProviderDetailBloc: Error loading provider details: $e");
      emit(ServiceProviderDetailError(
          message: "Failed to load details: ${e.toString()}"));
    }
  }

  // --- Toggle Favorite Event Handler (Keep for now, but consider moving) ---
  Future<void> _onToggleFavorite(ToggleFavoriteStatus event,
      Emitter<ServiceProviderDetailState> emit) async {
    final currentState = state;
    final userId = _userId;

    if (currentState is! ServiceProviderDetailLoaded || userId == null) {
      print("ServiceProviderDetailBloc: Cannot toggle favorite - State is not Loaded or user is null.");
      return; // Don't emit error, just ignore if state is wrong
    }

    final providerId = event.providerId;
    final bool currentStatus = event.currentStatus;
    final bool newFavoriteStatus = !currentStatus;

    print("ServiceProviderDetailBloc: Toggling favorite for $providerId to $newFavoriteStatus");

    // Optimistically update the UI state immediately
    emit(currentState.copyWith(isFavorite: newFavoriteStatus));

    // *** Logic BELONGS in FavoritesRepository ***
    final favoriteDocRef = FirebaseFirestore.instance // Temp direct access
        .collection(_usersCollection)
        .doc(userId)
        .collection(_favoritesSubCollection)
        .doc(providerId);

    try {
      if (newFavoriteStatus == true) {
        await favoriteDocRef.set({'addedAt': FieldValue.serverTimestamp()});
      } else {
        await favoriteDocRef.delete();
      }
      print("ServiceProviderDetailBloc: Favorite status updated in Firestore.");
      // TODO: Notify HomeBloc or other listeners if necessary (using a shared service/stream)
    } catch (e) {
      print("ServiceProviderDetailBloc: Error toggling favorite status in Firestore: $e");
      // Revert the optimistic UI update
      emit(currentState.copyWith(isFavorite: currentStatus));
      // Optionally show a snackbar via a different mechanism or state flag
    }
  }

    // Add handlers for Review/Report later
    // Future<void> _onSubmitReview(...) async { ... }
    // Future<void> _onReportProvider(...) async { ... }
}

// --------------------------------------------------------------------------

// Modify: lib/feature/details/views/bloc/service_provider_detail_event.dart
// (No changes needed based on current implementation phase)

// Modify: lib/feature/details/views/bloc/service_provider_detail_state.dart
// Ensure ServiceProviderDetailLoaded uses the enhanced ServiceProviderModel (already done in the existing file)
// (No structural changes needed here for now, just ensure the model type matches)