// lib/feature/service_details/bloc/service_details_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/details/data/plan_model.dart';
import 'package:shamil_mobile_app/feature/details/data/service_model.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_display_model.dart'; // Re-use from home for provider details

part 'service_details_event.dart';
part 'service_details_state.dart';

class ServiceDetailsBloc extends Bloc<ServiceDetailsEvent, ServiceDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _serviceProvidersCollection = 'serviceProviders';
  static const String _plansSubCollection = 'plans'; // Assuming plans are a sub-collection
  static const String _servicesSubCollection = 'services'; // Assuming services are a sub-collection

  ServiceDetailsBloc() : super(ServiceDetailsInitial()) {
    on<LoadServiceDetails>(_onLoadServiceDetails);
    on<PlanSelected>(_onPlanSelected);
    on<ServiceSelected>(_onServiceSelected);
    // on<ToggleFavoriteServiceDetails>(_onToggleFavoriteServiceDetails); // If needed
  }

  Future<void> _onLoadServiceDetails(
    LoadServiceDetails event,
    Emitter<ServiceDetailsState> emit,
  ) async {
    emit(ServiceDetailsLoading(providerId: event.providerId));
    try {
      // Fetch Service Provider's main details
      // This reuses the ServiceProviderDisplayModel. If you have a more detailed model, fetch that.
      final providerDoc = await _firestore
          .collection(_serviceProvidersCollection)
          .doc(event.providerId)
          .get();

      if (!providerDoc.exists) {
        emit(ServiceDetailsError(message: 'Service provider not found.', providerId: event.providerId));
        return;
      }
      // Assuming isFavorite status is not managed by this BLoC directly,
      // or it's passed from the previous screen. For simplicity, setting to false.
      // In a real app, you might need to fetch this or get it from HomeBloc's state.
      final providerDetails = ServiceProviderDisplayModel.fromFirestore(providerDoc, isFavorite: false);


      // Fetch Plans for the provider
      final plansSnapshot = await _firestore
          .collection(_serviceProvidersCollection)
          .doc(event.providerId)
          .collection(_plansSubCollection)
          .where('isActive', isEqualTo: true) // Only fetch active plans
          .get();
      final plans = plansSnapshot.docs
          .map((doc) => PlanModel.fromFirestore(doc))
          .toList();

      // Fetch Services for the provider
      final servicesSnapshot = await _firestore
          .collection(_serviceProvidersCollection)
          .doc(event.providerId)
          .collection(_servicesSubCollection)
          .where('isActive', isEqualTo: true) // Only fetch active services
          .get();
      final services = servicesSnapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();

      emit(ServiceDetailsLoaded(
        providerDetails: providerDetails,
        plans: plans,
        services: services,
      ));
    } catch (e, s) {
      print("Error loading service details: $e\n$s");
      emit(ServiceDetailsError(message: 'Failed to load service details: ${e.toString()}', providerId: event.providerId));
    }
  }

  void _onPlanSelected(PlanSelected event, Emitter<ServiceDetailsState> emit) {
    if (state is ServiceDetailsLoaded) {
      final loadedState = state as ServiceDetailsLoaded;
      final selectedPlan = loadedState.plans.firstWhere(
        (plan) => plan.id == event.planId,
        orElse: () => throw Exception("Selected plan not found in state"), // Should not happen if UI is correct
      );
      // Emit a state to trigger navigation or pass data to the next screen
      emit(NavigatingToOptionsConfiguration(
        providerId: event.providerId,
        selectedPlanId: event.planId,
        plan: selectedPlan,
      ));
      // Important: Re-emit the loaded state if you don't want the UI to change
      // just because navigation is triggered. Or, handle navigation purely in UI.
      // For this example, NavigatingToOptionsConfiguration will be the new state.
      // If you want to return to ServiceDetailsLoaded after navigation logic in UI:
      // emit(loadedState);
    }
  }

  void _onServiceSelected(ServiceSelected event, Emitter<ServiceDetailsState> emit) {
    if (state is ServiceDetailsLoaded) {
      final loadedState = state as ServiceDetailsLoaded;
       final selectedService = loadedState.services.firstWhere(
        (service) => service.id == event.serviceId,
         orElse: () => throw Exception("Selected service not found in state"),
      );
      emit(NavigatingToOptionsConfiguration(
        providerId: event.providerId,
        selectedServiceId: event.serviceId,
        service: selectedService,
      ));
      // emit(loadedState); // Similar to _onPlanSelected
    }
  }

  // Example if you had favorite toggling specific to this screen's context
  // Future<void> _onToggleFavoriteServiceDetails(
  //   ToggleFavoriteServiceDetails event,
  //   Emitter<ServiceDetailsState> emit,
  // ) async {
  //   final currentState = state;
  //   if (currentState is ServiceDetailsLoaded) {
  //     // Logic to update favorite in Firestore
  //     // ...
  //     // Then update the providerDetails model and re-emit ServiceDetailsLoaded
  //     final updatedProvider = currentState.providerDetails.copyWith(isFavorite: event.currentStatus);
  //     emit(currentState.copyWith(providerDetails: updatedProvider));
  //   }
  // }
}
