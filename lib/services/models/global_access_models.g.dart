// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_access_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessRequestModel _$AccessRequestModelFromJson(Map<String, dynamic> json) =>
    AccessRequestModel(
      protocolVersion: json['protocolVersion'] as String,
      appId: json['appId'] as String,
      action: json['action'] as String,
      userData:
          UserDataModel.fromJson(json['userData'] as Map<String, dynamic>),
      requestData: RequestDataModel.fromJson(
          json['requestData'] as Map<String, dynamic>),
      authToken: json['authToken'] as String,
    );

Map<String, dynamic> _$AccessRequestModelToJson(AccessRequestModel instance) =>
    <String, dynamic>{
      'protocolVersion': instance.protocolVersion,
      'appId': instance.appId,
      'action': instance.action,
      'userData': instance.userData,
      'requestData': instance.requestData,
      'authToken': instance.authToken,
    };

UserDataModel _$UserDataModelFromJson(Map<String, dynamic> json) =>
    UserDataModel(
      firebaseUid: json['firebaseUid'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$UserDataModelToJson(UserDataModel instance) =>
    <String, dynamic>{
      'firebaseUid': instance.firebaseUid,
      'userName': instance.userName,
      'email': instance.email,
      'phone': instance.phone,
    };

RequestDataModel _$RequestDataModelFromJson(Map<String, dynamic> json) =>
    RequestDataModel(
      requestId: json['requestId'] as String,
      timestamp: json['timestamp'] as String,
      deviceType: json['deviceType'] as String,
      appVersion: json['appVersion'] as String?,
    );

Map<String, dynamic> _$RequestDataModelToJson(RequestDataModel instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'timestamp': instance.timestamp,
      'deviceType': instance.deviceType,
      'appVersion': instance.appVersion,
    };

AccessResponseModel _$AccessResponseModelFromJson(Map<String, dynamic> json) =>
    AccessResponseModel(
      success: json['success'] as bool,
      userName: json['userName'] as String?,
      reason: json['reason'] as String?,
      accessType: json['accessType'] as String?,
      processingTime: (json['processingTime'] as num?)?.toInt(),
      validUntil: json['validUntil'] as String?,
      location: json['location'] as String?,
      facility: json['facility'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AccessResponseModelToJson(
        AccessResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'userName': instance.userName,
      'reason': instance.reason,
      'accessType': instance.accessType,
      'processingTime': instance.processingTime,
      'validUntil': instance.validUntil,
      'location': instance.location,
      'facility': instance.facility,
      'additionalData': instance.additionalData,
    };

NFCCardData _$NFCCardDataFromJson(Map<String, dynamic> json) => NFCCardData(
      cardId: json['cardId'] as String,
      firebaseUid: json['firebaseUid'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      accessLevel: json['accessLevel'] as String,
      issuedAt: json['issuedAt'] as String,
      expiresAt: json['expiresAt'] as String,
    );

Map<String, dynamic> _$NFCCardDataToJson(NFCCardData instance) =>
    <String, dynamic>{
      'cardId': instance.cardId,
      'firebaseUid': instance.firebaseUid,
      'userName': instance.userName,
      'email': instance.email,
      'accessLevel': instance.accessLevel,
      'issuedAt': instance.issuedAt,
      'expiresAt': instance.expiresAt,
    };
