import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:workmanager/workmanager.dart';  // Removed due to compilation issues

import 'models/global_access_models.dart';
import 'notification_service.dart';

class ShamIlNFCService extends ChangeNotifier {
  static final ShamIlNFCService _instance = ShamIlNFCService._internal();
  factory ShamIlNFCService() => _instance;
  ShamIlNFCService._internal();

  // Platform channels for native communication
  static const MethodChannel _methodChannel =
      MethodChannel('shamil_nfc_service');

  // State
  bool _isAvailable = false;
  bool _isProcessing = false;
  bool _isCardEmulationEnabled = false;
  String _status = 'Initializing...';

  // Streams
  final StreamController<AccessResponseModel> _responseController =
      StreamController<AccessResponseModel>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isProcessing => _isProcessing;
  bool get isCardEmulationEnabled => _isCardEmulationEnabled;
  String get status => _status;
  Stream<AccessResponseModel> get responseStream => _responseController.stream;
  Stream<String> get statusStream => _statusController.stream;

  /// Initialize the global NFC service
  static Future<void> initialize() async {
    await _instance._initialize();
  }

  Future<void> _initialize() async {
    try {
      _updateStatus('🔧 Initializing Shamil NFC Service...');

      // Setup platform channel communication
      _methodChannel.setMethodCallHandler(_handleMethodCall);

      // Check NFC availability
      _isAvailable = await NfcManager.instance.isAvailable();

      if (_isAvailable) {
        _updateStatus('📱 NFC Available - Enabling services...');

        // Enable NFC card emulation
        await _enableCardEmulation();

        // Start global NFC monitoring
        await _startGlobalNFCMonitoring();

        // Background tasks removed due to WorkManager issues

        _updateStatus('✅ Shamil NFC Service Ready');
      } else {
        _updateStatus('❌ NFC not available on this device');
      }
    } catch (e) {
      _updateStatus('❌ NFC initialization failed: $e');
      if (kDebugMode) {
        print('❌ ShamIlNFCService initialization error: $e');
      }
    }
  }

