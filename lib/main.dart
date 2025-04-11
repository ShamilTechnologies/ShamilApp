import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // For App Check
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/core/utils/themes.dart';
import 'package:shamil_mobile_app/feature/intro/splash_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/firebase_options.dart';
import 'package:shamil_mobile_app/storage_service.dart'; // Keep if used elsewhere

// Import necessary views for global listeners/navigation
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/feature/navigation/main_navigation_view.dart';
import 'package:shamil_mobile_app/feature/social/views/friends_view.dart'; // For navigation target
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart'; // For providing to FriendsView if needed

// Import Firestore and Auth for token management
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- FCM Background Handler ---
// Needs to be a top-level function (outside of any class)
// This handles messages received when the app is terminated or in the background (but not tapped)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, like Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // IMPORTANT: Keep this handler lightweight.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Usually needed if accessing Firebase services
  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  if (message.notification != null) {
    print(
        'Message also contained a notification: ${message.notification?.title}');
    // You cannot update UI from here directly.
    // You could potentially use flutter_local_notifications to show a notification.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalStorage.init(); // Initialize SharedPreferences

  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/env/.env"); // Ensure path is correct
    print(".env file loaded successfully.");
  } catch (e) {
    print("Error loading .env file: $e");
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate Firebase App Check (Optional but recommended)
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          AndroidProvider.playIntegrity, // Use playIntegrity for release
      // androidProvider: AndroidProvider.debug, // Use debug for testing
      // appleProvider: AppleProvider.appAttest, // Use appAttest for release
      // appleProvider: AppleProvider.debug, // Use debug for testing
    );
    print("Firebase App Check activated.");
  } catch (e) {
    print("Error activating Firebase App Check: $e");
  }

  // --- Initialize Firebase Messaging Background Handler ---
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // --- End FCM Init ---

  runApp(
    // Provide necessary services and Blocs globally
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageService()), // If used
        // Provide AuthBloc globally as it manages core auth state
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
          lazy: false, // Create immediately to handle initial state
        ),
        // Provide SocialBloc globally IF multiple screens need access easily
        // Otherwise, providing it locally in ProfileScreen (as done previously) is fine
        BlocProvider<SocialBloc>(
          create: (context) => SocialBloc(),
          lazy: true, // Can be lazy if only needed later
        ),
      ],
      child: const MainApp(),
    ),
  );
}

