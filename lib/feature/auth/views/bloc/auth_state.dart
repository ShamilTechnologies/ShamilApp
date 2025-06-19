part of 'auth_bloc.dart'; // Links this file to auth_bloc.dart

// Removed imports as they are moved to auth_bloc.dart

// Base class for all authentication states
@immutable
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => []; // Helps Equatable compare state instances
}

/// Initial state, also represents the unauthenticated/logged-out state.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Generic loading state for any auth operation (Login, Register, Upload, Logout, PW Reset etc.)
/// Can add optional message for specific loading contexts if needed
class AuthLoadingState extends AuthState {
  final String? message;
  const AuthLoadingState({this.message});
  @override
  List<Object?> get props => [message];
}

/// State emitted upon successful login or profile update, contains current user data.
class LoginSuccessState extends AuthState {
  final AuthModel user;
  const LoginSuccessState({required this.user});

  @override
  List<Object?> get props => [user];
}

/// State emitted upon successful registration, before email verification might be checked.
class RegisterSuccessState extends AuthState {
  const RegisterSuccessState();
  // Note: After this, the user might be directed to login or check email.
}

/// State emitted upon successful ID upload during the 'OneMoreStep' flow.
/// Includes the updated user model.
class UploadIdSuccessState extends AuthState {
  final AuthModel user; // Include user data
  const UploadIdSuccessState({required this.user}); // Require user data

  @override
  List<Object?> get props => [user]; // Add user to props
}

/// State indicating user is authenticated but needs to verify their email.
class AwaitingVerificationState extends AuthState {
  final String email;
  final AuthModel? user; // Add user data to show reminders
  const AwaitingVerificationState(this.email, {this.user});

  @override
  List<Object?> get props => [email, user];
}

/// State indicating user is authenticated but needs to complete profile setup (One More Step).
class IncompleteProfileState extends AuthState {
  final AuthModel user;
  final bool isEmailVerified;
  const IncompleteProfileState(
      {required this.user, required this.isEmailVerified});

  @override
  List<Object?> get props => [user, isEmailVerified];
}

/// State indicating a password reset email has been successfully sent.
/// This is often a transient state, UI might show a confirmation message.
class PasswordResetEmailSentState extends AuthState {
  const PasswordResetEmailSentState();
}

/// State for any authentication or profile update errors.
class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- States for National ID Check during Registration ---

/// State emitted when the National ID matches an existing external family member
/// who has NOT yet registered. Contains data to pre-fill the form.
class ExistingFamilyMemberFound extends AuthState {
  final FamilyMember
      externalMemberData; // Data from the familyMembers subcollection doc
  final String parentUserId; // UID of the user who added this external member
  final String familyDocId; // Doc ID of the external member record itself

  const ExistingFamilyMemberFound({
    required this.externalMemberData,
    required this.parentUserId,
    required this.familyDocId,
  });

  @override
  List<Object?> get props => [externalMemberData, parentUserId, familyDocId];
}

/// State emitted when the National ID check fails due to an error (network, index, etc.).
class NationalIdCheckFailed extends AuthState {
  // Renamed from NationalIdCheckError
  final String message;
  const NationalIdCheckFailed({required this.message});
  @override
  List<Object?> get props => [message];
}

/// State emitted when the National ID is already associated with a registered user
/// in the `endUsers` collection.
class NationalIdAlreadyRegistered extends AuthState {
  // NEW State
  const NationalIdAlreadyRegistered();
}

/// State emitted when the National ID is not found in `endUsers` and not found
/// as an 'external' record in `familyMembers`. Signals it's available for new registration.
class NationalIdAvailable extends AuthState {
  // Renamed from NationalIdNotFoundOrRegistered
  const NationalIdAvailable();
}

// --- States for Username Availability Check during Registration ---

/// State emitted when the username check fails due to an error (network, etc.).
class UsernameCheckFailed extends AuthState {
  final String message;
  const UsernameCheckFailed({required this.message});
  @override
  List<Object?> get props => [message];
}

/// State emitted when the username is already taken by another user.
class UsernameAlreadyTaken extends AuthState {
  const UsernameAlreadyTaken();
}

/// State emitted when the username is available for registration.
class UsernameAvailable extends AuthState {
  const UsernameAvailable();
}
