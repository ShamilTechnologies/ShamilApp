import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/cloudinary_service.dart'; // Cloudinary upload service

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(const AuthInitial()) {
    // Register event handlers
    on<CheckInitialAuthStatus>(_onCheckInitialAuthStatus);
    on<RegisterEvent>(_register);
    on<LoginEvent>(_login);
    on<UploadIdEvent>(_uploadId);
    on<LogoutEvent>(_onLogout);
    on<UpdateProfilePicture>(_onUpdateProfilePicture);
    on<SendPasswordResetEmail>(_onSendPasswordResetEmail);
    on<CheckEmailVerificationStatus>(_onCheckEmailVerificationStatus);
    on<UpdateUserProfile>(_onUpdateUserProfile);
  }

  /// Handler for checking auth status on app start
  Future<void> _onCheckInitialAuthStatus( CheckInitialAuthStatus event, Emitter<AuthState> emit) async {
     emit(const AuthLoadingState()); // Indicate checking status
     print("AuthBloc: Checking initial auth status...");
     final User? user = _auth.currentUser;

     if (user == null) {
        print("AuthBloc: No user currently logged in.");
        await AppLocalStorage.cacheData(key: "isLoggedIn", value: false); // Ensure flag is false
        emit(const AuthInitial());
     } else {
        print("AuthBloc: User ${user.uid} found. Checking verification and profile...");
        try {
           await user.reload(); // Refresh user state
           final freshUser = _auth.currentUser; // Get potentially updated user state

           if (freshUser == null) { // Check again after reload
              print("AuthBloc: User became null after reload during initial check.");
              await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
              emit(const AuthInitial());
              return;
           }

           if (!freshUser.emailVerified) {
              print("AuthBloc: Initial check - Email not verified for ${freshUser.email}.");
              await AppLocalStorage.cacheData(key: "isLoggedIn", value: false); // Treat as not fully logged in for app access
              emit(AwaitingVerificationState(freshUser.email!));
           } else {
              print("AuthBloc: Initial check - Email verified. Fetching Firestore data...");
              final DocumentSnapshot doc = await _firestore.collection("endUsers").doc(freshUser.uid).get();
              if (doc.exists) {
                 final authModel = AuthModel.fromFirestore(doc);
                 print("AuthBloc: Initial check - Firestore data found for ${authModel.name}.");
                 await AppLocalStorage.cacheData(key: "isLoggedIn", value: true); // Set logged in flag
                 emit(LoginSuccessState(user: authModel)); // Emit success with data
              } else {
                 print("AuthBloc: Error - User document not found for verified user ${freshUser.uid}.");
                 emit(const AuthErrorState("User profile data missing. Please log in again or contact support."));
                 await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
                 await _auth.signOut(); // Sign out if profile is corrupt/missing
              }
           }
        } catch (e, s) {
           print("AuthBloc: Error during initial auth check: $e\n$s");
           await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
           // Don't sign out here, could be temporary network issue
           emit(AuthErrorState("Failed to check authentication status: ${e.toString()}"));
        }
     }
  }

  /// Handles the login event.
  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    try {
      print("Starting login for email: ${event.email}");
      final userCredential = await _auth.signInWithEmailAndPassword( email: event.email, password: event.password, );
      final User user = userCredential.user!;
      print("User logged in: ${user.uid}");

      // Check email verification status immediately after login
      await user.reload(); // Refresh user data
      final freshUser = _auth.currentUser; // Get potentially updated user state
      if (freshUser != null && !freshUser.emailVerified) {
         print("Login successful but email not verified for ${freshUser.email}. Emitting AwaitingVerificationState.");
         emit(AwaitingVerificationState(freshUser.email!));
         // Don't cache isLoggedIn=true yet if verification is required
         return; // Stop further processing until verified
      }

      // Proceed if verified
      await AppLocalStorage.cacheData( key: "isLoggedIn", value: true );
      print("isLoggedIn flag cached");

      // Fetch the user document from Firestore
      final DocumentSnapshot doc = await _firestore.collection("endUsers").doc(user.uid).get();
      if (!doc.exists) {
         print("Error: User document not found in Firestore after login for UID: ${user.uid}");
         emit(const AuthErrorState("User profile not found. Please contact support."));
         await AppLocalStorage.cacheData(key: "isLoggedIn", value: false);
         await _auth.signOut(); return;
      }
      final authModel = AuthModel.fromFirestore(doc);
      print("User data fetched from Firestore: ${authModel.name}");
      emit(LoginSuccessState(user: authModel));
      print("LoginSuccessState emitted");

    } on FirebaseAuthException catch (e) {
       String errorMessage = 'Authentication error';
       if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') { errorMessage = "Incorrect email or password."; }
       else if (e.code == 'user-disabled') { errorMessage = "This user account has been disabled."; }
       else { errorMessage = e.message ?? errorMessage; }
       emit(AuthErrorState(errorMessage)); print("FirebaseAuthException on Login: ${e.code} - ${e.message}");
    } catch (e, s) { emit(const AuthErrorState('Something went wrong during login.')); print("General exception during login: $e\n$s"); }
  }

  /// Handles the registration event.
  Future<void> _register(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    try {
      // 1. Check Username Uniqueness
      print("Registration: Checking username uniqueness for '${event.username}'...");
      final usernameQuery = await _firestore.collection("endUsers").where('username', isEqualTo: event.username).limit(1).get();
      if (usernameQuery.docs.isNotEmpty) {
        print("Registration: Username '${event.username}' already taken.");
        emit(const AuthErrorState('Username is already taken. Please choose another.'));
        return;
      }
      print("Registration: Username '${event.username}' appears unique.");

      // 2. Check National ID Uniqueness
      print("Registration: Checking National ID uniqueness for '${event.nationalId}'...");
      final nationalIdQuery = await _firestore.collection("endUsers").where('nationalId', isEqualTo: event.nationalId).limit(1).get();
      if (nationalIdQuery.docs.isNotEmpty) {
         print("Registration: National ID '${event.nationalId}' already registered.");
         emit(const AuthErrorState('This National ID is already registered. Try logging in.'));
         return;
      }
      print("Registration: National ID '${event.nationalId}' appears unique.");
      // IMPORTANT: Client-side checks are prone to race conditions. Use Cloud Functions/Transactions for guaranteed uniqueness.

      // 3. Create Firebase Auth User
      final userCredential = await _auth.createUserWithEmailAndPassword( email: event.email, password: event.password, );
      final User user = userCredential.user!; print("Registration: Firebase Auth User created: ${user.uid}");
      await user.updateDisplayName(event.name); print("Registration: Display name updated.");
      try { await user.sendEmailVerification(); print("Registration: Verification email sent to ${user.email}."); }
      catch (e) { print("Registration: Warning - Failed to send verification email: $e"); }

      // 4. Prepare Firestore Data
      final authModel = AuthModel( uid: user.uid, name: event.name, username: event.username, email: event.email, nationalId: event.nationalId, phone: event.phone, gender: event.gender, dob: event.dob, image: '', uploadedId: false, isVerified: false, isBlocked: false, createdAt: Timestamp.now(), updatedAt: Timestamp.now(), lastSeen: Timestamp.now(), profilePicUrl: null );
      final modelMap = authModel.toMap();
      modelMap['createdAt'] = FieldValue.serverTimestamp(); modelMap['updatedAt'] = FieldValue.serverTimestamp(); modelMap['lastSeen'] = FieldValue.serverTimestamp(); modelMap['isApproved'] = false; // Default approval status

      // 5. Save to Firestore
      await _firestore.collection("endUsers").doc(user.uid).set(modelMap); print("Registration: User data (including username) saved to Firestore.");
      emit(const RegisterSuccessState()); print("Registration successful for user: ${user.uid}");

    } on FirebaseAuthException catch (e) {
       String errorMessage = 'Registration error';
       if (e.code == 'weak-password') { errorMessage = 'Password is too weak.'; }
       else if (e.code == 'email-already-in-use') { errorMessage = 'This email is already registered. Try logging in.'; }
       else if (e.code == 'invalid-email') { errorMessage = 'Please enter a valid email address.'; }
       else { errorMessage = e.message ?? errorMessage; }
       emit(AuthErrorState(errorMessage)); print("FirebaseAuthException during registration: ${e.code} - ${e.message}");
    } catch (e, s) { emit(AuthErrorState('Something went wrong during registration: ${e.toString()}')); print("Exception during registration: $e\n$s"); }
  }

  /// Handles the upload of ID images.
  Future<void> _uploadId(UploadIdEvent event, Emitter<AuthState> emit) async {
     emit(const AuthLoadingState());
     String? uploadedProfileUrl; String? uploadedIdFrontUrl; String? uploadedIdBackUrl;
    try {
      final user = _auth.currentUser; if (user == null) { emit(const AuthErrorState("User not logged in. Cannot upload ID.")); return; }
      final uid = user.uid; print("Uploading ID for user: $uid");
      String profileFolder = 'users/$uid/profilePic'; String idFrontFolder = 'users/$uid/idFront'; String idBackFolder = 'users/$uid/idBack';

      // Upload files
      print("Uploading profile picture..."); uploadedProfileUrl = await CloudinaryService.uploadFile(event.profilePic, folder: profileFolder);
      if (uploadedProfileUrl == null || uploadedProfileUrl.isEmpty) throw Exception("Profile picture upload failed."); print("Profile picture uploaded: $uploadedProfileUrl");
      print("Uploading ID front..."); uploadedIdFrontUrl = await CloudinaryService.uploadFile(event.idFront, folder: idFrontFolder);
      if (uploadedIdFrontUrl == null || uploadedIdFrontUrl.isEmpty) throw Exception("ID front upload failed."); print("ID front uploaded: $uploadedIdFrontUrl");
      print("Uploading ID back..."); uploadedIdBackUrl = await CloudinaryService.uploadFile(event.idBack, folder: idBackFolder);
       if (uploadedIdBackUrl == null || uploadedIdBackUrl.isEmpty) throw Exception("ID back upload failed."); print("ID back uploaded: $uploadedIdBackUrl");

      // Update Firestore
      await _firestore.collection("endUsers").doc(uid).update({ 'uploadedId': true, 'profilePicUrl': uploadedProfileUrl, 'image': uploadedProfileUrl, 'idFrontUrl': uploadedIdFrontUrl, 'idBackUrl': uploadedIdBackUrl, 'updatedAt': FieldValue.serverTimestamp(), }); print("Firestore updated with ID image URLs.");

      // Fetch updated user model
      print("AuthBloc: Fetching updated user model after ID upload...");
      final updatedDoc = await _firestore.collection("endUsers").doc(uid).get();
      if (!updatedDoc.exists) { throw Exception("Failed to fetch updated user profile after ID upload."); }
      final updatedAuthModel = AuthModel.fromFirestore(updatedDoc); print("AuthBloc: Updated user model fetched after ID upload.");

      // Emit success state WITH the updated user model
      emit(UploadIdSuccessState(user: updatedAuthModel));
      print("ID images uploaded and UploadIdSuccessState emitted successfully");

    } catch (e, s) {
      print("Exception during ID upload process: $e\n$s"); emit(AuthErrorState("ID Upload Failed: ${e.toString()}"));
      print("Error occurred during upload/update. Manual cleanup on Cloudinary might be needed if files were partially uploaded.");
      if (uploadedProfileUrl != null) print("Profile URL succeeded: $uploadedProfileUrl"); if (uploadedIdFrontUrl != null) print("ID Front URL succeeded: $uploadedIdFrontUrl"); if (uploadedIdBackUrl != null) print("ID Back URL succeeded: $uploadedIdBackUrl");
    }
  }

   /// Handles LogoutEvent
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
     emit(const AuthLoadingState()); print("AuthBloc: Logging out user...");
     try {
        await _auth.signOut(); print("AuthBloc: Firebase sign out successful.");
        await AppLocalStorage.cacheData(key: "isLoggedIn", value: false); await AppLocalStorage.cacheData(key: AppLocalStorage.userToken, value: null); print("AuthBloc: Local storage cleared.");
        emit(const AuthInitial()); print("AuthBloc: Emitted AuthInitial state after logout.");
     } catch (e, s) { print("AuthBloc: Error during logout: $e\n$s"); await AppLocalStorage.cacheData(key: "isLoggedIn", value: false); await AppLocalStorage.cacheData(key: AppLocalStorage.userToken, value: null); emit(AuthErrorState("Logout failed: ${e.toString()}")); }
  }

  /// Handles UpdateProfilePicture event
  Future<void> _onUpdateProfilePicture( UpdateProfilePicture event, Emitter<AuthState> emit) async {
      AuthState currentState = state; emit(const AuthLoadingState()); print("AuthBloc: Updating profile picture...");
     final user = _auth.currentUser; if (user == null) { emit(const AuthErrorState("User not logged in. Cannot update picture.")); return; }
     final uid = user.uid;
     try {
        String profileFolder = 'users/$uid/profilePic'; print("AuthBloc: Uploading new profile picture to Cloudinary...");
        final String? newProfilePicUrl = await CloudinaryService.uploadFile(event.imageFile, folder: profileFolder);
        if (newProfilePicUrl == null || newProfilePicUrl.isEmpty) { throw Exception("Cloudinary upload failed for profile picture."); }
         print("AuthBloc: New profile picture uploaded: $newProfilePicUrl");
         print("AuthBloc: Updating Firestore with new profile picture URL...");
         // Ensure field names here match your AuthModel and Firestore exactly
         await _firestore.collection("endUsers").doc(uid).update({ 'profilePicUrl': newProfilePicUrl, 'image': newProfilePicUrl, 'updatedAt': FieldValue.serverTimestamp(), }); print("AuthBloc: Firestore updated successfully.");
         print("AuthBloc: Fetching updated user model...");
         final updatedDoc = await _firestore.collection("endUsers").doc(uid).get();
          if (!updatedDoc.exists) { throw Exception("Failed to fetch updated user profile after picture update."); }
         final updatedAuthModel = AuthModel.fromFirestore(updatedDoc); print("AuthBloc: Updated user model fetched.");
         emit(LoginSuccessState(user: updatedAuthModel)); print("AuthBloc: Emitted LoginSuccessState with updated profile picture.");
     } catch (e, s) { print("AuthBloc: Error updating profile picture: $e\n$s"); emit(AuthErrorState("Failed to update profile picture: ${e.toString()}")); }
  }

  /// Handles SendPasswordResetEmail event
  Future<void> _onSendPasswordResetEmail( SendPasswordResetEmail event, Emitter<AuthState> emit) async {
     emit(const AuthLoadingState()); print("AuthBloc: Sending password reset email to ${event.email}...");
     try {
        await _auth.sendPasswordResetEmail(email: event.email); print("AuthBloc: Password reset email sent successfully.");
        emit(const PasswordResetEmailSentState());
     } on FirebaseAuthException catch (e) {
        String errorMessage = "Failed to send password reset email.";
        if (e.code == 'user-not-found' || e.code == 'invalid-email') { errorMessage = "No user found for that email, or email is invalid."; }
        else { errorMessage = e.message ?? errorMessage; }
        print("AuthBloc: Error sending password reset email: ${e.code} - ${e.message}"); emit(AuthErrorState(errorMessage));
     } catch (e, s) { print("AuthBloc: Generic error sending password reset email: $e\n$s"); emit(AuthErrorState("Failed to send password reset email: ${e.toString()}")); }
  }

  /// Handles CheckEmailVerificationStatus event
  Future<void> _onCheckEmailVerificationStatus( CheckEmailVerificationStatus event, Emitter<AuthState> emit) async {
     print("AuthBloc: Checking email verification status..."); User? user = _auth.currentUser;
     if (user == null) { print("AuthBloc: No user found while checking verification status."); emit(const AuthInitial()); return; }
     try {
        await user.reload(); user = _auth.currentUser;
        if (user == null) { print("AuthBloc: User became null after reload during verification check."); emit(const AuthInitial()); return; }
        print("AuthBloc: Current verification status for ${user.email}: ${user.emailVerified}");
        if (user.emailVerified) {
           print("AuthBloc: Email verified. Fetching user data...");
           final DocumentSnapshot doc = await _firestore.collection("endUsers").doc(user.uid).get();
           if (doc.exists) { final authModel = AuthModel.fromFirestore(doc); emit(LoginSuccessState(user: authModel)); print("AuthBloc: Emitted LoginSuccessState after verification check."); }
           else { print("AuthBloc: Error - User document not found after email verification."); emit(AuthErrorState("User profile not found after verification. UID: ${user.uid}")); }
        } else { print("AuthBloc: Email still not verified. Emitting AwaitingVerificationState."); emit(AwaitingVerificationState(user.email!)); }
     } catch (e, s) { print("AuthBloc: Error checking email verification status: $e\n$s"); emit(AuthErrorState("Failed to check email status: ${e.toString()}")); }
  }

   /// Handles UpdateUserProfile event
   Future<void> _onUpdateUserProfile( UpdateUserProfile event, Emitter<AuthState> emit) async {
      AuthState currentState = state; emit(const AuthLoadingState()); print("AuthBloc: Updating user profile...");
      final user = _auth.currentUser; if (user == null) { emit(const AuthErrorState("User not logged in. Cannot update profile.")); return; }
      final uid = user.uid;
      try {
         Map<String, dynamic> dataToUpdate = Map.from(event.updatedData); print("AuthBloc: Data received for update: $dataToUpdate");
         // *** IMPORTANT: Add validation/sanitization for updatedData here ***
         // Remove fields that shouldn't be updated directly
         dataToUpdate.remove('email'); dataToUpdate.remove('uid'); dataToUpdate.remove('isApproved'); dataToUpdate.remove('isBlocked'); dataToUpdate.remove('createdAt'); dataToUpdate.remove('uploadedId'); dataToUpdate.remove('profilePicUrl'); dataToUpdate.remove('image'); dataToUpdate.remove('username'); // Don't allow username change here easily
         dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();
         if (dataToUpdate.isEmpty || dataToUpdate.length == 1 && dataToUpdate.containsKey('updatedAt')) {
             print("AuthBloc: No valid fields provided for profile update.");
             if (currentState is LoginSuccessState) {
               emit(currentState);
             } else { final doc = await _firestore.collection("endUsers").doc(uid).get(); if (doc.exists) {
               emit(LoginSuccessState(user: AuthModel.fromFirestore(doc)));
             } else {
               emit(const AuthErrorState("Failed to load profile after empty update attempt."));
             } }
             return;
         }
         print("AuthBloc: Updating Firestore profile with data: $dataToUpdate");
         await _firestore.collection("endUsers").doc(uid).update(dataToUpdate); print("AuthBloc: Firestore profile update successful.");
         print("AuthBloc: Fetching updated user model after profile update...");
         final updatedDoc = await _firestore.collection("endUsers").doc(uid).get();
         if (!updatedDoc.exists) { throw Exception("Failed to fetch updated user profile after general update."); }
         final updatedAuthModel = AuthModel.fromFirestore(updatedDoc); print("AuthBloc: Updated user model fetched.");
         emit(LoginSuccessState(user: updatedAuthModel)); print("AuthBloc: Emitted LoginSuccessState with updated profile data.");
      } catch (e, s) { print("AuthBloc: Error updating user profile: $e\n$s"); emit(AuthErrorState("Failed to update profile: ${e.toString()}")); }
   }

}

