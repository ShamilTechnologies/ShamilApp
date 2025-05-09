 // lib/feature/passes/bloc/my_passes_bloc.dart

 import 'package:bloc/bloc.dart';
 import 'package:cloud_firestore/cloud_firestore.dart';
 import 'package:equatable/equatable.dart';
 import 'package:firebase_auth/firebase_auth.dart';
 import 'package:meta/meta.dart';

 // Import Models
 import 'package:shamil_mobile_app/feature/reservation/data/reservation_model.dart';
 import 'package:shamil_mobile_app/feature/subscription/data/subscription_model.dart'; // Assuming this path is correct

 part 'my_passes_event.dart';
 part 'my_passes_state.dart'; // Already defined in previous step

 class MyPassesBloc extends Bloc<MyPassesEvent, MyPassesState> {
   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   final FirebaseAuth _auth = FirebaseAuth.instance;

   // Collection names (adjust if different)
   static const String _usersCollection = 'endUsers';
   static const String _reservationsSubCollection = 'myReservations'; // User's reservation copies
   static const String _subscriptionsSubCollection = 'mySubscriptions'; // User's subscription copies

   MyPassesBloc() : super(MyPassesInitial()) {
     on<LoadMyPasses>(_onLoadMyPasses);
   }

   String? get _userId => _auth.currentUser?.uid;

   Future<void> _onLoadMyPasses(
       LoadMyPasses event, Emitter<MyPassesState> emit) async {
     final userId = _userId;
     if (userId == null) {
       emit(const MyPassesError(message: "User not logged in."));
       return;
     }

     // Emit loading state only if not already loaded (for pull-to-refresh)
     if (state is! MyPassesLoaded) {
        emit(MyPassesLoading());
     }
     print("MyPassesBloc: Loading passes for user $userId");

     try {
       // Fetch Reservations and Subscriptions concurrently
       final results = await Future.wait([
         _fetchUserReservations(userId),
         _fetchUserSubscriptions(userId),
       ]);

       final allReservations = results[0] as List<ReservationModel>;
       final allSubscriptions = results[1] as List<SubscriptionModel>;

       // --- Categorize Reservations ---
       final List<ReservationModel> upcoming = [];
       final List<ReservationModel> past = [];
       final List<ReservationModel> cancelled = [];
       final now = Timestamp.now();

       for (final res in allReservations) {
         // Check status first
         if (res.status == ReservationStatus.cancelledByUser ||
             res.status == ReservationStatus.cancelledByProvider) {
           cancelled.add(res);
         }
         // Check time for non-cancelled reservations
         else if (res.reservationStartTime != null && res.reservationStartTime!.compareTo(now) >= 0) {
            // Start time is now or in the future (and not cancelled)
           if (res.status == ReservationStatus.confirmed || res.status == ReservationStatus.pending) {
              upcoming.add(res);
           } else {
              // Could be completed/noShow but start time is future (edge case?) - treat as past/other for now
              past.add(res);
           }
         } else {
           // Start time is in the past (or null) and not cancelled
           past.add(res);
         }
       }
        // Sort lists (e.g., upcoming soonest first, past latest first)
       upcoming.sort((a, b) => a.reservationStartTime!.compareTo(b.reservationStartTime!));
       past.sort((a, b) => b.reservationStartTime?.compareTo(a.reservationStartTime ?? now) ?? -1); // Handle null start times
       cancelled.sort((a, b) => b.updatedAt?.compareTo(a.updatedAt ?? now) ?? -1); // Sort cancelled by update time


       // --- Categorize Subscriptions ---
       final List<SubscriptionModel> active = [];
       final List<SubscriptionModel> expiredOrStopped = [];

       for (final sub in allSubscriptions) {
         if (sub.status == SubscriptionStatus.active && sub.expiryDate.compareTo(now) > 0) {
           active.add(sub);
         } else {
           expiredOrStopped.add(sub); // Includes expired, cancelled, failed
         }
       }
       // Sort lists (e.g., active expiring soonest first, expired latest first)
       active.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
       expiredOrStopped.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));


       print("MyPassesBloc: Data fetched and categorized.");
       emit(MyPassesLoaded(
         upcomingReservations: upcoming,
         pastReservations: past,
         cancelledReservations: cancelled,
         activeSubscriptions: active,
         expiredSubscriptions: expiredOrStopped,
       ));

     } catch (e, s) {
       print("MyPassesBloc: Error loading passes: $e\n$s");
       emit(MyPassesError(message: "Failed to load passes: ${e.toString()}"));
     }
   }

   /// Fetches user's reservations from their subcollection.
   Future<List<ReservationModel>> _fetchUserReservations(String userId) async {
     try {
       final snapshot = await _firestore
           .collection(_usersCollection)
           .doc(userId)
           .collection(_reservationsSubCollection)
           // Optionally order by date for easier categorization later
           .orderBy('reservationStartTime', descending: true)
           .limit(100) // Limit query size for performance
           .get();

       return snapshot.docs
           .map((doc) {
              try { return ReservationModel.fromFirestore(doc); }
              catch(e) { print("Error parsing reservation ${doc.id}: $e"); return null; }
           })
           .whereType<ReservationModel>() // Filter out parsing errors
           .toList();
     } catch (e) {
       print("Error fetching user reservations: $e");
       // Depending on requirements, could return empty list or rethrow
       throw Exception("Could not fetch reservations.");
     }
   }

   /// Fetches user's subscriptions from their subcollection.
   Future<List<SubscriptionModel>> _fetchUserSubscriptions(String userId) async {
      try {
       final snapshot = await _firestore
           .collection(_usersCollection)
           .doc(userId)
           .collection(_subscriptionsSubCollection)
           // Optionally order by expiry date
           .orderBy('expiryDate', descending: true)
           .limit(50) // Limit query size
           .get();

       return snapshot.docs
           .map((doc) {
              try { return SubscriptionModel.fromFirestore(doc); }
              catch(e) { print("Error parsing subscription ${doc.id}: $e"); return null; }
           })
           .whereType<SubscriptionModel>()
           .toList();
     } catch (e) {
       print("Error fetching user subscriptions: $e");
       throw Exception("Could not fetch subscriptions.");
     }
   }

 } // End of MyPassesBloc
 