import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/feature/access/data/nfc_service.dart';

// Events
abstract class AccessEvent extends Equatable {
  const AccessEvent();

  @override
  List<Object?> get props => [];
}

class CheckNFCAvailabilityEvent extends AccessEvent {}

class StartNFCSessionEvent extends AccessEvent {}

class StopNFCSessionEvent extends AccessEvent {}

class StartNFCWriteSessionEvent extends AccessEvent {
  final String userId;

  const StartNFCWriteSessionEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class StartNFCBeamSessionEvent extends AccessEvent {
  final String userId;

  const StartNFCBeamSessionEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class NFCTagReadEvent extends AccessEvent {
  final String userId;

  const NFCTagReadEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ActivateNFCEvent extends AccessEvent {}

class ResetNFCServiceEvent extends AccessEvent {}

// States
abstract class AccessState extends Equatable {
  const AccessState();

  @override
  List<Object?> get props => [];
}

class AccessInitial extends AccessState {}

class NFCAvailableState extends AccessState {}

class NFCUnavailableState extends AccessState {}

class NFCReadingState extends AccessState {}

class NFCWritingState extends AccessState {}

class NFCSuccessState extends AccessState {
  final String userId;
  final bool isWriteSuccess;

  const NFCSuccessState(this.userId, {this.isWriteSuccess = false});

  @override
  List<Object?> get props => [userId, isWriteSuccess];
}

class NFCErrorState extends AccessState {
  final String? message;

  const NFCErrorState([this.message]);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AccessBloc extends Bloc<AccessEvent, AccessState> {
  final NFCService _nfcService = NFCService();
  StreamSubscription? _nfcStatusSubscription;
  StreamSubscription? _nfcTagDataSubscription;
  bool _isInitialized = false;

  AccessBloc() : super(AccessInitial()) {
    on<CheckNFCAvailabilityEvent>(_onCheckNFCAvailability);
    on<StartNFCSessionEvent>(_onStartNFCSession);
    on<StopNFCSessionEvent>(_onStopNFCSession);
    on<StartNFCWriteSessionEvent>(_onStartNFCWriteSession);
    on<StartNFCBeamSessionEvent>(_onStartNFCBeamSession);
    on<NFCTagReadEvent>(_onNFCTagRead);
    on<ActivateNFCEvent>(_onActivateNFC);
    on<ResetNFCServiceEvent>(_onResetNFCService);

    _initializeSubscriptions();
  }

  void _initializeSubscriptions() {
    if (_isInitialized) return;

    // Listen to NFC status changes
    _nfcStatusSubscription = _nfcService.statusStream.listen((status) {
      switch (status) {
        case NFCStatus.available:
          emit(NFCAvailableState());
          break;
        case NFCStatus.notAvailable:
        case NFCStatus.notEnabled:
          emit(NFCUnavailableState());
          break;
        case NFCStatus.reading:
          emit(NFCReadingState());
          break;
        case NFCStatus.writing:
          emit(NFCWritingState());
          break;
        case NFCStatus.error:
          emit(const NFCErrorState("An error occurred with NFC"));
          break;
        default:
          break;
      }
    });

    // Listen to NFC tag data
    _nfcTagDataSubscription = _nfcService.tagDataStream.listen((userId) {
      add(NFCTagReadEvent(userId));
    });

    _isInitialized = true;
  }

  void _cleanupSubscriptions() {
    _nfcStatusSubscription?.cancel();
    _nfcStatusSubscription = null;
    _nfcTagDataSubscription?.cancel();
    _nfcTagDataSubscription = null;
    _isInitialized = false;
  }

  Future<void> _onCheckNFCAvailability(
      CheckNFCAvailabilityEvent event, Emitter<AccessState> emit) async {
    final status = await _nfcService.checkAvailability();

    if (status == NFCStatus.available) {
      emit(NFCAvailableState());
    } else {
      emit(NFCUnavailableState());
    }
  }

  Future<void> _onStartNFCSession(
      StartNFCSessionEvent event, Emitter<AccessState> emit) async {
    emit(NFCReadingState());
    await _nfcService.startNFCSession();
  }

  Future<void> _onStopNFCSession(
      StopNFCSessionEvent event, Emitter<AccessState> emit) async {
    await _nfcService.stopNFCSession();
  }

  Future<void> _onStartNFCWriteSession(
      StartNFCWriteSessionEvent event, Emitter<AccessState> emit) async {
    emit(NFCWritingState());
    await _nfcService.startNFCWriteSession(event.userId);
  }

  Future<void> _onStartNFCBeamSession(
      StartNFCBeamSessionEvent event, Emitter<AccessState> emit) async {
    emit(NFCWritingState());
    await _nfcService.startNFCBeamSession(event.userId);
  }

  void _onNFCTagRead(NFCTagReadEvent event, Emitter<AccessState> emit) {
    emit(NFCSuccessState(event.userId));
  }

  // Auto-activate NFC when the screen is opened
  Future<void> _onActivateNFC(
      ActivateNFCEvent event, Emitter<AccessState> emit) async {
    // First check if NFC is available
    final status = await _nfcService.checkAvailability();

    if (status == NFCStatus.available) {
      // Start both reading and writing mode for P2P
      String userId = "";
      if (state is NFCSuccessState) {
        userId = (state as NFCSuccessState).userId;
      }

      if (userId.isNotEmpty) {
        await _nfcService.startNFCBeamSession(userId);
      }
    }
  }

  // Reset the NFC service to handle errors
  Future<void> _onResetNFCService(
      ResetNFCServiceEvent event, Emitter<AccessState> emit) async {
    _cleanupSubscriptions();
    _nfcService.reset();
    _initializeSubscriptions();
    add(CheckNFCAvailabilityEvent());
  }

  @override
  Future<void> close() {
    _cleanupSubscriptions();
    _nfcService.dispose();
    return super.close();
  }
}
