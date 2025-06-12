import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../data/enhanced_nfc_service.dart';
import '../data/models/nfc_models.dart';

// Events
abstract class EnhancedAccessEvent extends Equatable {
  const EnhancedAccessEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNFCEvent extends EnhancedAccessEvent {}

class RequestNFCAccessEvent extends EnhancedAccessEvent {
  final String userId;
  final String? userName;

  const RequestNFCAccessEvent({
    required this.userId,
    this.userName,
  });

  @override
  List<Object?> get props => [userId, userName];
}

class StartNFCListeningEvent extends EnhancedAccessEvent {
  final String userId;
  final String? userName;

  const StartNFCListeningEvent({
    required this.userId,
    this.userName,
  });

  @override
  List<Object?> get props => [userId, userName];
}

class StopNFCSessionEvent extends EnhancedAccessEvent {}

class NFCResponseReceivedEvent extends EnhancedAccessEvent {
  final NFCAccessResponse response;

  const NFCResponseReceivedEvent(this.response);

  @override
  List<Object?> get props => [response];
}

class NFCStatusChangedEvent extends EnhancedAccessEvent {
  final EnhancedNFCStatus status;

  const NFCStatusChangedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class ResetNFCEvent extends EnhancedAccessEvent {}

// States
abstract class EnhancedAccessState extends Equatable {
  const EnhancedAccessState();

  @override
  List<Object?> get props => [];
}

class EnhancedAccessInitial extends EnhancedAccessState {}

class NFCInitializing extends EnhancedAccessState {}

class NFCNotAvailable extends EnhancedAccessState {
  final String reason;

  const NFCNotAvailable(this.reason);

  @override
  List<Object?> get props => [reason];
}

class NFCReady extends EnhancedAccessState {
  final String? deviceUID;

  const NFCReady(this.deviceUID);

  @override
  List<Object?> get props => [deviceUID];
}

class NFCScanning extends EnhancedAccessState {
  final String message;

  const NFCScanning(this.message);

  @override
  List<Object?> get props => [message];
}

class NFCWriting extends EnhancedAccessState {}

class NFCListening extends EnhancedAccessState {
  final bool isFromAccessScreen;

  const NFCListening({this.isFromAccessScreen = false});

  @override
  List<Object?> get props => [isFromAccessScreen];
}

class NFCProcessing extends EnhancedAccessState {}

class NFCAccessSuccess extends EnhancedAccessState {
  final NFCAccessResponse response;
  final bool showBottomSheet;

  const NFCAccessSuccess({
    required this.response,
    this.showBottomSheet = true,
  });

  @override
  List<Object?> get props => [response, showBottomSheet];
}

class NFCAccessDenied extends EnhancedAccessState {
  final NFCAccessResponse response;
  final bool showBottomSheet;

  const NFCAccessDenied({
    required this.response,
    this.showBottomSheet = true,
  });

  @override
  List<Object?> get props => [response, showBottomSheet];
}

class NFCTimeout extends EnhancedAccessState {
  final String message;

  const NFCTimeout(this.message);

  @override
  List<Object?> get props => [message];
}

class NFCError extends EnhancedAccessState {
  final String message;
  final dynamic error;

  const NFCError(this.message, {this.error});

  @override
  List<Object?> get props => [message, error];
}

// Enhanced Access Bloc
class EnhancedAccessBloc
    extends Bloc<EnhancedAccessEvent, EnhancedAccessState> {
  final EnhancedNFCService _nfcService = EnhancedNFCService();
  StreamSubscription? _statusSubscription;
  StreamSubscription? _responseSubscription;
  StreamSubscription? _debugSubscription;
  bool _isInitialized = false;
  bool _isListeningFromAccessScreen = false;

  EnhancedAccessBloc() : super(EnhancedAccessInitial()) {
    on<InitializeNFCEvent>(_onInitializeNFC);
    on<RequestNFCAccessEvent>(_onRequestNFCAccess);
    on<StartNFCListeningEvent>(_onStartNFCListening);
    on<StopNFCSessionEvent>(_onStopNFCSession);
    on<NFCResponseReceivedEvent>(_onNFCResponseReceived);
    on<NFCStatusChangedEvent>(_onNFCStatusChanged);
    on<ResetNFCEvent>(_onResetNFC);

    _initializeSubscriptions();
  }

  void _initializeSubscriptions() {
    if (_isInitialized) return;

    // Listen to NFC status changes
    _statusSubscription = _nfcService.statusStream.listen((status) {
      if (!isClosed) {
        add(NFCStatusChangedEvent(status));
      }
    });

    // Listen to NFC responses
    _responseSubscription = _nfcService.responseStream.listen((response) {
      if (!isClosed) {
        add(NFCResponseReceivedEvent(response));
      }
    });

    // Listen to debug messages (optional)
    if (kDebugMode) {
      _debugSubscription = _nfcService.debugStream.listen((message) {
        debugPrint('[Enhanced Access Bloc] $message');
      });
    }

    _isInitialized = true;
  }

  void _cleanupSubscriptions() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _responseSubscription?.cancel();
    _responseSubscription = null;
    _debugSubscription?.cancel();
    _debugSubscription = null;
    _isInitialized = false;
  }

