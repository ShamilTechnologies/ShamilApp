import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'nfc_models.g.dart';

@JsonSerializable()
class NFCAccessRequest extends Equatable {
  final String type;
  final String appId;
  final String mobileUid;
  final String requestId;
  final String timestamp;
  final String appVersion;
  final NFCDeviceInfo deviceInfo;

  const NFCAccessRequest({
    required this.type,
    required this.appId,
    required this.mobileUid,
    required this.requestId,
    required this.timestamp,
    required this.appVersion,
    required this.deviceInfo,
  });

  factory NFCAccessRequest.fromJson(Map<String, dynamic> json) =>
      _$NFCAccessRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NFCAccessRequestToJson(this);

  @override
  List<Object?> get props => [
        type,
        appId,
        mobileUid,
        requestId,
        timestamp,
        appVersion,
        deviceInfo,
      ];
}

@JsonSerializable()
class NFCDeviceInfo extends Equatable {
  final String platform;
  final String model;
  final String osVersion;

  const NFCDeviceInfo({
    required this.platform,
    required this.model,
    required this.osVersion,
  });

  factory NFCDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$NFCDeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$NFCDeviceInfoToJson(this);

  @override
  List<Object?> get props => [platform, model, osVersion];
}

@JsonSerializable()
class NFCAccessResponse extends Equatable {
  final String type;
  final String appId;
  final String requestId;
  final String mobileUid;
  final bool accessGranted;
  final String decision;
  final String reason;
  final String? userName;
  final String? accessType;
  final String? validUntil;
  final String timestamp;
  final int processingTime;
  final String serviceProvider;
  final NFCAdditionalData? additionalData;

  const NFCAccessResponse({
    required this.type,
    required this.appId,
    required this.requestId,
    required this.mobileUid,
    required this.accessGranted,
    required this.decision,
    required this.reason,
    this.userName,
    this.accessType,
    this.validUntil,
    required this.timestamp,
    required this.processingTime,
    required this.serviceProvider,
    this.additionalData,
  });

  factory NFCAccessResponse.fromJson(Map<String, dynamic> json) =>
      _$NFCAccessResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NFCAccessResponseToJson(this);

  @override
  List<Object?> get props => [
        type,
        appId,
        requestId,
        mobileUid,
        accessGranted,
        decision,
        reason,
        userName,
        accessType,
        validUntil,
        timestamp,
        processingTime,
        serviceProvider,
        additionalData,
      ];
}

@JsonSerializable()
class NFCAdditionalData extends Equatable {
  final String? location;
  final String? facility;
  final String? accessLevel;

  const NFCAdditionalData({
    this.location,
    this.facility,
    this.accessLevel,
  });

  factory NFCAdditionalData.fromJson(Map<String, dynamic> json) =>
      _$NFCAdditionalDataFromJson(json);

  Map<String, dynamic> toJson() => _$NFCAdditionalDataToJson(this);

  @override
  List<Object?> get props => [location, facility, accessLevel];
}

enum NFCAccessDecision {
  granted,
  denied,
  error,
}

enum NFCAccessType {
  subscription,
  reservation,
  guest,
}

extension NFCAccessDecisionX on NFCAccessDecision {
  String get value {
    switch (this) {
      case NFCAccessDecision.granted:
        return 'granted';
      case NFCAccessDecision.denied:
        return 'denied';
      case NFCAccessDecision.error:
        return 'error';
    }
  }

  static NFCAccessDecision fromString(String value) {
    switch (value.toLowerCase()) {
      case 'granted':
        return NFCAccessDecision.granted;
      case 'denied':
        return NFCAccessDecision.denied;
      default:
        return NFCAccessDecision.error;
    }
  }
}

extension NFCAccessTypeX on NFCAccessType {
  String get value {
    switch (this) {
      case NFCAccessType.subscription:
        return 'subscription';
      case NFCAccessType.reservation:
        return 'reservation';
      case NFCAccessType.guest:
        return 'guest';
    }
  }

  static NFCAccessType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'subscription':
        return NFCAccessType.subscription;
      case 'reservation':
        return NFCAccessType.reservation;
      case 'guest':
        return NFCAccessType.guest;
      default:
        return NFCAccessType.guest;
    }
  }
}
