import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shamil_mobile_app/feature/home/data/homeModel.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  // Helper function to format the city name.
  String formatCity(String rawCity) {
    // Create a RegExp to remove the word "government" (case insensitive).
    final regex = RegExp(r'\s*Governorate\s*', caseSensitive: false);
    return rawCity.replaceAll(regex, '').trim();
  }

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      // Ensure location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      // Check and request location permissions.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      // Get the current position.
      final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Reverse geocode to obtain the administrative area (city).
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      String city = "Unknown";
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        city = placemark.administrativeArea ?? "Unknown";
        // Format the city to remove "government" if present.
        city = formatCity(city);
      }

      // If user is logged in, update their Firestore document with the city.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection("endUsers")
            .doc(currentUser.uid)
            .update({
          'city': city,
          'lastUpdatedLocation': FieldValue.serverTimestamp(),
        });

        // Create HomeModel and emit loaded state.
        final homeModel = HomeModel(
          uid: currentUser.uid,
          city: city,
          lastUpdatedLocation: Timestamp.now(),
        );
        emit(HomeLoaded(homeModel: homeModel));
      } else {
        throw Exception("User not logged in");
      }
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }
}
