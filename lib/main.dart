// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // For App Check
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM
import 'package:firebase_auth/firebase_auth.dart'; // Add explicit Firebase Auth import
// Required for kDebugMode check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Add this import
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/core/utils/themes.dart';
import 'package:shamil_mobile_app/feature/intro/enhanced_splash_view.dart';
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
// ACTION: Import SubscriptionRepository when created
// import 'package:shamil_mobile_app/feature/subscription/repository/subscription_repository.dart';
import 'package:shamil_mobile_app/feature/favorites/bloc/favorites_bloc.dart';
import 'package:shamil_mobile_app/feature/user/repository/user_repository.dart';
import 'package:shamil_mobile_app/core/services/notification_service.dart';
// Import Community Repository
import 'package:shamil_mobile_app/feature/community/repository/community_repository.dart';

// Import the new centralized data orchestrator
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';
import 'package:shamil_mobile_app/feature/profile/repository/profile_repository.dart';

// Payment system imports
import 'package:shamil_mobile_app/core/payment/bloc/payment_bloc.dart';
import 'package:shamil_mobile_app/core/payment/integration_example_simple.dart';
import 'package:shamil_mobile_app/feature/payments/views/payments_screen.dart';
import 'package:shamil_mobile_app/feature/reservation/presentation/screens/reservation_payment_screen.dart';

// Import options configuration screens
import 'package:shamil_mobile_app/feature/options_configuration/view/enhanced_booking_configuration_screen.dart';
import 'package:shamil_mobile_app/feature/home/data/service_provider_model.dart';

// Import the new credentials manager
import 'package:shamil_mobile_app/core/payment/config/payment_credentials_manager.dart';
import 'package:shamil_mobile_app/core/payment/config/payment_environment_config.dart';
import 'package:shamil_mobile_app/core/payment/gateways/stripe/stripe_service.dart';

// Import NFC services for proper initialization
import 'package:shamil_mobile_app/feature/access/data/enhanced_nfc_service.dart';
import 'package:shamil_mobile_app/feature/access/data/nfc_sound_service.dart';
// Import global NFC services
import 'package:shamil_mobile_app/services/shamil_nfc_service.dart';
import 'package:shamil_mobile_app/services/notification_service.dart'
    as global_notification;
// Import Firebase App Check service
import 'package:shamil_mobile_app/core/services/firebase_app_check_service.dart';

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

/// Initialize payment system with credentials
Future<void> _initializePaymentSystem() async {
  try {
    // Initialize payment credentials manager
    await PaymentCredentialsManager.instance.initializeWithStripeCredentials();

    // Initialize payment environment configuration
    await PaymentEnvironmentConfig.instance.initialize();

    // Initialize Stripe service
    await StripeService().initialize();

    debugPrint('✅ Payment system initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize payment system: $e');
    // Don't throw error to prevent app crash
    // Payment features will be disabled if initialization fails
  }
}

/// Initialize NFC services
Future<void> _initializeNFCServices() async {
  try {
    debugPrint('🔧 Initializing NFC services...');

    // Initialize sound service first
    await NFCSoundService().initialize();
    debugPrint('✅ NFC Sound Service initialized');

    // Background processing removed due to WorkManager compilation issues
    debugPrint('⚠️ Background processing disabled');

    // Initialize global notification service
    await global_notification.ShamIlNotificationService.initialize();
    debugPrint('✅ Global Notification Service initialized');

    // Initialize the enhanced NFC service (legacy)
    final nfcService = EnhancedNFCService();
    final isAvailable = await nfcService.initialize();

    if (isAvailable) {
      debugPrint('✅ Enhanced NFC Service initialized successfully');

      // Initialize global NFC service (new)
      await ShamIlNFCService.initialize();
      debugPrint('✅ Global Shamil NFC Service initialized');
    } else {
      debugPrint('⚠️ NFC not available on this device');
    }
  } catch (e) {
    debugPrint('❌ Failed to initialize NFC services: $e');
    // Don't throw error to prevent app crash
    // NFC features will be disabled if initialization fails
  }
}

