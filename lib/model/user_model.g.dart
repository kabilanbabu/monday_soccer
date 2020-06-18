// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String,
    image: json['image'] as String,
    nickName: json['nickName'] as String,
    position: (json['position'] as List)?.map((e) => e as String)?.toList(),
    clubAccNo: json['clubAccNo'] as String,
    admin: json['admin'] as bool,
    birthDay: json['birthDay'] == null
        ? null
        : DateTime.parse(json['birthDay'] as String),
  );
}

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'nickName': instance.nickName,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'image': instance.image,
      'position': instance.position,
      'clubAccNo': instance.clubAccNo,
      'birthDay': instance.birthDay?.toIso8601String(),
      'admin': instance.admin,
    };
