import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'global_access_models.g.dart';

/// Enhanced Access Request Model for ESP32 Integration
@JsonSerializable()
class AccessRequestModel {
  final String protocolVersion;
  final String appId;
  final String action;
  final UserDataModel userData;
  final RequestDataModel requestData;
  final String authToken;

  const AccessRequestModel({
    required this.protocolVersion,
    required this.appId,
    required this.action,
    required this.userData,
    required this.requestData,
    required this.authToken,
  });

  factory AccessRequestModel.fromJson(Map<String, dynamic> json) =>
      _$AccessRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$AccessRequestModelToJson(this);

  /// Create ESP32-compatible JSON string
  String toESP32Json() {
    return '''
{
  "type": "MOBILE_UID_ACCESS_REQUEST_ENHANCED",
  "protocol_version": "$protocolVersion",
  "app_id": "$appId",
  "action": "$action",
  "user_data": {
    "firebase_uid": "${userData.firebaseUid}",
    "user_name": "${userData.userName}",
    "email": "${userData.email}",
    "phone": "${userData.phone ?? ''}"
  },
  "request_data": {
    "request_id": "${requestData.requestId}",
    "timestamp": "${requestData.timestamp}",
    "device_type": "${requestData.deviceType}",
    "app_version": "${requestData.appVersion ?? '1.0.0'}"
  },
  "auth_token": "$authToken"
}''';
  }
}

/// User Data Model
@JsonSerializable()
class UserDataModel {
  final String firebaseUid;
  final String userName;
  final String email;
  final String? phone;

  const UserDataModel({
    required this.firebaseUid,
    required this.userName,
    required this.email,
    this.phone,
  });

  factory UserDataModel.fromJson(Map<String, dynamic> json) =>
      _$UserDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataModelToJson(this);
}

/// Request Data Model
@JsonSerializable()
class RequestDataModel {
  final String requestId;
  final String timestamp;
  final String deviceType;
  final String? appVersion;

  const RequestDataModel({
    required this.requestId,
    required this.timestamp,
    required this.deviceType,
    this.appVersion,
  });

  factory RequestDataModel.fromJson(Map<String, dynamic> json) =>
      _$RequestDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$RequestDataModelToJson(this);
}

/// Enhanced Access Response Model
@JsonSerializable()
class AccessResponseModel {
  final bool success;
  final String? userName;
  final String? reason;
  final String? accessType;
  final int? processingTime;
  final String? validUntil;
  final String? location;
  final String? facility;
  final Map<String, dynamic>? additionalData;

  const AccessResponseModel({
    required this.success,
    this.userName,
    this.reason,
    this.accessType,
    this.processingTime,
    this.validUntil,
    this.location,
    this.facility,
    this.additionalData,
  });

  factory AccessResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AccessResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AccessResponseModelToJson(this);

  /// Create from ESP32 response
  factory AccessResponseModel.fromESP32Response(String jsonResponse) {
    try {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(jsonDecode(jsonResponse));

      return AccessResponseModel(
        success: data['access_granted'] ?? false,
        userName: data['user_name'],
        reason: data['reason'],
        accessType: data['access_type'],
        processingTime: data['processing_time'],
        validUntil: data['valid_until'],
        location: data['additional_data']?['location'],
        facility: data['additional_data']?['facility'],
        additionalData: data['additional_data'],
      );
    } catch (e) {
      return AccessResponseModel(
        success: false,
        reason: 'Failed to parse response: $e',
      );
    }
  }
}

/// NFC Card Emulation Data for HostApduService
@JsonSerializable()
class NFCCardData {
  final String cardId;
  final String firebaseUid;
  final String userName;
  final String email;
  final String accessLevel;
  final String issuedAt;
  final String expiresAt;

  const NFCCardData({
    required this.cardId,
    required this.firebaseUid,
    required this.userName,
    required this.email,
    required this.accessLevel,
    required this.issuedAt,
    required this.expiresAt,
  });

  factory NFCCardData.fromJson(Map<String, dynamic> json) =>
      _$NFCCardDataFromJson(json);

  Map<String, dynamic> toJson() => _$NFCCardDataToJson(this);

  /// Convert to APDU response bytes
  List<int> toApduBytes() {
    final jsonString = toJson().toString();
    final bytes = utf8.encode(jsonString);
    return [...bytes, 0x90, 0x00]; // SW1, SW2 success response
  }
}

/// APDU Command Model
class ApduCommand {
  final int cla;
  final int ins;
  final int p1;
  final int p2;
  final List<int>? data;
  final int? le;

  const ApduCommand({
    required this.cla,
    required this.ins,
    required this.p1,
    required this.p2,
    this.data,
    this.le,
  });

  factory ApduCommand.fromBytes(List<int> bytes) {
    if (bytes.length < 4) {
      throw ArgumentError('APDU command must be at least 4 bytes');
    }

    return ApduCommand(
      cla: bytes[0],
      ins: bytes[1],
      p1: bytes[2],
      p2: bytes[3],
      data: bytes.length > 5 ? bytes.sublist(5, 5 + bytes[4]) : null,
      le: bytes.length > 4 ? bytes[4] : null,
    );
  }

  @override
  String toString() {
    return 'APDU(CLA: 0x${cla.toRadixString(16).padLeft(2, '0').toUpperCase()}, '
        'INS: 0x${ins.toRadixString(16).padLeft(2, '0').toUpperCase()}, '
        'P1: 0x${p1.toRadixString(16).padLeft(2, '0').toUpperCase()}, '
        'P2: 0x${p2.toRadixString(16).padLeft(2, '0').toUpperCase()})';
  }
}
