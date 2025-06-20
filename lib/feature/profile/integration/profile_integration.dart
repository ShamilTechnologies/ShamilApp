import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shamil_mobile_app/feature/profile/repository/profile_repository.dart';
import 'package:shamil_mobile_app/feature/profile/bloc/profile_bloc.dart';
import 'package:shamil_mobile_app/feature/social/bloc/social_bloc.dart';
import 'package:shamil_mobile_app/core/data/firebase_data_orchestrator.dart';

/// Integration helper for profile system
class ProfileIntegration {
  static ProfileRepository? _profileRepository;
  static ProfileBloc? _profileBloc;

  /// Initialize profile system
  static void initialize() {
    _profileRepository ??= ProfileRepository();
  }

  /// Get profile repository instance
  static ProfileRepository getProfileRepository() {
    _profileRepository ??= ProfileRepository();
    return _profileRepository!;
  }

  /// Create profile bloc
  static ProfileBloc createProfileBloc() {
    return ProfileBloc(
      profileRepository: getProfileRepository(),
    );
  }

  /// Update social bloc to include profile repository
  static SocialBloc createSocialBloc(
      FirebaseDataOrchestrator dataOrchestrator) {
    return SocialBloc(
      dataOrchestrator: dataOrchestrator,
      profileRepository: getProfileRepository(),
    );
  }

  /// Provide all profile-related blocs
  static List<BlocProvider> getProfileProviders(
      FirebaseDataOrchestrator dataOrchestrator) {
    return [
      BlocProvider<ProfileBloc>(
        create: (context) => createProfileBloc(),
      ),
      BlocProvider<SocialBloc>(
        create: (context) => createSocialBloc(dataOrchestrator),
      ),
    ];
  }

  /// Dispose resources
  static void dispose() {
    _profileBloc?.close();
    _profileRepository = null;
    _profileBloc = null;
  }
}

/// Extension methods for easy navigation to profile views
extension ProfileNavigation on NavigatorState {
  Future<T?> pushProfile<T extends Object?>(String userId) {
    return pushNamed('/profile', arguments: userId);
  }

  Future<T?> pushSettings<T extends Object?>() {
    return pushNamed('/settings');
  }

  Future<T?> pushFindFriends<T extends Object?>() {
    return pushNamed('/find-friends');
  }
}