  /// Handle platform channel method calls
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNFCDetected':
        await _handleNFCDetection(call.arguments);
        break;
      case 'onAccessResponse':
        await _handleAccessResponse(call.arguments);
        break;
      case 'onCardEmulationTriggered':
        await _handleCardEmulationTriggered(call.arguments);
        break;
      default:
        if (kDebugMode) {
          print('🤔 Unknown method call: ${call.method}');
        }
    }
  }

  /// Enable NFC card emulation
  Future<void> _enableCardEmulation() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare user data for card emulation
      final userData = NFCCardData(
        cardId: 'SHAMIL_${firebaseUser.uid.substring(0, 8)}',
        firebaseUid: firebaseUser.uid,
        userName: firebaseUser.displayName ?? 'Unknown User',
        email: firebaseUser.email ?? '',
        accessLevel: 'standard',
        issuedAt: DateTime.now().toIso8601String(),
        expiresAt:
            DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      );

      // Send user data to Android HostApduService with retry logic
      await _enableCardEmulationWithRetry(userData);

      _isCardEmulationEnabled = true;

      if (kDebugMode) {
        print('✅ NFC Card Emulation enabled for: ${userData.userName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error enabling card emulation: $e');
      }
      // Don't rethrow - let the service continue in degraded mode
      _updateStatus('⚠️ NFC Card Emulation failed - using fallback mode');
    }
  }

  /// Enable card emulation with retry logic
  Future<void> _enableCardEmulationWithRetry(NFCCardData userData) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          print('🔄 Card emulation attempt $attempt/$maxRetries');
        }

        await _methodChannel.invokeMethod('enableCardEmulation', {
          'userData': jsonEncode(userData.toJson()),
        });

        if (kDebugMode) {
          print('✅ Card emulation enabled on attempt $attempt');
        }
        return; // Success
      } catch (e) {
        if (kDebugMode) {
          print('❌ Card emulation attempt $attempt failed: $e');
        }

        if (attempt == maxRetries) {
          // Last attempt failed
          if (e is MissingPluginException) {
            throw Exception(
                'NFC Method Channel not available - Native Android code may not be properly compiled');
          } else {
            rethrow;
          }
        }

        // Wait before retry
        await Future.delayed(retryDelay);
      }
    }
  }

  /// Disable NFC card emulation
  Future<void> _disableCardEmulation() async {
    try {
      await _methodChannel.invokeMethod('disableCardEmulation');
      _isCardEmulationEnabled = false;

      if (kDebugMode) {
        print('❌ NFC Card Emulation disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disabling card emulation: $e');
      }
    }
  }

  /// Start global NFC monitoring
  Future<void> _startGlobalNFCMonitoring() async {
    try {
      // Start listening for NFC events globally
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          if (!_isProcessing) {
            await _handleGlobalNFCDetection(tag);
          }
        },
      );

      if (kDebugMode) {
        print('👂 Global NFC monitoring started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting global NFC monitoring: $e');
      }
    }
  }

  /// Handle global NFC detection
  Future<void> _handleGlobalNFCDetection(NfcTag tag) async {
    try {
      _setProcessing(true);
      _updateStatus('🔄 Processing NFC access request...');

      // Perform access request
      final result = await performGlobalAccess();

      if (result.success) {
        _updateStatus('✅ Access granted');
        await ShamIlNotificationService.showAccessGrantedNotification(
          result.userName ?? 'User',
        );
      } else {
        _updateStatus('❌ Access denied');
        await ShamIlNotificationService.showAccessDeniedNotification(
          result.reason ?? 'Unknown error',
        );
      }

      // Emit response
      _responseController.add(result);
    } catch (e) {
      _updateStatus('❌ Access failed: $e');
      if (kDebugMode) {
        print('❌ Global NFC detection error: $e');
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Handle platform-level NFC detection
  Future<void> _handleNFCDetection(dynamic arguments) async {
    if (kDebugMode) {
      print('📱 Platform NFC Detection: $arguments');
    }
    // Handle NFC detection from native side
  }

  /// Handle access response from ESP32
  Future<void> _handleAccessResponse(dynamic arguments) async {
    try {
      if (arguments is String) {
        final response = AccessResponseModel.fromESP32Response(arguments);
        _responseController.add(response);

        if (kDebugMode) {
          print('📥 Received access response: ${response.success}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling access response: $e');
      }
    }
  }

  /// Handle card emulation trigger
  Future<void> _handleCardEmulationTriggered(dynamic arguments) async {
    if (kDebugMode) {
      print('💳 Card emulation triggered: $arguments');
    }

    // Update status when card is being read
    _updateStatus('💳 NFC card being read...');

    // Send notification
    await ShamIlNotificationService.showNFCInteractionNotification();
  }

  /// Perform global access from anywhere in the app
  static Future<AccessResponseModel> performGlobalAccess() async {
    return await _instance._performAccess();
  }

  /// Core access functionality
  Future<AccessResponseModel> _performAccess() async {
    try {
      _setProcessing(true);
      _updateStatus('🔐 Preparing access request...');

      // Get current Firebase user
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }

      // Ensure non-nullable email string
      final String userEmail = firebaseUser.email ?? 'no-email@shamil.app';

      // Create enhanced protocol request
      final accessRequest = AccessRequestModel(
        protocolVersion: '1.0',
        appId: 'SHAMIL_ACCESS_CONTROL',
        action: 'ACCESS_REQUEST',
        userData: UserDataModel(
          firebaseUid: firebaseUser.uid,
          userName: firebaseUser.displayName ?? 'Unknown User',
          email: userEmail,
        ),
        requestData: RequestDataModel(
          requestId: 'REQ_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now().toIso8601String(),
          deviceType: 'mobile',
          appVersion: '1.0.0',
        ),
        authToken: await firebaseUser.getIdToken() ?? 'NO_TOKEN',
      );

      _updateStatus('📡 Transmitting to ESP32...');

      // Use card emulation for data transmission
      final success = await _transmitViaCardEmulation(accessRequest);

      if (success) {
        _updateStatus('⏳ Waiting for response...');

        // Listen for response (timeout after 15 seconds)
        final response = await _listenForResponse().timeout(
          const Duration(seconds: 15),
          onTimeout: () => AccessResponseModel(
            success: false,
            reason: 'Response timeout - ESP32 not responding',
          ),
        );

        return response;
      } else {
        return AccessResponseModel(
          success: false,
          reason: 'Failed to transmit data to ESP32',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Access performance error: $e');
      }

      return AccessResponseModel(
        success: false,
        reason: 'Access request failed: $e',
      );
    } finally {
      _setProcessing(false);
    }
  }

  /// Transmit data via card emulation
  Future<bool> _transmitViaCardEmulation(AccessRequestModel request) async {
    try {
      // Update card data with current request
      await _methodChannel.invokeMethod('updateCardData', {
        'requestData': request.toESP32Json(),
      });

      if (kDebugMode) {
        print('📤 Card emulation data updated');
        print('🔑 Firebase UID: ${request.userData.firebaseUid}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating card data: $e');
      }
      return false;
    }
  }

  /// Listen for access response
  Future<AccessResponseModel> _listenForResponse() async {
    // Use the response stream to wait for response
    return _responseController.stream.first.timeout(
      const Duration(seconds: 15),
      onTimeout: () => AccessResponseModel(
        success: false,
        reason: 'Response timeout',
      ),
    );
  }

  /// Background tasks removed due to WorkManager compilation issues
  // Future<void> _registerBackgroundTasks() async { ... }

  /// Manual access trigger (for testing or manual use)
  Future<AccessResponseModel> triggerManualAccess() async {
    return await _performAccess();
  }

  /// Update current user data
  Future<void> updateUserData() async {
    if (_isCardEmulationEnabled) {
      await _enableCardEmulation(); // Refresh card data
    }
  }

  /// Update processing state
  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  /// Update status
  void _updateStatus(String status) {
    _status = status;
    _statusController.add(status);
    notifyListeners();

    if (kDebugMode) {
      print('📱 NFC Status: $status');
    }
  }

  /// Stop global NFC services
  Future<void> stopGlobalServices() async {
    try {
      await NfcManager.instance.stopSession();
      await _disableCardEmulation();
      // Background task cancellation removed due to WorkManager issues
      _updateStatus('🛑 NFC services stopped');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping NFC services: $e');
      }
    }
  }

  @override
  void dispose() {
    stopGlobalServices();
    _responseController.close();
    _statusController.close();
    super.dispose();
  }
}
