// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // For App Check
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM
import 'package:flutter/foundation.dart'; // Required for kDebugMode check
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/core/utils/themes.dart';
import 'package:shamil_mobile_app/feature/intro/splash_view.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/firebase_options.dart';
// import 'package:shamil_mobile_app/storage_service.dart'; // Keep if used elsewhere

// Import necessary views for global listeners/navigation
import 'package:shamil_mobile_app/feature/auth/views/page/login_view.dart';
import 'package:shamil_mobile_app/core/navigation/main_navigation_view.dart';
import 'package:shamil_mobile_app/feature/social/views/friends_view.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
// *** ADDED: Import HomeBloc ***
import 'package:shamil_mobile_app/feature/home/views/bloc/home_bloc.dart';
// *** ADDED: Import NavigationNotifier ***
import 'package:shamil_mobile_app/core/navigation/navigation_notifier.dart';

// Import Firestore and Auth for token management
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// *** Import Repositories ***
import 'package:shamil_mobile_app/feature/reservation/repository/reservation_repository.dart';
import 'package:shamil_mobile_app/feature/social/repository/social_repository.dart';
// ACTION: Import SubscriptionRepository when created
// import 'package:shamil_mobile_app/feature/subscription/repository/subscription_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamil_mobile_app/feature/favorites/repository/firebase_favorites_repository.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';

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
  final prefs = await SharedPreferences.getInstance();

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

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );

  // Initialize Firebase Messaging Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReservationRepository>(
          create: (context) => FirebaseReservationRepository(),
        ),
        RepositoryProvider<SocialRepository>(
          create: (context) => FirebaseSocialRepository(),
        ),
        // RepositoryProvider<SubscriptionRepository>(
        //   create: (context) => FirebaseSubscriptionRepository(),
        // ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc()..add(const CheckInitialAuthStatus()),
            lazy: false,
          ),
          BlocProvider<SocialBloc>(
            create: (context) => SocialBloc(
              socialRepository: context.read<SocialRepository>(),
            ),
            lazy: true,
          ),
          // *** ENSURED HomeBloc IS PROVIDED HERE ***
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc()..add(const LoadHomeData()),
            lazy: false,
          ),
          // BlocProvider<SubscriptionBloc>(
          //   create: (context) => SubscriptionBloc(
          //     subscriptionRepository: context.read<SubscriptionRepository>(),
          //   ),
          //   lazy: true,
          // ),
          BlocProvider<FavoritesBloc>(
            create: (context) {
              String userId = 'guest_placeholder';
              final authState = context.read<AuthBloc>().state;
              if (authState is LoginSuccessState) {
                userId = authState.user.uid;
              }
              return FavoritesBloc(
                FirebaseFavoritesRepository(userId: userId),
              )..add(const LoadFavorites());
            },
            lazy: false,
          ),
        ],
        // *** ADDED ChangeNotifierProvider for NavigationNotifier ***
        child: ChangeNotifierProvider(
          create: (_) => NavigationNotifier(),
          child: const MainApp(),
        ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupFcmListenersAndPermissions();
        _handleTerminatedNotification();
      }
    });
  }

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

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground Message received:');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
              'Message notification: ${message.notification?.title} / ${message.notification?.body}');
          // TODO: Implement local notification display
        }
      });

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

  Future<void> _handleTerminatedNotification() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print(
          'Message clicked (terminated)! Navigating based on data: ${initialMessage.data}');
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _handleNotificationTap(context, initialMessage.data);
        }
      });
    }
  }

  void _handleNotificationTap(
      BuildContext navContext, Map<String, dynamic> data) {
    print("Handling notification tap with data: $data");
    final String? type = data['type'] as String?;

    if (type == 'friend_request' || type == 'family_request') {
      print("Navigating to Friends/Family Requests...");
      try {
        Navigator.of(navContext).push(MaterialPageRoute(
          builder: (_) => const FriendsView(),
        ));
      } catch (e) {
        print("Error navigating from notification tap: $e");
        Navigator.of(navContext)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
    // TODO: Add handlers for other notification types
  }

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

  Future<void> _updateTokenInFirestore(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (token == null || user == null) {
      print("Cannot update FCM token: Token is null or User is null.");
      return;
    }
    print("Attempting to update FCM token in Firestore for user ${user.uid}");
    try {
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
      theme: AppThemes.lightTheme,
      home: const SplashView(),
      routes: {
        '/login': (context) => const LoginView(),
        '/home': (context) => const MainNavigationView(),
      },
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<FavoritesBloc>.value(
              value: BlocProvider.of<FavoritesBloc>(context),
            ),
          ],
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              final currentRoute = ModalRoute.of(context)?.settings.name;
              print(
                  "Global Auth Listener: State=${state.runtimeType}, CurrentRoute=$currentRoute");

              if (state is AuthInitial) {
                print(
                    "Global Auth Listener: Detected AuthInitial, navigating to Login.");
                try {
                  FirebaseMessaging.instance.deleteToken();
                  print("FCM Token deleted from device on logout.");
                } catch (e) {
                  print("Error deleting FCM token from device on logout: $e");
                }
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: child!,
          ),
        );
      },
    );
  }
}
