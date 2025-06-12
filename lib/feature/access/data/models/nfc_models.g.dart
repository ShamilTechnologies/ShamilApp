// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nfc_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NFCAccessRequest _$NFCAccessRequestFromJson(Map<String, dynamic> json) =>
    NFCAccessRequest(
      type: json['type'] as String,
      appId: json['appId'] as String,
      mobileUid: json['mobileUid'] as String,
      requestId: json['requestId'] as String,
      timestamp: json['timestamp'] as String,
      appVersion: json['appVersion'] as String,
      deviceInfo:
          NFCDeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NFCAccessRequestToJson(NFCAccessRequest instance) =>
    <String, dynamic>{
      'type': instance.type,
      'appId': instance.appId,
      'mobileUid': instance.mobileUid,
      'requestId': instance.requestId,
      'timestamp': instance.timestamp,
      'appVersion': instance.appVersion,
      'deviceInfo': instance.deviceInfo,
    };

NFCDeviceInfo _$NFCDeviceInfoFromJson(Map<String, dynamic> json) =>
    NFCDeviceInfo(
      platform: json['platform'] as String,
      model: json['model'] as String,
      osVersion: json['osVersion'] as String,
    );

Map<String, dynamic> _$NFCDeviceInfoToJson(NFCDeviceInfo instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'model': instance.model,
      'osVersion': instance.osVersion,
    };

NFCAccessResponse _$NFCAccessResponseFromJson(Map<String, dynamic> json) =>
    NFCAccessResponse(
      type: json['type'] as String,
      appId: json['appId'] as String,
      requestId: json['requestId'] as String,
      mobileUid: json['mobileUid'] as String,
      accessGranted: json['accessGranted'] as bool,
      decision: json['decision'] as String,
      reason: json['reason'] as String,
      userName: json['userName'] as String?,
      accessType: json['accessType'] as String?,
      validUntil: json['validUntil'] as String?,
      timestamp: json['timestamp'] as String,
      processingTime: (json['processingTime'] as num).toInt(),
      serviceProvider: json['serviceProvider'] as String,
      additionalData: json['additionalData'] == null
          ? null
          : NFCAdditionalData.fromJson(
              json['additionalData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NFCAccessResponseToJson(NFCAccessResponse instance) =>
    <String, dynamic>{
      'type': instance.type,
      'appId': instance.appId,
      'requestId': instance.requestId,
      'mobileUid': instance.mobileUid,
      'accessGranted': instance.accessGranted,
      'decision': instance.decision,
      'reason': instance.reason,
      'userName': instance.userName,
      'accessType': instance.accessType,
      'validUntil': instance.validUntil,
      'timestamp': instance.timestamp,
      'processingTime': instance.processingTime,
      'serviceProvider': instance.serviceProvider,
      'additionalData': instance.additionalData,
    };

NFCAdditionalData _$NFCAdditionalDataFromJson(Map<String, dynamic> json) =>
    NFCAdditionalData(
      location: json['location'] as String?,
      facility: json['facility'] as String?,
      accessLevel: json['accessLevel'] as String?,
    );

Map<String, dynamic> _$NFCAdditionalDataToJson(NFCAdditionalData instance) =>
    <String, dynamic>{
      'location': instance.location,
      'facility': instance.facility,
      'accessLevel': instance.accessLevel,
    };
