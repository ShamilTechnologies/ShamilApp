import 'package:flutter/material.dart';
import 'package:shamil_mobile_app/feature/auth/views/bloc/auth_bloc.dart';
import 'package:shamil_mobile_app/core/widgets/enhanced_stroke_loader.dart';

/// Mixin to provide auth loading functionality to any widget
mixin AuthLoadingMixin<T extends StatefulWidget> on State<T> {
  /// Shows loading overlay for auth operations
  void showAuthLoading(
    BuildContext context, {
    String? customMessage,
    Map<Type, String>? stateMessages,
  }) {
    LoadingOverlay.showLoading(
      context,
      message: customMessage ?? _getContextualMessage(stateMessages),
    );
  }

  /// Shows success overlay for auth operations
  void showAuthSuccess(
    BuildContext context, {
    String? message,
    VoidCallback? onComplete,
  }) {
    LoadingOverlay.showSuccess(
      context,
      message: message ?? 'Success!',
      onComplete: onComplete,
    );
  }

  /// Shows error overlay for auth operations
  void showAuthError(
    BuildContext context, {
    String? message,
    VoidCallback? onComplete,
  }) {
    LoadingOverlay.showError(
      context,
      message: message ?? 'Something went wrong',
      onComplete: onComplete,
    );
  }

  /// Hides any active overlay
  void hideAuthOverlay() {
    LoadingOverlay.hide();
  }

  /// Gets contextual loading message based on current screen
  String? _getContextualMessage(Map<Type, String>? stateMessages) {
    if (stateMessages != null) {
      // Use custom state messages if provided
      for (final entry in stateMessages.entries) {
        if (T
            .toString()
            .toLowerCase()
            .contains(entry.key.toString().toLowerCase())) {
          return entry.value;
        }
      }
    }

    // Default messages based on screen type
    final screenName = T.toString().toLowerCase();

    if (screenName.contains('login')) {
      return 'Signing in to your account...';
    } else if (screenName.contains('register') ||
        screenName.contains('signup')) {
      return 'Creating your account...';
    } else if (screenName.contains('forgot') || screenName.contains('reset')) {
      return 'Sending reset email...';
    } else if (screenName.contains('upload') || screenName.contains('id')) {
      return 'Uploading your documents...';
    } else if (screenName.contains('profile')) {
      return 'Updating your profile...';
    }

    return 'Loading...';
  }
}

/// Extension to add auth loading to any AuthState
extension AuthStateLoadingExtension on AuthState {
  bool get isLoading => this is AuthLoadingState;

  String? get loadingMessage {
    if (this is AuthLoadingState) {
      return (this as AuthLoadingState).message;
    }
    return null;
  }
}