  Future<void> _onInitializeNFC(
    InitializeNFCEvent event,
    Emitter<EnhancedAccessState> emit,
  ) async {
    emit(NFCInitializing());

    try {
      final isAvailable = await _nfcService.initialize();

      if (isAvailable) {
        emit(NFCReady(_nfcService.deviceUID));
      } else {
        emit(const NFCNotAvailable('NFC is not available on this device'));
      }
    } catch (e) {
      emit(NFCError('Failed to initialize NFC: ${e.toString()}', error: e));
    }
  }

  Future<void> _onRequestNFCAccess(
    RequestNFCAccessEvent event,
    Emitter<EnhancedAccessState> emit,
  ) async {
    try {
      emit(const NFCScanning('Hold your device near an NFC reader'));

      await _nfcService.requestAccess(
        userId: event.userId,
        userName: event.userName,
      );
    } catch (e) {
      emit(NFCError('Failed to start NFC access request: ${e.toString()}',
          error: e));
    }
  }

  Future<void> _onStartNFCListening(
    StartNFCListeningEvent event,
    Emitter<EnhancedAccessState> emit,
  ) async {
    try {
      _isListeningFromAccessScreen = true;
      emit(const NFCListening(isFromAccessScreen: true));

      await _nfcService.startListening(
        userId: event.userId,
        userName: event.userName,
      );
    } catch (e) {
      _isListeningFromAccessScreen = false;
      emit(
          NFCError('Failed to start NFC listening: ${e.toString()}', error: e));
    }
  }

  Future<void> _onStopNFCSession(
    StopNFCSessionEvent event,
    Emitter<EnhancedAccessState> emit,
  ) async {
    try {
      await _nfcService.stopSession();
      _isListeningFromAccessScreen = false;

      // Return to ready state if NFC is available
      if (_nfcService.deviceUID != null) {
        emit(NFCReady(_nfcService.deviceUID));
      } else {
        emit(EnhancedAccessInitial());
      }
    } catch (e) {
      emit(NFCError('Failed to stop NFC session: ${e.toString()}', error: e));
    }
  }

  void _onNFCResponseReceived(
    NFCResponseReceivedEvent event,
    Emitter<EnhancedAccessState> emit,
  ) {
    final response = event.response;

    // Determine if we should show bottom sheet
    // Don't show bottom sheet if user is on access screen and listening
    final showBottomSheet = !_isListeningFromAccessScreen;

    if (response.accessGranted) {
      emit(NFCAccessSuccess(
        response: response,
        showBottomSheet: showBottomSheet,
      ));
    } else {
      emit(NFCAccessDenied(
        response: response,
        showBottomSheet: showBottomSheet,
      ));
    }

    // Reset listening flag
    _isListeningFromAccessScreen = false;
  }

  void _onNFCStatusChanged(
    NFCStatusChangedEvent event,
    Emitter<EnhancedAccessState> emit,
  ) {
    final status = event.status;

    switch (status) {
      case EnhancedNFCStatus.notAvailable:
        emit(const NFCNotAvailable('NFC is not available'));
        break;

      case EnhancedNFCStatus.available:
        emit(NFCReady(_nfcService.deviceUID));
        break;

      case EnhancedNFCStatus.scanning:
        emit(const NFCScanning('Scanning for NFC devices...'));
        break;

      case EnhancedNFCStatus.writing:
        emit(NFCWriting());
        break;

      case EnhancedNFCStatus.listening:
        emit(NFCListening(isFromAccessScreen: _isListeningFromAccessScreen));
        break;

      case EnhancedNFCStatus.processing:
        emit(NFCProcessing());
        break;

      case EnhancedNFCStatus.success:
        // Response will be handled by NFCResponseReceivedEvent
        break;

      case EnhancedNFCStatus.denied:
        // Response will be handled by NFCResponseReceivedEvent
        break;

      case EnhancedNFCStatus.timeout:
        emit(const NFCTimeout('Request timeout. Please try again.'));
        break;

      case EnhancedNFCStatus.error:
        emit(const NFCError('An NFC error occurred'));
        break;
    }
  }

  Future<void> _onResetNFC(
    ResetNFCEvent event,
    Emitter<EnhancedAccessState> emit,
  ) async {
    try {
      await _nfcService.stopSession();
      _isListeningFromAccessScreen = false;

      // Reinitialize
      final isAvailable = await _nfcService.initialize();

      if (isAvailable) {
        emit(NFCReady(_nfcService.deviceUID));
      } else {
        emit(const NFCNotAvailable('NFC is not available after reset'));
      }
    } catch (e) {
      emit(NFCError('Failed to reset NFC: ${e.toString()}', error: e));
    }
  }

  // Helper methods
  bool get isNFCActive => _nfcService.isSessionActive;
  NFCOperation get currentOperation => _nfcService.currentOperation;
  String? get deviceUID => _nfcService.deviceUID;

  @override
  Future<void> close() {
    _cleanupSubscriptions();
    _nfcService.dispose();
    return super.close();
  }
}
