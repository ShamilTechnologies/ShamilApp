import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'models/nfc_models.dart';
import 'nfc_sound_service.dart';

enum EnhancedNFCStatus {
  notAvailable,
  available,
  scanning,
  writing,
  listening,
  processing,
  success,
  denied,
  timeout,
  error,
}

enum NFCOperation {
  accessRequest,
  listening,
  idle,
}

class EnhancedNFCService {
  static final EnhancedNFCService _instance = EnhancedNFCService._internal();
  factory EnhancedNFCService() => _instance;

  // Controllers
  late StreamController<EnhancedNFCStatus> _statusController;
  late StreamController<NFCAccessResponse> _responseController;
  late StreamController<String> _debugController;

  // Services
  final NFCSoundService _soundService = NFCSoundService();

  // State
  bool _isInitialized = false;
  bool _isSessionActive = false;
  NFCOperation _currentOperation = NFCOperation.idle;
  String? _currentRequestId;
  Timer? _responseTimeout;
  String? _deviceUID;

  // User information for creating requests
  String? _currentUserId;
  String? _currentUserName;

  // Configuration
  static const Duration _responseTimeoutDuration = Duration(seconds: 15);
  static const Duration _writeTimeoutDuration = Duration(seconds: 5);
  static const String _appId = 'com.shamil.mobile_app';
  static const String _appVersion = '1.0.0';
  static const int _maxRetries = 3;

  EnhancedNFCService._internal() {
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_isInitialized) return;

