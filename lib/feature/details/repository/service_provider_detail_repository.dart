// Create file: lib/feature/details/repository/service_provider_detail_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart'; // Use the enhanced model

abstract class ServiceProviderDetailRepository {
  /// Fetches the full details for a single service provider.
  Future<ServiceProviderModel> fetchServiceProviderDetails(String providerId);

  // Add methods for submitting reviews, reports later
  // Future<void> submitReview(...);
  // Future<void> reportProvider(...);
}

class FirebaseServiceProviderDetailRepository implements ServiceProviderDetailRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _providersCollection = 'serviceProviders';

  @override
  Future<ServiceProviderModel> fetchServiceProviderDetails(String providerId) async {
    try {
      print("FirebaseServiceProviderDetailRepository: Fetching details for $providerId");
      final docSnapshot = await _firestore
          .collection(_providersCollection)
          .doc(providerId)
          .get();

      if (docSnapshot.exists) {
        // Use the enhanced ServiceProviderModel.fromFirestore factory
        final provider = ServiceProviderModel.fromFirestore(docSnapshot);
        print("FirebaseServiceProviderDetailRepository: Provider ${provider.businessName} fetched successfully.");
        return provider;
      } else {
         print("FirebaseServiceProviderDetailRepository: Error - Provider document not found ID: $providerId");
        throw Exception("Provider details not found.");
      }
    } on FirebaseException catch (e) {
       print("FirebaseServiceProviderDetailRepository: Firestore error fetching provider $providerId: $e");
       throw Exception("Database error: ${e.message}");
    } catch (e) {
       print("FirebaseServiceProviderDetailRepository: Generic error fetching provider $providerId: $e");
       throw Exception("Failed to load provider details: ${e.toString()}");
    }
  }
}

// --------------------------------------------------------------------------
