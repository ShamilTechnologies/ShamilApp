part of 'auth_bloc.dart';

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
class AuthLoadingState extends AuthState {
   const AuthLoadingState();
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
  const AwaitingVerificationState(this.email);

  @override
  List<Object?> get props => [email];
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
  final FamilyMember externalMemberData; // Data from the familyMembers subcollection doc
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

/// State emitted when the National ID check fails (e.g., Firestore error,
/// or the ID belongs to an already registered user).
class NationalIdCheckError extends AuthState {
  final String message;
  const NationalIdCheckError({required this.message});
  @override List<Object?> get props => [message];
}

/// State emitted when the National ID is not found among external family members,
/// or if it belongs to an already registered user (handled by NationalIdCheckError).
/// Signals the UI to proceed with normal registration flow for this ID.
class NationalIdNotFoundOrRegistered extends AuthState {
  const NationalIdNotFoundOrRegistered();
}
