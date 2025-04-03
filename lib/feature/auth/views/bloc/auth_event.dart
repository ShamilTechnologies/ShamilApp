part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent extends Equatable{
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Event to check auth status on app start
class CheckInitialAuthStatus extends AuthEvent {
  const CheckInitialAuthStatus();
}

class RegisterEvent extends AuthEvent {
  final String name;
  // *** ADDED: username parameter ***
  final String username;
  final String email;
  final String password;
  final String nationalId;
  final String phone;
  final String gender;
  final String dob;

  const RegisterEvent({
    required this.name,
    // *** ADDED: username required ***
    required this.username,
    required this.email,
    required this.password,
    required this.nationalId,
    required this.phone,
    required this.gender,
    required this.dob,
  });

   @override
   // *** ADDED: username to props ***
   List<Object?> get props => [name, username, email, password, nationalId, phone, gender, dob];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({
    required this.email,
    required this.password,
  });

   @override
   List<Object?> get props => [email, password];
}

class UploadIdEvent extends AuthEvent {
  final File profilePic;
  final File idFront;
  final File idBack;

  const UploadIdEvent({
    required this.profilePic,
    required this.idFront,
    required this.idBack,
  });

   @override
   List<Object?> get props => [profilePic, idFront, idBack];
}

class LogoutEvent extends AuthEvent {
   const LogoutEvent();
}

class UpdateProfilePicture extends AuthEvent {
  final File imageFile;

  const UpdateProfilePicture({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

class SendPasswordResetEmail extends AuthEvent {
  final String email;
  const SendPasswordResetEmail({required this.email});
  @override List<Object?> get props => [email];
}

class CheckEmailVerificationStatus extends AuthEvent {
  const CheckEmailVerificationStatus();
}

class UpdateUserProfile extends AuthEvent {
  final Map<String, dynamic> updatedData;
  const UpdateUserProfile({required this.updatedData});
  @override List<Object?> get props => [updatedData];
}
