// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // For App Check
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM
import 'package:flutter/foundation.dart'; // Required for kDebugMode check
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart'; // Needed for basic Provider
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/core/utils/themes.dart';
import 'package:shamil_mobile_app/feature/intro/splash_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/firebase_options.dart';
import 'package:shamil_mobile_app/storage_service.dart'; // Keep if used elsewhere

// Import necessary views for global listeners/navigation
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/core/navigation/main_navigation_view.dart';
import 'package:shamil_mobile_app/feature/social/views/friends_view.dart'; // For navigation target
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart'; // For providing SocialBloc

// Import Firestore and Auth for token management
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// *** Import Repositories ***
import 'package:shamil_mobile_app/feature/reservation/repository/reservation_repository.dart';
import 'package:shamil_mobile_app/feature/social/repository/social_repository.dart';
// ACTION: Import SubscriptionRepository when created
// import 'package:shamil_mobile_app/feature/subscription/repository/subscription_repository.dart';

// --- FCM Background Handler ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need Firebase services here, ensure initialization
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  if (message.notification != null) {
    print(
        'Message also contained a notification: ${message.notification?.title}');
  }
}

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SharedPreferences
  await AppLocalStorage.init();

  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/env/.env");
    print(".env file loaded successfully.");
  } catch (e) {
    print("Error loading .env file: $e");
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate Firebase App Check
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
    if (kDebugMode) {
      print("Firebase App Check activated with DEBUG provider.");
    } else {
      print("Firebase App Check activated with release provider.");
    }
  } catch (e) {
    print("Error activating Firebase App Check: $e");
  }

  // Initialize Firebase Messaging Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    // Provide Repositories first
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReservationRepository>(
          create: (context) => FirebaseReservationRepository(),
        ),
        RepositoryProvider<SocialRepository>(
          create: (context) => FirebaseSocialRepository(),
        ),
        // ACTION: Provide SubscriptionRepository when created
        // RepositoryProvider<SubscriptionRepository>(
        //   create: (context) => FirebaseSubscriptionRepository(),
        // ),
      ],
      // Then provide Blocs that might depend on Repositories
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(),
            lazy: false, // Check auth state immediately
          ),
          BlocProvider<SocialBloc>(
            create: (context) => SocialBloc(
              // Inject the repository provided above
              socialRepository: context.read<SocialRepository>(),
            ),
            lazy: true, // Load social data when needed
          ),
          // ACTION: Provide SubscriptionBloc when created, injecting its repository
          // BlocProvider<SubscriptionBloc>(
          //   create: (context) => SubscriptionBloc(
          //     subscriptionRepository: context.read<SubscriptionRepository>(),
          //   ),
          //   lazy: true,
          // ),
          // Provide StorageService if used via Provider
          // Provider<StorageService>(create: (_) => StorageService()),
        ],
        child: const MainApp(), // Your main application widget
      ),
    ),
  );
}

/// The root application widget.
class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Setup FCM listeners after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupFcmListenersAndPermissions();
        _handleTerminatedNotification();
      }
    });
  }

  /// Request notification permissions and set up FCM message listeners.
  Future<void> _setupFcmListenersAndPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print(
        'User granted notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print(
          'Notification Permission Granted. Setting up listeners and token handling.');
      _getAndSaveFcmToken();
      messaging.onTokenRefresh.listen(_updateTokenInFirestore);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground Message received:');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
              'Message notification: ${message.notification?.title} / ${message.notification?.body}');
          // TODO: Implement local notification display (e.g., flutter_local_notifications)
        }
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
            'Message clicked (background)! Navigating based on data: ${message.data}');
        if (mounted) {
          _handleNotificationTap(context, message.data);
        }
      });
    } else {
      print('User declined or has not accepted notification permission');
    }
  }

  /// Check if the app was launched from a terminated state via a notification tap.
  Future<void> _handleTerminatedNotification() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print(
          'Message clicked (terminated)! Navigating based on data: ${initialMessage.data}');
      // Delay slightly to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _handleNotificationTap(context, initialMessage.data);
        }
      });
    }
  }

  /// Handle navigation based on the data payload of a tapped notification.
  void _handleNotificationTap(
      BuildContext navContext, Map<String, dynamic> data) {
    print("Handling notification tap with data: $data");
    final String? type = data['type'] as String?;

    // Example navigation logic
    if (type == 'friend_request' || type == 'family_request') {
      print("Navigating to Friends/Family Requests...");
      try {
        // Navigate to FriendsView, assuming SocialBloc is globally provided
        // You might need to pass arguments to show the 'Requests' tab specifically
        Navigator.of(navContext).push(MaterialPageRoute(
          builder: (_) => const FriendsView(),
          // settings: RouteSettings(arguments: {'initialTab': 'requests'}), // Example argument passing
        ));
      } catch (e) {
        print("Error navigating from notification tap: $e");
        // Fallback navigation if specific route fails
        Navigator.of(navContext)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
    // TODO: Add handlers for other notification types
  }

  /// Get the current FCM Token and save/update it in Firestore.
  Future<void> _getAndSaveFcmToken() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("Initial FCM Token: $fcmToken");
      if (fcmToken != null) {
        _updateTokenInFirestore(fcmToken);
      } else {
        print("Failed to get FCM token.");
      }
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }

  /// Update token in Firestore for the currently logged-in user.
  Future<void> _updateTokenInFirestore(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (token == null || user == null) {
      print("Cannot update FCM token: Token is null or User is null.");
      return;
    }
    print("Attempting to update FCM token in Firestore for user ${user.uid}");
    try {
      // Use 'endUsers' collection as per AuthBloc
      await FirebaseFirestore.instance
          .collection('endUsers')
          .doc(user.uid)
          .set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("FCM Token update/add attempted in Firestore.");
    } catch (e) {
      print("Error saving FCM token to Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shamil App',
      theme: AppThemes.lightTheme, // Apply light theme
      home: const SplashView(), // Start with the splash screen
      routes: {
        // Define named routes for cleaner navigation
        '/login': (context) => const LoginView(),
        '/home': (context) => const MainNavigationView(),
        // Add other routes as needed
      },
      // Global BlocListener for Auth state changes (handles logout navigation)
      builder: (context, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            final currentRoute = ModalRoute.of(context)?.settings.name;
            print(
                "Global Auth Listener: State=${state.runtimeType}, CurrentRoute=$currentRoute");

            // Navigate to Login screen when authentication state becomes initial (logged out)
            if (state is AuthInitial) {
              print(
                  "Global Auth Listener: Detected AuthInitial, navigating to Login.");
              // Delete local FCM token instance on logout
              try {
                FirebaseMessaging.instance.deleteToken();
                print("FCM Token deleted from device on logout.");
              } catch (e) {
                print("Error deleting FCM token from device on logout: $e");
              }
              // Navigate to Login and remove all previous routes
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
          child: child!, // The rest of the app defined by home/routes
        );
      },
    );
  }
}
