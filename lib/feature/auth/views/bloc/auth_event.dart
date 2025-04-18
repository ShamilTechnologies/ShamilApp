part of 'auth_bloc.dart'; // Links this file to auth_bloc.dart

// Base class for all authentication-related events
@immutable
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => []; // Helps Equatable compare event instances
}

/// Event dispatched on app start to check the current authentication status.
class CheckInitialAuthStatus extends AuthEvent {
  const CheckInitialAuthStatus();
}

/// Event dispatched when the user attempts to register a new account.
class RegisterEvent extends AuthEvent {
  final String name;
  final String username;
  final String email;
  final String password;
  final String nationalId;
  final String phone;
  final String gender;
  final String dob; // Consider using DateTime if parsed earlier
  // Optional fields for linking an existing external family member during registration
  final String? parentUserId;
  final String? familyMemberDocId;

  const RegisterEvent({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.nationalId,
    required this.phone,
    required this.gender,
    required this.dob,
    this.parentUserId,
    this.familyMemberDocId,
  });

  @override
  List<Object?> get props => [
        name, username, email, password, nationalId, phone, gender, dob,
        parentUserId, familyMemberDocId // Include optional fields in props
      ];
}

/// Event dispatched when the user attempts to log in.
class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event dispatched during the "One More Step" flow to upload ID documents.
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

/// Event dispatched when the user requests to log out.
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Event dispatched when the user updates their profile picture.
class UpdateProfilePicture extends AuthEvent {
  final File imageFile;

  const UpdateProfilePicture({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

/// Event dispatched when the user requests a password reset email.
class SendPasswordResetEmail extends AuthEvent {
  final String email;
  const SendPasswordResetEmail({required this.email});
  @override
  List<Object?> get props => [email];
}

/// Event dispatched (e.g., manually or periodically) to re-check
/// if the user's email has been verified.
class CheckEmailVerificationStatus extends AuthEvent {
  const CheckEmailVerificationStatus();
}

/// Event dispatched when the user saves changes on an "Edit Profile" screen.
class UpdateUserProfile extends AuthEvent {
  // Contains only the fields that were actually changed by the user.
  final Map<String, dynamic> updatedData;
  const UpdateUserProfile({required this.updatedData});
  @override
  List<Object?> get props => [updatedData];
}

/// Event dispatched during registration to check if the entered National ID
/// matches an existing external family member record.
class CheckNationalIdAsFamilyMember extends AuthEvent {
  final String nationalId;
  const CheckNationalIdAsFamilyMember({required this.nationalId});
  @override
  List<Object?> get props => [nationalId];
}