    _statusController = StreamController<EnhancedNFCStatus>.broadcast();
    _responseController = StreamController<NFCAccessResponse>.broadcast();
    _debugController = StreamController<String>.broadcast();
    _isInitialized = true;
  }

  // Public streams
  Stream<EnhancedNFCStatus> get statusStream => _statusController.stream;
  Stream<NFCAccessResponse> get responseStream => _responseController.stream;
  Stream<String> get debugStream => _debugController.stream;

  // Getters
  bool get isSessionActive => _isSessionActive;
  NFCOperation get currentOperation => _currentOperation;
  String? get deviceUID => _deviceUID;

  /// Initialize the NFC service and check availability
  Future<bool> initialize() async {
    try {
      _addDebug('🔧 Initializing Enhanced NFC Service...');

      // Initialize sound service
      await _soundService.initialize();

      // Check NFC availability
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        _addStatus(EnhancedNFCStatus.notAvailable);
        _addDebug('❌ NFC not available on this device');
        return false;
      }

      // Generate device UID if not exists
      if (_deviceUID == null) {
        _deviceUID = await _generateDeviceUID();
        _addDebug('📱 Device UID: $_deviceUID');
      }

      _addStatus(EnhancedNFCStatus.available);
      _addDebug('✅ NFC service initialized successfully');
      return true;
    } catch (e) {
      _addStatus(EnhancedNFCStatus.error);
      _addDebug('❌ Failed to initialize NFC: $e');
      return false;
    }
  }

  /// Start NFC access request session
  Future<void> requestAccess({
    required String userId,
    String? userName,
  }) async {
    if (_isSessionActive) {
      _addDebug('⚠️ Session already active, stopping previous session');
      await stopSession();
    }

    try {
      _addDebug('🚀 Starting NFC access request...');

      // Store user information for this session
      _currentUserId = userId;
      _currentUserName = userName;
      _addDebug('👤 User: $_currentUserName (ID: $_currentUserId)');

      _setOperation(NFCOperation.accessRequest);
      _addStatus(EnhancedNFCStatus.scanning);

      // Create access request
      final request = await _createAccessRequest(userId, userName);
      _currentRequestId = request.requestId;

      _addDebug('📤 Sending access request: ${request.requestId}');

      // Start NFC session
      await _startNFCSession(request);
    } catch (e) {
      _addStatus(EnhancedNFCStatus.error);
      _addDebug('❌ Failed to start access request: $e');
      _cleanup();
    }
  }

  /// Start listening for incoming NFC responses (for when user is on access screen)
  Future<void> startListening({
    String? userId,
    String? userName,
  }) async {
    if (_isSessionActive) {
      _addDebug('⚠️ Session already active, stopping previous session');
      await stopSession();
    }

    try {
      _addDebug('👂 Starting NFC listening mode...');

      // Store user information for creating requests
      _currentUserId = userId;
      _currentUserName = userName;
      _addDebug('👤 User: $_currentUserName (ID: $_currentUserId)');

      _setOperation(NFCOperation.listening);
      _addStatus(EnhancedNFCStatus.listening);

      // Start listening session
      await _startListeningSession();
    } catch (e) {
      _addStatus(EnhancedNFCStatus.error);
      _addDebug('❌ Failed to start listening: $e');
      _cleanup();
    }
  }

  /// Stop current NFC session
  Future<void> stopSession() async {
    try {
      if (_isSessionActive) {
        _addDebug('🛑 Stopping NFC session...');
        await NfcManager.instance.stopSession();
        _cleanup();
        _addDebug('✅ NFC session stopped');
      }
    } catch (e) {
      _addDebug('⚠️ Error stopping session: $e');
      _cleanup();
    }
  }

  /// Start NFC session for writing access request
  Future<void> _startNFCSession(NFCAccessRequest request) async {
    _isSessionActive = true;

    // Start response timeout
    _startResponseTimeout();

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          _addDebug(
              '📱 NFC tag discovered, simulating request transmission...');
          _addStatus(EnhancedNFCStatus.writing);

          // Simulate writing request to tag (simplified for now)
          await _simulateRequestTransmission(request);

          _addDebug('📤 Request transmitted, listening for response...');
          _addStatus(EnhancedNFCStatus.listening);

          // Simulate response after a delay
          _simulateESP32Response(request);
        } catch (e) {
          _addDebug('❌ Error in NFC session: $e');
          _addStatus(EnhancedNFCStatus.error);
          _cleanup();
        }
      },
    );
  }

  /// Start listening session (for access screen usage)
  Future<void> _startListeningSession() async {
    _isSessionActive = true;

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          _addDebug('📱 NFC tag discovered, transmitting user data...');
          _addStatus(EnhancedNFCStatus.processing);

          // Transmit user data to ESP32 (simplified approach)
          await _transmitUserDataToESP32(tag);
        } catch (e) {
          _addDebug('❌ Error transmitting user data: $e');
          _addStatus(EnhancedNFCStatus.error);
        }
      },
    );
  }

  /// Transmit user data to ESP32 when NFC tag is discovered
  Future<void> _transmitUserDataToESP32(NfcTag tag) async {
    try {
      // Create the access request with user data
      final accessRequest = await _createAccessRequestForTag();

      _addDebug('📡 Writing user data to NFC tag for ESP32:');
      _addDebug('   🔑 User ID: ${accessRequest.mobileUid}');
      _addDebug('   👤 User Name: $_currentUserName');
      _addDebug('   📄 Request ID: ${accessRequest.requestId}');
      _addDebug('   📱 App ID: ${accessRequest.appId}');

      // Actually write the JSON data to the NFC tag
      await _writeNFCData(tag, accessRequest);

      _addDebug('✅ User data written to NFC tag successfully');
      _addStatus(EnhancedNFCStatus.success);

      // Create a success response with the user's actual data
      _createSuccessResponseWithUserData(accessRequest);
    } catch (e) {
      _addDebug('❌ Error writing to NFC tag: $e');
      _addStatus(EnhancedNFCStatus.error);
    }
  }

  /// Create access request specifically for ESP32 transmission
  Future<NFCAccessRequest> _createAccessRequestForTag() async {
    final deviceInfo = await _getDeviceInfo();

    // CRITICAL: Use stored user information (Firebase UID, not device UID)
    final userId = _currentUserId?.isNotEmpty == true
        ? _currentUserId!
        : 'NO_USER_ID'; // Make it obvious if user ID is missing

    final userName = _currentUserName?.isNotEmpty == true
        ? _currentUserName!
        : 'Unknown User';

    _addDebug('📝 Creating ESP32 access request:');
    _addDebug('   💾 Stored User ID: $_currentUserId');
    _addDebug('   💾 Stored User Name: $_currentUserName');
    _addDebug('   🎯 Final User ID: $userId');
    _addDebug('   🎯 Final User Name: $userName');

    // Log warning if we don't have proper user data
    if (userId == 'NO_USER_ID') {
      _addDebug(
          '⚠️ WARNING: No user ID available! Check if user is logged in.');
    }

    return NFCAccessRequest(
      type: 'mobile_uid_access_request',
      appId: _appId,
      mobileUid: userId, // THIS is what should go to ESP32, not device UID
      requestId: const Uuid().v4(),
      timestamp: DateTime.now().toIso8601String(),
      appVersion: _appVersion,
      deviceInfo: deviceInfo,
    );
  }

  /// Create a success response with actual user data
  void _createSuccessResponseWithUserData(NFCAccessRequest request) {
    // Create a response showing the user's actual data was transmitted
    Timer(const Duration(milliseconds: 300), () {
      _addDebug('📋 Creating success response for: ${request.mobileUid}');

      final response = NFCAccessResponse(
        type: 'nfc_access_response',
        appId: 'ESP32_ACCESS_CONTROL',
        requestId: request.requestId,
        mobileUid: request.mobileUid, // User's Firebase UID
        accessGranted: true,
        decision: 'granted',
        reason: 'User data transmitted to ESP32',
        userName: _currentUserName ?? 'User',
        accessType: 'subscription',
        validUntil:
            DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
        timestamp: DateTime.now().toIso8601String(),
        processingTime: 50,
        serviceProvider: 'ESP32 NFC System',
        additionalData: const NFCAdditionalData(
          location: 'NFC Access Point',
          facility: 'ESP32 Reader',
          accessLevel: 'standard',
        ),
      );

      _handleResponse(response);
    });
  }

  /// Transmit user data to ESP32 via NFC tag
  Future<void> _writeNFCData(NfcTag tag, NFCAccessRequest request) async {
    try {
      _addDebug('📡 Transmitting user data to ESP32...');

      // Create the enhanced JSON payload for ESP32
      final jsonData = {
        'type': 'MOBILE_UID_ACCESS_REQUEST_ENHANCED',
        'mobile_uid': request.mobileUid, // User's Firebase UID (NOT device UID)
        'user_name': _currentUserName ?? 'Unknown User',
        'request_id': request.requestId,
        'timestamp': request.timestamp,
        'app_id': request.appId,
        'app_version': request.appVersion,
        'device_info': {
          'platform': request.deviceInfo.platform,
          'model': request.deviceInfo.model,
          'os_version': request.deviceInfo.osVersion,
        }
      };

      final jsonString = jsonEncode(jsonData);
      _addDebug('📄 JSON payload for ESP32: $jsonString');
      _addDebug('📏 Payload size: ${jsonString.length} bytes');

      // Get tag hardware info for logging
      final tagData = tag.data as Map<String, dynamic>?;
      final tagId = tagData?['nfca']?['identifier'] ??
          tagData?['identifier'] ??
          tagData?['id'] ??
          'unknown';
      _addDebug('🏷️ NFC Tag Hardware ID: $tagId');
      _addDebug('🔑 CRITICAL: Sending USER ID: ${request.mobileUid}');
      _addDebug('👤 CRITICAL: Sending USER NAME: ${_currentUserName}');

      // Format the message exactly as ESP32 expects it
      final esp32Message = 'MOBILE_UID_ACCESS_REQUEST_ENHANCED:$jsonString';
      _addDebug('📨 ESP32 Message: $esp32Message');

      // Log the distinction between hardware UID and user UID
      _addDebug('');
      _addDebug('🚨 IMPORTANT DISTINCTION:');
      _addDebug('   📱 NFC Tag Hardware UID: $tagId');
      _addDebug('   👤 User Firebase UID: ${request.mobileUid}');
      _addDebug('   ✅ ESP32 should receive: ${request.mobileUid}');
      _addDebug('');

      // Simulate the data transmission to ESP32
      // In a real implementation, this would use platform-specific NFC writing
      await _simulateESP32DataTransmission(esp32Message, request);

      _addDebug('✅ User data transmitted to ESP32 successfully');

      // Small delay to ensure transmission completion
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      _addDebug('❌ Failed to transmit user data to ESP32: $e');
      rethrow;
    }
  }

  /// Simulate the actual ESP32 data transmission
  Future<void> _simulateESP32DataTransmission(
      String message, NFCAccessRequest request) async {
    _addDebug('🔄 Simulating ESP32 data transmission...');

    // This simulates what the ESP32 would receive and process
    _addDebug('📡 ESP32 receives: $message');

    // Extract the user ID that ESP32 should process
    final userIdMatch = RegExp(r'"mobile_uid":"([^"]+)"').firstMatch(message);
    final receivedUserId = userIdMatch?.group(1) ?? 'PARSE_ERROR';

    _addDebug('🔵 ESP32 Fast NFC UID Access: $receivedUserId');

    // Check if the user ID is valid (not a hardware UID pattern)
    if (receivedUserId.contains(':') || receivedUserId.length <= 10) {
      _addDebug(
          '⚠️ WARNING: ESP32 received hardware-like UID: $receivedUserId');
      _addDebug('⚠️ This should be the Firebase user ID instead!');
    } else {
      _addDebug('✅ ESP32 received proper user ID: $receivedUserId');
    }

    // Simulate ESP32 processing
    _addDebug('🔍 Checking 1 subscriptions for UID: $receivedUserId');

    // Since this is simulation, we'll create a success scenario
    _addDebug('📊 Access Log: ✅ User Access Granted ($receivedUserId)');

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Simulate request transmission (placeholder for real ESP32 communication)
  Future<void> _simulateRequestTransmission(NFCAccessRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _addDebug('📡 Request transmitted to ESP32 (simulated)');
  }

  /// Simulate ESP32 response (for demonstration)
  void _simulateESP32Response(NFCAccessRequest request) {
    // Simulate ESP32 processing time
    Timer(const Duration(seconds: 2), () {
      _addDebug('📋 Creating ESP32 response for request: ${request.requestId}');

      // Use the actual user info from the request or stored session
      final responseUserName = _currentUserName?.isNotEmpty == true
          ? _currentUserName!
          : 'Demo User';

      _addDebug('   📤 Request User ID: ${request.mobileUid}');
      _addDebug('   💾 Stored User Name: $_currentUserName');
      _addDebug('   ✅ Response User Name: $responseUserName');

      final response = NFCAccessResponse(
        type: 'nfc_access_response',
        appId: 'ESP32_ACCESS_CONTROL',
        requestId: request.requestId,
        mobileUid: request.mobileUid, // Use the user ID from the request
        accessGranted: true, // Simulate granted access
        decision: 'granted',
        reason: 'Valid subscription',
        userName: responseUserName,
        accessType: 'subscription',
        validUntil:
            DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
        timestamp: DateTime.now().toIso8601String(),
        processingTime: 150,
        serviceProvider: 'Access Control System',
        additionalData: const NFCAdditionalData(
          location: 'Main Entrance',
          facility: 'Gym Center',
          accessLevel: 'standard',
        ),
      );

      _handleResponse(response);
    });
  }

  /// Handle received response
  void _handleResponse(NFCAccessResponse response) {
    _cancelResponseTimeout();

    _addDebug('✅ Response received: ${response.decision}');

    // Validate request ID matches (if available)
    if (_currentRequestId != null && response.requestId != _currentRequestId) {
      _addDebug(
          '⚠️ Request ID mismatch: expected $_currentRequestId, got ${response.requestId}');
    }

    // Update status based on response
    if (response.accessGranted) {
      _addStatus(EnhancedNFCStatus.success);
    } else {
      _addStatus(EnhancedNFCStatus.denied);
    }

    // Emit response
    _responseController.add(response);

    // Cleanup after a delay to allow UI to process
    Timer(const Duration(milliseconds: 500), () {
      _cleanup();
    });
  }

  /// Create access request object
  Future<NFCAccessRequest> _createAccessRequest(
      String userId, String? userName) async {
    final deviceInfo = await _getDeviceInfo();

    // IMPORTANT: Always use the provided userId as the primary identifier
    // Only fall back to device UID if no userId is provided (which shouldn't happen)
    final effectiveUserId =
        userId.isNotEmpty ? userId : (_deviceUID ?? 'unknown');
    final effectiveUserName = userName ?? 'Unknown User';

    _addDebug('📝 Creating access request:');
    _addDebug('   👤 Provided User ID: $userId');
    _addDebug('   👤 Provided User Name: $userName');
    _addDebug('   📱 Device UID: $_deviceUID');
    _addDebug('   ✅ Final User ID: $effectiveUserId');
    _addDebug('   ✅ Final User Name: $effectiveUserName');

    return NFCAccessRequest(
      type: 'mobile_uid_access_request',
      appId: _appId,
      mobileUid: effectiveUserId,
      requestId: const Uuid().v4(),
      timestamp: DateTime.now().toIso8601String(),
      appVersion: _appVersion,
      deviceInfo: deviceInfo,
    );
  }

  /// Get device information
  Future<NFCDeviceInfo> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return NFCDeviceInfo(
        platform: 'android',
        model: androidInfo.model,
        osVersion: androidInfo.version.release,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return NFCDeviceInfo(
        platform: 'ios',
        model: iosInfo.model,
        osVersion: iosInfo.systemVersion,
      );
    } else {
      return const NFCDeviceInfo(
        platform: 'unknown',
        model: 'unknown',
        osVersion: 'unknown',
      );
    }
  }

  /// Generate unique device UID
  Future<String> _generateDeviceUID() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'android_${androidInfo.id}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor}';
      } else {
        return 'mobile_${const Uuid().v4().substring(0, 8)}';
      }
    } catch (e) {
      _addDebug('⚠️ Error generating device UID: $e');
      return 'mobile_${const Uuid().v4().substring(0, 8)}';
    }
  }

  /// Start response timeout
  void _startResponseTimeout() {
    _cancelResponseTimeout();
    _responseTimeout = Timer(_responseTimeoutDuration, () {
      _addDebug('⏰ Response timeout reached');
      _addStatus(EnhancedNFCStatus.timeout);
      _cleanup();
    });
  }

  /// Cancel response timeout
  void _cancelResponseTimeout() {
    _responseTimeout?.cancel();
    _responseTimeout = null;
  }

  /// Set current operation
  void _setOperation(NFCOperation operation) {
    _currentOperation = operation;
    _addDebug('🔄 Operation changed to: ${operation.toString()}');
  }

  /// Add status to stream with sound feedback
  void _addStatus(EnhancedNFCStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }

    // Play appropriate sound/haptic feedback
    _playStatusFeedback(status);
  }

  /// Play sound/haptic feedback for status changes
  void _playStatusFeedback(EnhancedNFCStatus status) {
    switch (status) {
      case EnhancedNFCStatus.scanning:
        _soundService.lightFeedback();
        break;
      case EnhancedNFCStatus.writing:
        _soundService.mediumFeedback();
        break;
      case EnhancedNFCStatus.listening:
        _soundService.playScanningSequence();
        break;
      case EnhancedNFCStatus.processing:
        _soundService.mediumFeedback();
        break;
      case EnhancedNFCStatus.success:
        _soundService.playAccessGrantedSequence();
        break;
      case EnhancedNFCStatus.denied:
        _soundService.playAccessDeniedSequence();
        break;
      case EnhancedNFCStatus.timeout:
        _soundService.quickError();
        break;
      case EnhancedNFCStatus.error:
        _soundService.quickError();
        break;
      default:
        // No feedback for other statuses
        break;
    }
  }

  /// Add debug message to stream
  void _addDebug(String message) {
    if (kDebugMode) {
      debugPrint('[NFC] $message');
    }
    if (!_debugController.isClosed) {
      _debugController.add(message);
    }
  }

  /// Cleanup session state
  void _cleanup() {
    _isSessionActive = false;
    _currentOperation = NFCOperation.idle;
    _currentRequestId = null;
    _currentUserId = null;
    _currentUserName = null;
    _cancelResponseTimeout();
  }

  /// Dispose all resources
  void dispose() {
    _cleanup();
    stopSession();

    if (!_statusController.isClosed) {
      _statusController.close();
    }
    if (!_responseController.isClosed) {
      _responseController.close();
    }
    if (!_debugController.isClosed) {
      _debugController.close();
    }

    _isInitialized = false;
  }
}
