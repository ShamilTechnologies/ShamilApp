import 'dart:io'; // For File type
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM for token removal
import 'package:flutter/material.dart'; // Needed for @immutable
import 'package:meta/meta.dart'; // For @immutable
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
// Import FamilyMember model for the check event state
import 'package:shamil_mobile_app/feature/social/data/family_member_model.dart';
import 'package:shamil_mobile_app/cloudinary_service.dart'; // Cloudinary upload service
import 'package:shamil_mobile_app/core/services/enhanced_email_service.dart'; // Enhanced email service

// *** ADDED part directives ***
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance; // FCM instance

  // Helper getter for current user ID
  String? get _userId => _auth.currentUser?.uid;

  AuthBloc() : super(const AuthInitial()) {
    // Register event handlers for all defined AuthEvents
    on<CheckInitialAuthStatus>(_onCheckInitialAuthStatus);
    on<RegisterEvent>(_register);
    on<LoginEvent>(_login);
    on<UploadIdEvent>(_uploadId);
    on<LogoutEvent>(_onLogout);
    on<UpdateProfilePicture>(_onUpdateProfilePicture);
    on<SendPasswordResetEmail>(_onSendPasswordResetEmail);
    on<CheckEmailVerificationStatus>(_onCheckEmailVerificationStatus);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<CheckNationalIdAsFamilyMember>(_onCheckNationalIdAsFamilyMember);
    on<CheckUsernameAvailability>(_onCheckUsernameAvailability);
  }

  /// Handler for checking auth status on app start
  Future<void> _onCheckInitialAuthStatus(
      CheckInitialAuthStatus event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState()); // Indicate checking status
    print("AuthBloc: Checking initial auth status...");
    final User? user = _auth.currentUser;

    if (user == null) {
      print("AuthBloc: No user currently logged in.");
      await AppLocalStorage.cacheData(
          key: "isLoggedIn", value: false); // Ensure flag is false
      emit(const AuthInitial());
    } else {
      print(
          "AuthBloc: User ${user.uid} found. Checking verification and profile...");
      try {
        await user.reload(); // Refresh user state from Firebase backend
        final freshUser =
            _auth.currentUser; // Get potentially updated user state

        if (freshUser == null) {
          // Double-check user didn't become null
          print(
              "AuthBloc: User became null after reload during initial check.");
          await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
          emit(const AuthInitial());
          return;
        }

        // Fetch corresponding Firestore profile
        print("AuthBloc: Initial check - Fetching Firestore data...");
        final DocumentSnapshot doc =
            await _firestore.collection("endUsers").doc(freshUser.uid).get();
        if (!doc.exists) {
          // Firestore document missing - potential data issue
          print(
              "AuthBloc: Error - User document not found for user ${freshUser.uid}.");
          emit(const AuthErrorState(
              "User profile data missing. Please log in again or contact support."));
          await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
          await _auth.signOut(); // Sign out if profile is corrupt/missing
          emit(const AuthInitial()); // Go back to initial state after sign out
          return;
        }

        final authModel = AuthModel.fromFirestore(doc);
        print(
            "AuthBloc: Initial check - Firestore data found for ${authModel.name}.");

        // Check user status and route accordingly
        final isEmailVerified = freshUser.emailVerified;
        final hasCompletedProfile = authModel.uploadedId;

        print(
            "Initial check - Email verified: $isEmailVerified, Profile completed: $hasCompletedProfile");

        if (!hasCompletedProfile) {
          // User needs to complete profile setup - take to OneMoreStep
          print("Initial check - User needs to complete profile setup");
          await AppLocalStorage.cacheData(key: "isLoggedIn", value: true);
          emit(IncompleteProfileState(
              user: authModel, isEmailVerified: isEmailVerified));
        } else {
          // User has completed profile - proceed to main app regardless of email verification
          print(
              "Initial check - User has completed profile - proceeding to main app");
          await AppLocalStorage.cacheData(key: "isLoggedIn", value: true);

          // Proceed to main app regardless of email verification status
          emit(LoginSuccessState(user: authModel));
        }

        // Optionally update FCM token here after successful login/initial check
        _fcm
            .getToken()
            .then((token) => _updateTokenInFirestore(token, freshUser.uid));
      } catch (e, s) {
        // Handle errors during the check process (e.g., network issues)
        print("AuthBloc: Error during initial auth check: $e\n$s");
        await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
        emit(AuthErrorState(
            "Failed to check authentication status: ${e.toString()}"));
        // Consider signing out on error during initial check?
        // await _auth.signOut();
        // emit(const AuthInitial());
      }
    }
  }

  /// Handles the login event.
  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    try {
      print("Starting login for email: ${event.email}");
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final User user = userCredential.user!;
      print("User logged in: ${user.uid}");

      // Reload user to get fresh verification status
      await user.reload();
      final freshUser = _auth.currentUser;
      if (freshUser == null) {
        print("User became null after reload");
        emit(const AuthErrorState("Authentication failed. Please try again."));
        return;
      }

      // Fetch the user document from Firestore
      final DocumentSnapshot doc =
          await _firestore.collection("endUsers").doc(user.uid).get();
      if (!doc.exists) {
        print(
            "Error: User document not found in Firestore after login for UID: ${user.uid}");
        emit(const AuthErrorState(
            "User profile not found. Please contact support."));
        await _auth.signOut();
        emit(const AuthInitial());
        return;
      }

      final authModel = AuthModel.fromFirestore(doc);
      print("User data fetched from Firestore: ${authModel.name}");

      // Check user status and route accordingly
      final isEmailVerified = freshUser.emailVerified;
      final hasCompletedProfile = authModel.uploadedId;

      print(
          "Email verified: $isEmailVerified, Profile completed: $hasCompletedProfile");

      if (!hasCompletedProfile) {
        // User needs to complete profile setup - take to OneMoreStep
        print("User needs to complete profile setup - routing to OneMoreStep");
        await AppLocalStorage.cacheData(key: "isLoggedIn", value: true);
        emit(IncompleteProfileState(
            user: authModel, isEmailVerified: isEmailVerified));
      } else {
        // User has completed profile - proceed to main app regardless of email verification
        print("User has completed profile - proceeding to main app");
        await AppLocalStorage.cacheData(key: "isLoggedIn", value: true);

        // Proceed to main app regardless of email verification status
        emit(LoginSuccessState(user: authModel));
      }

      print("Login flow completed");
      // Update FCM token on successful login
      _fcm.getToken().then((token) => _updateTokenInFirestore(token, user.uid));
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication error';
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        errorMessage = "Incorrect email or password.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This user account has been disabled.";
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      emit(AuthErrorState(errorMessage));
      print("FirebaseAuthException on Login: ${e.code} - ${e.message}");
    } catch (e, s) {
      emit(const AuthErrorState('Something went wrong during login.'));
      print("General exception during login: $e\n$s");
    }
  }

  /// Handles the registration event, including uniqueness checks and potential linking.
  Future<void> _register(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    try {
      // 1. Check Username Uniqueness
      print(
          "Registration: Checking username uniqueness for '${event.username}'...");
      // Requires Firestore index on 'username' in 'endUsers' collection
      final usernameQuery = await _firestore
          .collection("endUsers")
          .where('username', isEqualTo: event.username)
          .limit(1)
          .get();
      if (usernameQuery.docs.isNotEmpty) {
        emit(const AuthErrorState(
            'Username is already taken. Please choose another.'));
        return;
      }
      print("Registration: Username '${event.username}' appears unique.");

      // 2. Check National ID Uniqueness *ONLY IF NOT PRE-FILLING*
      if (event.familyMemberDocId == null) {
        print(
            "Registration: Checking National ID uniqueness for '${event.nationalId}'...");
        // Requires index on 'nationalId' in 'endUsers' collection
        final nationalIdQuery = await _firestore
            .collection("endUsers")
            .where('nationalId', isEqualTo: event.nationalId)
            .limit(1)
            .get();
        if (nationalIdQuery.docs.isNotEmpty) {
          emit(const AuthErrorState(
              'This National ID is already registered. Try logging in.'));
          return;
        }
        print(
            "Registration: National ID '${event.nationalId}' appears unique.");
      } else {
        print(
            "Registration: Skipping National ID uniqueness check due to pre-fill from family record.");
      }
      // IMPORTANT: Client-side checks are prone to race conditions. Use security rules or Cloud Function for robust check.

      // 3. Create Firebase Auth User
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final User user = userCredential.user!;
      print("Registration: Firebase Auth User created: ${user.uid}");
      await user.updateDisplayName(event.name);
      print("Registration: Display name updated.");
      try {
        await user.sendEmailVerification();
        print("Registration: Verification email sent to ${user.email}.");
      } catch (e) {
        print("Registration: Warning - Failed to send verification email: $e");
      }

      // 4. Prepare Firestore Data
      final authModel = AuthModel(
          uid: user.uid,
          name: event.name,
          username: event.username,
          email: event.email,
          nationalId: event.nationalId,
          phone: event.phone,
          gender: event.gender,
          dob: event.dob,
          image: '',
          uploadedId: false,
          isVerified: false,
          isBlocked: false,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          lastSeen: Timestamp.now(),
          profilePicUrl: null);
      final modelMap = authModel.toMap();
      modelMap['createdAt'] = FieldValue.serverTimestamp();
      modelMap['updatedAt'] = FieldValue.serverTimestamp();
      modelMap['lastSeen'] = FieldValue.serverTimestamp();
      modelMap['isApproved'] = false; // Assuming new users need approval

      // 5. Save to Firestore
      await _firestore.collection("endUsers").doc(user.uid).set(modelMap);
      print("Registration: User data saved to Firestore.");

      // 6. Handle Linking if pre-filled (Requires Cloud Function)
      if (event.parentUserId != null && event.familyMemberDocId != null) {
        print("Registration: Linking pre-filled family member...");
        // TODO: Cloud Function Trigger Required Here!
        // This logic MUST be moved to a secure Cloud Function triggered by user creation or a callable function.
        print(
            "Registration: Cloud Function needed to complete family link for parent ${event.parentUserId} and doc ${event.familyMemberDocId}.");
      }

      emit(const RegisterSuccessState());
      print("Registration successful for user: ${user.uid}");
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration error';
      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered. Try logging in.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      emit(AuthErrorState(errorMessage));
      print(
          "FirebaseAuthException during registration: ${e.code} - ${e.message}");
    } catch (e, s) {
      emit(AuthErrorState(
          'Something went wrong during registration: ${e.toString()}'));
      print("Exception during registration: $e\n$s");
    }
  }

  /// Handles the upload of ID images during the "One More Step" flow.
  Future<void> _uploadId(UploadIdEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    String? uploadedProfileUrl;
    String? uploadedIdFrontUrl;
    String? uploadedIdBackUrl;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }
      final uid = user.uid;
      print("Uploading ID for user: $uid");

      String profileFolder = 'users/$uid/profilePic';
      String idFrontFolder = 'users/$uid/idFront';
      String idBackFolder = 'users/$uid/idBack';

      // Upload files concurrently
      print("Starting parallel uploads...");
      final uploads = await Future.wait([
        CloudinaryService.uploadFile(event.profilePic, folder: profileFolder),
        CloudinaryService.uploadFile(event.idFront, folder: idFrontFolder),
        CloudinaryService.uploadFile(event.idBack, folder: idBackFolder),
      ]);

      uploadedProfileUrl = uploads[0];
      uploadedIdFrontUrl = uploads[1];
      uploadedIdBackUrl = uploads[2];

      // Validate uploads
      if (uploadedProfileUrl == null || uploadedProfileUrl.isEmpty) {
        throw Exception("Profile picture upload failed.");
      }
      if (uploadedIdFrontUrl == null || uploadedIdFrontUrl.isEmpty) {
        throw Exception("ID front upload failed.");
      }
      if (uploadedIdBackUrl == null || uploadedIdBackUrl.isEmpty) {
        throw Exception("ID back upload failed.");
      }
      print("All uploads successful.");

      // Update Firestore
      await _firestore.collection("endUsers").doc(uid).update({
        'uploadedId': true, 'profilePicUrl': uploadedProfileUrl,
        'image': uploadedProfileUrl, // Update both image fields
        'idFrontUrl': uploadedIdFrontUrl, 'idBackUrl': uploadedIdBackUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Firestore updated with ID image URLs.");

      // Fetch updated user model
      print("AuthBloc: Fetching updated user model after ID upload...");
      final updatedDoc = await _firestore.collection("endUsers").doc(uid).get();
      if (!updatedDoc.exists) {
        throw Exception(
            "Failed to fetch updated user profile after ID upload.");
      }
      final updatedAuthModel = AuthModel.fromFirestore(updatedDoc);
      print("AuthBloc: Updated user model fetched after ID upload.");

      // Emit success state WITH the updated user model
      emit(UploadIdSuccessState(user: updatedAuthModel));
      print("ID images uploaded and UploadIdSuccessState emitted successfully");
    } catch (e, s) {
      print("Exception during ID upload process: $e\n$s");
      emit(AuthErrorState("ID Upload Failed: ${e.toString()}"));
      // Log partial success for debugging/cleanup
      if (uploadedProfileUrl != null) {
        print("Profile URL succeeded: $uploadedProfileUrl");
      }
      if (uploadedIdFrontUrl != null) {
        print("ID Front URL succeeded: $uploadedIdFrontUrl");
      }
      if (uploadedIdBackUrl != null) {
        print("ID Back URL succeeded: $uploadedIdBackUrl");
      }
    }
  }

  /// Handles LogoutEvent, including FCM token removal attempt
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    print("AuthBloc: Logging out user...");
    final String? currentUserId = _userId; // Get UID *before* signing out
    String? currentToken;

    try {
      // Get the token for *this* device to remove it
      currentToken = await _fcm.getToken();
      print("AuthBloc: Current FCM token for removal: $currentToken");

      // Sign out from Firebase Auth
      await _auth.signOut();
      print("AuthBloc: Firebase sign out successful.");

      // Clear local storage flags
      await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
      await AppLocalStorage.cacheData(
          key: AppLocalStorage.userToken, value: null);
      print("AuthBloc: Local storage cleared.");

      // Attempt to remove the token from Firestore *after* sign out (using stored UID)
      if (currentUserId != null) {
        await _removeTokenFromFirestore(currentToken, currentUserId);
      } else {
        print("AuthBloc: Could not remove FCM token (missing UID or token).");
      }

      // Delete the token instance on the device itself
      try {
        await _fcm.deleteToken();
        print("AuthBloc: FCM token deleted from device.");
      } catch (e) {
        print("AuthBloc: Error deleting FCM token from device: $e");
      }

      // Emit initial/unauthenticated state
      emit(const AuthInitial());
      print("AuthBloc: Emitted AuthInitial state after logout.");
    } catch (e, s) {
      print("AuthBloc: Error during logout: $e\n$s");
      // Ensure local storage is cleared even on error
      await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
      await AppLocalStorage.cacheData(
          key: AppLocalStorage.userToken, value: null);
      // Attempt removal even on error
      if (currentUserId != null && currentToken != null) {
        await _removeTokenFromFirestore(currentToken, currentUserId);
      }
      try {
        await _fcm.deleteToken();
      } catch (e) {
        print(
            "AuthBloc: Error deleting FCM token from device on logout error: $e");
      }
      emit(AuthErrorState("Logout failed: ${e.toString()}"));
    }
  }

  /// Handles UpdateProfilePicture event
  Future<void> _onUpdateProfilePicture(
      UpdateProfilePicture event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    print("AuthBloc: Updating profile picture...");
    final user = _auth.currentUser;
    if (user == null) {
      emit(const AuthErrorState("User not logged in. Cannot update picture."));
      return;
    }
    final uid = user.uid;
    try {
      String profileFolder = 'users/$uid/profilePic';
      print("AuthBloc: Uploading new profile picture to Cloudinary...");
      final String? newProfilePicUrl = await CloudinaryService.uploadFile(
          event.imageFile,
          folder: profileFolder);
      if (newProfilePicUrl == null || newProfilePicUrl.isEmpty) {
        throw Exception("Cloudinary upload failed for profile picture.");
      }
      print("AuthBloc: New profile picture uploaded: $newProfilePicUrl");
      print("AuthBloc: Updating Firestore with new profile picture URL...");
      // Update both 'profilePicUrl' and 'image' for consistency if needed
      await _firestore.collection("endUsers").doc(uid).update({
        'profilePicUrl': newProfilePicUrl,
        'image': newProfilePicUrl, // Also update 'image' if used elsewhere
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("AuthBloc: Firestore updated successfully.");
      print("AuthBloc: Fetching updated user model...");
      final updatedDoc = await _firestore.collection("endUsers").doc(uid).get();
      if (!updatedDoc.exists) {
        throw Exception(
            "Failed to fetch updated user profile after picture update.");
      }
      final updatedAuthModel = AuthModel.fromFirestore(updatedDoc);
      print("AuthBloc: Updated user model fetched.");
      emit(LoginSuccessState(user: updatedAuthModel));
      print(
          "AuthBloc: Emitted LoginSuccessState with updated profile picture.");
    } catch (e, s) {
      print("AuthBloc: Error updating profile picture: $e\n$s");
      emit(AuthErrorState("Failed to update profile picture: ${e.toString()}"));
    }
  }

  /// Handles SendPasswordResetEmail event
  Future<void> _onSendPasswordResetEmail(
      SendPasswordResetEmail event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    print("AuthBloc: Sending password reset email to ${event.email}...");

    try {
      // Use Enhanced Email Service for better error handling and diagnostics
      await EnhancedEmailService().sendPasswordResetEmail(event.email);

      print("AuthBloc: Password reset email sent successfully.");
      emit(const PasswordResetEmailSentState());
    } on FirebaseAuthException catch (e) {
      print("AuthBloc: Firebase Auth error - ${e.code}: ${e.message}");

      String userMessage;
      switch (e.code) {
        case 'invalid-email':
          userMessage = "Please enter a valid email address.";
          break;
        case 'too-many-requests':
          userMessage = e.message ??
              "Too many requests. Please wait before trying again.";
          break;
        case 'user-not-found':
          // Show success message for security (prevent account enumeration)
          userMessage =
              "If an account exists with this email, a password reset link has been sent.";
          break;
        default:
          userMessage = e.message ??
              "Failed to send password reset email. Please try again.";
      }

      emit(AuthErrorState(userMessage));
    } catch (e) {
      print("AuthBloc: Unexpected error sending password reset email: $e");
      emit(const AuthErrorState(
          "An error occurred. Please check your connection and try again."));
    }
  }

  /// Handles CheckEmailVerificationStatus event
  Future<void> _onCheckEmailVerificationStatus(
      CheckEmailVerificationStatus event, Emitter<AuthState> emit) async {
    print("AuthBloc: Checking email verification status...");
    User? user = _auth.currentUser;
    if (user == null) {
      print("AuthBloc: No user found while checking verification status.");
      emit(const AuthInitial());
      return;
    }
    // Avoid emitting loading state here to prevent unnecessary UI flashes
    try {
      await user.reload();
      user = _auth.currentUser;
      if (user == null) {
        print(
            "AuthBloc: User became null after reload during verification check.");
        emit(const AuthInitial());
        return;
      }
      print(
          "AuthBloc: Current verification status for ${user.email}: ${user.emailVerified}");
      if (user.emailVerified) {
        print("AuthBloc: Email verified. Fetching user data...");
        final DocumentSnapshot doc =
            await _firestore.collection("endUsers").doc(user.uid).get();
        if (doc.exists) {
          final authModel = AuthModel.fromFirestore(doc);
          // Only emit LoginSuccess if not already in that state with same user data
          if (state is! LoginSuccessState ||
              (state as LoginSuccessState).user != authModel) {
            emit(LoginSuccessState(user: authModel));
            print(
                "AuthBloc: Emitted LoginSuccessState after verification check.");
          } else {
            print("AuthBloc: State is already LoginSuccess with updated data.");
          }
        } else {
          print(
              "AuthBloc: Error - User document not found after email verification.");
          emit(AuthErrorState(
              "User profile not found after verification. UID: ${user.uid}"));
        }
      } else {
        // Only emit AwaitingVerification if not already in that state
        if (state is! AwaitingVerificationState) {
          print(
              "AuthBloc: Email still not verified. Emitting AwaitingVerificationState.");

          // Fetch user data for the state
          final DocumentSnapshot doc =
              await _firestore.collection("endUsers").doc(user.uid).get();
          AuthModel? authModel;
          if (doc.exists) {
            authModel = AuthModel.fromFirestore(doc);
          }

          emit(AwaitingVerificationState(user.email!, user: authModel));
        } else {
          print("AuthBloc: State is already AwaitingVerification.");
        }
      }
    } catch (e, s) {
      print("AuthBloc: Error checking email verification status: $e\n$s");
      emit(AuthErrorState("Failed to check email status: ${e.toString()}"));
    }
  }

  /// Handles UpdateUserProfile event
  Future<void> _onUpdateUserProfile(
      UpdateUserProfile event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    print("AuthBloc: Updating user profile...");
    final user = _auth.currentUser;
    if (user == null) {
      emit(const AuthErrorState("User not logged in. Cannot update profile."));
      return;
    }
    final uid = user.uid;
    try {
      Map<String, dynamic> dataToUpdate = Map.from(event.updatedData);
      print("AuthBloc: Data received for update: $dataToUpdate");
      // Remove fields that shouldn't be updated directly or are handled elsewhere
      dataToUpdate.remove('email');
      dataToUpdate.remove('uid');
      dataToUpdate.remove('isApproved');
      dataToUpdate.remove('isBlocked');
      dataToUpdate.remove('createdAt');
      dataToUpdate.remove('uploadedId');
      dataToUpdate.remove('profilePicUrl');
      dataToUpdate.remove('image');
      dataToUpdate.remove('username');
      dataToUpdate.remove('nationalId'); // National ID shouldn't be updatable
      dataToUpdate.removeWhere((key, value) =>
          value == null ||
          (value is String && value.isEmpty)); // Remove null/empty values

      // Check if there's anything valid left to update besides timestamp
      if (dataToUpdate.isEmpty) {
        print("AuthBloc: No valid fields provided for profile update.");
        // Re-fetch current state to avoid staying in loading
        final doc = await _firestore.collection("endUsers").doc(uid).get();
        if (doc.exists) {
          emit(LoginSuccessState(user: AuthModel.fromFirestore(doc)));
        } else {
          emit(const AuthErrorState(
              "Failed to load profile after empty update attempt."));
        }
        return;
      }

      // Add timestamp and perform update
      dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();
      print("AuthBloc: Updating Firestore profile with data: $dataToUpdate");
      await _firestore.collection("endUsers").doc(uid).update(dataToUpdate);
      print("AuthBloc: Firestore profile update successful.");

      // Update display name in Firebase Auth if 'name' was changed
      if (dataToUpdate.containsKey('name')) {
        await user.updateDisplayName(dataToUpdate['name']);
        print("AuthBloc: Firebase Auth display name updated.");
      }

      // Fetch updated model and emit success state
      print("AuthBloc: Fetching updated user model after profile update...");
      final updatedDoc = await _firestore.collection("endUsers").doc(uid).get();
      if (!updatedDoc.exists) {
        throw Exception(
            "Failed to fetch updated user profile after general update.");
      }
      final updatedAuthModel = AuthModel.fromFirestore(updatedDoc);
      print("AuthBloc: Updated user model fetched.");
      emit(LoginSuccessState(user: updatedAuthModel));
      print("AuthBloc: Emitted LoginSuccessState with updated profile data.");
    } catch (e, s) {
      print("AuthBloc: Error updating user profile: $e\n$s");
      emit(AuthErrorState("Failed to update profile: ${e.toString()}"));
    }
  }

  /// Handles checking National ID against registered users and external family members.
  Future<void> _onCheckNationalIdAsFamilyMember(
      CheckNationalIdAsFamilyMember event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState(
        message: "Checking National ID...")); // Specific loading message

    try {
      final String nationalId = event.nationalId;
      print("AuthBloc: Checking National ID $nationalId...");

      // 1. Check if ID already exists in endUsers collection
      print("AuthBloc: Step 1 - Checking 'endUsers' collection...");
      // *** Firestore Index Required: on 'endUsers' collection for 'nationalId' field (ASC) ***
      final userQuerySnapshot = await _firestore
          .collection('endUsers')
          .where('nationalId', isEqualTo: nationalId)
          .limit(1)
          .get();

      if (userQuerySnapshot.docs.isNotEmpty) {
        // ID found in endUsers - means user is already registered
        print(
            "AuthBloc: National ID $nationalId found in 'endUsers'. User already registered.");
        emit(const NationalIdAlreadyRegistered()); // Emit specific state
        return; // Stop checking
      }

      // 2. If not in endUsers, check if ID exists as 'external' in familyMembers collection group
      print(
          "AuthBloc: Step 2 - Checking 'familyMembers' collection group for external record...");
      // *** Firestore Index Required: collectionGroup='familyMembers', fields: 'nationalId' (ASC), 'status' (ASC) ***
      // Ensure this index exists in your Firebase console!
      final familyQuerySnapshot = await _firestore
          .collectionGroup('familyMembers')
          .where('nationalId', isEqualTo: nationalId)
          .where('status',
              isEqualTo: 'external') // Only find 'external' records
          .limit(1)
          .get(); // Execute the query

      if (familyQuerySnapshot.docs.isNotEmpty) {
        // Found as an external family member record
        print("AuthBloc: Found matching external family member record.");
        final familyDoc = familyQuerySnapshot.docs.first;
        final familyData = FamilyMember.fromFirestore(familyDoc);
        final parentUserId = familyDoc.reference.parent.parent!.id;
        final familyDocId = familyDoc.id;

        // Double-check: Ensure the linked userId (if any) isn't somehow registered now
        if (familyData.userId != null && familyData.userId!.isNotEmpty) {
          print(
              "AuthBloc: External record has userId ${familyData.userId}. Verifying...");
          final linkedUserDoc = await _firestore
              .collection('endUsers')
              .doc(familyData.userId!)
              .get();
          if (linkedUserDoc.exists) {
            print(
                "AuthBloc: ERROR - Inconsistent Data! External record's linked user (${familyData.userId}) exists in endUsers.");
            emit(const NationalIdCheckFailed(
                message: "Data inconsistency found. Please contact support."));
            return; // Stop
          } else {
            print(
                "AuthBloc: Linked user ${familyData.userId} not registered. Proceeding with pre-fill.");
          }
        } else {
          print(
              "AuthBloc: External record has no linked userId. Proceeding with pre-fill.");
        }

        // Emit state with data for pre-filling the registration form
        emit(ExistingFamilyMemberFound(
          externalMemberData: familyData,
          parentUserId: parentUserId,
          familyDocId: familyDocId,
        ));
        print("AuthBloc: Emitted ExistingFamilyMemberFound state.");
        return; // Stop checking
      } else {
        // ID not found in endUsers AND not found as 'external' in familyMembers
        print(
            "AuthBloc: National ID $nationalId is available for registration.");
        emit(
            const NationalIdAvailable()); // Emit specific state indicating available
        return; // Stop checking
      }
    } catch (e, s) {
      print("AuthBloc: Error checking National ID: $e\n$s");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        // Specific error for missing index
        emit(const NationalIdCheckFailed(
            message:
                "Database index missing for National ID check. Please check Firestore indexes in Firebase console."));
      } else {
        // Generic error
        emit(NationalIdCheckFailed(
            message: "Error checking National ID: ${e.toString()}"));
      }
    }
  }

  /// Handles checking username availability during registration.
  Future<void> _onCheckUsernameAvailability(
      CheckUsernameAvailability event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState(
        message:
            "Checking username availability...")); // Specific loading message

    try {
      final String username = event.username.trim();
      print("AuthBloc: Checking username availability for '$username'...");

      // Check if username already exists in endUsers collection
      // *** Firestore Index Required: on 'endUsers' collection for 'username' field (ASC) ***
      final usernameQuerySnapshot = await _firestore
          .collection('endUsers')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuerySnapshot.docs.isNotEmpty) {
        // Username is already taken
        print("AuthBloc: Username '$username' is already taken.");
        emit(const UsernameAlreadyTaken());
        return;
      }

      // Username is available
      print("AuthBloc: Username '$username' is available for registration.");
      emit(const UsernameAvailable());
    } catch (e, s) {
      print("AuthBloc: Error checking username availability: $e\n$s");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        // Specific error for missing index
        emit(const UsernameCheckFailed(
            message:
                "Database index missing for username check. Please check Firestore indexes in Firebase console."));
      } else {
        // Generic error
        emit(UsernameCheckFailed(
            message: "Error checking username availability: ${e.toString()}"));
      }
    }
  }

  // --- Helper Methods ---

  /// Helper to update FCM token in Firestore
  Future<void> _updateTokenInFirestore(String? token, String? userId) async {
    if (token == null || userId == null) return;
    print("Attempting to update FCM token in Firestore for user $userId");
    try {
      await _firestore.collection('endUsers').doc(userId).set({
        'fcmTokens':
            FieldValue.arrayUnion([token]) // Add token to array if not present
      }, SetOptions(merge: true)); // Merge to avoid overwriting other fields
      print("FCM Token update/add attempted in Firestore.");
    } catch (e) {
      print("Error saving FCM token to Firestore: $e");
    }
  }

  /// Helper to remove FCM token from Firestore
  Future<void> _removeTokenFromFirestore(String? token, String? userId) async {
    if (token == null || userId == null) return;
    print("Attempting to remove FCM token $token for user $userId");
    try {
      await _firestore.collection("endUsers").doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]) // Remove specific token
      });
      print("FCM Token removal attempted in Firestore.");
    } catch (e) {
      print(
          "AuthBloc: Warning - Failed to remove FCM token from Firestore (might require backend): $e");
    }
  }
} // End of AuthBloc
