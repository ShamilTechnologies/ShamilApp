import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:shamil_mobile_app/core/services/local_storage.dart';
import 'package:shamil_mobile_app/feature/auth/data/authModel.dart';
import 'package:shamil_mobile_app/cloudinary_service.dart'; // Cloudinary upload service

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<RegisterEvent>(_register);
    on<LoginEvent>(_login);
    on<UploadIdEvent>(_uploadId);
  }

  /// Handles the login event.
  Future<void> _login(LoginEvent event, Emitter<AuthState> emit) async {
    emit(LoginLoadingState());
    try {
      print("Starting login for email: ${event.email}");
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final User user = userCredential.user!;
      print("User logged in: ${user.uid}");

      // Retrieve and cache the Firebase ID token.
      final token = await user.getIdToken();
      print("Token retrieved: $token");
      await AppLocalStorage.cacheData(
        key: AppLocalStorage.userToken,
        value: token,
      );
      print("Token cached successfully");

      // Store the login state flag.
      await AppLocalStorage.cacheData(
        key: "isLoggedIn",
        value: true,
      );
      print("isLoggedIn flag cached");

      // Fetch the user document from Firestore and create an AuthModel.
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("endUsers")
          .doc(user.uid)
          .get();
      final authModel = AuthModel.fromFirestore(doc);
      print("User data fetched from Firestore");

      emit(LoginSuccessState(user: authModel));
      print("LoginSuccessState emitted");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        emit(AuthErrorState("Account not found"));
      } else if (e.code == 'wrong-password') {
        emit(AuthErrorState("Wrong password"));
      } else {
        emit(AuthErrorState(e.message ?? 'Authentication error'));
      }
      print("FirebaseAuthException: ${e.code} - ${e.message}");
    } catch (e) {
      emit(AuthErrorState('Something went wrong'));
      print("General exception during login: $e");
    }
  }

  /// Handles the registration event.
  Future<void> _register(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(RegisterLoadingState());
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final User user = userCredential.user!;

      await user.updateDisplayName(event.name);
      await user.sendEmailVerification();

      final authModel = AuthModel(
        uid: user.uid,
        name: event.name,
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
      );

      final modelMap = authModel.toMap();
      modelMap['createdAt'] = FieldValue.serverTimestamp();
      modelMap['updatedAt'] = FieldValue.serverTimestamp();
      modelMap['lastSeen'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection("endUsers").doc(user.uid).set(modelMap);
      emit(RegisterSuccessState());
      print("Registration successful for user: ${user.uid}");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        emit(AuthErrorState('Password is weak'));
      } else if (e.code == 'email-already-in-use') {
        emit(AuthErrorState('Email is already in use'));
      } else {
        emit(AuthErrorState(e.message ?? 'Registration error'));
      }
      print("FirebaseAuthException in registration: ${e.code} - ${e.message}");
    } catch (e) {
      emit(AuthErrorState('Something went wrong'));
      print("Exception during registration: $e");
    }
  }

  /// Handles the upload of ID images from the "One More Step" screen using Cloudinary.
  /// Files are partitioned into distinct folders for easier identification:
  /// - Profile picture → users/<uid>/profilePic/...
  /// - Front ID → users/<uid>/idFront/...
  /// - Back ID → users/<uid>/idBack/...
  Future<void> _uploadId(UploadIdEvent event, Emitter<AuthState> emit) async {
    emit(UploadIdLoadingState());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(AuthErrorState("User not logged in"));
        return;
      }
      final uid = user.uid;
      print("Uploading ID for user: $uid");

      // Upload files concurrently to distinct folders.
      final results = await Future.wait([
        CloudinaryService.uploadFile(event.profilePic, folder: 'users/$uid/profilePic'),
        CloudinaryService.uploadFile(event.idFront, folder: 'users/$uid/idFront'),
        CloudinaryService.uploadFile(event.idBack, folder: 'users/$uid/idBack'),
      ]);

      final profilePicUrl = results[0];
      final idFrontUrl = results[1];
      final idBackUrl = results[2];

      if (profilePicUrl == null || idFrontUrl == null || idBackUrl == null) {
        emit(AuthErrorState("Error uploading one or more files"));
        print("Error: one or more file URLs are null");
        return;
      }

      // Update Firestore with the Cloudinary URLs.
      await FirebaseFirestore.instance.collection("endUsers").doc(uid).update({
        'uploadedId': true,
        'profilePicUrl': profilePicUrl,
        'idFrontUrl': idFrontUrl,
        'idBackUrl': idBackUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      emit(UploadIdSuccessState());
      print("ID images uploaded and Firestore updated successfully");
    } catch (e) {
      emit(AuthErrorState(e.toString()));
      print("Exception during ID upload: $e");
    }
  }
}
