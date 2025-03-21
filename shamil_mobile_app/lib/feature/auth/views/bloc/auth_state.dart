part of 'auth_bloc.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class LoginLoadingState extends AuthState {}

class LoginSuccessState extends AuthState {
  final AuthModel user;
  LoginSuccessState({required this.user});
}

class RegisterLoadingState extends AuthState {}

class RegisterSuccessState extends AuthState {}

class UploadIdLoadingState extends AuthState {}

class UploadIdSuccessState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;
  AuthErrorState(this.message);
}