/// Configure Firebase Auth for proper email delivery
Future<void> _configureFirebaseAuthEmails() async {
  try {
    debugPrint('📧 Configuring Firebase Auth email settings...');

    final FirebaseAuth auth = FirebaseAuth.instance;

    // Configure Firebase Auth settings for better email delivery
    await auth.setSettings(
      appVerificationDisabledForTesting: kDebugMode, // Only disable in debug
      forceRecaptchaFlow: !kDebugMode, // Enable reCAPTCHA in production
    );

    // Set language code to ensure proper email templates
    auth.setLanguageCode(
        'en'); // You can change this to your preferred language

    debugPrint('✅ Firebase Auth email settings configured');
    debugPrint('🔧 Debug mode: $kDebugMode');
    debugPrint('🌐 Language code: ${auth.languageCode}');
    debugPrint('🏗️ App: ${auth.app.name}');
    debugPrint('📱 Project: ${auth.app.options.projectId}');

    // Verify email settings
    _verifyEmailConfiguration();
  } catch (e) {
    debugPrint('❌ Failed to configure Firebase Auth emails: $e');
  }
}

/// Verify Firebase email configuration
void _verifyEmailConfiguration() {
  debugPrint('🔍 Firebase Auth Email Configuration Check:');
  debugPrint('--------------------------------------------------');
  debugPrint(
      '✅ App Check: ${kDebugMode ? 'DISABLED (Debug)' : 'ENABLED (Production)'}');
  debugPrint(
      '📧 Email Templates: Check Firebase Console > Authentication > Templates');
  debugPrint(
      '🌐 Authorized Domains: Verify in Firebase Console > Authentication > Settings');
  debugPrint('🔗 Action URL: Should be configured in Firebase Console');
  debugPrint('--------------------------------------------------');
  debugPrint('📋 If emails still don\'t work, check:');
  debugPrint(
      '   1. Firebase Console > Authentication > Templates (Enable all)');
  debugPrint(
      '   2. Firebase Console > Authentication > Settings > Authorized domains');
  debugPrint('   3. Check spam folder in email client');
  debugPrint('   4. Verify email address exists and is correct');
  debugPrint('--------------------------------------------------');
}

