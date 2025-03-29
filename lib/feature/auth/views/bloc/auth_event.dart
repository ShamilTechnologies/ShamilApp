part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String nationalId;
  final String phone;
  final String gender;
  final String dob; // Date of Birth

  RegisterEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.nationalId,
    required this.phone,
    required this.gender,
    required this.dob,
  });
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({
    required this.email,
    required this.password,
  });
}

class UploadIdEvent extends AuthEvent {
  final File profilePic;
  final File idFront;
  final File idBack;

  UploadIdEvent({
    required this.profilePic,
    required this.idFront,
    required this.idBack,
  });
}