// Convert MainApp to StatefulWidget to handle FCM setup in initState
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Use a GlobalKey for navigation from notification taps if needed outside build context
  // static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Setup FCM listeners and request permissions AFTER the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupFcmListenersAndPermissions();
        _handleTerminatedNotification(); // Check if app opened from terminated notification
      }
    });
  }

  /// Request permissions and set up foreground/background tap listeners
  Future<void> _setupFcmListenersAndPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
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

    // Handle permission status
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print(
          'Notification Permission Granted (or provisional). Setting up listeners and token handling.');
      // Get initial token and listen for refreshes
      _getAndSaveFcmToken();
      messaging.onTokenRefresh.listen(_updateTokenInFirestore);

      // Handle foreground messages (when app is open and visible)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground Message received:');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
              'Message notification: ${message.notification?.title} / ${message.notification?.body}');
          // TODO: Show local notification using flutter_local_notifications
          // Example: display local notification with message.notification details
          // Or update a badge count in the UI using a Bloc/Provider
        }
      });

      // Handle notification tap when app is in background (but running)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
            'Message clicked (background)! Navigating based on data: ${message.data}');
        // Use the current context for navigation if possible and safe
        if (mounted) {
          _handleNotificationTap(context, message.data);
        }
      });
    } else {
      print('User declined or has not accepted notification permission');
      // Optionally show a message explaining why notifications are useful
    }
  }

  /// Check if the app was launched from a terminated state via notification
  Future<void> _handleTerminatedNotification() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print(
          'Message clicked (terminated)! Navigating based on data: ${initialMessage.data}');
      // Handle navigation after app is initialized
      // Use a short delay to ensure context/navigator is ready
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _handleNotificationTap(context, initialMessage.data);
        }
      });
    }
  }

  /// Handle navigation based on notification data payload
  /// Needs context to access Navigator and potentially Blocs
  void _handleNotificationTap(
      BuildContext navContext, Map<String, dynamic> data) {
    print("Handling notification tap with data: $data");
    final String? type =
        data['type'] as String?; // Get notification type from data

    // Example: Navigate to Friends screen requests tab if it's a friend request
    if (type == 'friend_request' || type == 'family_request') {
      print("Navigating to Friends/Family Requests...");
      // Use the provided context (should be valid from listeners/initial message handling)
      // Ensure SocialBloc is available via context before navigating
      try {
        Navigator.of(navContext).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
                  value: BlocProvider.of<SocialBloc>(
                      navContext), // Provide existing SocialBloc
                  child: const FriendsView(), // Navigate to FriendsView
                  // TODO: Add logic inside FriendsView to switch to 'Requests' tab based on incoming data
                )));
      } catch (e) {
        print(
            "Error navigating from notification tap (maybe Bloc not found?): $e");
        // Fallback navigation if push fails
        // Navigator.of(navContext).pushReplacement(MaterialPageRoute(builder: (_) => const MainNavigationView(initialIndex: 3)));
      }
    }
    // Handle other notification types if necessary
    // else if (type == 'some_other_type') { ... }
  }

  /// Get FCM Token and save/update it in Firestore
  Future<void> _getAndSaveFcmToken() async {
    // Request token (for APNS on iOS, FCM token on Android)
    // String? apnsToken = await FirebaseMessaging.instance.getAPNSToken(); // iOS only
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print("Initial FCM Token: $fcmToken");
    // TODO: Consider platform specific logic if needed (e.g. using APNS token)
    _updateTokenInFirestore(fcmToken);
  }

  /// Update token in Firestore (needs user to be logged in)
  Future<void> _updateTokenInFirestore(String? token) async {
    // Get current user directly from FirebaseAuth instance
    final user = FirebaseAuth.instance.currentUser;
    if (token == null || user == null) {
      print("Cannot update FCM token: Token is null or User is null.");
      return;
    }
    print("Attempting to update FCM token in Firestore for user ${user.uid}");
    try {
      // Use set with merge: true to add/update the fcmTokens array field
      await FirebaseFirestore.instance
          .collection('endUsers')
          .doc(user.uid)
          .set({
        'fcmTokens':
            FieldValue.arrayUnion([token]) // Add token to array if not present
      }, SetOptions(merge: true));
      print("FCM Token update/add attempted in Firestore.");
    } catch (e) {
      print("Error saving FCM token to Firestore: $e");
    }
  }

  /// Remove specific token from Firestore (needs user ID before logout)
  Future<void> _removeTokenFromFirestore(String? token, String? userId) async {
    if (token == null || userId == null) {
      print("Cannot remove FCM token: Token or UserID is null.");
      return;
    }
    print("Attempting to remove FCM token $token for user $userId");
    try {
      await FirebaseFirestore.instance
          .collection('endUsers')
          .doc(userId)
          .update({
        'fcmTokens': FieldValue.arrayRemove([token]) // Remove specific token
      });
      print("FCM Token removal attempted in Firestore.");
    } catch (e) {
      print("Error removing FCM token from Firestore: $e");
      // This might fail if rules require auth, best done server-side
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shamil App',
      theme: AppThemes.lightTheme,
      // navigatorKey: navigatorKey, // Assign key if needed for navigation without context
      home: const SplashView(), // Initial route
      routes: {
        // Define named routes if used
        '/login': (context) => const LoginView(),
        '/home': (context) => const MainNavigationView(),
      },
      // Global BlocListener for Auth state (handles logout navigation & token removal)
      builder: (context, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            final currentRoute = ModalRoute.of(context)?.settings.name;
            print(
                "Global Auth Listener: State=${state.runtimeType}, CurrentRoute=$currentRoute");

            // *** UPDATED Condition: Navigate whenever state becomes AuthInitial ***
            if (state is AuthInitial) {
              print(
                  "Global Auth Listener: Detected AuthInitial, navigating to Login.");

              // Attempt to clear local FCM token instance (Firestore removal handled in Bloc)
              try {
                FirebaseMessaging.instance.deleteToken();
                print("FCM Token deleted from device on logout.");
              } catch (e) {
                print("Error deleting FCM token from device on logout: $e");
              }

              // Navigate to Login and remove all previous routes
              // Ensure context used here is valid (builder context should be fine)
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false // Remove all routes below LoginView
                  );
            }
          },
          child: child!, // The rest of the app defined by home/routes
        );
      },
    );
  }
}