// Background task callback dispatcher removed due to WorkManager issues

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

  // Configure Firebase Auth for proper email delivery
  await _configureFirebaseAuthEmails();

  // Completely disable App Check in debug mode
  if (!kDebugMode) {
    // Only initialize App Check in production/release mode
    try {
      await FirebaseAppCheckService().initialize();
    } catch (e) {
      print(
          "⚠️ Firebase App Check initialization failed, continuing without it: $e");
      // Continue without App Check in case of failure
    }
  } else {
    print("🔧 DEBUG MODE: App Check completely disabled - no initialization");
    print(
        "📧 Email operations will use standard Firebase Auth without App Check");
  }

  // Initialize Firebase Messaging Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize payment system
  await _initializePaymentSystem();

  // Initialize NFC services
  await _initializeNFCServices();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        // Provide the centralized data orchestrator
        Provider<FirebaseDataOrchestrator>(
          create: (_) => FirebaseDataOrchestrator(),
        ),
        // Temporary: Keep old repositories for screens not yet migrated
        Provider<UserRepository>(
          create: (context) => FirebaseUserRepository(
            orchestrator: context.read<FirebaseDataOrchestrator>(),
          ),
        ),
        Provider<CommunityRepository>(
          create: (_) => CommunityRepositoryImpl(),
        ),
        Provider<ProfileRepository>(
          create: (_) => ProfileRepository(),
        ),
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
              dataOrchestrator: context.read<FirebaseDataOrchestrator>(),
              profileRepository: context.read<ProfileRepository>(),
            ),
            lazy: true,
          ),
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              dataOrchestrator: context.read<FirebaseDataOrchestrator>(),
            )..add(const LoadHomeData()),
            lazy: false,
          ),
          BlocProvider<FavoritesBloc>(
            create: (context) => FavoritesBloc(
              dataOrchestrator: context.read<FirebaseDataOrchestrator>(),
            )..add(const LoadFavorites()),
            lazy: false,
          ),
          // Payment system provider
          BlocProvider<PaymentBloc>(
            create: (context) => PaymentBloc()..add(const InitializePayments()),
          ),
        ],
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
    _configureFirebaseMessaging();
    _handleTerminatedNotification();

    // Initialize the notification service
    _initializeNotificationService();

    // Setup auth listener for NFC service
    _setupAuthListenerForNFC();
  }

  Future<void> _configureFirebaseMessaging() async {
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

  Future<void> _initializeNotificationService() async {
    try {
      await NotificationService().initialize();

      // Set user ID for notifications if user is logged in
      final firebaseAuth = FirebaseAuth.instance;
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        await NotificationService().setUserId(currentUser.uid);
      }

      // Listen for auth state changes to update notification user ID
      firebaseAuth.authStateChanges().listen((User? user) {
        if (user != null) {
          NotificationService().setUserId(user.uid);
        } else {
          NotificationService().removeUserId();
        }
      });
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  /// Setup authentication listener to update NFC service with user information
  void _setupAuthListenerForNFC() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('🔑 User logged in - updating NFC service with user info');
        debugPrint('👤 User: ${user.displayName ?? 'Unknown'} (${user.uid})');

        // The NFC service will get user info when needed through the bloc
        // No need to manually update here as the enhanced access view handles this
      } else {
        debugPrint('🔑 User logged out - clearing NFC service user info');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shamil App',
      theme: AppThemes.lightTheme,
      home: const EnhancedSplashView(),
      routes: {
        '/login': (context) => const LoginView(),
        '/home': (context) => const MainNavigationView(),
        // Payment routes
        '/payment-demo': (context) => const PaymentShowcaseScreen(),
        '/service-payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return PaymentIntegrationExamples.buildServicePaymentScreen(
            serviceId: args?['serviceId'] ?? 'default',
            serviceName: args?['serviceName'] ?? 'Service',
            amount: args?['amount'] ?? 100.0,
            userId: args?['userId'] ?? 'user123',
            userEmail: args?['userEmail'] ?? 'user@example.com',
            userName: args?['userName'] ?? 'User Name',
          );
        },
        '/subscription-payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return PaymentIntegrationExamples.buildSubscriptionPaymentScreen(
            planId: args?['planId'] ?? 'plan_default',
            planName: args?['planName'] ?? 'Plan',
            monthlyPrice: args?['monthlyPrice'] ?? 99.0,
            durationMonths: args?['durationMonths'] ?? 1,
            userId: args?['userId'] ?? 'user123',
            userEmail: args?['userEmail'] ?? 'user@example.com',
            userName: args?['userName'] ?? 'User Name',
          );
        },
        '/payments': (context) => const PaymentsScreen(),
        '/payment-history': (context) => const PaymentsScreen(),
        '/reservation-payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args == null ||
              args['reservation'] == null ||
              args['serviceProvider'] == null) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid payment data'),
              ),
            );
          }
          return ReservationPaymentScreen(
            reservation: args['reservation'],
            serviceProvider: args['serviceProvider'],
          );
        },
        '/options_configuration': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args == null || args['providerId'] == null) {
            return const Scaffold(
              body: Center(
                child: Text('Invalid configuration data'),
              ),
            );
          }

          // For now, we need to pass a mock provider until we can fetch it properly
          final provider = ServiceProviderModel(
            id: args['providerId'] as String,
            businessName: 'Service Provider',
            category: 'General',
            businessDescription: 'Service provider description',
            address: const {'city': 'Unknown', 'street': 'Unknown'},
            isActive: true,
            isApproved: true,
            pricingModel: PricingModel.reservation,
            createdAt: Timestamp.now(),
          );

          return EnhancedBookingConfigurationScreen(
            provider: provider,
            service: args['service'],
            plan: args['plan'],
          );
        },
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
